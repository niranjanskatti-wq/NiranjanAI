import 'dart:ui' show Color;

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import '../core/settings.dart';
import '../core/util/format.dart';
import '../data/database.dart';
import 'native.dart';

enum NotifyKind { morning, evening, weekly, breakOver, sessionComplete }

/// Local notifications, scheduled with Android so they fire even when the app is closed.
/// Respects the master switch, per-reminder toggles and quiet hours.
class Notifications {
  static final _plugin = FlutterLocalNotificationsPlugin();
  static bool _ready = false;

  static const timerId = 1001;
  static const _reminderBase = 3000;
  static const _channel = AndroidNotificationDetails(
    'deepwork_timer',
    'Timer and reminders',
    channelDescription: 'Session complete, break over, and planning/review reminders',
    importance: Importance.high,
    priority: Priority.high,
    icon: 'ic_stat_deepwork',
    color: Color(0xFF7C7CFF),
  );

  static AndroidFlutterLocalNotificationsPlugin? get _android =>
      _plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();

  static Future<void> init() async {
    if (_ready || !NativeBridge.available) return;
    tzdata.initializeTimeZones();
    try {
      final info = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(info.identifier));
    } catch (_) {
      // Fall back to UTC offsets if the zone name is unknown.
    }
    await _plugin.initialize(settings: const InitializationSettings(android: AndroidInitializationSettings('ic_stat_deepwork')));
    _ready = true;
  }

  static Future<bool> permissionGranted() async => _ready && ((await _android?.areNotificationsEnabled()) ?? false);
  static Future<bool> requestPermission() async => _ready && ((await _android?.requestNotificationsPermission()) ?? false);
  static Future<bool> exactAllowed() async => _ready && ((await _android?.canScheduleExactNotifications()) ?? false);
  static Future<void> requestExact() async {
    if (_ready) await _android?.requestExactAlarmsPermission();
  }

  static bool kindEnabled(AppSettings s, NotifyKind k) {
    if (!s.on('notifications')) return false;
    return switch (k) {
      NotifyKind.morning => s.b('notifications.morning.enabled') && s.on('priorities'),
      NotifyKind.evening => s.b('notifications.evening.enabled') && s.on('eveningReview'),
      NotifyKind.weekly => s.b('notifications.weekly.enabled') && s.on('weeklyReview'),
      NotifyKind.breakOver => s.b('notifications.breakOver') && s.on('breaks'),
      NotifyKind.sessionComplete => s.b('notifications.sessionComplete'),
    };
  }

  static bool inQuietHours(AppSettings s, DateTime at) =>
      s.b('notifications.quietHours.enabled') && inTimeRange(at, s.s('notifications.quietHours.start'), s.s('notifications.quietHours.end'));

  static NotificationDetails get _details => const NotificationDetails(android: _channel);

  static Future<bool> show(AppSettings s, NotifyKind k, String title, String body, {bool force = false}) async {
    if (!_ready) return false;
    if (!force && (!kindEnabled(s, k) || inQuietHours(s, DateTime.now()))) return false;
    if (!await permissionGranted()) return false;
    await _plugin.show(id: 5000 + DateTime.now().millisecond, title: title, body: body, notificationDetails: _details);
    return true;
  }

  static Future<void> _schedule(int id, DateTime at, String title, String body) async {
    final mode = await exactAllowed() ? AndroidScheduleMode.exactAllowWhileIdle : AndroidScheduleMode.inexactAllowWhileIdle;
    await _plugin.zonedSchedule(
      id: id,
      scheduledDate: tz.TZDateTime.from(at, tz.local),
      notificationDetails: _details,
      androidScheduleMode: mode,
      title: title,
      body: body,
    );
  }

  /// Schedules (or clears, when [at] is null) the alert for the running timer.
  static Future<void> scheduleTimerAlert(AppSettings s, DateTime? at, NotifyKind kind) async {
    if (!_ready) return;
    await _plugin.cancel(id: timerId);
    if (at == null || !at.isAfter(DateTime.now())) return;
    if (!kindEnabled(s, kind) || inQuietHours(s, at) || !await permissionGranted()) return;
    final complete = kind == NotifyKind.sessionComplete;
    await _schedule(
      timerId,
      at,
      complete ? 'Session complete' : 'Break is over',
      complete ? 'Nice work. Open Deepwork to note what you got done.' : 'Ready for the next session?',
    );
  }

  /// Plans the next week of reminders. Called on launch, on resume, and when settings or reviews change.
  static Future<void> rescheduleReminders(AppSettings s, {required bool eveningDoneToday, required DateTime? weeklyDoneAt}) async {
    if (!_ready) return;
    final pending = await _plugin.pendingNotificationRequests();
    for (final p in pending) {
      if (p.id >= _reminderBase && p.id < _reminderBase + 1000) await _plugin.cancel(id: p.id);
    }
    if (!s.on('notifications') || !await permissionGranted()) return;

    final now = DateTime.now();
    final today = startOfDay(now);
    final list = <(int, DateTime, String, String)>[];
    for (var i = 0; i < 7; i++) {
      final day = addDays(today, i);
      if (kindEnabled(s, NotifyKind.morning)) {
        list.add((_reminderBase + i, atTime(day, s.s('notifications.morning.time')), 'Plan your day', "Pick today's ${s.priorityLabel.toLowerCase()} and start your first session."));
      }
      if (kindEnabled(s, NotifyKind.evening) && !(i == 0 && eveningDoneToday)) {
        list.add((_reminderBase + 100 + i, atTime(day, s.s('eveningReview.time')), 'Evening review', 'Two minutes to look back at today and pick tomorrow’s priorities.'));
      }
    }
    if (kindEnabled(s, NotifyKind.weekly)) {
      final day = s.i('weeklyReview.day');
      for (var w = 0; w < 3; w++) {
        final d = addDays(today, ((day - weekday0(today) + 7) % 7) + 7 * w);
        final when = atTime(d, s.s('weeklyReview.time'));
        // Skip this week's reminder if the review is already done.
        if (weeklyDoneAt != null && when.difference(weeklyDoneAt).inDays < 6 && when.isAfter(weeklyDoneAt)) continue;
        list.add((_reminderBase + 200 + w, when, 'Weekly review', 'Take ten minutes to review your week.'));
      }
    }
    for (final (id, at, title, body) in list) {
      if (at.isAfter(now.add(const Duration(seconds: 30))) && !inQuietHours(s, at)) await _schedule(id, at, title, body);
    }
  }
}

/// Helpers the reminder planner needs from the database.
Future<({bool eveningDoneToday, DateTime? weeklyDoneAt})> reviewStateFor(List<Review> reviews) async {
  final today = todayKey();
  final evening = reviews.any((r) => r.type == 'daily' && r.date == today);
  final weekly = reviews.where((r) => r.type == 'weekly').map((r) => r.createdAt).fold<int?>(null, (m, v) => m == null || v > m ? v : m);
  return (eveningDoneToday: evening, weeklyDoneAt: weekly == null ? null : DateTime.fromMillisecondsSinceEpoch(weekly));
}

@visibleForTesting
bool debugNotificationsReady() => Notifications._ready;
