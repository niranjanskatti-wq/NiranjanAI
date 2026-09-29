import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import 'alarm_planner.dart';
import 'reminder_model.dart';

/// A notification tap or button press waiting to be handled by the app.
class NotificationTap {
  const NotificationTap({required this.data, this.action});

  final Map<String, dynamic> data;
  final String? action;

  String get kind => data['k'] as String? ?? '';
  int? get eventId => (data['e'] as num?)?.toInt();
  String? get festivalKey => data['fk'] as String?;
  String? get date => data['d'] as String?;
}

/// Wraps the notifications plugin: channels, scheduling, snooze, permissions.
class NotificationService {
  NotificationService._();

  static final plugin = FlutterLocalNotificationsPlugin();
  static final taps = ValueNotifier<NotificationTap?>(null);
  static const _window = MethodChannel('smriti/window');
  static bool _ready = false;

  static bool get supported => !kIsWeb && Platform.isAndroid;

  static AndroidFlutterLocalNotificationsPlugin? get _android => supported
      ? plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
      : null;

  /// Loads time zones and sets the phone's own zone as local.
  static Future<void> initTimeZones() async {
    tzdata.initializeTimeZones();
    try {
      final info = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(info.identifier));
    } catch (_) {
      tz.setLocalLocation(tz.getLocation('Asia/Kolkata'));
    }
  }

  static Future<void> init() async {
    if (!supported || _ready) return;
    await plugin.initialize(
      settings: const InitializationSettings(android: AndroidInitializationSettings('ic_stat_smriti')),
      onDidReceiveNotificationResponse: _onResponse,
      onDidReceiveBackgroundNotificationResponse: notificationBackgroundHandler,
    );
    _ready = true;
    final launch = await plugin.getNotificationAppLaunchDetails();
    final r = launch?.notificationResponse;
    if ((launch?.didNotificationLaunchApp ?? false) && r != null) _onResponse(r);
  }

  static void _onResponse(NotificationResponse r) {
    final data = _decode(r.payload);
    if (data == null) return;
    final action = r.actionId;
    if (action != null && action.startsWith('snooze')) {
      snooze(data, action);
      return;
    }
    taps.value = NotificationTap(data: data, action: action);
  }

  static Map<String, dynamic>? _decode(String? payload) {
    if (payload == null) return null;
    try {
      return jsonDecode(payload) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }

  // ---------- channels ----------
  static String _channelId(AlarmSound s, bool alarm) => '${alarm ? 'alarm' : 'remind'}_${s.name}';

  static AndroidNotificationDetails _details({
    required AlarmSound sound,
    required bool alarm,
    required String body,
    bool wishActions = false,
    bool snoozeActions = false,
  }) {
    final file = sound.file.isEmpty ? null : (alarm ? 'midnight_${sound.file}' : sound.file);
    return AndroidNotificationDetails(
      _channelId(sound, alarm),
      alarm ? 'Midnight alarm · ${sound.label}' : 'Reminders · ${sound.label}',
      channelDescription: alarm ? 'Full-screen alarm at midnight' : 'Reminders before and on the day',
      icon: 'ic_stat_smriti',
      color: const Color(0xFFC9A45C),
      importance: Importance.max,
      priority: Priority.high,
      playSound: file != null,
      sound: file == null ? null : RawResourceAndroidNotificationSound(file),
      enableVibration: true,
      vibrationPattern: alarm ? Int64List.fromList([0, 600, 400, 600, 400, 900]) : null,
      audioAttributesUsage: alarm ? AudioAttributesUsage.alarm : AudioAttributesUsage.notification,
      category: alarm ? AndroidNotificationCategory.alarm : AndroidNotificationCategory.reminder,
      fullScreenIntent: alarm,
      visibility: NotificationVisibility.public,
      styleInformation: BigTextStyleInformation(body),
      actions: [
        if (wishActions) const AndroidNotificationAction('call', 'Call', showsUserInterface: true),
        if (wishActions) const AndroidNotificationAction('wish', 'Send Wish', showsUserInterface: true),
        if (snoozeActions) const AndroidNotificationAction('snooze10', 'Snooze 10 min'),
      ],
    );
  }

  static NotificationDetails detailsFor(PlannedAlarm a) => NotificationDetails(
        android: _details(
          sound: a.sound,
          alarm: a.fullScreen,
          body: a.body,
          wishActions: a.wishActions,
          snoozeActions: a.fullScreen,
        ),
      );

  // ---------- scheduling ----------
  /// Makes the phone's scheduled notifications match [plan]: cancels the
  /// ones no longer wanted, adds new or changed ones, leaves the rest alone.
  static Future<int> sync(List<PlannedAlarm> plan) async {
    if (!supported) return 0;
    await init();
    final pending = {for (final p in await plugin.pendingNotificationRequests()) p.id: p.payload};
    final wanted = {for (final a in plan) a.id: a};
    for (final id in pending.keys) {
      // Ids below 1000 are snoozes and tests; they manage themselves.
      if (id >= 1000 && !wanted.containsKey(id)) await plugin.cancel(id: id);
    }
    final exact = await _android?.canScheduleExactNotifications() ?? true;
    var changed = 0;
    for (final a in plan) {
      if (pending[a.id] == a.payload) continue;
      await plugin.zonedSchedule(
        id: a.id,
        scheduledDate: a.when,
        notificationDetails: detailsFor(a),
        androidScheduleMode: exact
            ? (a.fullScreen ? AndroidScheduleMode.alarmClock : AndroidScheduleMode.exactAllowWhileIdle)
            : AndroidScheduleMode.inexactAllowWhileIdle,
        title: a.title,
        body: a.body,
        payload: a.payload,
      );
      changed++;
    }
    return changed;
  }

  /// Shows the notification again later. [action]: snooze10, snooze60 or snoozeMorning.
  static Future<void> snooze(Map<String, dynamic> data, String action, {int morningMinute = 480}) async {
    if (!supported) return;
    await initTimeZones();
    await init();
    final now = tz.TZDateTime.now(tz.local);
    final when = switch (action) {
      'snooze60' => now.add(const Duration(hours: 1)),
      'snoozeMorning' => () {
          final t = tz.TZDateTime(tz.local, now.year, now.month, now.day, morningMinute ~/ 60, morningMinute % 60);
          return t.isAfter(now) ? t : t.add(const Duration(days: 1));
        }(),
      _ => now.add(const Duration(minutes: 10)),
    };
    final a = PlannedAlarm(
      id: 100 + now.millisecondsSinceEpoch % 800,
      when: when,
      kind: data['k'] == 'mid' ? 'rem' : (data['k'] as String? ?? 'rem'),
      title: data['t'] as String? ?? 'Smriti',
      body: data['b'] as String? ?? '',
      sound: AlarmSound.parse(data['s'] as String?),
      eventId: (data['e'] as num?)?.toInt(),
      date: null,
      wishActions: data['a'] as bool? ?? false,
    );
    final payload = jsonEncode({...data, 'k': a.kind, 'w': when.millisecondsSinceEpoch});
    await plugin.zonedSchedule(
      id: a.id,
      scheduledDate: when,
      notificationDetails: detailsFor(a),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      title: a.title,
      body: a.body,
      payload: payload,
    );
  }

  /// Plays a sound right away so the user can hear it (Settings › Sounds).
  static Future<void> preview(AlarmSound sound, {bool alarm = false}) async {
    if (!supported) return;
    await init();
    await plugin.show(
      id: 10,
      title: 'Sound preview: ${sound.label}',
      body: alarm ? 'This is how the midnight alarm sounds.' : 'This is how reminders sound.',
      notificationDetails: NotificationDetails(android: _details(sound: sound, alarm: false, body: '')),
    );
  }

  /// Schedules a full midnight-style alarm one minute from now, as a test.
  static Future<void> testAlarm({AlarmSound sound = AlarmSound.tickTock}) async {
    if (!supported) return;
    await init();
    final when = tz.TZDateTime.now(tz.local).add(const Duration(minutes: 1));
    final a = PlannedAlarm(
      id: 11,
      when: when,
      kind: 'mid',
      title: '🎂 Test alarm',
      body: 'This is what your midnight alarm looks and sounds like.',
      sound: sound,
      fullScreen: true,
    );
    await plugin.zonedSchedule(
      id: a.id,
      scheduledDate: when,
      notificationDetails: detailsFor(a),
      androidScheduleMode: AndroidScheduleMode.alarmClock,
      title: a.title,
      body: a.body,
      payload: a.payload,
    );
  }

  // ---------- permissions ----------
  static Future<bool> notificationsEnabled() async => await _android?.areNotificationsEnabled() ?? true;
  static Future<bool> exactAllowed() async => await _android?.canScheduleExactNotifications() ?? true;
  static Future<bool?> requestNotifications() async => _android?.requestNotificationsPermission();
  static Future<bool?> requestExact() async => _android?.requestExactAlarmsPermission();
  static Future<bool?> requestFullScreen() async => _android?.requestFullScreenIntentPermission();

  // ---------- window ----------
  static Future<void> setLockScreen(bool on) async {
    if (!supported) return;
    try {
      await _window.invokeMethod('setLockScreen', on);
    } catch (_) {}
  }

  static Future<int> sdkInt() async {
    if (!supported) return 0;
    try {
      return (await _window.invokeMethod<int>('sdkInt')) ?? 0;
    } catch (_) {
      return 0;
    }
  }

  static Future<String> manufacturer() async {
    if (!supported) return '';
    try {
      return (await _window.invokeMethod<String>('manufacturer')) ?? '';
    } catch (_) {
      return '';
    }
  }
}

/// Runs in the background when a notification button is pressed while the
/// app is closed (e.g. Snooze).
@pragma('vm:entry-point')
void notificationBackgroundHandler(NotificationResponse r) {
  WidgetsFlutterBinding.ensureInitialized();
  final data = NotificationService._decode(r.payload);
  final action = r.actionId;
  if (data != null && action != null && action.startsWith('snooze')) {
    NotificationService.snooze(data, action);
  }
}
