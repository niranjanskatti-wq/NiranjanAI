import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/theme/tokens.dart';
import '../../core/util/format.dart';
import '../../core/util/occurrence.dart';
import '../../data/providers.dart';
import '../../widgets/common.dart';

/// Which Saturdays are off. Banks close on the 2nd and 4th.
enum SaturdayRule {
  secondFourth('2nd & 4th Saturdays', 'Banks (RBI rule)'),
  second('2nd Saturday only', ''),
  all('Every Saturday', '5-day week'),
  none('No Saturdays', '');

  const SaturdayRule(this.label, this.help);
  final String label, help;
}

class BizHoliday {
  const BizHoliday(this.day, this.name, {this.approx = false, this.mine = false});
  final Day day;
  final String name;

  /// The date depends on the moon sighting and can move by a day.
  final bool approx;

  /// Added or renamed by you.
  final bool mine;
}

/// A run of days off in a row.
class DaysOff {
  const DaysOff(this.from, this.to, {this.leave});
  final Day from, to;

  /// The working day to take off to join two breaks (null when no leave is needed).
  final Day? leave;

  int get length => from.daysUntil(to) + 1;
}

/// Karnataka bank holidays, Sundays and the chosen Saturdays.
class BusinessCalendar {
  BusinessCalendar(List<BizHoliday> listed, {this.saturdays = SaturdayRule.secondFourth})
      : _byDay = {for (final h in listed) h.day: h};

  final Map<Day, BizHoliday> _byDay;
  final SaturdayRule saturdays;

  /// [asset]: assets/holidays/karnataka_bank.json. [edits]: date → name you gave it,
  /// or '' for a listed holiday you removed.
  static BusinessCalendar build(String asset, Map<String, String> edits, SaturdayRule saturdays) {
    final out = <Day, BizHoliday>{};
    final data = jsonDecode(asset) as Map<String, dynamic>;
    for (final h in (data['holidays'] as List).cast<Map<String, dynamic>>()) {
      final d = parseDay(h['date'] as String);
      final prev = out[d];
      final name = h['name'] as String;
      out[d] = BizHoliday(d, prev == null ? name : '${prev.name} · $name', approx: h['approx'] == true);
    }
    for (final e in edits.entries) {
      final d = parseDay(e.key);
      if (e.value.isEmpty) {
        out.remove(d);
      } else {
        out[d] = BizHoliday(d, e.value, mine: true);
      }
    }
    return BusinessCalendar(out.values.toList(), saturdays: saturdays);
  }

  static Day parseDay(String s) {
    final p = s.split('-').map(int.parse).toList();
    return Day(p[0], p[1], p[2]);
  }

  BizHoliday? holiday(Day d) => _byDay[d];

  /// "2nd Saturday", "4th Saturday" or null.
  String? offSaturday(Day d) {
    if (d.asDateTime.weekday != DateTime.saturday) return null;
    final n = (d.day - 1) ~/ 7 + 1;
    final off = switch (saturdays) {
      SaturdayRule.secondFourth => n == 2 || n == 4,
      SaturdayRule.second => n == 2,
      SaturdayRule.all => true,
      SaturdayRule.none => false,
    };
    if (!off) return null;
    return switch (n) { 1 => '1st Saturday', 2 => '2nd Saturday', 3 => '3rd Saturday', 4 => '4th Saturday', _ => '5th Saturday' };
  }

  bool isSunday(Day d) => d.asDateTime.weekday == DateTime.sunday;

  bool isOff(Day d) => _byDay.containsKey(d) || isSunday(d) || offSaturday(d) != null;

  /// Why the day is off, or null on a working day.
  String? reason(Day d) =>
      [?_byDay[d]?.name, if (isSunday(d)) 'Sunday', ?offSaturday(d)].join(' · ').ifEmptyNull;

  /// Listed holidays from [from] on (not plain Sundays or Saturdays).
  List<BizHoliday> upcoming(Day from, {int count = 12}) =>
      (_byDay.values.where((h) => h.day >= from).toList()..sort((a, b) => a.day.compareTo(b.day)))
          .take(count)
          .toList();

