import 'dart:io' show Platform;

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../core/api/api.dart';
import '../data/app_api.dart';
import '../firebase_options.dart';

/// Push notifications through Firebase Cloud Messaging, so a notification shows as a system
/// popup with the chime even when the app is closed. Firebase keeps a message for the phone
/// until it is online again, so everything missed while offline pops up when the internet returns.
///
/// Flow: sign in → [register] sends this phone's FCM token to `POST /api/devices` → the web
/// server pushes each new notification to that token (see `src/lib/push.ts` in the web project).
/// While the app is open the live WebSocket already updates the bell and plays the chime.
class PushService {
  PushService._();

  /// Must match the channel the server names in its message (`avd_notifications`).
  static const channelId = 'avd_notifications';

  static bool _ready = false;
  static String? _token;

  /// A tapped popup's page, waiting for the app to finish starting (see splash).
  static String? pendingUrl;

  /// Called when a popup is tapped while the app is running (opens the page).
  static void Function(String url)? onOpenUrl;

  static bool get isReady => _ready;

  /// Call once from `main()`. Does nothing (and never throws) until `flutterfire configure` has run.
  static Future<void> init() async {
    if (kIsWeb) return;
    try {
      await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
    } catch (e) {
      debugPrint('[push] Firebase not started: $e');
      return;
    }
    _ready = true;

    if (Platform.isAndroid) {
      // The channel carries the custom chime (android/app/src/main/res/raw/notification.mp3).
      final plugin = FlutterLocalNotificationsPlugin();
      await plugin.initialize(const InitializationSettings(android: AndroidInitializationSettings('@mipmap/ic_launcher')));
      await plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()?.createNotificationChannel(
            const AndroidNotificationChannel(
              channelId,
              'Notifications',
              description: 'New tasks, comments and approvals',
              importance: Importance.high,
              playSound: true,
              sound: RawResourceAndroidNotificationSound('notification'),
            ),
          );
    }

    // Tapped while the app was in the background / closed.
    FirebaseMessaging.onMessageOpenedApp.listen(_open);
    final initial = await FirebaseMessaging.instance.getInitialMessage();
    if (initial != null) pendingUrl = initial.data['url'] as String?;
    FirebaseMessaging.instance.onTokenRefresh.listen(_send);
  }

  static void _open(RemoteMessage m) {
    final url = m.data['url'] as String?;
    if (url == null || url.isEmpty) return;
    if (onOpenUrl != null) {
      onOpenUrl!(url);
    } else {
      pendingUrl = url;
    }
  }

  /// After sign-in: ask permission and give the server this phone's token.
  static Future<void> register() async {
    if (!_ready) return;
    try {
      await FirebaseMessaging.instance.requestPermission();
      _token = await FirebaseMessaging.instance.getToken();
      if (_token != null) await _send(_token!);
    } catch (e) {
      debugPrint('[push] register failed: $e');
    }
  }

  static Future<void> _send(String token) async {
    _token = token;
    if (!AppApi.client.hasSession) return;
    await AppApi.client.post(ApiEndpoints.devices, body: {'token': token, 'platform': Platform.isIOS ? 'ios' : 'android'});
  }

  /// On sign-out (while the session is still valid): stop pushes to this phone.
  static Future<void> unregister() async {
    if (!_ready) return;
    try {
      final token = _token ?? await FirebaseMessaging.instance.getToken();
      if (token != null) await AppApi.client.delete('${ApiEndpoints.devices}?token=${Uri.encodeQueryComponent(token)}');
      await FirebaseMessaging.instance.deleteToken();
      _token = null;
    } catch (e) {
      debugPrint('[push] unregister failed: $e');
    }
  }
}
