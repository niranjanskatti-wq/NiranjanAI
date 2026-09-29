import 'package:intl/intl.dart';

import '../../core/util/format.dart';
import '../../core/util/occurrence.dart';
import '../../core/util/phone.dart';
import '../../data/database.dart';
import '../../data/enums.dart';
import '../../data/models.dart';
import '../../data/repository.dart';
import '../reminders/reminder_model.dart';
import 'xlsx_writer.dart';

/// What to include in an export.
class ExportOptions {
  const ExportOptions({
    this.personIds,
    this.minStars = 0,
    this.month,
    this.types,
    this.groupPersonIds,
    this.includeNumbers = true,
    this.includeNotes = true,
  });

  final Set<int>? personIds;
  final int minStars;
  final int? month;
  final Set<EventType>? types;
  final Set<int>? groupPersonIds;
  final bool includeNumbers, includeNotes;

  bool get isFiltered =>
      personIds != null || minStars > 0 || month != null || types != null || groupPersonIds != null;
}

const allEventsColumns = [
  'Name', 'Nickname', 'Relationship', 'Star Rating', 'Event Type', 'Date', 'Repeat', 'Birth Year',
  'Age Turning', 'Days Left', 'Phone', 'WhatsApp Number', 'Send Wishes To', 'Group', 'Reminders Set',
  'Saved Message', 'Notes', 'Last Wished On', 'Day', 'Month', 'Start Year',
];
const peopleColumns = [
  'Name', 'Nickname', 'Relationship', 'Star Rating', 'Birth Year', 'Phone', 'WhatsApp Number', 'Time Zone',
  'Group', 'Notes', 'Likes', 'Dislikes', 'Clothing Size', 'Favourite Sweets', 'Gift Ideas', 'Archived',
];
const importantColumns = ['Title', 'Category', 'Date', 'Repeat', 'Notes', 'Days Left', 'Day', 'Month', 'Start Year'];
const byMonthColumns = ['Month / Name', 'Event', 'Date', 'Relationship', 'Days Left'];

final _stamp = DateFormat('dd-MM-yyyy');

/// Builds the Excel workbook from the database.
class ExportService {
  ExportService(this.db, {this.groupNames = const {}});

  final AppDatabase db;

  /// personId → group names (Phase 7).
  final Map<int, List<String>> groupNames;

