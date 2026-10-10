import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../core/format.dart';
import '../../core/strings.dart';
import '../../core/theme.dart';
import '../../data/models.dart';
import '../../services/holiday_calendar.dart';
import 'common.dart';

const _closedColor = Color(0xFFEF9A9A);

/// Home-page bank status at a glance: open/closed today and tomorrow, when
/// it opens again, and a countdown to each coming closure.
class BankGlance extends StatelessWidget {
  const BankGlance({super.key, required this.cal, required this.prefs, this.now, this.onTap});
  final HolidayCalendar cal;
  final Prefs prefs;
  final DateTime? now;
  final VoidCallback? onTap;

  /// Closures to list: anything today or tomorrow, plus the ones the user
  /// chose to see (named holidays, 2nd/4th Saturday weekends, ...).
  static List<Closure> coming(HolidayCalendar cal, Prefs prefs, DateTime now, {int max = 5}) {
    final today = Fmt.dateOnly(now);
    final tomorrow = DateTime(today.year, today.month, today.day + 1);
    return cal
        .closures(today, DateTime(today.year, today.month + 4, today.day))
        .where((c) => !c.start.isAfter(tomorrow) || c.listed(weekendHolidays: prefs.holidayWeekendAlerts, everySunday: prefs.everySundayAlerts))
        .take(max)
        .toList();
  }

  DateTime _nextOpen(DateTime d) {
    var x = d;
    for (var i = 0; i < 60 && cal.isClosed(x); i++) {
      x = DateTime(x.year, x.month, x.day + 1);
    }
    return x;
  }

  String _why(BuildContext context, DateTime d) =>
      [...cal.namedOn(d), if (cal.weekendOn(d) != null) context.t('hol.${cal.weekendOn(d)}')].join(', ');

  @override
  Widget build(BuildContext context) {
    final today = Fmt.dateOnly(now ?? DateTime.now());
    final tomorrow = DateTime(today.year, today.month, today.day + 1);
    final locale = Localizations.localeOf(context).languageCode;
    final day = DateFormat('EEE, d MMM', locale);
    final list = coming(cal, prefs, today);
    final closedToday = cal.isClosed(today);
    final closedTomorrow = cal.isClosed(tomorrow);
    final opens = _nextOpen(closedToday ? today : tomorrow);

    Widget status(String when, DateTime d, bool closed) => Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: (closed ? _closedColor : GV.ok).withValues(alpha: 0.13),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: (closed ? _closedColor : GV.ok).withValues(alpha: 0.6)),
            ),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('$when · ${day.format(d)}', style: const TextStyle(color: GV.muted, fontSize: 13)),
              const SizedBox(height: 2),
              Row(children: [
                Icon(closed ? Icons.block : Icons.check_circle, color: closed ? _closedColor : GV.ok, size: 20),
                const SizedBox(width: 6),
                Text(context.t(closed ? 'bank.closed' : 'bank.open'),
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: closed ? _closedColor : GV.ok)),
              ]),
              if (closed) Text(_why(context, d), maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 13)),
            ]),
          ),
        );

    Widget badge(Closure c) {
      final n = c.start.difference(today).inDays;
      final (big, small) = n <= 0
          ? (context.t('bank.todayShort'), '')
          : n == 1
              ? (context.t('bank.tomorrowShort'), '')
              : ('$n', context.t('bank.days'));
      final soon = n <= 1;
      return Container(
        width: 62,
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: (soon ? _closedColor : GV.gold).withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Text(big,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: small.isEmpty ? 13 : 22, fontWeight: FontWeight.w800, color: soon ? _closedColor : GV.gold)),
          if (small.isNotEmpty) Text(small, style: const TextStyle(fontSize: 11, color: GV.muted)),
        ]),
      );
    }

    return GoldCard(
      onTap: onTap,
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Row(children: [
          status(context.t('bank.today'), today, closedToday),
          const SizedBox(width: 10),
          status(context.t('bank.tomorrow'), tomorrow, closedTomorrow),
        ]),
        if (closedToday || closedTomorrow) ...[
          const SizedBox(height: 8),
          Text(context.t('bank.opensOn', {'date': day.format(opens)}),
              style: const TextStyle(color: GV.goldLight, fontWeight: FontWeight.w700)),
        ],
        const SizedBox(height: 6),
        if (list.isEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Text(context.t('hol.noneUpcoming'), style: const TextStyle(color: GV.muted)),
          ),
        for (final c in list)
          Padding(
            padding: const EdgeInsets.only(top: 10),
            child: Row(children: [
              badge(c),
              const SizedBox(width: 12),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(c.label((w) => context.t('hol.$w')), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                  Text(
                    '${c.days > 1 ? '${day.format(c.start)} – ${day.format(c.end)}' : day.format(c.start)} · ${context.t('hol.closedDays', {'n': c.days})}',
                    style: const TextStyle(color: GV.muted, fontSize: 13.5),
                  ),
                ]),
              ),
            ]),
          ),
      ]),
    );
  }
}
