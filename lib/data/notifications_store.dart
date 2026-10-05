import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../core/core.dart';
import 'app_api.dart';

class AppNotification {
  AppNotification.fromJson(Map<String, dynamic> j)
      : id = (j['notificationId'] as num).toInt(),
        type = j['type'] as String?,
        moduleName = j['moduleName'] as String?,
        title = '${j['title'] ?? ''}',
        message = '${j['message'] ?? ''}',
        url = j['url'] as String?,
        referenceId = (j['referenceId'] as num?)?.toInt(),
        isRead = j['isRead'] == true,
        createdAt = DateTime.tryParse('${j['createdAt']}')?.toLocal() ?? DateTime.now();

  final int id;
  final String? type;
  final String? moduleName;
  final String title;
  final String message;
  final String? url;
  final int? referenceId;
  bool isRead;
  final DateTime createdAt;
}

/// Notification list shared by the header bell and the Notifications page (web
/// `NotificationsContext`): loaded from the API and kept live over the WebSocket.
class NotificationsStore extends ChangeNotifier {
  NotificationsStore._();
  static final NotificationsStore instance = NotificationsStore._();

  List<AppNotification> items = [];
  bool loading = false;
  bool live = false;
  AppNotification? latest;

  StreamSubscription<Map<String, dynamic>>? _push;
  StreamSubscription<bool>? _conn;

  int get unread => items.where((n) => !n.isRead).length;

  /// Loads the list and opens the socket (called after sign-in).
  void start() {
    load();
    if (AppApi.liveSocket) {
      _push ??= AppApi.socket.notifications.listen(_onPush);
      _conn ??= AppApi.socket.connected.listen((v) {
        live = v;
        notifyListeners();
      });
    }
    if (AppApi.liveSocket) AppApi.socket.connect();
  }

  Future<void> load() async {
    loading = true;
    notifyListeners();
    final r = await AppApi.client.get(ApiEndpoints.notifications, query: {'limit': '50'});
    if (r.ok && r.data is Map) {
      final list = (r.data as Map)['items'];
      if (list is List) items = [for (final x in list) if (x is Map) AppNotification.fromJson(Map<String, dynamic>.from(x))];
    }
    loading = false;
    notifyListeners();
  }

  AudioPlayer? _player;

  /// The same chime the web plays for a new notification (web `NotificationsContext`).
  Future<void> _chime() async {
    // In the background the system popup (Firebase push) already plays the chime.
    final state = WidgetsBinding.instance.lifecycleState;
    if (state != null && state != AppLifecycleState.resumed) return;
    try {
      final p = _player ??= AudioPlayer();
      await p.setReleaseMode(ReleaseMode.stop);
      await p.play(AssetSource('sounds/notification.mp3'));
    } catch (_) {/* no audio output available — the badge still updates */}
  }

  void _onPush(Map<String, dynamic> j) {
    try {
      final n = AppNotification.fromJson(j);
      if (items.any((x) => x.id == n.id)) return;
      items = [n, ...items];
      latest = n;
      notifyListeners();
      _chime();
    } catch (_) {/* ignore a malformed push */}
  }

  Future<void> markRead(int id) async {
    for (final n in items) {
      if (n.id == id) n.isRead = true;
    }
    notifyListeners();
    await AppApi.client.post(ApiEndpoints.notificationsRead, body: {'id': id});
  }

  Future<void> markAllRead() async {
    for (final n in items) {
      n.isRead = true;
    }
    notifyListeners();
    await AppApi.client.post(ApiEndpoints.notificationsRead, body: {'all': true});
  }

  void clear() {
    _push?.cancel();
    _conn?.cancel();
    _push = _conn = null;
    items = [];
    latest = null;
    live = false;
    notifyListeners();
  }
}

/// Icon + colour per notification type (web `notificationStyle`).
({IconData icon, Color color}) notificationStyle(String? type) => switch (type) {
      'task' => (icon: LucideIcons.squareCheck, color: const Color(0xFF7C3AED)),
      'attendance' => (icon: LucideIcons.clock, color: const Color(0xFF10B981)),
      'leave' => (icon: LucideIcons.clipboardCheck, color: const Color(0xFFEA580C)),
      'document' => (icon: LucideIcons.fileText, color: const Color(0xFF0F766E)),
      'employee' => (icon: LucideIcons.users, color: const Color(0xFFE11D48)),
      'system' => (icon: LucideIcons.settings, color: const Color(0xFF475569)),
      _ => (icon: LucideIcons.bell, color: const Color(0xFF475569)),
    };

String timeAgo(DateTime d) {
  final seconds = DateTime.now().difference(d).inSeconds;
  if (seconds < 60) return 'just now';
  final minutes = seconds ~/ 60;
  if (minutes < 60) return '${minutes}m ago';
  final hours = minutes ~/ 60;
  if (hours < 24) return '${hours}h ago';
  final days = hours ~/ 24;
  if (days < 7) return '${days}d ago';
  return formatShortDate(d);
}

const _m = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
String formatShortDate(DateTime d) => '${_m[d.month - 1]} ${d.day}, ${d.year}';
