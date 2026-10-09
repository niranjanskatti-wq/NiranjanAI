import 'dart:ui';

import 'package:flutter/widgets.dart';
import 'package:workmanager/workmanager.dart';

import '../core/app_services.dart';
import '../core/format.dart';
import '../core/strings.dart';
import '../data/repository.dart';
import 'backup_service.dart';
import 'notifications.dart';
import 'alarm_scheduler.dart';

const _taskReminders = 'gv.reminders';
const _taskCloud = 'gv.cloud';

/// Runs in a background isolate started by Android WorkManager.
@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, input) async {
    WidgetsFlutterBinding.ensureInitialized();
    DartPluginRegistrant.ensureInitialized();
    try {
      final svc = await AppServices.init();
      await svc.google.load();
      switch (task) {
        case _taskReminders:
          await Background.notifyDue(svc);
          return true;
        case _taskCloud:
          return await Background.cloudWork(svc);
      }
      return true;
    } catch (e) {
      debugPrint('Background task $task failed: $e');
      return false; // WorkManager retries with back-off
    }
  });
}

class Background {
  Background._();

  static Future<void> init() async {
    try {
      await Workmanager().initialize(callbackDispatcher);
    } catch (e) {
      debugPrint('WorkManager unavailable: $e');
    }
  }

  /// (Re)register periodic jobs. Reminder checks need no network; the cloud
  /// job only runs when a (Wi-Fi, if chosen) connection is available, so an
  /// offline phone simply catches up once it reconnects.
  static Future<void> schedule(AppServices svc) async {
    try {
      final sched = await svc.backup.schedule();
      await Workmanager().registerPeriodicTask(
        _taskReminders,
        _taskReminders,
        frequency: const Duration(hours: 6),
        existingWorkPolicy: ExistingPeriodicWorkPolicy.update,
      );
      await Workmanager().registerPeriodicTask(
        _taskCloud,
        _taskCloud,
        frequency: const Duration(hours: 1),
        constraints: Constraints(
          networkType: sched.wifiOnly ? NetworkType.unmetered : NetworkType.connected,
          requiresBatteryNotLow: true,
        ),
        existingWorkPolicy: ExistingPeriodicWorkPolicy.update,
        backoffPolicy: BackoffPolicy.exponential,
        backoffPolicyDelay: const Duration(minutes: 15),
      );
    } catch (e) {
      debugPrint('Scheduling failed: $e');
    }
  }

  static Future<S> _strings(AppServices svc) async => S(await svc.repo.getSetting('lang') ?? 'en');

  /// Keeps exact-time alarms fresh and nags once a day about overdue rent
  /// and items not returned.
  static Future<void> notifyDue(AppServices svc) async {
    await AlarmScheduler.reschedule(svc.repo);
    final prefs = await svc.repo.prefs();
    if (!prefs.notifications) return;
    final s = await _strings(svc);
    // Weekly nudge to save a backup to Google Drive (no sign-in needed).
    if (prefs.backupNudge) {
      final last = Fmt.parse(await svc.repo.getSetting('last_backup'));
      final hasItems = (await svc.repo.items(const ItemQuery())).isNotEmpty;
      final week = DateTime.now().difference(DateTime(2024)).inDays ~/ 7;
      final key = 'backup_nudge@$week';
      if (hasItems && (last == null || DateTime.now().difference(last).inDays >= 7) && !await svc.repo.wasNotified(key)) {
        await Notifier.reminder(9002, s.t('fbk.nudge'), s.t('fbk.nudgeBody'));
        await svc.repo.markNotified(key);
      }
    }
    var n = 0;
    for (final d in await svc.reminders.dueForNotification()) {
      final key = '${d.key}@${Fmt.isoDate(DateTime.now())}';
      if (await svc.repo.wasNotified(key)) continue;
      final (title, body) = AlarmScheduler.texts(s, d);
      await Notifier.reminder(AlarmScheduler.idFor(key), title, body);
      await svc.repo.markNotified(key);
      if (++n >= 6) break;
    }
  }

  /// Weekly Drive backup when due, then Sheets auto-sync when needed.
  /// Returns false to let WorkManager retry later.
  static Future<bool> cloudWork(AppServices svc) async {
    final s = await _strings(svc);
    var ok = true;
    if (await svc.backup.isDue()) {
      try {
        final name = await svc.backup.autoBackup();
        if ((await svc.repo.prefs()).backupNotifications) await Notifier.backup(s.t('notif.backupDone'), name);
      } on BackupException catch (e) {
        // No place chosen yet: the weekly "save a backup" nudge covers it.
        if (e.code == 'no_target') return ok;
        // Needs the user (choose a place / sign in): tell them once a day.
        final key = 'backup_fail:${e.code}@${Fmt.isoDate(DateTime.now())}';
        if (!await svc.repo.wasNotified(key)) {
          await Notifier.backup(s.t('notif.backupFailed'), s.t('backup.err.${e.code}'));
          await svc.repo.markNotified(key);
        }
      } catch (e) {
        debugPrint('Backup failed, will retry: $e');
        ok = false;
      }
    }
    if ((await svc.repo.getSetting('auto_sync')) != '0' &&
        await svc.sheets.isDirty()) {
      try {
        await svc.sheets.syncNow();
      } catch (e) {
        debugPrint('Sync failed, will retry: $e');
        ok = false;
      }
    }
    return ok;
  }
}
