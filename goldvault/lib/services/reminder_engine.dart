import '../core/format.dart';
import '../data/constants.dart';
import '../data/models.dart';
import '../data/repository.dart';
import 'holiday_calendar.dart';

enum DueKind { rent, notReturned, plannedVisit, custom, keep, take, holiday }

/// One thing the family should be reminded about.
class DueItem {
  final DueKind kind;
  final String key; // stable id (notification id, de-duplication)
  final DateTime date; // the day it is about
  final DateTime notifyAt; // when the alert / alarm goes off
  final bool alarm; // ring like an alarm
  final String title;
  final String? subtitle;
  final int? locationId;
  final int? itemId;
  final int? reminderId;
  final List<int> itemIds;
  final int days; // holiday closures: number of closed days

  const DueItem({
    required this.kind,
    required this.key,
    required this.date,
    required this.notifyAt,
    required this.title,
    this.alarm = false,
    this.subtitle,
    this.locationId,
    this.itemId,
    this.reminderId,
    this.itemIds = const [],
    this.days = 1,
  });

  bool isOverdue(DateTime now) => date.isBefore(Fmt.dateOnly(now));
}

/// Computes all reminders (rent, not returned, user alarms, bank holidays)
/// from local data and the user's on/off settings.
class ReminderEngine {
  ReminderEngine(this.repo);
  final VaultRepo repo;

  Future<int> notReturnedDays() async => (await repo.prefs()).notReturnedDays;
  Future<int> rentLeadDays() async => (await repo.prefs()).rentLeadDays;

  static DateTime _atTime(DateTime day, String hhmm) {
    final p = hhmm.split(':');
    return DateTime(day.year, day.month, day.day, int.tryParse(p[0]) ?? 9, p.length > 1 ? int.tryParse(p[1]) ?? 0 : 0);
  }

  /// Everything due within [horizonDays] (plus anything overdue).
  Future<List<DueItem>> upcoming({DateTime? now, int horizonDays = 30}) async {
    final n = now ?? DateTime.now();
    final today = Fmt.dateOnly(n);
    final horizon = today.add(Duration(days: horizonDays));
    final prefs = await repo.prefs();
    final t = prefs.alertTime;
    final out = <DueItem>[];
    final locs = await repo.locationMap();

    // Locker rent.
    if (prefs.rentAlerts) {
      final lead = prefs.rentLeadDays;
      for (final e in (await repo.allLockerInfo()).entries) {
        final loc = locs[e.key];
        if (loc == null || loc.isClosed) continue;
        final due = Fmt.parse(e.value.rentDueDate);
        if (due == null) continue;
        final remindFrom = due.subtract(Duration(days: lead));
        // Show when due inside the horizon, or once the lead window has started.
        if (due.isAfter(horizon) && remindFrom.isAfter(today)) continue;
        out.add(DueItem(
          kind: DueKind.rent,
          key: 'rent:${e.key}:${e.value.rentDueDate}',
          date: due,
          notifyAt: _atTime(remindFrom, t),
          title: loc.name,
          subtitle: e.value.annualRent == null ? null : Fmt.rupees(e.value.annualRent),
          locationId: e.key,
        ));
      }
    }

    // Items taken out (worn / repair / lent / pledged) and not back in time.
    if (prefs.notReturnedAlerts) {
      final days = prefs.notReturnedDays;
      for (final i in await repo.items(ItemQuery(statuses: Opt.outStatuses.toSet()))) {
        final last = await repo.lastMoveTo(i.id!, i.status) ?? await repo.lastMove(i.id!);
        final since = last?.at ?? Fmt.parse(i.updatedAt) ?? today;
        final due = Fmt.dateOnly(since).add(Duration(days: days));
        if (due.isAfter(horizon)) continue;
        out.add(DueItem(
          kind: DueKind.notReturned,
          key: 'out:${i.id}:${Fmt.isoDate(since)}',
          date: due,
          notifyAt: _atTime(due, t),
          title: '${i.name} (${i.serial})',
          subtitle: Fmt.date(since),
          itemId: i.id,
        ));
      }
    }

    // User reminders / alarms (with repeats).
    for (final r in await repo.reminders()) {
      if (!r.enabled) continue;
      final kind = switch (r.kind) {
        'planned_visit' => DueKind.plannedVisit,
        'keep' => DueKind.keep,
        'take' => DueKind.take,
        _ => DueKind.custom,
      };
      if (kind == DueKind.plannedVisit && !prefs.plannedAlerts) continue;
      var at = r.at(t);
      for (var k = 0; k < 12 && !Fmt.dateOnly(at).isAfter(horizon); k++) {
        // Planned visits alert a few days ahead (at the chosen time).
        final notifyAt = kind == DueKind.plannedVisit && r.time == null
            ? at.subtract(Duration(days: prefs.plannedLeadDays))
            : at;
        out.add(DueItem(
          kind: kind,
          key: 'rem:${r.id}:${Fmt.isoDateTime(at)}',
          date: Fmt.dateOnly(at),
          notifyAt: notifyAt,
          alarm: r.alarm,
          title: r.title,
          subtitle: r.locationId != null ? locs[r.locationId]?.name : r.notes,
          locationId: r.locationId,
          reminderId: r.id,
          itemIds: r.itemIds,
        ));
        final next = r.nextAfter(at);
        if (next == null) break;
        at = next;
      }
    }

    // Bank holidays: warn before the bank closes.
    if (prefs.holidayAlerts) {
      final cal = await HolidayCalendar.load(repo);
      for (final c in cal.closures(today.add(const Duration(days: 1)), horizon)) {
        if (!c.hasNamedHoliday && !prefs.holidayWeekendAlerts) continue;
        out.add(DueItem(
          kind: DueKind.holiday,
          key: 'hol:${Fmt.isoDate(c.start)}',
          date: c.start,
          notifyAt: _atTime(c.start.subtract(Duration(days: prefs.holidayLeadDays)), t),
          title: c.names.isEmpty ? '' : c.names.toSet().join(', '),
          days: c.days,
          subtitle: c.days > 1 ? '${Fmt.date(c.start)} – ${Fmt.date(c.end)}' : Fmt.date(c.start),
        ));
      }
    }

    out.sort((a, b) => a.date.compareTo(b.date));
    return out;
  }

  /// Overdue rent / not-returned items: nagged once a day by the background
  /// job (everything else is scheduled at its exact time).
  Future<List<DueItem>> dueForNotification({DateTime? now}) async {
    final n = now ?? DateTime.now();
    final all = await upcoming(now: n, horizonDays: 1);
    return all
        .where((d) => (d.kind == DueKind.rent || d.kind == DueKind.notReturned) && !d.notifyAt.isAfter(n))
        .toList();
  }

  static Reminder planned(Location l, DateTime date, {String? time, String? notes}) => Reminder(
        kind: 'planned_visit',
        title: l.name,
        dueDate: Fmt.isoDate(date),
        time: time,
        locationId: l.id,
        notes: notes,
      );
}
