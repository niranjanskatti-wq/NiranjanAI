import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart' show Color;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

/// Local notifications and alarms (no internet involved).
class Notifier {
  Notifier._();
  static final _plugin = FlutterLocalNotificationsPlugin();
  static bool _ready = false;
  static bool _tzReady = false;

  static const _gold = Color(0xFFE0B04B);

  static const _reminders = AndroidNotificationDetails(
    'goldvault_reminders',
    'Reminders',
    channelDescription: 'Locker rent, items not returned, planned visits and bank holidays',
    importance: Importance.high,
    priority: Priority.high,
    color: _gold,
  );

  /// Alarm style: alarm volume, keeps ringing until opened or dismissed.
  static final _alarm = AndroidNotificationDetails(
    'goldvault_alarms',
    'Alarms',
    channelDescription: 'Alarm-style reminders to keep or take jewellery from the locker',
    importance: Importance.max,
    priority: Priority.max,
    category: AndroidNotificationCategory.alarm,
    audioAttributesUsage: AudioAttributesUsage.alarm,
    additionalFlags: Int32List.fromList(<int>[4]), // FLAG_INSISTENT
    enableVibration: true,
    color: _gold,
    ticker: 'GoldVault alarm',
  );

  static const _backup = AndroidNotificationDetails(
    'goldvault_backup',
    'Backup & sync',
    channelDescription: 'Weekly Google Drive backup results',
    importance: Importance.low,
    priority: Priority.low,
    color: _gold,
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

  static void _initTz() {
    if (_tzReady) return;
    tzdata.initializeTimeZones();
    // Pick the zone that matches the phone's current offset (India first).
    final offset = DateTime.now().timeZoneOffset;
    tz.Location? loc;
    if (offset == const Duration(hours: 5, minutes: 30)) {
      loc = tz.getLocation('Asia/Kolkata');
    } else {
      for (final l in tz.timeZoneDatabase.locations.values) {
        if (l.currentTimeZone.offset == offset) {
          loc = l;
          break;
        }
      }
    }
    tz.setLocalLocation(loc ?? tz.UTC);
    _tzReady = true;
  }

  static AndroidFlutterLocalNotificationsPlugin? get _android =>
      _plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();

  static Future<void> requestPermission() async {
    await init();
    try {
      await _android?.requestNotificationsPermission();
    } catch (_) {}
  }

  /// Exact alarms need user permission on Android 12; granted automatically
  /// on Android 13+ (USE_EXACT_ALARM).
  static Future<void> requestExactAlarms() async {
    await init();
    try {
      if (await _android?.canScheduleExactNotifications() == false) {
        await _android?.requestExactAlarmsPermission();
      }
    } catch (_) {}
  }

  static Future<void> reminder(int id, String title, String body, {bool alarm = false}) async {
    await init();
    if (!_ready) return;
    await _plugin.show(
      id: id,
      title: title,
      body: body,
      notificationDetails: NotificationDetails(android: alarm ? _alarm : _reminders),
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

  /// Schedules a notification at an exact local time (survives reboot).
  static Future<void> schedule(int id, DateTime when, String title, String body, {bool alarm = false}) async {
    await init();
    if (!_ready) return;
    _initTz();
    final at = tz.TZDateTime.from(when, tz.local);
    final details = NotificationDetails(android: alarm ? _alarm : _reminders);
    for (final mode in [
      alarm ? AndroidScheduleMode.alarmClock : AndroidScheduleMode.exactAllowWhileIdle,
      AndroidScheduleMode.inexactAllowWhileIdle, // if exact alarms are not allowed
    ]) {
      try {
        await _plugin.zonedSchedule(
          id: id,
          scheduledDate: at,
          notificationDetails: details,
          androidScheduleMode: mode,
          title: title,
          body: body,
        );
        return;
      } catch (e) {
        debugPrint('Schedule ($mode) failed: $e');
      }
    }
  }

  static Future<void> cancel(int id) async {
    await init();
    if (!_ready) return;
    try {
      await _plugin.cancel(id: id);
    } catch (_) {}
  }
}
