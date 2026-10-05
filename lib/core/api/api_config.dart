/// Where the app finds the Avatara Defence web API (the Next.js project in
/// `../avataradefence`, whose `/api/...` routes the app reuses as-is).
///
/// **Change the addresses here — nowhere else.**
///
/// | Environment | URL                          | When                                  |
/// |-------------|------------------------------|---------------------------------------|
/// | `device`    | [deviceUrl]  (PC's LAN IP)   | real phone on the same Wi-Fi          |
/// | `emulator`  | [emulatorUrl] (10.0.2.2)     | Android emulator (10.0.2.2 = your PC) |
/// | `local`     | [localUrl] (localhost)       | iOS simulator, desktop, web           |
/// | `production`| [productionUrl]              | the live site (default)               |
///
/// With no flag the app uses the live site. Pick another without editing code:
///   flutter run --dart-define=API_ENV=device      (PC on the same Wi-Fi)
///   flutter run --dart-define=API_ENV=emulator
/// or point at any server directly:
///   flutter run --dart-define=API_BASE_URL=http://192.168.1.20:3000
class ApiConfig {
  ApiConfig._();

  /// PC running `npm run dev` for the web project. If your Wi-Fi gives the PC a new
  /// IP, update this one line (find it with `ipconfig`).
  static const String deviceUrl = 'http://192.168.1.6:3000';
  static const String emulatorUrl = 'http://10.0.2.2:3000';
  static const String localUrl = 'http://localhost:3000';

  /// The deployed web app (default). Must be https for release builds.
  static const String productionUrl = 'https://avataradefenceerp.cloud';

  static const String _override = String.fromEnvironment('API_BASE_URL');
  static const String _env = String.fromEnvironment('API_ENV', defaultValue: 'production');

  /// Base URL without a trailing slash, e.g. `http://192.168.1.6:3000`.
  static String get baseUrl {
    if (_override.isNotEmpty) return _trim(_override);
    return _trim(switch (_env) {
      'emulator' => emulatorUrl,
      'local' => localUrl,
      'production' => productionUrl,
      _ => deviceUrl,
    });
  }

  /// Real-time notifications socket (`/ws`), same host, `ws://` / `wss://`.
  /// It needs the signed-in `session` cookie, like the browser.
  static String get webSocketUrl {
    final u = Uri.parse(baseUrl);
    return u.replace(scheme: u.scheme == 'https' ? 'wss' : 'ws', path: '/ws').toString();
  }

  /// Build a full URL from an endpoint path (see [ApiEndpoints]).
  static Uri uri(String path, [Map<String, String>? query]) {
    final base = Uri.parse(baseUrl);
    return base.replace(path: path.startsWith('/') ? path : '/$path', queryParameters: query?.isEmpty ?? true ? null : query);
  }

  static const Duration connectTimeout = Duration(seconds: 15);
  static const Duration receiveTimeout = Duration(seconds: 30);

  /// Uploads (task / project / employee documents) can be slow on mobile data.
  static const Duration uploadTimeout = Duration(minutes: 2);

  static String _trim(String url) => url.endsWith('/') ? url.substring(0, url.length - 1) : url;
}
