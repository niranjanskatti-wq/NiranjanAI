import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import '../core/app_services.dart';
import '../core/strings.dart';

/// How a single alarm/notification should behave.
class AlertStyle {
  final String sound; // alarm / notify / silent
  final bool vibrate;
  final int snooze; // minutes, 0 = no snooze button
  final int? reminderId; // adds a "Done" button
  const AlertStyle({this.sound = 'notify', this.vibrate = true, this.snooze = 0, this.reminderId});

  Map<String, Object?> toJson() => {'sound': sound, 'vibrate': vibrate, 'snooze': snooze, 'rid': reminderId};
  factory AlertStyle.fromJson(Map<String, dynamic> m) => AlertStyle(
        sound: m['sound'] as String? ?? 'notify',
        vibrate: m['vibrate'] as bool? ?? true,
        snooze: m['snooze'] as int? ?? 0,
        reminderId: m['rid'] as int?,
      );
}

/// Snooze / Done tapped while the app is closed (runs in a background isolate).
@pragma('vm:entry-point')
void notificationActionBackground(NotificationResponse r) {
  WidgetsFlutterBinding.ensureInitialized();
  Notifier.handleAction(r);
}

/// Local notifications and alarms (no internet involved).
class Notifier {
  Notifier._();
  static final _plugin = FlutterLocalNotificationsPlugin();
  static bool _ready = false;
  static bool _tzReady = false;

  static const _gold = Color(0xFFE0B04B);

  static const _backup = AndroidNotificationDetails(
    'goldvault_backup',
    'Backup & sync',
    channelDescription: 'Weekly Google Drive backup results',
    importance: Importance.low,
    priority: Priority.low,
    color: _gold,
  );

  /// Android fixes sound/vibration per channel, so each combination has one.
  static AndroidNotificationDetails _details(AlertStyle st, {String? lang}) {
    final s = S(lang ?? 'en');
    final actions = <AndroidNotificationAction>[
      if (st.snooze > 0)
        AndroidNotificationAction('snooze', s.t('notif.snooze', {'n': st.snooze}), cancelNotification: true),
      if (st.reminderId != null) AndroidNotificationAction('done', s.t('notif.done'), cancelNotification: true),
    ];
    final vib = st.vibrate ? '' : '_novib';
    switch (st.sound) {
      case 'alarm':
        return AndroidNotificationDetails(
          'goldvault_alarms$vib',
          st.vibrate ? 'Alarms' : 'Alarms (no vibration)',
          channelDescription: 'Alarm-style reminders to keep or take jewellery from the locker',
          importance: Importance.max,
          priority: Priority.max,
          category: AndroidNotificationCategory.alarm,
          audioAttributesUsage: AudioAttributesUsage.alarm,
          additionalFlags: Int32List.fromList(<int>[4]), // FLAG_INSISTENT: keeps ringing
          enableVibration: st.vibrate,
          color: _gold,
          ticker: 'GoldVault alarm',
          actions: actions,
        );
      case 'silent':
        return AndroidNotificationDetails(
          'goldvault_silent$vib',
          st.vibrate ? 'Silent reminders' : 'Silent reminders (no vibration)',
          channelDescription: 'Reminders without sound',
          importance: Importance.high,
          priority: Priority.high,
          playSound: false,
          enableVibration: st.vibrate,
          color: _gold,
          actions: actions,
        );
      default:
        return AndroidNotificationDetails(
          'goldvault_reminders$vib',
          st.vibrate ? 'Reminders' : 'Reminders (no vibration)',
          channelDescription: 'Locker rent, items not returned, planned visits and bank holidays',
          importance: Importance.high,
          priority: Priority.high,
          enableVibration: st.vibrate,
          color: _gold,
          actions: actions,
        );
    }
  }

  static Future<void> init() async {
    if (_ready) return;
    try {
      await _plugin.initialize(
        settings: const InitializationSettings(
          android: AndroidInitializationSettings('@drawable/ic_stat_goldvault'),
        ),
        onDidReceiveNotificationResponse: handleAction,
        onDidReceiveBackgroundNotificationResponse: notificationActionBackground,
      );
      _ready = true;
    } catch (e) {
      debugPrint('Notifications unavailable: $e');
    }
  }

  /// Snooze → ring again later; Done → mark the reminder done.
  static Future<void> handleAction(NotificationResponse r) async {
    final action = r.actionId;
    if (action == null || r.payload == null) return;
    try {
      final p = jsonDecode(r.payload!) as Map<String, dynamic>;
      final st = AlertStyle.fromJson(p);
      if (action == 'snooze' && st.snooze > 0) {
        await schedule(
          (r.id ?? 1) ^ 0x40000000,
          DateTime.now().add(Duration(minutes: st.snooze)),
          p['title'] as String? ?? 'GoldVault',
          p['body'] as String? ?? '',
          style: st,
          lang: p['lang'] as String?,
        );
      } else if (action == 'done' && st.reminderId != null) {
        final svc = await AppServices.init();
        await svc.repo.setReminderDone(st.reminderId!, true);
      }
    } catch (e) {
      debugPrint('Notification action failed: $e');
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

  static String _payload(String title, String body, AlertStyle st, String? lang) =>
      jsonEncode({...st.toJson(), 'title': title, 'body': body, 'lang': lang});

  static Future<void> reminder(int id, String title, String body, {AlertStyle style = const AlertStyle(), String? lang}) async {
    await init();
    if (!_ready) return;
    await _plugin.show(
      id: id,
      title: title,
      body: body,
      notificationDetails: NotificationDetails(android: _details(style, lang: lang)),
      payload: _payload(title, body, style, lang),
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
  static Future<void> schedule(int id, DateTime when, String title, String body,
      {AlertStyle style = const AlertStyle(), String? lang}) async {
    await init();
    if (!_ready) return;
    _initTz();
    final at = tz.TZDateTime.from(when, tz.local);
    final details = NotificationDetails(android: _details(style, lang: lang));
    for (final mode in [
      style.sound == 'alarm' ? AndroidScheduleMode.alarmClock : AndroidScheduleMode.exactAllowWhileIdle,
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
          payload: _payload(title, body, style, lang),
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
