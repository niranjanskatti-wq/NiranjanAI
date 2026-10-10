import 'package:intl/intl.dart';

import 'occurrence.dart';

final _dayMonth = DateFormat('d MMM');
final _weekdayDayMonth = DateFormat('EEE, d MMM');
final _full = DateFormat('d MMM yyyy');
final _monthYear = DateFormat('MMMM yyyy');

String fmtDayMonth(Day d) => _dayMonth.format(d.asDateTime);
String fmtWeekday(Day d) => _weekdayDayMonth.format(d.asDateTime);
String fmtFull(Day d) => _full.format(d.asDateTime);
String fmtMonthYear(DateTime d) => _monthYear.format(d);

/// "Today", "Tomorrow", "in 12 days".
String relativeDays(int days) => switch (days) {
      0 => 'Today',
      1 => 'Tomorrow',
      _ => 'in $days days',
    };

/// Date as stored for an event: "3 Oct", "3 Oct 1966", or "Every month on the 31st".
String fmtEventDate({required int day, required int month, int? year, bool monthly = false}) {
  if (monthly) return 'Every month on the ${ordinal(day)}';
  final d = DateTime(2000, month, day);
  return year == null ? _dayMonth.format(d) : '${_dayMonth.format(d)} $year';
}

const monthNames = [
  'January', 'February', 'March', 'April', 'May', 'June',
  'July', 'August', 'September', 'October', 'November', 'December',
];
