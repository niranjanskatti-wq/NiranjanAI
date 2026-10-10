import 'package:flutter_test/flutter_test.dart';
import 'package:smriti/core/util/occurrence.dart';
import 'package:smriti/data/enums.dart';

void main() {
  group('yearly', () {
    test('later this year', () {
      expect(
        nextOccurrence(repeat: Repeat.yearly, month: 10, day: 3, from: const Day(2026, 9, 29)),
        const Day(2026, 10, 3),
      );
    });

    test('today counts as the next occurrence', () {
      expect(
        nextOccurrence(repeat: Repeat.yearly, month: 9, day: 29, from: const Day(2026, 9, 29)),
        const Day(2026, 9, 29),
      );
    });

    test('already passed this year moves to next year', () {
      expect(
        nextOccurrence(repeat: Repeat.yearly, month: 1, day: 5, from: const Day(2026, 9, 29)),
        const Day(2027, 1, 5),
      );
    });

    test('29 Feb in a leap year stays on 29 Feb', () {
      expect(
        nextOccurrence(repeat: Repeat.yearly, month: 2, day: 29, from: const Day(2028, 1, 1)),
        const Day(2028, 2, 29),
      );
    });

    test('29 Feb falls on 28 Feb or 1 Mar in other years', () {
      expect(
        nextOccurrence(repeat: Repeat.yearly, month: 2, day: 29, from: const Day(2026, 9, 29)),
        const Day(2027, 2, 28),
      );
      expect(
        nextOccurrence(
          repeat: Repeat.yearly,
          month: 2,
          day: 29,
          feb29: Feb29Rule.mar1,
          from: const Day(2026, 9, 29),
        ),
        const Day(2027, 3, 1),
      );
    });

    test('a start year in the future waits for it', () {
      expect(
        nextOccurrence(
            repeat: Repeat.yearly, month: 3, day: 1, year: 2028, from: const Day(2026, 9, 29)),
        const Day(2028, 3, 1),
      );
    });
  });

  group('monthly', () {
    test('31st falls on the last day of shorter months', () {
      expect(
        nextOccurrence(repeat: Repeat.monthly, month: 1, day: 31, from: const Day(2026, 9, 1)),
        const Day(2026, 9, 30),
      );
      expect(
        nextOccurrence(repeat: Repeat.monthly, month: 1, day: 31, from: const Day(2027, 2, 2)),
        const Day(2027, 2, 28),
      );
      expect(
        nextOccurrence(repeat: Repeat.monthly, month: 1, day: 31, from: const Day(2028, 2, 2)),
        const Day(2028, 2, 29),
      );
    });

    test('rolls over the year end', () {
      expect(
        nextOccurrence(repeat: Repeat.monthly, month: 1, day: 5, from: const Day(2026, 12, 6)),
        const Day(2027, 1, 5),
      );
    });

    test('does not start before its first month', () {
      expect(
        nextOccurrence(
            repeat: Repeat.monthly, month: 12, day: 10, year: 2026, from: const Day(2026, 9, 29)),
        const Day(2026, 12, 10),
      );
    });
  });

  group('one time', () {
    test('future date', () {
      expect(
        nextOccurrence(
            repeat: Repeat.once, month: 11, day: 2, year: 2026, from: const Day(2026, 9, 29)),
        const Day(2026, 11, 2),
      );
    });

    test('past date never repeats', () {
      expect(
        nextOccurrence(
            repeat: Repeat.once, month: 1, day: 2, year: 2026, from: const Day(2026, 9, 29)),
        isNull,
      );
    });
  });

  group('previous occurrence', () {
    test('yesterday', () {
      expect(
        previousOccurrence(
            repeat: Repeat.yearly, month: 9, day: 28, before: const Day(2026, 9, 29)),
        const Day(2026, 9, 28),
      );
    });

    test('monthly last month', () {
      expect(
        previousOccurrence(
            repeat: Repeat.monthly, month: 1, day: 31, before: const Day(2026, 10, 1)),
        const Day(2026, 9, 30),
      );
    });
  });

  group('years and milestones', () {
    test('turning age', () {
      expect(yearsOn(const Day(2026, 10, 3), 1966), 60);
      expect(yearsOn(const Day(2026, 10, 3), null), isNull);
      expect(yearsOn(const Day(2026, 10, 3), 2026), isNull);
    });

    test('milestones', () {
      expect(isMilestone(EventType.birthday, 60), isTrue);
      expect(isMilestone(EventType.birthday, 61), isFalse);
      expect(isMilestone(EventType.weddingAnniversary, 25), isTrue);
      expect(isMilestone(EventType.weddingAnniversary, 60), isFalse);
      expect(isMilestone(EventType.insurance, 25), isFalse);
    });

    test('ordinals', () {
      expect(ordinal(1), '1st');
      expect(ordinal(12), '12th');
      expect(ordinal(22), '22nd');
      expect(ordinal(60), '60th');
      expect(ordinal(113), '113th');
    });
  });

  test('days between dates ignores daylight saving', () {
    expect(const Day(2026, 3, 1).daysUntil(const Day(2026, 4, 1)), 31);
    expect(const Day(2026, 12, 31).daysUntil(const Day(2027, 1, 1)), 1);
    expect(const Day(2026, 9, 29).addDays(3), const Day(2026, 10, 2));
  });
}
