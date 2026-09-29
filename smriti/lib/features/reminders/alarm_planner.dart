import 'dart:convert';

import 'package:intl/intl.dart';
import 'package:timezone/timezone.dart' as tz;

import '../../core/util/occurrence.dart';
import '../../data/enums.dart';
import '../../data/models.dart';
import 'reminder_model.dart';

/// One notification to schedule.
class PlannedAlarm {
  PlannedAlarm({
    required this.id,
    required this.when,
    required this.kind,
    required this.title,
    required this.body,
    required this.sound,
    this.eventId,
    this.date,
    this.festivalKey,
    this.fullScreen = false,
    this.wishActions = false,
  });

  final int id;
  final tz.TZDateTime when;

  /// mid (midnight alarm), rem (reminder), bel (belated nudge), month (monthly summary), fest (festival).
  final String kind;
  final String title, body;
  final AlarmSound sound;
  final int? eventId;
  final Day? date;
  final String? festivalKey;
  final bool fullScreen, wishActions;

  /// Everything needed to rebuild the notification later (snooze, tap).
  String get payload => jsonEncode({
        'k': kind,
        'e': ?eventId,
        'd': ?date?.toString(),
        'fk': ?festivalKey,
        't': title,
        'b': body,
        's': sound.name,
        'f': fullScreen,
        'a': wishActions,
        'w': when.millisecondsSinceEpoch,
      });
}

/// Inputs for planning, gathered from the database.
class PlanInput {
  PlanInput({
    required this.entries,
    required this.reminders,
    required this.wished,
    required this.giftCounts,
    this.monthlySummary = true,
    this.belatedMinute = 540,
    this.extra = const [],
  });

  final List<EventEntry> entries;
  final Map<int, List<ReminderSpec>> reminders;

  /// "eventId|yyyy-mm-dd" keys already marked as wished.
  final Set<String> wished;
  final Map<int, int> giftCounts;
  final bool monthlySummary;
  final int belatedMinute;

  /// Alarms from other sources (festivals).
  final List<PlannedAlarm> extra;
}

/// Stable positive 31-bit id from a key (FNV-1a), never below 1000.
int stableId(String key) {
  var h = 0x811c9dc5;
  for (final c in key.codeUnits) {
    h ^= c;
    h = (h * 0x01000193) & 0xFFFFFFFF;
  }
  return 1000 + (h & 0x7FFFFFFF) % 2000000000;
}

final _dm = DateFormat('EEE, d MMM');

