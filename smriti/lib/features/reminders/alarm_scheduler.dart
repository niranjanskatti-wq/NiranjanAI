import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:workmanager/workmanager.dart';

import '../backup/backup_service.dart';
import '../../data/database.dart';
import '../../data/repository.dart';
import '../festivals/festival_alarms.dart';
import 'alarm_planner.dart';
import 'notification_service.dart';
import 'reminder_model.dart';

/// Extra alarms contributed by other features (festivals in Phase 5).
typedef ExtraAlarms = Future<List<PlannedAlarm>> Function(AppDatabase db, tz.TZDateTime now);

/// Rebuilds every reminder from the database and hands them to Android.
class AlarmScheduler {
  AlarmScheduler._();

  static final List<ExtraAlarms> extraSources = [];
  static Timer? _debounce;

  /// Collects everything the planner needs.
  static Future<PlanInput> gather(AppDatabase db, tz.TZDateTime now) async {
    final repo = Repository(db);
    final entries = await repo.watchEntries().first;
    final reminders = <int, List<ReminderSpec>>{};
    for (final r in await repo.allReminders()) {
      reminders.putIfAbsent(r.eventId, () => []).add(ReminderSpec.fromRow(r));
    }
    final wished = {
      for (final l in await db.select(db.wishLogs).get())
        if (l.confirmed && l.occasionDate != null) '${l.eventId ?? l.festivalId}|${l.occasionDate}',
    };
    final gifts = <int, int>{};
    for (final g in await db.select(db.giftIdeas).get()) {
      if (!g.purchased) gifts[g.personId] = (gifts[g.personId] ?? 0) + 1;
    }
    final extra = <PlannedAlarm>[];
    for (final src in extraSources) {
      extra.addAll(await src(db, now));
    }
    return PlanInput(
      entries: entries,
      reminders: reminders,
      wished: wished,
      giftCounts: gifts,
      monthlySummary: (await db.getSetting('monthlySummary')) != 'false',
      belatedMinute: int.tryParse(await db.getSetting('morningMinute') ?? '') ?? 540,
      extra: extra,
    );
  }

  static Future<int> syncNow(AppDatabase db) async {
    if (!NotificationService.supported) return 0;
    try {
      final now = tz.TZDateTime.now(tz.local);
      final plan = planAlarms(await gather(db, now), now: now, local: tz.local);
      return await NotificationService.sync(plan);
    } catch (e) {
      debugPrint('Alarm sync failed: $e');
      return 0;
    }
  }

  /// Reschedules shortly after the last change (many edits → one sync).
  static void syncSoon(AppDatabase db) {
    if (!NotificationService.supported) return;
    _debounce?.cancel();
    _debounce = Timer(const Duration(seconds: 2), () => syncNow(db));
  }

  /// Twice-daily background refresh so alarms stay scheduled a year ahead
  /// even if the app is not opened.
  static Future<void> registerBackground() async {
    if (!NotificationService.supported) return;
    try {
      await Workmanager().initialize(backgroundDispatcher);
      await Workmanager().registerPeriodicTask(
        'smriti-refresh',
        'refresh-alarms',
        frequency: const Duration(hours: 12),
        existingWorkPolicy: ExistingPeriodicWorkPolicy.keep,
      );
    } catch (e) {
      debugPrint('Background refresh not available: $e');
    }
  }
}

/// Entry point for the background refresh.
@pragma('vm:entry-point')
void backgroundDispatcher() {
  Workmanager().executeTask((task, input) async {
    await NotificationService.initTimeZones();
    if (AlarmScheduler.extraSources.isEmpty) AlarmScheduler.extraSources.add(festivalAlarms);
    final db = AppDatabase();
    try {
      await AlarmScheduler.syncNow(db);
      await BackupService(db).autoIfDue();
    } finally {
      await db.close();
    }
    return true;
  });
}
