import '../core/format.dart';
import '../data/models.dart';
import '../data/repository.dart';

/// A run of consecutive days the bank is closed.
class Closure {
  final DateTime start;
  final DateTime end;
  final List<String> names; // named holidays in the run (not weekends)
  const Closure(this.start, this.end, this.names);

  int get days => end.difference(start).inDays + 1;
  bool get hasNamedHoliday => names.isNotEmpty;
}

/// Bank holiday rules: user's holiday list + (optionally) every Sunday and
/// the 2nd & 4th Saturday, as followed by Indian banks.
class HolidayCalendar {
  HolidayCalendar(this.holidays, {this.sundays = true, this.saturdays24 = true});

  final List<Holiday> holidays;
  final bool sundays;
  final bool saturdays24;

  static Future<HolidayCalendar> load(VaultRepo repo) async {
    final p = await repo.prefs();
    return HolidayCalendar(
      (await repo.holidays()).where((h) => h.enabled).toList(),
      sundays: p.sundaysClosed,
      saturdays24: p.saturdays24Closed,
    );
  }

  /// 2 or 4 when [d] is the 2nd/4th Saturday of its month, else null.
  static int? saturdayNumber(DateTime d) {
    if (d.weekday != DateTime.saturday) return null;
    final n = (d.day - 1) ~/ 7 + 1;
    return (n == 2 || n == 4) ? n : null;
  }

  List<String> namedOn(DateTime d) => [for (final h in holidays) if (h.fallsOn(d)) h.name];

  /// Weekend closure code: 'sun', 'sat2' or 'sat4'.
  String? weekendOn(DateTime d) {
    if (sundays && d.weekday == DateTime.sunday) return 'sun';
    final s = saturdays24 ? saturdayNumber(d) : null;
    return s == null ? null : 'sat$s';
  }

  bool isClosed(DateTime d) => namedOn(d).isNotEmpty || weekendOn(d) != null;

  /// Closures that start between [from] and [to] (inclusive). A run that is
  /// already going on at [from] is reported from [from].
  List<Closure> closures(DateTime from, DateTime to) {
    final out = <Closure>[];
    var d = Fmt.dateOnly(from);
    final last = Fmt.dateOnly(to);
    while (!d.isAfter(last)) {
      if (!isClosed(d)) {
        d = DateTime(d.year, d.month, d.day + 1);
        continue;
      }
      final start = d;
      final names = <String>[];
      while (isClosed(d)) {
        names.addAll(namedOn(d));
        d = DateTime(d.year, d.month, d.day + 1);
      }
      out.add(Closure(start, DateTime(d.year, d.month, d.day - 1), names));
    }
    return out;
  }
}
