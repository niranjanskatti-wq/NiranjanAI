import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart' show Color;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// Local notifications (no internet involved).
class Notifier {
  Notifier._();
  static final _plugin = FlutterLocalNotificationsPlugin();
  static bool _ready = false;

  static const _reminders = AndroidNotificationDetails(
    'goldvault_reminders',
    'Reminders',
    channelDescription: 'Locker rent, items not returned and planned visits',
    importance: Importance.high,
    priority: Priority.high,
    color: Color(0xFFE0B04B),
  );
  static const _backup = AndroidNotificationDetails(
    'goldvault_backup',
    'Backup & sync',
    channelDescription: 'Weekly Google Drive backup results',
    importance: Importance.low,
    priority: Priority.low,
    color: Color(0xFFE0B04B),
  );

  static Future<void> init() async {
    if (_ready) return;
    try {
      await _plugin.initialize(
        settings: const InitializationSettings(
          android: AndroidInitializationSettings('@drawable/ic_stat_goldvault'),
        ),
      );
      _ready = true;
    } catch (e) {
      debugPrint('Notifications unavailable: $e');
    }
  }

  static Future<void> requestPermission() async {
    await init();
    await _plugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
  }

  static Future<void> reminder(int id, String title, String body) async {
    await init();
    if (!_ready) return;
    await _plugin.show(
      id: id,
      title: title,
      body: body,
      notificationDetails: const NotificationDetails(android: _reminders),
    );
  }

  static Future<void> backup(String title, String body) async {
    await init();
    if (!_ready) return;
    await _plugin.show(
      id: 9001,
      title: title,
      body: body,
      notificationDetails: const NotificationDetails(android: _backup),
    );
  }
}
