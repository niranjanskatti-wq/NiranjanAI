import 'package:flutter_test/flutter_test.dart';
import 'package:smriti/core/util/occurrence.dart';
import 'package:smriti/data/database.dart';
import 'package:smriti/data/models.dart';
import 'package:smriti/features/reminders/alarm_planner.dart';
import 'package:smriti/features/reminders/reminder_model.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

Person person(int id, String name, {String rel = 'father', String? tz, int stars = 3}) => Person(
      id: id,
      name: name,
      relationship: rel,
      stars: stars,
      timeZone: tz,
      whatsappApp: 'auto',
      editedFields: '',
      isMe: false,
      isArchived: false,
      createdAt: DateTime(2020),
      updatedAt: DateTime(2020),
    );

EventEntry event(int id, int month, int day, List<Person> people,
        {String kind = 'person', String type = 'birthday', String repeat = 'yearly', int? year, String clock = 'mine', String? title}) =>
    EventEntry(
      Event(
        id: id,
        kind: kind,
        type: type,
        title: title,
        day: day,
        month: month,
        year: year,
        repeat: repeat,
        feb29Rule: 'feb28',
        alarmClock: clock,
        belatedNudge: true,
        createdAt: DateTime(2020),
      ),
      people,
    );

void main() {
  late tz.Location ist;
  setUpAll(() {
    tzdata.initializeTimeZones();
    ist = tz.getLocation('Asia/Kolkata');
  });

  List<PlannedAlarm> plan(List<EventEntry> entries, Map<int, List<ReminderSpec>> rem,
          {Set<String> wished = const {}, bool monthly = false, tz.TZDateTime? now, int cap = 450}) =>
      planAlarms(
        PlanInput(entries: entries, reminders: rem, wished: wished, giftCounts: const {}, monthlySummary: monthly),
        now: now ?? tz.TZDateTime(ist, 2026, 9, 29, 10),
        local: ist,
        cap: cap,
      );

  test('morning reminder fires at 8:00 on the day', () {
    final a = plan([event(1, 10, 3, [person(1, 'Appa')])], {1: [const ReminderSpec(ReminderKind.morning, minute: 480)]});
    final mine = a.where((x) => x.kind == 'rem').first;
    expect(mine.when, tz.TZDateTime(ist, 2026, 10, 3, 8));
    expect(mine.title, "Today: Appa's birthday");
  });

  test('midnight alarm starts at 11:59:50 the night before, full screen', () {
    final a = plan([event(1, 10, 3, [person(1, 'Appa')])], {1: [const ReminderSpec(ReminderKind.midnight)]});
    final mid = a.firstWhere((x) => x.kind == 'mid');
    expect(mid.when, tz.TZDateTime(ist, 2026, 10, 2, 23, 59, 50));
    expect(mid.fullScreen, isTrue);
  });

  test("'their midnight' for someone in New York is 9:29:50 AM in India (daylight time)", () {
    final a = plan(
      [event(1, 10, 3, [person(1, 'Ravi', tz: 'America/New_York')], clock: 'theirs')],
      {1: [const ReminderSpec(ReminderKind.midnight)]},
    );
    final mid = a.firstWhere((x) => x.kind == 'mid');
    expect(mid.when, tz.TZDateTime(ist, 2026, 10, 3, 9, 29, 50));
    expect(mid.body, contains('New York'));
  });

  test('days-before and gift reminders', () {
    final a = plan([event(1, 10, 12, [person(1, 'Chinnu', rel: 'niece')])], {
      1: [
        const ReminderSpec(ReminderKind.daysBefore, daysBefore: 3, minute: 1200),
        const ReminderSpec(ReminderKind.gift, daysBefore: 7, minute: 600),
      ]
    });
    expect(a.map((x) => x.when), containsAll([tz.TZDateTime(ist, 2026, 10, 9, 20), tz.TZDateTime(ist, 2026, 10, 5, 10)]));
    expect(a.any((x) => x.title.startsWith('In 3 days')), isTrue);
    expect(a.any((x) => x.title.startsWith('Gift for Chinnu')), isTrue);
  });

  test('important dates use their title', () {
    final a = plan(
      [event(5, 10, 28, const [], kind: 'other', type: 'insurance', title: 'Car insurance')],
      {5: [const ReminderSpec(ReminderKind.daysBefore, daysBefore: 7, minute: 540)]},
    );
    expect(a.single.title, 'Car insurance in 7 days');
    expect(a.single.when, tz.TZDateTime(ist, 2026, 10, 21, 9));
    expect(a.single.wishActions, isFalse);
  });

  test('belated nudge the next morning unless already wished', () {
    final e = event(1, 9, 28, [person(1, 'Ravi', rel: 'friend')]);
    final now = tz.TZDateTime(ist, 2026, 9, 28, 20);
    final a = plan([e], {1: const []}, now: now);
    final bel = a.where((x) => x.kind == 'bel').single;
    expect(bel.when, tz.TZDateTime(ist, 2026, 9, 29, 9));
    expect(bel.title, "You missed Ravi's birthday yesterday");
    final b = plan([e], {1: const []}, now: now, wished: {'1|2026-09-28'});
    // The nudge now points at next year's birthday instead.
    expect(b.where((x) => x.kind == 'bel').single.date, const Day(2027, 9, 28));
  });

  test('monthly summary on the 1st at 9 AM lists that month', () {
    final a = plan([
      event(1, 10, 3, [person(1, 'Appa')]),
      event(2, 10, 12, [person(2, 'Chinnu', rel: 'niece')]),
    ], {1: const [], 2: const []}, monthly: true);
    final m = a.firstWhere((x) => x.kind == 'month');
    expect(m.when, tz.TZDateTime(ist, 2026, 10, 1, 9));
    expect(m.title, 'October: 2 dates to remember');
    expect(m.body, 'Appa 3rd, Chinnu 12th');
  });

  test('monthly events repeat each month and fall back on the 31st', () {
    final a = plan(
      [event(7, 1, 31, const [], kind: 'other', type: 'rent', title: 'Rent', repeat: 'monthly')],
      {7: [const ReminderSpec(ReminderKind.morning, minute: 540)]},
    );
    final days = a.map((x) => x.date.toString()).take(6).toList();
    expect(days, ['2026-09-30', '2026-10-31', '2026-11-30', '2026-12-31', '2027-01-31', '2027-02-28']);
  });

  test('never more than the cap, soonest first', () {
    final entries = [for (var i = 1; i <= 300; i++) event(i, 1 + i % 12, 1 + i % 28, [person(i, 'P$i')])];
    final rem = {
      for (var i = 1; i <= 300; i++)
        i: [const ReminderSpec(ReminderKind.morning), const ReminderSpec(ReminderKind.midnight)]
    };
    final a = plan(entries, rem, cap: 450);
    expect(a.length, 450);
    for (var i = 1; i < a.length; i++) {
      expect(a[i].when.isBefore(a[i - 1].when), isFalse);
    }
  });

  test('stable ids do not change between runs', () {
    expect(stableId('rem|1|2026-10-03|0|480'), stableId('rem|1|2026-10-03|0|480'));
    expect(stableId('a'), isNot(stableId('b')));
    expect(stableId('x') >= 1000, isTrue);
  });
}
