import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:avataradefence/core/api/api.dart';

http.Response json(Object body, {int status = 200, Map<String, String> headers = const {}}) =>
    http.Response(jsonEncode(body), status, headers: {'content-type': 'application/json', ...headers});

void main() {
  group('ApiConfig', () {
    test('default base URL is the live site, without a trailing slash', () {
      expect(ApiConfig.baseUrl, ApiConfig.productionUrl);
      expect(ApiConfig.baseUrl.endsWith('/'), isFalse);
    });

    test('uri() joins path and query onto the base URL', () {
      final u = ApiConfig.uri(ApiEndpoints.tasks, {'scope': 'mine'});
      expect(u.toString(), '${ApiConfig.baseUrl}/api/tasks?scope=mine');
      expect(ApiConfig.uri('api/db-test').path, '/api/db-test');
    });

    test('WebSocket URL is ws(s):// on the same host at /ws', () {
      final ws = Uri.parse(ApiConfig.webSocketUrl);
      expect(ws.scheme, 'wss');
      expect(ws.path, '/ws');
      expect(ws.host, Uri.parse(ApiConfig.baseUrl).host);
    });
  });

  group('ApiEndpoints', () {
    test('paths match the web routes', () {
      expect(ApiEndpoints.signIn, '/api/auth/signin');
      expect(ApiEndpoints.task(17), '/api/tasks/17');
      expect(ApiEndpoints.taskChecklistItem(17, 3), '/api/tasks/17/checklist/3');
      expect(ApiEndpoints.projectDocument(1, 9), '/api/projects/1/documents/9');
      expect(ApiEndpoints.settingsUserReportsTo(2), '/api/settings/users/2/reports-to');
      expect(ApiEndpoints.byId(ApiEndpoints.departments, 4), '/api/master-data/departments/4');
    });
  });

  group('ApiClient', () {
    test('unwraps the { success, message, data } envelope', () async {
      final api = ApiClient(httpClient: MockClient((_) async => json({'success': true, 'message': 'Tasks fetched', 'data': [1, 2]})));
      final r = await api.get(ApiEndpoints.tasks, query: {'scope': 'mine'});
      expect(r.ok, isTrue);
      expect(r.message, 'Tasks fetched');
      expect(r.data, [1, 2]);
    });

    test('server errors keep the server message and status', () async {
      final api = ApiClient(httpClient: MockClient((_) async => json({'success': false, 'message': 'Only the creator can edit'}, status: 403)));
      final r = await api.put(ApiEndpoints.task(5), body: {'title': 'x'});
      expect(r.ok, isFalse);
      expect(r.forbidden, isTrue);
      expect(r.message, 'Only the creator can edit');
    });

    test('sends JSON bodies and keeps the session cookie from sign-in', () async {
      final seen = <http.Request>[];
      final api = ApiClient(
        httpClient: MockClient((req) async {
          seen.add(req);
          if (req.url.path == '/api/auth/signin') {
            return json({'success': true, 'message': 'ok', 'data': {}}, headers: {'set-cookie': 'session=abc.def.ghi; Path=/; HttpOnly; SameSite=Lax'});
          }
          return json({'success': true, 'message': 'ok'});
        }),
      );

      await api.post(ApiEndpoints.signIn, body: {'identifier': 'rushi', 'password': 'pw'});
      expect(jsonDecode(seen.first.body), {'identifier': 'rushi', 'password': 'pw'});
      expect(seen.first.headers['Content-Type'], contains('application/json'));
      expect(api.hasSession, isTrue);
      expect(api.cookieHeader, 'session=abc.def.ghi');

      await api.get(ApiEndpoints.myPermissions);
      expect(seen.last.headers['Cookie'], 'session=abc.def.ghi');
    });

    test('sign-out (empty cookie) clears the session', () async {
      final api = ApiClient(
        httpClient: MockClient((req) async => json({'success': true, 'message': 'ok'}, headers: {'set-cookie': 'session=; Path=/; Max-Age=0'})),
        sessionStore: MemorySessionStore(),
      );
      await api.post(ApiEndpoints.signOut);
      expect(api.hasSession, isFalse);
    });

    test('401 triggers onUnauthorized', () async {
      var called = 0;
      final api = ApiClient(
        httpClient: MockClient((_) async => json({'success': false, 'message': 'Authentication required'}, status: 401)),
        onUnauthorized: () => called++,
      );
      final r = await api.get(ApiEndpoints.tasks);
      expect(r.unauthorized, isTrue);
      expect(called, 1);
    });

    test('network failure becomes a friendly offline result, not an exception', () async {
      final api = ApiClient(httpClient: MockClient((_) async => throw http.ClientException('no route')));
      final r = await api.get(ApiEndpoints.tasks);
      expect(r.ok, isFalse);
      expect(r.offline, isTrue);
      expect(r.message, contains(ApiConfig.baseUrl));
    });

    test('non-JSON bodies (HTML error page) do not crash', () async {
      final api = ApiClient(httpClient: MockClient((_) async => http.Response('<html>502</html>', 502)));
      final r = await api.get(ApiEndpoints.tasks);
      expect(r.ok, isFalse);
      expect(r.statusCode, 502);
    });

    test('multipart uploads carry fields, files and the cookie', () async {
      http.BaseRequest? seen;
      final api = ApiClient(
        httpClient: MockClient.streaming((req, body) async {
          seen = req;
          final text = await http.ByteStream(body).bytesToString();
          expect(text, contains('files'));
          expect(text, contains('hello.txt'));
          return http.StreamedResponse(Stream.value(utf8.encode(jsonEncode({'success': true, 'message': 'ok', 'data': []}))), 201,
              headers: {'content-type': 'application/json'});
        }),
        sessionStore: MemorySessionStore()..write('tok'),
      );
      await api.restoreSession();
      final r = await api.postMultipart(
        ApiEndpoints.taskDocuments(17),
        files: [http.MultipartFile.fromString('files', 'hi', filename: 'hello.txt')],
      );
      expect(r.ok, isTrue);
      expect(seen!.headers['Cookie'], 'session=tok');
      expect(seen!.headers['content-type'], contains('multipart/form-data'));
    });
  });
}