  /// Breaks of three or more days off in a row starting before [until], and
  /// the ones you could make by taking a single day of leave.
  List<DaysOff> breaks(Day from, Day until) {
    final runs = <DaysOff>[];
    var d = from;
    // Start at the beginning of a run already going on.
    while (isOff(d.addDays(-1)) && from.daysUntil(d) > -10) {
      d = d.addDays(-1);
    }
    Day? start;
    for (; !(until < d) || start != null; d = d.addDays(1)) {
      if (isOff(d)) {
        start ??= d;
      } else if (start != null) {
        runs.add(DaysOff(start, d.addDays(-1)));
        start = null;
      }
    }
    final out = <DaysOff>[];
    for (var i = 0; i < runs.length; i++) {
      final r = runs[i];
      if (r.length >= 3) out.add(r);
      if (i + 1 < runs.length) {
        final next = runs[i + 1];
        final gap = r.to.addDays(1);
        if (gap.addDays(1) == next.from && r.length + next.length + 1 >= 4) {
          out.add(DaysOff(r.from, next.to, leave: gap));
        }
      }
    }
    return out.where((b) => b.to >= from).toList();
  }
}

extension on String {
  String? get ifEmptyNull => isEmpty ? null : this;
}

final _assetProvider = FutureProvider<String>((ref) => rootBundle.loadString('assets/holidays/karnataka_bank.json'));

final saturdayRuleProvider = StreamProvider<SaturdayRule>((ref) => ref
    .watch(databaseProvider)
    .watchSetting('bizSaturdays')
    .map((v) => SaturdayRule.values.asNameMap()[v] ?? SaturdayRule.secondFourth));

final _editsProvider = StreamProvider<Map<String, String>>((ref) => ref
    .watch(databaseProvider)
    .watchSetting('bizEdits')
    .map((v) => v == null ? <String, String>{} : (jsonDecode(v) as Map<String, dynamic>).cast<String, String>()));

final businessCalendarProvider = Provider<BusinessCalendar?>((ref) {
  final asset = ref.watch(_assetProvider).value;
  if (asset == null) return null;
  return BusinessCalendar.build(asset, ref.watch(_editsProvider).value ?? const {},
      ref.watch(saturdayRuleProvider).value ?? SaturdayRule.secondFourth);
});

const _red = Color(0xFFE5484D);

/// Business calendar: Karnataka bank holidays, Sundays and bank Saturdays in
/// red, upcoming holidays and long weekends for planning trips.
class BusinessCalendarScreen extends ConsumerStatefulWidget {
  const BusinessCalendarScreen({super.key});

  @override
  ConsumerState<BusinessCalendarScreen> createState() => _BusinessCalendarScreenState();
}

class _BusinessCalendarScreenState extends ConsumerState<BusinessCalendarScreen> {
  late DateTime _month = DateTime(DateTime.now().year, DateTime.now().month);
  Day? _selected;

  Future<void> _edit(Day d, String? name) async {
    final db = ref.read(databaseProvider);
    final edits = {...ref.read(_editsProvider).value ?? const <String, String>{}};
    if (name == null) {
      edits.remove('$d');
    } else {
      edits['$d'] = name;
    }
    await db.setSetting('bizEdits', jsonEncode(edits));
  }