/// Works out every notification for the next [horizonDays], soonest first,
/// capped at [cap] (some phones refuse more than 500 alarms per app).
List<PlannedAlarm> planAlarms(
  PlanInput input, {
  required tz.TZDateTime now,
  required tz.Location local,
  int horizonDays = 366,
  int cap = 450,
}) {
  final out = <PlannedAlarm>[];
  final today = Day(now.year, now.month, now.day);
  final end = today.addDays(horizonDays);

  tz.TZDateTime at(Day d, int minute, [tz.Location? loc]) =>
      tz.TZDateTime(loc ?? local, d.year, d.month, d.day, minute ~/ 60, minute % 60);

  for (final e in input.entries) {
    if (e.isArchived) continue;
    final specs = (input.reminders[e.event.id] ?? const []).where((s) => s.enabled).toList();
    final sound = AlarmSound.parse(e.event.sound);
    final person = e.people.where((p) => !p.isMe).firstOrNull;
    final wishable = (e.kind == EventKind.person || e.kind == EventKind.couple) && !e.isMine && e.people.isNotEmpty;

    // Every occurrence in the window (monthly events have several).
    var from = today.addDays(-1);
    final dates = <Day>[];
    while (true) {
      final d = e.nextFrom(from);
      if (d == null || end < d) break;
      dates.add(d);
      from = d.addDays(1);
      if (dates.length > 14) break;
    }
    // Also look at a date that just passed, for the belated nudge.
    final prev = previousOccurrence(
      repeat: e.repeat,
      month: e.event.month,
      day: e.event.day,
      year: e.repeat == Repeat.once ? e.event.year : e.startYear,
      feb29: e.feb29,
      before: today,
    );

    for (final d in dates) {
      final u = Upcoming(e, d, today.daysUntil(d));
      final what = _what(e, u);
      for (final s in specs) {
        tz.TZDateTime when;
        String title, body;
        var full = false;
        switch (s.kind) {
          case ReminderKind.midnight:
            final useTheirs = e.event.alarmClock == 'theirs' && person?.timeZone != null;
            final loc = useTheirs ? _loc(person!.timeZone!) ?? local : local;
            when = tz.TZDateTime.from(at(d, 0, loc).subtract(const Duration(seconds: 10)), local);
            title = _midnightTitle(e, u);
            body = useTheirs
                ? "It's midnight in ${person!.timeZone!.split('/').last.replaceAll('_', ' ')}. Be the first to wish!"
                : (wishable ? 'Be the first to wish!' : _dm.format(d.asDateTime));
            full = true;
          case ReminderKind.morning:
          case ReminderKind.custom:
            when = at(d, s.minute);
            title = 'Today: $what';
            body = [?u.yearsPhrase, if (wishable) 'Tap to call or send a wish' else e.event.notes ?? '']
                .where((x) => x.isNotEmpty)
                .join(' · ');
          case ReminderKind.daysBefore:
            if (s.daysBefore <= 0) continue;
            when = at(d.addDays(-s.daysBefore), s.minute);
            title = e.kind == EventKind.other
                ? '${e.title} in ${s.daysBefore} day${s.daysBefore == 1 ? '' : 's'}'
                : 'In ${s.daysBefore} day${s.daysBefore == 1 ? '' : 's'}: $what';
            body = [_dm.format(d.asDateTime), ?u.yearsPhrase, if (e.kind == EventKind.other) ?e.event.notes]
                .join(' · ');
          case ReminderKind.gift:
            if (s.daysBefore <= 0) continue;
            when = at(d.addDays(-s.daysBefore), s.minute);
            final gifts = person == null ? 0 : (input.giftCounts[person.id] ?? 0);
            title = 'Gift for ${e.title}';
            body = '${e.typeLabel} in ${s.daysBefore} days (${_dm.format(d.asDateTime)})'
                '${gifts > 0 ? ' · $gifts gift idea${gifts == 1 ? '' : 's'} saved' : ''}';
        }
        if (!when.isAfter(now)) continue;
        out.add(PlannedAlarm(
          id: stableId('${s.kind.name}|${e.event.id}|$d|${s.daysBefore}|${s.minute}'),
          when: when,
          kind: s.kind == ReminderKind.midnight ? 'mid' : 'rem',
          title: title,
          body: body,
          sound: sound,
          eventId: e.event.id,
          date: d,
          fullScreen: full,
          wishActions: wishable,
        ));
      }
    }

    // Belated nudge: the morning after, unless marked as wished.
    if (wishable && e.event.belatedNudge) {
      for (final d in [?prev, ...dates]) {
        if (input.wished.contains('${e.event.id}|$d')) continue;
        final when = at(d.addDays(1), input.belatedMinute);
        if (!when.isAfter(now)) continue;
        out.add(PlannedAlarm(
          id: stableId('bel|${e.event.id}|$d'),
          when: when,
          kind: 'bel',
          title: 'You missed ${e.title}\'s ${e.typeLabel.toLowerCase()} yesterday',
          body: 'A belated wish is ready. Tap to call or send it.',
          sound: AlarmSound.softBell,
          eventId: e.event.id,
          date: d,
          wishActions: true,
        ));
        break; // only the next one
      }
    }
  }

  // Monthly summary on the 1st at 9 AM.
  if (input.monthlySummary) {
    for (var i = 0; i <= 12; i++) {
      final first = Day(today.year + (today.month - 1 + i) ~/ 12, (today.month - 1 + i) % 12 + 1, 1);
      final when = at(first, 540);
      if (!when.isAfter(now)) continue;
      final lastDay = Day(first.year, first.month, daysInMonth(first.year, first.month));
      final inMonth = computeUpcoming(input.entries, first).where((u) => !(lastDay < u.date)).toList();
      if (inMonth.isEmpty) continue;
      final month = DateFormat('MMMM').format(first.asDateTime);
      out.add(PlannedAlarm(
        id: stableId('month|$first'),
        when: when,
        kind: 'month',
        title: '$month: ${inMonth.length} date${inMonth.length == 1 ? '' : 's'} to remember',
        body: inMonth.take(8).map((u) => '${u.entry.title} ${ordinal(u.date.day)}').join(', ') +
            (inMonth.length > 8 ? ' and more' : ''),
        sound: AlarmSound.softBell,
        date: first,
      ));
    }
  }

  out.addAll(input.extra.where((a) => a.when.isAfter(now)));
  out.sort((a, b) => a.when.compareTo(b.when));
  return out.length > cap ? out.sublist(0, cap) : out;
}

tz.Location? _loc(String name) {
  try {
    return tz.getLocation(name);
  } catch (_) {
    return null;
  }
}

String _what(EventEntry e, Upcoming u) {
  if (e.kind == EventKind.other) return e.title;
  if (e.isMine) return 'Your ${e.typeLabel.toLowerCase()}';
  return "${e.title}'s ${e.typeLabel.toLowerCase()}";
}

String _midnightTitle(EventEntry e, Upcoming u) {
  if (e.kind == EventKind.other) return e.title;
  if (e.type == EventType.birthday && u.years != null && !e.isMine) return '🎂 ${e.title} turns ${u.years}';
  if (e.type == EventType.birthday) return e.isMine ? '🎂 Happy birthday to you!' : "🎂 ${e.title}'s birthday";
  return '💐 ${e.title} · ${u.yearsPhrase ?? e.typeLabel}';
}
