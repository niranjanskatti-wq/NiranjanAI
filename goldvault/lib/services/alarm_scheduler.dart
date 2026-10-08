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

  // Android allows ~500 pending alarms per app; keep headroom for the
  // background jobs. Later ones are scheduled automatically as these pass.
  static const _maxScheduled = 450;
  // Far enough for alerts set months ahead; only the nearest are scheduled.
  static const _horizonDays = 400;

  static int idFor(String key) => 100000 + (key.hashCode & 0x3FFFFFF);

  /// "1 day", "3 hrs", "15 min" – how long before the due time.
  static String beforeText(S s, int minutes) {
    if (minutes % 43200 == 0) return s.t('alert.months', {'n': minutes ~/ 43200});
    if (minutes % 10080 == 0) return s.t('alert.weeks', {'n': minutes ~/ 10080});
    if (minutes % 1440 == 0) return s.t('alert.days', {'n': minutes ~/ 1440});
    if (minutes % 60 == 0) return s.t('alert.hours', {'n': minutes ~/ 60});
    return s.t('alert.mins', {'n': minutes});
  }

  static (String, String) texts(S s, DueItem d) {
    final (title, body) = _texts(s, d);
    if (d.minutesBefore <= 0) return (title, body);
    // Early alert: say how long until the actual time.
    return (
      '${s.t('alert.inX', {'x': beforeText(s, d.minutesBefore)})} · $title',
      '${Fmt.dateTime(d.notifyAt.add(Duration(minutes: d.minutesBefore)))} · $body',
    );
  }

  static (String, String) _texts(S s, DueItem d) {
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
            .where((d) => d.notify && d.notifyAt.isAfter(now))
            .toList()
          ..sort((a, b) => a.notifyAt.compareTo(b.notifyAt));
        for (final d in items.take(_maxScheduled)) {
          want[idFor(d.key)] = d;
        }
      }
      for (final id in old.difference(want.keys.toSet())) {
        await Notifier.cancel(id);
      }
      final lang = await repo.getSetting('lang') ?? 'en';
      final s = S(lang);
      for (final e in want.entries) {
        final d = e.value;
        final (title, body) = texts(s, d);
        await Notifier.schedule(e.key, d.notifyAt, title, body,
            lang: lang,
            style: AlertStyle(sound: d.sound, vibrate: d.vibrate, snooze: d.snooze, reminderId: d.reminderId));
      }
      await repo.setSetting('scheduled_ids', want.keys.join(','));
    } catch (e) {
      debugPrint('Reschedule failed: $e');
    }
  }
}
