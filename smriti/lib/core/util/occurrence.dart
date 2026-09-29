import '../../data/enums.dart';

/// A calendar date with no time or time zone.
class Day implements Comparable<Day> {
  const Day(this.year, this.month, this.day);

  factory Day.of(DateTime d) => Day(d.year, d.month, d.day);
  factory Day.today() => Day.of(DateTime.now());

  final int year;
  final int month;
  final int day;

  DateTime get asDateTime => DateTime(year, month, day);

  /// Whole days from this date to [other] (positive when [other] is later).
  /// Uses UTC so daylight-saving changes never shift the count.
  int daysUntil(Day other) =>
      DateTime.utc(other.year, other.month, other.day)
          .difference(DateTime.utc(year, month, day))
          .inDays;

  Day addDays(int n) {
    final d = DateTime.utc(year, month, day).add(Duration(days: n));
    return Day(d.year, d.month, d.day);
  }

  @override
  int compareTo(Day other) => year != other.year
      ? year.compareTo(other.year)
      : month != other.month
          ? month.compareTo(other.month)
          : day.compareTo(other.day);

  bool operator <(Day o) => compareTo(o) < 0;
  bool operator >=(Day o) => compareTo(o) >= 0;

  @override
  bool operator ==(Object other) => other is Day && compareTo(other) == 0;

  @override
  int get hashCode => Object.hash(year, month, day);

  @override
  String toString() =>
      '$year-${month.toString().padLeft(2, '0')}-${day.toString().padLeft(2, '0')}';
}

bool isLeapYear(int y) => (y % 4 == 0 && y % 100 != 0) || y % 400 == 0;

int daysInMonth(int y, int m) => DateTime.utc(y, m + 1, 0).day;

/// The date a yearly event with [month]/[day] falls on in [year].
Day resolveYearly(int year, int month, int day, Feb29Rule rule) {
  if (month == 2 && day == 29 && !isLeapYear(year)) {
    return rule == Feb29Rule.feb28 ? Day(year, 2, 28) : Day(year, 3, 1);
  }
  return Day(year, month, day);
}

/// The date a monthly event on [day] falls on in [year]/[month]:
/// the 31st becomes the last day of shorter months.
Day resolveMonthly(int year, int month, int day) {
  final last = daysInMonth(year, month);
  return Day(year, month, day > last ? last : day);
}

/// The first date on or after [from] on which an event happens, or null when a
/// one-time event is already over. [year] is the start year when known.
Day? nextOccurrence({
  required Repeat repeat,
  required int month,
  required int day,
  int? year,
  Feb29Rule feb29 = Feb29Rule.feb28,
  required Day from,
}) {
  final start = year == null ? null : Day(year, month, day);
  switch (repeat) {
    case Repeat.once:
      if (year == null) return null;
      final d = Day(year, month, day);
      return d >= from ? d : null;
    case Repeat.yearly:
      for (var y = from.year; y <= from.year + 2; y++) {
        final d = resolveYearly(y, month, day, feb29);
        if (d >= from && (start == null || y >= start.year)) return d;
      }
      return null;
    case Repeat.monthly:
      var y = from.year, m = from.month;
      for (var i = 0; i < 400; i++) {
        final d = resolveMonthly(y, m, day);
        if (d >= from && (start == null || d >= resolveMonthly(start.year, start.month, day))) {
          return d;
        }
        m++;
        if (m > 12) {
          m = 1;
          y++;
        }
      }
      return null;
  }
}

/// Most recent date strictly before [before] on which a repeating event
/// happened (used for "Missed" in later phases).
Day? previousOccurrence({
  required Repeat repeat,
  required int month,
  required int day,
  int? year,
  Feb29Rule feb29 = Feb29Rule.feb28,
  required Day before,
}) {
  switch (repeat) {
    case Repeat.once:
      if (year == null) return null;
      final d = Day(year, month, day);
      return d < before ? d : null;
    case Repeat.yearly:
      for (var y = before.year; y >= before.year - 2; y--) {
        if (year != null && y < year) return null;
        final d = resolveYearly(y, month, day, feb29);
        if (d < before) return d;
      }
      return null;
    case Repeat.monthly:
      var y = before.year, m = before.month;
      for (var i = 0; i < 3; i++) {
        final d = resolveMonthly(y, m, day);
        if (d < before) {
          if (year != null && d < Day(year, month, 1)) return null;
          return d;
        }
        m--;
        if (m < 1) {
          m = 12;
          y--;
        }
      }
      return null;
  }
}

/// How many years an event is marking on [occurrence] (age for birthdays,
/// years married for anniversaries). Null when the start year is unknown.
int? yearsOn(Day occurrence, int? startYear) {
  if (startYear == null) return null;
  final n = occurrence.year - startYear;
  return n > 0 ? n : null;
}

const birthdayMilestones = {18, 25, 50, 60, 75, 80};
const anniversaryMilestones = {25, 50};

/// Birthdays 18/25/50/60/75/80 and silver (25) / golden (50) anniversaries.
bool isMilestone(EventType type, int? years) {
  if (years == null) return false;
  if (type == EventType.birthday) return birthdayMilestones.contains(years);
  if (type.isAnniversaryLike) return anniversaryMilestones.contains(years);
  return false;
}

String ordinal(int n) {
  if (n % 100 >= 11 && n % 100 <= 13) return '${n}th';
  switch (n % 10) {
    case 1:
      return '${n}st';
    case 2:
      return '${n}nd';
    case 3:
      return '${n}rd';
    default:
      return '${n}th';
  }
}
