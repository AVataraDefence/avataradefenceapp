import 'dart:async';
import 'dart:convert';

import 'package:web_socket_channel/io.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import 'api_client.dart';
import 'api_config.dart';

/// Real-time channel to the web server's `/ws` (notifications).
///
/// The server only accepts a connection carrying the signed-in `session` cookie, so sign in
/// with [ApiClient] first. The connection is kept alive for you: if it drops (Wi-Fi switch,
/// server restart) it reconnects with 1s, 2s, 4s … 30s back-off, and [connected] tells the UI
/// when pushes are arriving live. Messages from the server are `{type, data}`:
///   `{"type":"ready"}`                         once, right after connecting
///   `{"type":"notification","data":{...}}`     a new notification for the user
class ApiSocket {
  ApiSocket(this._api);

  final ApiClient _api;
  final _messages = StreamController<Map<String, dynamic>>.broadcast();
  final _connected = StreamController<bool>.broadcast();

  WebSocketChannel? _channel;
  Timer? _retry;
  int _attempt = 0;
  bool _wanted = false;
  bool _isConnected = false;

  /// Every message the server pushes.
  Stream<Map<String, dynamic>> get messages => _messages.stream;

  /// Only `notification` pushes, unwrapped to their `data` map (same shape as `GET /api/notifications`).
  Stream<Map<String, dynamic>> get notifications => _messages.stream
      .where((m) => m['type'] == 'notification' && m['data'] is Map)
      .map((m) => Map<String, dynamic>.from(m['data'] as Map));

  Stream<bool> get connected => _connected.stream;
  bool get isConnected => _isConnected;

  /// Starts (and keeps) the connection. Safe to call again; does nothing without a session.
  void connect() {
    _wanted = true;
    if (_channel != null || !_api.hasSession) return;
    _open();
  }

  /// Closes the socket and stops reconnecting (call on sign-out).
  void disconnect() {
    _wanted = false;
    _retry?.cancel();
    _channel?.sink.close();
    _channel = null;
    _setConnected(false);
  }

  void dispose() {
    disconnect();
    _messages.close();
    _connected.close();
  }

  void _open() {
    final channel = IOWebSocketChannel.connect(
      Uri.parse(ApiConfig.webSocketUrl),
      headers: {'Cookie': _api.cookieHeader!},
      connectTimeout: ApiConfig.connectTimeout,
    );
    _channel = channel;
    channel.stream.listen(
      (raw) {
        if (!_isConnected) {
          _attempt = 0;
          _setConnected(true);
        }
        try {
          final decoded = jsonDecode(raw as String);
          if (decoded is Map<String, dynamic>) _messages.add(decoded);
        } catch (_) {/* ignore malformed frames */}
      },
      onError: (_) {},
      onDone: _onClosed,
      cancelOnError: true,
    );
  }

  void _onClosed() {
    _channel = null;
    _setConnected(false);
    if (!_wanted || !_api.hasSession) return;
    final seconds = (1 << _attempt).clamp(1, 30);
    if (_attempt < 5) _attempt++;
    _retry = Timer(Duration(seconds: seconds), () {
      if (_wanted && _channel == null && _api.hasSession) _open();
    });
  }

  void _setConnected(bool value) {
    if (_isConnected == value) return;
    _isConnected = value;
    if (!_connected.isClosed) _connected.add(value);
  }
}
