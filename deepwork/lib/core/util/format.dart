import 'package:intl/intl.dart';

const dayNames = ['Sunday', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday'];
const dayShort = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];

/// Weekday index with Sunday = 0 (Dart uses Monday = 1 … Sunday = 7).
int weekday0(DateTime d) => d.weekday % 7;

DateTime startOfDay(DateTime d) => DateTime(d.year, d.month, d.day);
DateTime addDays(DateTime d, int n) => DateTime(d.year, d.month, d.day + n, d.hour, d.minute, d.second, d.millisecond);

String dateKey([DateTime? d]) => DateFormat('yyyy-MM-dd').format(d ?? DateTime.now());
String dateKeyMs(int ms) => dateKey(DateTime.fromMillisecondsSinceEpoch(ms));
DateTime parseDateKey(String k) => DateTime.parse(k);
String todayKey() => dateKey();
String tomorrowKey() => dateKey(addDays(DateTime.now(), 1));

int timeToMinutes(String t) {
  final p = t.split(':');
  return (int.tryParse(p[0]) ?? 0) * 60 + (p.length > 1 ? int.tryParse(p[1]) ?? 0 : 0);
}

String minutesToTime(int min) {
  final m = ((min % 1440) + 1440) % 1440;
  return '${(m ~/ 60).toString().padLeft(2, '0')}:${(m % 60).toString().padLeft(2, '0')}';
}

String formatClock(String t) {
  final mins = timeToMinutes(t);
  final h = mins ~/ 60, m = mins % 60;
  final suffix = h >= 12 ? 'pm' : 'am';
  final h12 = h % 12 == 0 ? 12 : h % 12;
  return m == 0 ? '$h12 $suffix' : '$h12:${m.toString().padLeft(2, '0')} $suffix';
}

String formatHour(int h) {
  final suffix = h >= 12 && h < 24 ? 'pm' : 'am';
  final h12 = h % 12 == 0 ? 12 : h % 12;
  return '$h12 $suffix';
}

/// "1h 25m", "45m", "0m"
String formatDuration(num seconds) {
  final totalMin = (seconds / 60).round();
  final h = totalMin ~/ 60, m = totalMin % 60;
  if (h == 0) return '${m}m';
  if (m == 0) return '${h}h';
  return '${h}h ${m}m';
}

/// Timer display: mm:ss or h:mm:ss; or minutes only.
String formatTimer(num seconds, {bool hideSeconds = false}) {
  final s = seconds < 0 ? 0 : seconds.floor();
  if (hideSeconds) {
    final totalMin = (s / 60).ceil();
    final hh = totalMin ~/ 60, mm = totalMin % 60;
    return hh > 0 ? '${hh}h ${mm.toString().padLeft(2, '0')}m' : '${mm}m';
  }
  final h = s ~/ 3600, m = (s % 3600) ~/ 60, sec = s % 60;
  final mm = m.toString().padLeft(2, '0'), ss = sec.toString().padLeft(2, '0');
  return h > 0 ? '$h:$mm:$ss' : '$mm:$ss';
}

String relativeDays(int ms) {
  final d = startOfDay(DateTime.now()).difference(startOfDay(DateTime.fromMillisecondsSinceEpoch(ms))).inDays;
  if (d <= 0) return 'today';
  if (d == 1) return 'yesterday';
  if (d < 7) return '$d days ago';
  if (d < 14) return '1 week ago';
  if (d < 60) return '${d ~/ 7} weeks ago';
  return DateFormat('MMM d, yyyy').format(DateTime.fromMillisecondsSinceEpoch(ms));
}

String greeting([DateTime? now]) {
  final h = (now ?? DateTime.now()).hour;
  if (h < 5) return 'Good night';
  if (h < 12) return 'Good morning';
  if (h < 18) return 'Good afternoon';
  return 'Good evening';
}

bool isWeekend(DateTime d) => d.weekday == DateTime.saturday || d.weekday == DateTime.sunday;

/// Is [now] inside [start, end) — handles ranges that wrap past midnight.
bool inTimeRange(DateTime now, String start, String end) {
  final n = now.hour * 60 + now.minute;
  final s = timeToMinutes(start), e = timeToMinutes(end);
  if (s == e) return false;
  return s < e ? n >= s && n < e : n >= s || n < e;
}

List<DateTime> lastNDays(int n, [DateTime? end]) {
  final e = startOfDay(end ?? DateTime.now());
  return [for (var i = n - 1; i >= 0; i--) addDays(e, -i)];
}

String pluralize(int n, String one, [String? many]) => '$n ${n == 1 ? one : (many ?? '${one}s')}';

/// Time-of-day at [time] ('HH:mm') on [day].
DateTime atTime(DateTime day, String time) {
  final m = timeToMinutes(time);
  return DateTime(day.year, day.month, day.day, m ~/ 60, m % 60);
}
