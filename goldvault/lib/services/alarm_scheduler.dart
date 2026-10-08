import 'package:flutter/foundation.dart';

import '../core/format.dart';
import '../core/strings.dart';
import '../data/repository.dart';
import 'notifications.dart';
import 'reminder_engine.dart';

/// Turns upcoming reminders into exact-time Android notifications/alarms.
/// Re-run whenever data or settings change, at app start and from the
/// background job (scheduled alarms also survive a reboot).
class AlarmScheduler {
  AlarmScheduler._();

  static const _maxScheduled = 60;
  static const _horizonDays = 60;

  static int idFor(String key) => 100000 + (key.hashCode & 0x3FFFFFF);

  static (String, String) texts(S s, DueItem d) {
    final date = Fmt.date(d.date);
    switch (d.kind) {
      case DueKind.rent:
        return (s.t('notif.rent', {'name': d.title}), s.t('notif.rentBody', {'date': date, 'amount': d.subtitle ?? ''}));
      case DueKind.notReturned:
        return (s.t('notif.notReturned'), s.t('notif.notReturnedBody', {'name': d.title, 'date': d.subtitle ?? ''}));
      case DueKind.plannedVisit:
        return (s.t('notif.planned', {'name': d.title}), s.t('notif.plannedBody', {'date': date}));
      case DueKind.keep:
        return (s.t('notif.keep'), [d.title, ?d.subtitle].join(' · '));
      case DueKind.take:
        return (s.t('notif.take'), [d.title, ?d.subtitle].join(' · '));
      case DueKind.custom:
        return (d.title, [Fmt.dateTime(d.notifyAt), ?d.subtitle].join(' · '));
      case DueKind.holiday:
        final what = d.title.isEmpty ? s.t('hol.weekend') : d.title;
        return (
          s.t('notif.holiday', {'n': d.days, 'date': date}),
          s.t('notif.holidayBody', {'what': what, 'range': d.subtitle ?? date}),
        );
    }
  }

  static Future<void> reschedule(VaultRepo repo) async {
    try {
      final prefs = await repo.prefs();
      final old = (await repo.getSetting('scheduled_ids') ?? '').split(',').map(int.tryParse).whereType<int>().toSet();
      final now = DateTime.now();
      final want = <int, DueItem>{};
      if (prefs.notifications) {
        final engine = ReminderEngine(repo);
        final items = (await engine.upcoming(now: now, horizonDays: _horizonDays))
            .where((d) => d.notifyAt.isAfter(now))
            .toList()
          ..sort((a, b) => a.notifyAt.compareTo(b.notifyAt));
        for (final d in items.take(_maxScheduled)) {
          want[idFor(d.key)] = d;
        }
      }
      for (final id in old.difference(want.keys.toSet())) {
        await Notifier.cancel(id);
      }
      final s = S(await repo.getSetting('lang') ?? 'en');
      for (final e in want.entries) {
        final (title, body) = texts(s, e.value);
        await Notifier.schedule(e.key, e.value.notifyAt, title, body, alarm: e.value.alarm);
      }
      await repo.setSetting('scheduled_ids', want.keys.join(','));
    } catch (e) {
      debugPrint('Reschedule failed: $e');
    }
  }
}
