import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../core/api/api.dart';

/// Keeps the sign-in token on the device (Keychain / Android Keystore) so the user stays
/// signed in between launches, like the browser's 7-day cookie.
class SecureSessionStore implements SessionStore {
  static const _key = 'avd_session';
  final _storage = const FlutterSecureStorage();

  @override
  Future<String?> read() async {
    try {
      return await _storage.read(key: _key);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> write(String? token) async {
    try {
      if (token == null) {
        await _storage.delete(key: _key);
      } else {
        await _storage.write(key: _key, value: token);
      }
    } catch (_) {/* storage unavailable: the session just lasts for this run */}
  }
}

/// The app-wide API client + live socket. Screens read `AppApi.client`.
class AppApi {
  AppApi._();

  /// Lets non-widget code (a 401 from any call) push the sign-in screen.
  static final navigatorKey = GlobalKey<NavigatorState>();

  /// Set by the session: called when a signed-in user's token is rejected.
  static VoidCallback? onSessionExpired;

  static ApiClient client = ApiClient(sessionStore: SecureSessionStore(), onUnauthorized: () => onSessionExpired?.call());
  static ApiSocket socket = ApiSocket(client);

  /// Opens the live notification socket after sign-in (off in tests).
  static bool liveSocket = true;

  /// Swaps the client (tests inject one backed by a fake server).
  static void configure(ApiClient c) {
    client = c;
    socket = ApiSocket(c);
  }
}

/// Pulls a list out of an API result (`data` is a list) — empty when the call failed.
List<Map<String, dynamic>> asRows(ApiResult<dynamic> r) =>
    r.ok && r.data is List ? [for (final x in r.data as List) if (x is Map) Map<String, dynamic>.from(x)] : <Map<String, dynamic>>[];
