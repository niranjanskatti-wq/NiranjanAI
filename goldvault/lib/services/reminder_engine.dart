import '../core/format.dart';
import '../data/constants.dart';
import '../data/models.dart';
import '../data/repository.dart';

enum DueKind { rent, notReturned, plannedVisit, custom }

/// One thing the family should be reminded about.
class DueItem {
  final DueKind kind;
  final String key; // stable id used to avoid duplicate notifications
  final DateTime date;
  final String title;
  final String? subtitle;
  final int? locationId;
  final int? itemId;
  final int? reminderId;

  const DueItem({
    required this.kind,
    required this.key,
    required this.date,
    required this.title,
    this.subtitle,
    this.locationId,
    this.itemId,
    this.reminderId,
  });

  bool isOverdue(DateTime now) => date.isBefore(Fmt.dateOnly(now));
}

/// Computes rent-due, not-returned and planned-visit reminders from data.
class ReminderEngine {
  ReminderEngine(this.repo);
  final VaultRepo repo;

  Future<int> notReturnedDays() async =>
      int.tryParse(await repo.getSetting('not_returned_days') ?? '') ?? 30;

  Future<int> rentLeadDays() async =>
      int.tryParse(await repo.getSetting('rent_lead_days') ?? '') ?? 15;

  /// Everything due within [horizonDays] (plus anything overdue).
  Future<List<DueItem>> upcoming({DateTime? now, int horizonDays = 30}) async {
    final today = Fmt.dateOnly(now ?? DateTime.now());
    final horizon = today.add(Duration(days: horizonDays));
    final out = <DueItem>[];
    final locs = await repo.locationMap();

    // Locker rent.
    final lead = await rentLeadDays();
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
        title: loc.name,
        subtitle: e.value.annualRent == null ? null : Fmt.rupees(e.value.annualRent),
        locationId: e.key,
      ));
    }

    // Items taken out (worn / repair / lent / pledged) and not back in time.
    final days = await notReturnedDays();
    final outItems = await repo.items(ItemQuery(statuses: Opt.outStatuses.toSet()));
    for (final i in outItems) {
      final last = await repo.lastMoveTo(i.id!, i.status) ?? await repo.lastMove(i.id!);
      final since = last?.at ?? Fmt.parse(i.updatedAt) ?? today;
      final due = Fmt.dateOnly(since).add(Duration(days: days));
      if (due.isAfter(horizon)) continue;
      out.add(DueItem(
        kind: DueKind.notReturned,
        key: 'out:${i.id}:${Fmt.isoDate(since)}',
        date: due,
        title: '${i.name} (${i.serial})',
        subtitle: Fmt.date(since),
        itemId: i.id,
      ));
    }

    // Planned visits and custom reminders.
    for (final r in await repo.reminders()) {
      final due = DateTime.parse(r.dueDate);
      if (due.isAfter(horizon)) continue;
      out.add(DueItem(
        kind: r.kind == 'planned_visit' ? DueKind.plannedVisit : DueKind.custom,
        key: 'rem:${r.id}:${r.dueDate}',
        date: due,
        title: r.title,
        subtitle: r.locationId == null ? r.notes : locs[r.locationId]?.name,
        locationId: r.locationId,
        reminderId: r.id,
      ));
    }

    out.sort((a, b) => a.date.compareTo(b.date));
    return out;
  }

  /// Items that should trigger a notification today.
  Future<List<DueItem>> dueForNotification({DateTime? now}) async {
    final today = Fmt.dateOnly(now ?? DateTime.now());
    final lead = await rentLeadDays();
    final all = await upcoming(now: now, horizonDays: lead);
    return all.where((d) {
      switch (d.kind) {
        case DueKind.rent:
          return true; // within lead window or overdue
        case DueKind.notReturned:
        case DueKind.custom:
          return !d.date.isAfter(today);
        case DueKind.plannedVisit:
          return !d.date.isAfter(today.add(const Duration(days: 1)));
      }
    }).toList();
  }

  static Reminder planned(Location l, DateTime date, {String? notes}) => Reminder(
        kind: 'planned_visit',
        title: l.name,
        dueDate: Fmt.isoDate(date),
        locationId: l.id,
        notes: notes,
      );
}
