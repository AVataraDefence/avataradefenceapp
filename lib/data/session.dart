import 'package:flutter/foundation.dart';

import '../push/push_service.dart';
import '../core/core.dart';
import 'app_api.dart';
import 'directory.dart';
import 'notifications_store.dart';

/// Who is signed in, and what they may open (web `PermissionsContext` + the sign-in flow).
class AppSession extends ChangeNotifier {
  AppSession._() {
    AppApi.onSessionExpired = _expired;
  }
  static final AppSession instance = AppSession._();

  bool _signedIn = false;
  bool get signedIn => _signedIn;

  Rec? _user;
  List<Rec> _permissions = [];
  String _displayName = '';

  /// Called when a signed-in session is rejected (token expired) — the app routes to sign in.
  VoidCallback? onExpired;

  int get userId => (_user?['userId'] as num?)?.toInt() ?? 0;
  String get username => '${_user?['username'] ?? ''}';
  String get email => '${_user?['email'] ?? ''}';
  String? get imageUrl => _user?['imageUrl'] as String?;
  String get userName => _displayName.isNotEmpty ? _displayName : (username.isEmpty ? 'Not signed in' : username);

  /// Restores the saved token. True when it is still valid.
  Future<bool> restore() async {
    await AppApi.client.restoreSession();
    if (!AppApi.client.hasSession) return false;
    return _afterAuth();
  }

  Future<ApiResult<dynamic>> signIn(String identifier, String password) async {
    final r = await AppApi.client.post(ApiEndpoints.signIn, body: {'identifier': identifier, 'password': password});
    if (!r.ok) return r;
    if (!await _afterAuth()) {
      return const ApiResult(ok: false, statusCode: 0, message: 'Signed in, but your permissions could not be loaded. Please try again.');
    }
    return r;
  }

  Future<ApiResult<dynamic>> signUp({required String email, required String password, required String username}) =>
      AppApi.client.post(ApiEndpoints.signUp, body: {'email': email, 'password': password, 'username': username});

  Future<void> signOut() async {
    AppApi.socket.disconnect();
    await PushService.unregister();
    await AppApi.client.post(ApiEndpoints.signOut);
    await AppApi.client.clearSession();
    _reset();
  }

  /// Re-reads the profile + permissions (after a profile / photo change).
  Future<void> refresh() async {
    await _loadPermissions();
    notifyListeners();
  }

  /// Pull-to-refresh on the module pages: permissions (a role change shows up), lookups, notifications.
  Future<void> reloadAll() async {
    await Future.wait([refresh(), Directory.instance.load(), NotificationsStore.instance.load()]);
  }

  Future<bool> _afterAuth() async {
    final ok = await _loadPermissions();
    if (!ok) {
      await AppApi.client.clearSession();
      return false;
    }
    _signedIn = true;
    notifyListeners();
    // Lookups, notifications and the live socket load in the background.
    Directory.instance.load();
    NotificationsStore.instance.start();
    PushService.register();
    return true;
  }

  Future<bool> _loadPermissions() async {
    final r = await AppApi.client.get(ApiEndpoints.myPermissions);
    if (!r.ok || r.data is! Map) return false;
    final data = r.data as Map;
    _user = data['user'] is Map ? Map<String, dynamic>.from(data['user'] as Map) : null;
    _permissions = [for (final p in (data['permissions'] as List? ?? const [])) if (p is Map) Map<String, dynamic>.from(p)];
    if (_user == null) return false;
    final p = await AppApi.client.get(ApiEndpoints.settingsProfile);
    if (p.ok && p.data is Map) _displayName = userFullName(Map<String, dynamic>.from(p.data as Map));
    return true;
  }

  void _reset() {
    _signedIn = false;
    _user = null;
    _permissions = [];
    _displayName = '';
    Directory.instance.clear();
    NotificationsStore.instance.clear();
    notifyListeners();
  }

  void _expired() {
    if (!_signedIn) return;
    AppApi.socket.disconnect();
    AppApi.client.clearSession();
    _reset();
    onExpired?.call();
  }

  // ── Permissions ─────────────────────────────────────────────────────────────────
  Rec? _row(String moduleKey) {
    for (final r in _permissions) {
      if (r['modulename'] == moduleKey) return r;
    }
    return null;
  }

  bool canViewModule(String moduleKey) => !_signedIn || _row(moduleKey)?['modulenameaccess'] == 'Y';

  bool canViewMenuItem(String moduleKey, String itemId) {
    if (!_signedIn) return true;
    final row = _row(moduleKey);
    if (row == null || row['modulenameaccess'] != 'Y') return false;
    return [for (final i in (row['menuitemaccess'] as List? ?? const [])) if (i is Map) i].any((i) => i['id'] == itemId && i['access'] == 'Y');
  }
}