  Future<List<int>> build(ExportOptions o, {Day? today}) async {
    final repo = Repository(db);
    final t = today ?? Day.today();
    final entries = await repo.watchEntries().first;
    final people = await repo.allPeople();
    final reminders = <int, List<ReminderSpec>>{};
    for (final r in await repo.allReminders()) {
      reminders.putIfAbsent(r.eventId, () => []).add(ReminderSpec.fromRow(r));
    }
    final logs = await db.select(db.wishLogs).get();
    final gifts = await db.select(db.giftIdeas).get();
    final byId = {for (final p in people) p.id: p};

    DateTime? lastWished(EventEntry e) {
      final ids = e.people.map((p) => p.id).toSet();
      DateTime? best;
      for (final l in logs.where((l) => l.confirmed && (l.eventId == e.event.id || ids.contains(l.personId)))) {
        if (best == null || l.createdAt.isAfter(best)) best = l.createdAt;
      }
      return best;
    }

    bool personOk(Person p) =>
        (o.personIds == null || o.personIds!.contains(p.id)) &&
        (o.groupPersonIds == null || o.groupPersonIds!.contains(p.id)) &&
        p.stars >= o.minStars;

    final upcoming = computeUpcoming(entries, t, includeArchived: true).where((u) {
      final e = u.entry;
      if (o.month != null && u.date.month != o.month) return false;
      if (o.types != null && !o.types!.contains(e.type)) return false;
      if (e.kind == EventKind.other) return o.personIds == null && o.groupPersonIds == null && o.minStars == 0;
      return e.people.any(personOk);
    }).toList();
    // One-time events that already passed still belong in a full export.
    final past = entries.where((e) => e.nextFrom(t) == null).where((e) {
      if (o.isFiltered) return false;
      return true;
    });

    String tr(String? s) => o.includeNotes ? (s ?? '') : '';
    String num(String? s) => o.includeNumbers ? formatPhone(s) : '';

    // ---- All Events ----
    final all = XSheet('All Events', columns: allEventsColumns, widths: [
      22, 14, 16, 10, 20, 12, 12, 10, 10, 9, 18, 18, 18, 16, 28, 40, 30, 14, 6, 6, 10,
    ]);
    void addEvent(EventEntry e, Day? next, int? daysLeft, int? years) {
      final ps = e.people;
      final first = ps.firstOrNull;
      final sendTo = e.event.sendWishesToId == null ? null : byId[e.event.sendWishesToId];
      final lw = lastWished(e);
      all.add([
        XText(ps.map((p) => p.isMe ? '${p.name} (me)' : p.name).join(' & ')),
        XText(ps.map((p) => p.nickname ?? '').where((x) => x.isNotEmpty).join(' & ')),
        XText(ps.map((p) => p.isMe ? 'You' : p.relationLabel).join(' & ')),
        XNum(e.stars),
        XText(e.typeLabel),
        next == null ? null : XDate(next.year, next.month, next.day),
        XText(e.repeat.label),
        first?.birthYear == null ? null : XNum(first!.birthYear!),
        years == null || e.type != EventType.birthday ? null : XNum(years),
        daysLeft == null ? null : XNum(daysLeft),
        XText(num(first?.callNumber)),
        XText(num(first?.whatsappNumber ?? first?.callNumber)),
        XText(sendTo?.name ?? ''),
        XText(ps.expand((p) => groupNames[p.id] ?? const <String>[]).toSet().join(', ')),
        XText(describeSpecs(reminders[e.event.id] ?? const [])),
        XText(e.event.draftMessage ?? ''),
        XText(tr(e.event.notes)),
        lw == null ? null : XDate(lw.year, lw.month, lw.day),
        XNum(e.event.day),
        XNum(e.event.month),
        e.event.year == null ? null : XNum(e.event.year!),
      ]);
    }

    for (final u in upcoming.where((u) => u.entry.kind != EventKind.other)) {
      addEvent(u.entry, u.date, u.daysLeft, u.years);
    }
    for (final e in past.where((e) => e.kind != EventKind.other)) {
      addEvent(e, e.event.year == null ? null : Day(e.event.year!, e.event.month, e.event.day), null, null);
    }

    // ---- By Month ----
    final byMonth = XSheet('By Month', columns: byMonthColumns, widths: [26, 22, 12, 18, 9]);
    for (var m = 1; m <= 12; m++) {
      final inMonth = upcoming.where((u) => u.date.month == m).toList()
        ..sort((a, b) => a.date.day.compareTo(b.date.day));
      if (inMonth.isEmpty) continue;
      byMonth.add([XText(monthNames[m - 1])], bold: true);
      for (final u in inMonth) {
        byMonth.add([
          XText('   ${u.entry.title}'),
          XText(u.entry.typeLabel),
          XDate(u.date.year, u.date.month, u.date.day),
          XText(u.entry.kind == EventKind.other ? '' : u.entry.relationLine),
          XNum(u.daysLeft),
        ]);
      }
    }

    // ---- People ----
    final ppl = XSheet('People', columns: peopleColumns, widths: [
      22, 14, 16, 10, 10, 18, 18, 18, 16, 30, 24, 24, 12, 18, 30, 9,
    ]);
    for (final p in people.where((p) => !p.isMe && personOk(p))..toList().sort((a, b) => a.name.compareTo(b.name))) {
      ppl.add([
        XText(p.name),
        XText(p.nickname ?? ''),
        XText(p.relationLabel),
        XNum(p.stars),
        p.birthYear == null ? null : XNum(p.birthYear!),
        XText(num(p.callNumber)),
        XText(num(p.whatsappNumber ?? p.callNumber)),
        XText(p.timeZone ?? ''),
        XText((groupNames[p.id] ?? const []).join(', ')),
        XText(tr(p.notes)),
        XText(tr(p.likes)),
        XText(tr(p.dislikes)),
        XText(p.clothingSize ?? ''),
        XText(p.favouriteSweets ?? ''),
        XText(gifts.where((g) => g.personId == p.id).map((g) => g.idea).join('; ')),
        XText(p.isArchived ? 'Yes' : ''),
      ]);
    }

    // ---- Important Dates ----
    final imp = XSheet('Important Dates', columns: importantColumns, widths: [26, 20, 12, 12, 34, 9, 6, 6, 10]);
    void addImportant(EventEntry e, Day? d, int? left) => imp.add([
          XText(e.title),
          XText(e.typeLabel),
          d == null ? null : XDate(d.year, d.month, d.day),
          XText(e.repeat.label),
          XText(tr(e.event.notes)),
          left == null ? null : XNum(left),
          XNum(e.event.day),
          XNum(e.event.month),
          e.event.year == null ? null : XNum(e.event.year!),
        ]);
    for (final u in upcoming.where((u) => u.entry.kind == EventKind.other)) {
      addImportant(u.entry, u.date, u.daysLeft);
    }
    for (final e in past.where((e) => e.kind == EventKind.other)) {
      addImportant(e, e.event.year == null ? null : Day(e.event.year!, e.event.month, e.event.day), null);
    }

    return XlsxWriter.build([all, byMonth, ppl, imp]);
  }

  /// Blank template with one example row per sheet.
  static List<int> template() {
    final all = XSheet('All Events', columns: allEventsColumns.sublist(0, 18), widths: List.filled(18, 16));
    all.add([
      const XText('Ramesh Katti'), const XText('Appa'), const XText('Father'), const XNum(5), const XText('Birthday'),
      const XDate(2026, 10, 3), const XText('Every year'), const XNum(1966), null, null,
      const XText('+91 98450 12345'), null, null, const XText('Family'), null, null, const XText('Loves Mysore Pak'),
    ]);
    all.add([
      const XText('Ravi Kumar & Priya Kumar'), const XText('Ravi & Priya'), const XText('Uncle & Aunt'), const XNum(4),
      const XText('Wedding Anniversary'), const XDate(2001, 10, 16), const XText('Every year'),
    ]);
    final ppl = XSheet('People', columns: peopleColumns, widths: List.filled(peopleColumns.length, 16));
    ppl.add([
      const XText('Chinmayi'), const XText('Chinnu'), const XText('Niece'), const XNum(4), const XNum(2013),
      const XText('98450 11111'),
    ]);
    final imp = XSheet('Important Dates', columns: importantColumns.sublist(0, 5), widths: [24, 20, 12, 12, 30]);
    imp.add([const XText('Car insurance'), const XText('Insurance Renewal'), const XDate(2026, 10, 28), const XText('Every year'), const XText('Policy 12345')]);
    return XlsxWriter.build([all, ppl, imp]);
  }

  static String fileName() => 'Smriti ${_stamp.format(DateTime.now())}.xlsx';
}
