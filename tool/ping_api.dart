// ignore_for_file: avoid_print
// Quick connectivity check against the web API:
//   dart run tool/ping_api.dart
//   dart run -DAPI_ENV=emulator tool/ping_api.dart
//   dart run -DAPI_BASE_URL=http://192.168.1.20:3000 tool/ping_api.dart
import 'package:avataradefence/core/api/api.dart';

Future<void> main() async {
  final api = ApiClient();
  print('Base URL : ${ApiConfig.baseUrl}');
  print('WebSocket: ${ApiConfig.webSocketUrl}');

  final db = await api.get(ApiEndpoints.dbTest);
  print('GET ${ApiEndpoints.dbTest}  ->  ${db.statusCode} ${db.ok ? 'OK' : db.message}');

  // Protected route without a session: the server must answer 401.
  final me = await api.get(ApiEndpoints.myPermissions);
  print('GET ${ApiEndpoints.myPermissions}  ->  ${me.statusCode} (${me.unauthorized ? '401 as expected, no session' : me.message})');
  api.close();
}
