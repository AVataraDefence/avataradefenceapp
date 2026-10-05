import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import 'api_config.dart';

/// Outcome of one API call. The web API always answers `{ success, message, data }`;
/// this unwraps it so screens branch on [ok] and never parse JSON or catch exceptions.
class ApiResult<T> {
  const ApiResult({required this.ok, required this.statusCode, required this.message, this.data});

  final bool ok;

  /// HTTP status, or 0 when the server could not be reached at all.
  final int statusCode;
  final String message;
  final T? data;

  bool get unauthorized => statusCode == 401;
  bool get forbidden => statusCode == 403;
  bool get offline => statusCode == 0;

  @override
  String toString() => 'ApiResult(ok: $ok, status: $statusCode, message: $message)';
}

/// Keeps the sign-in token between app launches. The default keeps it in memory only;
/// plug in one backed by secure storage when the login screen is built.
abstract class SessionStore {
  Future<String?> read();
  Future<void> write(String? token);
}

class MemorySessionStore implements SessionStore {
  String? _token;

  @override
  Future<String?> read() async => _token;

  @override
  Future<void> write(String? token) async => _token = token;
}

/// HTTP client for the web project's `/api/*` routes.
///
/// The web app authenticates with an HttpOnly `session` cookie (JWT). A browser keeps it
/// automatically; a mobile client does not, so this class reads it from the sign-in
/// response's `Set-Cookie`, stores it in a [SessionStore], and sends it on every request
/// (and exposes it for the WebSocket handshake).
class ApiClient {
  ApiClient({http.Client? httpClient, SessionStore? sessionStore, this.onUnauthorized})
      : _http = httpClient ?? http.Client(),
        _store = sessionStore ?? MemorySessionStore();

  final http.Client _http;
  final SessionStore _store;

  /// Called when any call comes back 401 (token expired / signed out) so the app can
  /// route to the login screen.
  final void Function()? onUnauthorized;

  String? _session;

  /// Loads a token saved by a previous run. Call once at app start.
  Future<void> restoreSession() async => _session = await _store.read();

  bool get hasSession => _session != null && _session!.isNotEmpty;

  /// `session=<jwt>` — the exact header value the server expects (also for `/ws`).
  String? get cookieHeader => hasSession ? 'session=$_session' : null;

  Future<void> clearSession() async {
    _session = null;
    await _store.write(null);
  }

  // ── Requests ───────────────────────────────────────────────────────────────
  Future<ApiResult<dynamic>> get(String path, {Map<String, String>? query}) =>
      _send('GET', path, query: query);

  Future<ApiResult<dynamic>> post(String path, {Object? body}) => _send('POST', path, body: body);

  Future<ApiResult<dynamic>> put(String path, {Object? body}) => _send('PUT', path, body: body);

  Future<ApiResult<dynamic>> delete(String path) => _send('DELETE', path);

  /// File upload (`multipart/form-data`): task / project / employee documents, photos.
  Future<ApiResult<dynamic>> postMultipart(String path, {Map<String, String> fields = const {}, List<http.MultipartFile> files = const []}) =>
      _send('POST', path, fields: fields, files: files);

  Future<ApiResult<dynamic>> putMultipart(String path, {Map<String, String> fields = const {}, List<http.MultipartFile> files = const []}) =>
      _send('PUT', path, fields: fields, files: files);

  // ── Internals ──────────────────────────────────────────────────────────────
  Future<ApiResult<dynamic>> _send(
    String method,
    String path, {
    Map<String, String>? query,
    Object? body,
    Map<String, String>? fields,
    List<http.MultipartFile>? files,
  }) async {
    final uri = ApiConfig.uri(path, query);
    final multipart = files != null;
    try {
      final http.BaseRequest request;
      if (multipart) {
        request = http.MultipartRequest(method, uri)
          ..fields.addAll(fields ?? const {})
          ..files.addAll(files);
      } else {
        final r = http.Request(method, uri);
        if (body != null) {
          r.headers['Content-Type'] = 'application/json';
          r.body = jsonEncode(body);
        }
        request = r;
      }
      request.headers['Accept'] = 'application/json';
      final cookie = cookieHeader;
      if (cookie != null) request.headers['Cookie'] = cookie;

      final timeout = multipart ? ApiConfig.uploadTimeout : ApiConfig.receiveTimeout;
      final streamed = await _http.send(request).timeout(timeout);
      final response = await http.Response.fromStream(streamed);

      await _captureSession(response);
      final result = _parse(response);
      if (result.unauthorized) onUnauthorized?.call();
      return result;
    } on TimeoutException {
      return const ApiResult(ok: false, statusCode: 0, message: 'The server took too long to answer. Please try again.');
    } on http.ClientException {
      return ApiResult(ok: false, statusCode: 0, message: 'Cannot reach the server at ${ApiConfig.baseUrl}. Check your connection.');
    } catch (_) {
      return const ApiResult(ok: false, statusCode: 0, message: 'Something went wrong. Please try again.');
    }
  }

  /// Sign-in sets `session=<jwt>`; sign-out (and expiry) sends it back empty / `Max-Age=0`.
  Future<void> _captureSession(http.Response response) async {
    final header = response.headers['set-cookie'];
    if (header == null) return;
    final match = RegExp(r'(?:^|[\s,;])session=([^;,\s]*)').firstMatch(header);
    if (match == null) return;
    final value = match.group(1) ?? '';
    final expired = value.isEmpty || RegExp(r'max-age=0', caseSensitive: false).hasMatch(header);
    _session = expired ? null : value;
    await _store.write(_session);
  }

  ApiResult<dynamic> _parse(http.Response response) {
    final status = response.statusCode;
    Map<String, dynamic>? json;
    try {
      final decoded = jsonDecode(utf8.decode(response.bodyBytes));
      if (decoded is Map<String, dynamic>) json = decoded;
    } catch (_) {/* non-JSON body (HTML error page, proxy) */}

    if (json == null) {
      return ApiResult(ok: false, statusCode: status, message: 'Unexpected response from the server ($status).');
    }
    final success = json['success'] == true && status >= 200 && status < 300;
    return ApiResult(
      ok: success,
      statusCode: status,
      message: (json['message'] as String?) ?? (success ? 'OK' : 'Request failed'),
      data: json['data'],
    );
  }

  void close() => _http.close();
}
