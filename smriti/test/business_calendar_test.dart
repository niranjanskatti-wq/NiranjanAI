import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smriti/core/theme/app_theme.dart';
import 'package:smriti/data/database.dart';
import 'package:smriti/data/providers.dart';
import 'package:smriti/core/util/occurrence.dart';
import 'package:smriti/features/business/business_calendar.dart';

void main() {
  final asset = File('assets/holidays/karnataka_bank.json').readAsStringSync();
  BusinessCalendar cal([Map<String, String> edits = const {}, SaturdayRule r = SaturdayRule.secondFourth]) =>
      BusinessCalendar.build(asset, edits, r);

  test('Sundays, 2nd and 4th Saturdays and Karnataka bank holidays are off', () {
    final c = cal();
    expect(c.reason(const Day(2026, 10, 4)), 'Sunday');
    expect(c.reason(const Day(2026, 10, 10)), 'Mahalaya Amavasya · 2nd Saturday');
    expect(c.isOff(const Day(2026, 10, 3)), isFalse, reason: '1st Saturday: banks open');
    expect(c.isOff(const Day(2026, 10, 24)), isTrue, reason: '4th Saturday');
    expect(c.isOff(const Day(2026, 10, 31)), isFalse, reason: '5th Saturday');
    expect(c.holiday(const Day(2026, 10, 2))?.name, 'Gandhi Jayanti');
    expect(c.holiday(const Day(2026, 11, 1))?.name, 'Kannada Rajyotsava');
    expect(c.holiday(const Day(2026, 4, 3))?.name, 'Good Friday');
    expect(c.holiday(const Day(2026, 3, 20))?.approx, isTrue, reason: 'Eid depends on the moon');
    expect(c.isOff(const Day(2026, 10, 6)), isFalse, reason: 'ordinary Tuesday');
    // Every year up to 2036 has its holidays.
    for (var y = 2026; y <= 2036; y++) {
      expect(c.holiday(Day(y, 1, 26))?.name, 'Republic Day');
      expect(c.upcoming(Day(y, 1, 1), count: 40).where((h) => h.day.year == y).length, greaterThanOrEqualTo(24));
    }
  });

  test('your changes and the Saturday rule', () {
    final c = cal({'2026-10-06': 'Office anniversary', '2026-10-02': ''}, SaturdayRule.second);
    expect(c.holiday(const Day(2026, 10, 6))?.mine, isTrue);
    expect(c.isOff(const Day(2026, 10, 2)), isFalse, reason: 'removed by you');
    expect(c.isOff(const Day(2026, 10, 24)), isFalse, reason: 'only the 2nd Saturday now');
    expect(cal(const {}, SaturdayRule.all).isOff(const Day(2026, 10, 3)), isTrue);
  });

  test('long weekends and one-day-leave breaks for trips', () {
    final c = cal();
    final breaks = c.breaks(const Day(2026, 10, 1), const Day(2027, 1, 31));
    String show(DaysOff b) => '${b.from}..${b.to} ${b.length}${b.leave == null ? '' : ' leave ${b.leave}'}';
    expect(breaks.map(show).toList(), [
      // Sun 18 Oct + Mahanavami + Vijayadashami.
      '2026-10-18..2026-10-20 3',
      // 4th Saturday + Sunday + Valmiki Jayanti.
      '2026-10-24..2026-10-26 3',
      // Kanakadasa Jayanti (Fri) + 4th Saturday + Sunday.
      '2026-11-27..2026-11-29 3',
      // Christmas (Fri) + 4th Saturday + Sunday.
      '2026-12-25..2026-12-27 3',
      // Take Monday 25 Jan off: 4th Saturday to Republic Day, 4 days.
      '2027-01-23..2027-01-26 4 leave 2027-01-25',
    ]);
  });

  testWidgets('business calendar screen shows red holidays, the list and trip ideas', (tester) async {
    final db = AppDatabase(NativeDatabase.memory());
    await tester.pumpWidget(ProviderScope(
      overrides: [
        databaseProvider.overrideWithValue(db),
        todayProvider.overrideWith((ref) => Stream.value(const Day(2026, 10, 1))),
        businessCalendarProvider.overrideWithValue(cal()),
      ],
      child: MaterialApp(theme: buildTheme(Brightness.dark), home: const BusinessCalendarScreen()),
    ));
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.byType(GridView), findsOneWidget);
    await tester.scrollUntilVisible(find.text('UPCOMING BANK HOLIDAYS'), 200, scrollable: find.byType(Scrollable).first);
    await tester.scrollUntilVisible(find.text('Gandhi Jayanti'), 200, scrollable: find.byType(Scrollable).first);
    expect(find.text('Gandhi Jayanti'), findsOneWidget);
    await tester.scrollUntilVisible(find.text('LONG WEEKENDS & TRIP PLANNING'), 300, scrollable: find.byType(Scrollable).first);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 1));
    await db.close();
  });
}
