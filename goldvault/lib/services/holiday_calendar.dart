import '../core/format.dart';
import '../data/models.dart';
import '../data/repository.dart';

/// A run of consecutive days the bank is closed.
class Closure {
  final DateTime start;
  final DateTime end;
  final List<String> names; // named holidays in the run (not weekends)
  final List<String> weekends; // 'sun' / 'sat2' / 'sat4' days in the run
  const Closure(this.start, this.end, this.names, [this.weekends = const []]);

  int get days => end.difference(start).inDays + 1;
  bool get hasNamedHoliday => names.isNotEmpty;
  bool get hasSaturdayHoliday => weekends.contains('sat2') || weekends.contains('sat4');

  /// Whether this closure is shown in lists and gets a warning alarm.
  /// Named holidays always; 2nd/4th Saturday weekends when weekend holidays
  /// are on; a plain Sunday only if "every Sunday" is on.
  bool listed({required bool weekendHolidays, required bool everySunday}) =>
      hasNamedHoliday || (weekendHolidays && (hasSaturdayHoliday || (everySunday && weekends.isNotEmpty)));

  /// "Ayudha Pooja, 4th Saturday, Sunday" (weekend names via [weekendLabel]).
  String label(String Function(String code) weekendLabel) =>
      [...names.toSet(), ...weekends.toSet().map(weekendLabel)].join(', ');
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
      final weekends = <String>[];
      while (isClosed(d)) {
        names.addAll(namedOn(d));
        final w = weekendOn(d);
        if (w != null) weekends.add(w);
        d = DateTime(d.year, d.month, d.day + 1);
      }
      out.add(Closure(start, DateTime(d.year, d.month, d.day - 1), names, weekends));
    }
    return out;
  }
}