  Future<void> _dayMenu(Day d, BusinessCalendar cal) async {
    final h = cal.holiday(d);
    final edits = ref.read(_editsProvider).value ?? const <String, String>{};
    final choice = await showModalBottomSheet<String>(
      context: context,
      useRootNavigator: true,
      builder: (ctx) => SafeArea(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          ListTile(title: Text(fmtFull(d), style: ctx.text.titleLarge), subtitle: Text(cal.reason(d) ?? 'Working day')),
          ListTile(
            leading: const Icon(Icons.event_busy_rounded, color: _red),
            title: Text(h == null ? 'Mark as holiday' : 'Rename holiday'),
            onTap: () => Navigator.pop(ctx, 'name'),
          ),
          if (h != null)
            ListTile(
              leading: const Icon(Icons.work_outline_rounded),
              title: const Text('Not a holiday (banks open)'),
              onTap: () => Navigator.pop(ctx, 'remove'),
            ),
          if (edits.containsKey('$d'))
            ListTile(
              leading: const Icon(Icons.undo_rounded),
              title: const Text('Undo my change'),
              onTap: () => Navigator.pop(ctx, 'reset'),
            ),
          const SizedBox(height: 8),
        ]),
      ),
    );
    if (!mounted || choice == null) return;
    switch (choice) {
      case 'remove':
        await _edit(d, '');
      case 'reset':
        await _edit(d, null);
      case 'name':
        final ctrl = TextEditingController(text: h?.name ?? '');
        final name = await showDialog<String>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: Text(fmtWeekday(d)),
            content: TextField(
              controller: ctrl,
              autofocus: true,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(labelText: 'Holiday name', hintText: 'e.g. Office closed'),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
              FilledButton(onPressed: () => Navigator.pop(ctx, ctrl.text.trim()), child: const Text('Save')),
            ],
          ),
        );
        if (name != null) await _edit(d, name.isEmpty ? 'Holiday' : name);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final cal = ref.watch(businessCalendarProvider);
    final today = ref.watch(todayProvider).value ?? Day.today();
    final rule = ref.watch(saturdayRuleProvider).value ?? SaturdayRule.secondFourth;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Business calendar'),
        actions: [
          PopupMenuButton<SaturdayRule>(
            tooltip: 'Saturdays off',
            icon: const Icon(Icons.tune_rounded),
            onSelected: (r) => ref.read(databaseProvider).setSetting('bizSaturdays', r.name),
            itemBuilder: (_) => [
              for (final r in SaturdayRule.values)
                CheckedPopupMenuItem(
                  value: r,
                  checked: r == rule,
                  child: Text(r.help.isEmpty ? r.label : '${r.label} · ${r.help}'),
                ),
            ],
          ),
        ],
      ),
      body: cal == null
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 40),
              children: [
                Text('Karnataka bank holidays · Sundays · ${rule.label}',
                    style: context.text.bodySmall?.copyWith(color: c.muted)),
                const SizedBox(height: 4),
                _monthGrid(context, cal, today),
                const SizedBox(height: 8),
                Wrap(spacing: 14, runSpacing: 4, children: [
                  _legend(context, _red, 'Holiday / Sunday / bank Saturday'),
                  _legend(context, c.gold, 'Today'),
                ]),
                if (_selected != null) ...[
                  const SizedBox(height: 12),
                  Card(
                    child: ListTile(
                      title: Text(fmtFull(_selected!)),
                      subtitle: Text(cal.reason(_selected!) ?? 'Working day · banks open'),
                      trailing: TextButton(onPressed: () => _dayMenu(_selected!, cal), child: const Text('Change')),
                    ),
                  ),
                ],
                const SizedBox(height: 20),
                const SectionLabel('Upcoming bank holidays'),
                for (final h in cal.upcoming(today)) _holidayRow(context, cal, h, today),
                const SizedBox(height: 20),
                const SectionLabel('Long weekends & trip planning'),
                Text('Three or more days off in a row in the next 6 months, and where one day of leave makes a longer break.',
                    style: context.text.bodySmall?.copyWith(color: c.muted)),
                const SizedBox(height: 8),
                for (final b in cal.breaks(today, today.addDays(183))) _breakRow(context, cal, b, today),
                const SizedBox(height: 16),
                Text(
                  'Dates come from the Karnataka bank holiday list, worked out for each year. Moon-based dates '
                  '(marked ~) can move by a day when the government announces them. Tap any date to mark, rename '
                  'or remove a holiday.',
                  style: context.text.bodySmall?.copyWith(color: c.muted),
                ),
              ],
            ),
    );
  }

  Widget _legend(BuildContext context, Color color, String text) => Row(mainAxisSize: MainAxisSize.min, children: [
        Container(width: 10, height: 10, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 6),
        Text(text, style: context.text.bodySmall),
      ]);

  Widget _monthGrid(BuildContext context, BusinessCalendar cal, Day today) {
    final c = context.c;
    final daysCount = daysInMonth(_month.year, _month.month);
    final leading = (DateTime(_month.year, _month.month, 1).weekday + 6) % 7;
    final offCount = [
      for (var i = 1; i <= daysCount; i++)
        if (cal.isOff(Day(_month.year, _month.month, i))) i,
    ].length;
    return Column(children: [
      Row(children: [
        IconButton(
          tooltip: 'Previous month',
          onPressed: () => setState(() => _month = DateTime(_month.year, _month.month - 1)),
          icon: const Icon(Icons.chevron_left_rounded),
        ),
        Expanded(
          child: Column(children: [
            Text(fmtMonthYear(_month), textAlign: TextAlign.center, style: context.text.headlineMedium),
            Text('$offCount days off · ${daysCount - offCount} working days',
                style: context.text.bodySmall?.copyWith(color: c.muted)),
          ]),
        ),
        IconButton(
          tooltip: 'Next month',
          onPressed: () => setState(() => _month = DateTime(_month.year, _month.month + 1)),
          icon: const Icon(Icons.chevron_right_rounded),
        ),
      ]),
      const SizedBox(height: 8),
      Row(children: [
        for (final (i, d) in const ['M', 'T', 'W', 'T', 'F', 'S', 'S'].indexed)
          Expanded(
            child: Text(d,
                textAlign: TextAlign.center,
                style: context.text.labelSmall?.copyWith(color: i == 6 ? _red : null)),
          ),
      ]),
      const SizedBox(height: 6),
      GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 7, childAspectRatio: 0.9),
        itemCount: leading + daysCount,
        itemBuilder: (_, i) {
          if (i < leading) return const SizedBox.shrink();
          final d = Day(_month.year, _month.month, i - leading + 1);
          final off = cal.isOff(d);
          final h = cal.holiday(d);
          final isToday = d == today;
          final isSel = d == _selected;
          return InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () => setState(() => _selected = isSel ? null : d),
            onLongPress: () => _dayMenu(d, cal),
            child: Container(
              margin: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                color: isSel
                    ? c.text
                    : h != null
                        ? _red.withValues(alpha: 0.22)
                        : (off ? _red.withValues(alpha: 0.08) : null),
                borderRadius: BorderRadius.circular(12),
                border: isToday && !isSel ? Border.all(color: c.gold, width: 2) : null,
              ),
              child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                Text('${d.day}',
                    style: context.text.titleSmall?.copyWith(
                      color: isSel ? c.bg : (off ? _red : c.text),
                      fontWeight: off || isToday ? FontWeight.w800 : FontWeight.w600,
                    )),
                if (h != null)
                  Container(
                    width: 6,
                    height: 6,
                    margin: const EdgeInsets.only(top: 4),
                    decoration: const BoxDecoration(color: _red, shape: BoxShape.circle),
                  ),
              ]),
            ),
          );
        },
      ),
    ]);
  }

  Widget _holidayRow(BuildContext context, BusinessCalendar cal, BizHoliday h, Day today) {
    final c = context.c;
    final days = today.daysUntil(h.day);
    final weekend = cal.isSunday(h.day) || cal.offSaturday(h.day) != null;
    return ListTile(
      contentPadding: EdgeInsets.zero,
      onTap: () => setState(() {
        _month = DateTime(h.day.year, h.day.month);
        _selected = h.day;
      }),
      leading: Container(
        width: 48,
        padding: const EdgeInsets.symmetric(vertical: 4),
        decoration: BoxDecoration(color: _red.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(10)),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Text('${h.day.day}', style: context.text.titleMedium?.copyWith(color: _red, fontWeight: FontWeight.w800)),
          Text(DateFormat.MMM().format(h.day.asDateTime), style: context.text.labelSmall?.copyWith(color: _red)),
        ]),
      ),
      title: Text('${h.name}${h.approx ? ' ~' : ''}'),
      subtitle: Text([
        fmtWeekday(h.day),
        if (weekend) 'already a weekend',
        if (h.mine) 'added by you',
      ].join(' · ')),
      trailing: Text(relativeDays(days),
          textAlign: TextAlign.end, style: context.text.bodySmall?.copyWith(color: days <= 7 ? _red : c.muted)),
    );
  }

  Widget _breakRow(BuildContext context, BusinessCalendar cal, DaysOff b, Day today) {
    final c = context.c;
    final names = {
      for (var d = b.from; !(b.to < d); d = d.addDays(1)) ?cal.holiday(d)?.name,
    }.join(', ');
    return Card(
      child: ListTile(
        onTap: () => setState(() {
          _month = DateTime(b.from.year, b.from.month);
          _selected = b.from;
        }),
        leading: CircleAvatar(
          backgroundColor: (b.leave == null ? _red : c.gold).withValues(alpha: 0.18),
          child: Text('${b.length}',
              style: TextStyle(color: b.leave == null ? _red : c.gold, fontWeight: FontWeight.w800)),
        ),
        title: Text('${fmtWeekday(b.from)} – ${fmtWeekday(b.to)}'),
        subtitle: Text([
          b.leave == null ? '${b.length} days off' : 'Take leave on ${fmtWeekday(b.leave!)} → ${b.length} days off',
          if (names.isNotEmpty) names,
          if (today.daysUntil(b.from) <= 0) 'on now' else 'starts ${relativeDays(today.daysUntil(b.from)).toLowerCase()}',
        ].join('\n')),
        isThreeLine: true,
      ),
    );
  }
}
