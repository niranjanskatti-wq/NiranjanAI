import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';

import '../../core/app_services.dart';
import '../../core/format.dart';
import '../../core/strings.dart';
import '../../core/theme.dart';
import '../../data/models.dart';
import '../widgets/common.dart';
import '../widgets/tiles.dart';
import 'visit_detail_screen.dart';
import 'visit_form_screen.dart';

class _Ev {
  final Color color;
  final bool planned;
  const _Ev(this.color, this.planned);
}

class _Cal {
  final List<Visit> visits;
  final List<Reminder> planned;
  final Map<int, Location> locs;
  final Map<int, int> counts;
  _Cal(this.visits, this.planned, this.locs, this.counts);
}

class VisitsScreen extends StatefulWidget {
  const VisitsScreen({super.key});
  @override
  State<VisitsScreen> createState() => _VisitsScreenState();
}

class _VisitsScreenState extends State<VisitsScreen> {
  DateTime _focused = DateTime.now();
  DateTime _selected = Fmt.dateOnly(DateTime.now());
  CalendarFormat _format = CalendarFormat.month;

  Future<_Cal> _load() async {
    final repo = AppServices.I.repo;
    final planned = (await repo.reminders(includeDone: true)).where((r) => r.kind == 'planned_visit').toList();
    return _Cal(await repo.visits(), planned, await repo.locationMap(), await repo.visitItemCounts());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(context.t('visit.title'))),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: null,
        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => VisitFormScreen(date: _selected))),
        icon: const Icon(Icons.add, size: 28),
        label: Text(context.t('visit.log')),
      ),
      body: DataBuilder<_Cal>(
        load: _load,
        builder: (context, d) {
          final byDay = <DateTime, List<_Ev>>{};
          for (final v in d.visits) {
            byDay.putIfAbsent(Fmt.dateOnly(v.date), () => []).add(_Ev(Color(d.locs[v.locationId]?.color ?? 0xFF999999), false));
          }
          for (final r in d.planned.where((r) => !r.done)) {
            byDay.putIfAbsent(DateTime.parse(r.dueDate), () => []).add(_Ev(Color(d.locs[r.locationId]?.color ?? 0xFF999999), true));
          }
          final dayVisits = d.visits.where((v) => isSameDay(v.date, _selected)).toList()
            ..sort((a, b) => (a.timeIn ?? '').compareTo(b.timeIn ?? ''));
          final dayPlanned = d.planned.where((r) => isSameDay(DateTime.parse(r.dueDate), _selected) && !r.done).toList();
          final lockers = d.locs.values.where((l) => l.isLocker && !l.isClosed).toList();

          return ListView(padding: const EdgeInsets.fromLTRB(12, 0, 12, 120), children: [
            GoldCard(
              padding: const EdgeInsets.fromLTRB(8, 4, 8, 12),
              child: TableCalendar<_Ev>(
                locale: Localizations.localeOf(context).toLanguageTag(),
                firstDay: DateTime(2000),
                lastDay: DateTime(2100),
                focusedDay: _focused,
                calendarFormat: _format,
                availableCalendarFormats: {
                  CalendarFormat.month: context.t('visit.month'),
                  CalendarFormat.week: context.t('visit.week'),
                },
                startingDayOfWeek: StartingDayOfWeek.monday,
                rowHeight: 52,
                selectedDayPredicate: (day) => isSameDay(day, _selected),
                eventLoader: (day) => byDay[Fmt.dateOnly(day)] ?? const [],
                onDaySelected: (sel, foc) => setState(() {
                  _selected = Fmt.dateOnly(sel);
                  _focused = foc;
                }),
                onFormatChanged: (f) => setState(() => _format = f),
                onPageChanged: (f) => _focused = f,
                headerStyle: HeaderStyle(
                  titleTextStyle: const TextStyle(fontFamily: GV.display, fontSize: 20, color: GV.gold),
                  formatButtonTextStyle: const TextStyle(color: GV.gold, fontSize: 14),
                  formatButtonDecoration: BoxDecoration(border: Border.all(color: GV.goldDeep), borderRadius: BorderRadius.circular(12)),
                  leftChevronIcon: const Icon(Icons.chevron_left, color: GV.gold, size: 30),
                  rightChevronIcon: const Icon(Icons.chevron_right, color: GV.gold, size: 30),
                ),
                daysOfWeekStyle: const DaysOfWeekStyle(
                  weekdayStyle: TextStyle(color: GV.muted, fontSize: 13),
                  weekendStyle: TextStyle(color: GV.goldLight, fontSize: 13),
                ),
                calendarStyle: CalendarStyle(
                  outsideDaysVisible: false,
                  defaultTextStyle: const TextStyle(fontSize: 16, color: GV.text),
                  weekendTextStyle: const TextStyle(fontSize: 16, color: GV.goldLight),
                  todayDecoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: GV.gold, width: 1.5)),
                  todayTextStyle: const TextStyle(fontSize: 16, color: GV.gold, fontWeight: FontWeight.w800),
                  selectedDecoration: const BoxDecoration(shape: BoxShape.circle, gradient: GV.goldGradient),
                  selectedTextStyle: const TextStyle(fontSize: 16, color: Color(0xFF1A1405), fontWeight: FontWeight.w800),
                ),
                calendarBuilders: CalendarBuilders<_Ev>(
                  markerBuilder: (c, day, events) {
                    if (events.isEmpty) return null;
                    return Positioned(
                      bottom: 4,
                      child: Row(mainAxisSize: MainAxisSize.min, children: [
                        for (final e in events.take(4))
                          Container(
                            margin: const EdgeInsets.symmetric(horizontal: 1.5),
                            width: 7,
                            height: 7,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: e.planned ? Colors.transparent : e.color,
                              border: Border.all(color: e.color, width: 1.5),
                            ),
                          ),
                      ]),
                    );
                  },
                ),
              ),
            ),
            if (lockers.isNotEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 12, 8, 0),
                child: Wrap(spacing: 14, runSpacing: 6, children: [
                  for (final l in lockers)
                    Row(mainAxisSize: MainAxisSize.min, children: [Dot(Color(l.color), size: 10), const SizedBox(width: 6), Text(l.name, style: const TextStyle(fontSize: 13.5, color: GV.muted))]),
                  Row(mainAxisSize: MainAxisSize.min, children: [
                    Container(width: 10, height: 10, decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: GV.muted, width: 1.5))),
                    const SizedBox(width: 6),
                    Text(context.t('visit.plannedLegend'), style: const TextStyle(fontSize: 13.5, color: GV.muted)),
                  ]),
                ]),
              ),
            SectionTitle(Fmt.date(_selected)),
            if (dayVisits.isEmpty && dayPlanned.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Text(context.t('visit.none'), style: const TextStyle(color: GV.muted)),
              ),
            for (final r in dayPlanned)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: GoldCard(
                  accent: Color(d.locs[r.locationId]?.color ?? 0xFF999999),
                  child: Row(children: [
                    const Icon(Icons.event_available, color: GV.gold, size: 28),
                    const SizedBox(width: 12),
                    Expanded(child: Text('${context.t('rem.planned')}: ${r.title}', style: const TextStyle(fontSize: 16))),
                    TextButton(
                      onPressed: () => Navigator.push(context,
                          MaterialPageRoute(builder: (_) => VisitFormScreen(locationId: r.locationId, date: DateTime.parse(r.dueDate)))),
                      child: Text(context.t('visit.logNow')),
                    ),
                  ]),
                ),
              ),
            for (final v in dayVisits)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: GoldCard(
                  accent: Color(d.locs[v.locationId]?.color ?? 0xFF999999),
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => VisitDetailScreen(visitId: v.id!))),
                  child: Row(children: [
                    Dot(Color(d.locs[v.locationId]?.color ?? 0xFF999999), size: 14),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(d.locs[v.locationId]?.name ?? '', style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
                        Text('${Fmt.hhmm(v.timeIn)} – ${Fmt.hhmm(v.timeOut)}${v.visitors == null ? '' : ' · ${v.visitors}'}',
                            style: const TextStyle(color: GV.muted)),
                        if (v.purpose != null) Text(v.purpose!, style: const TextStyle(color: GV.muted)),
                      ]),
                    ),
                    Text(context.t('visit.itemsMoved', {'n': d.counts[v.id] ?? 0}), style: const TextStyle(color: GV.gold)),
                    const Icon(Icons.chevron_right, color: GV.gold),
                  ]),
                ),
              ),
            _DayMovements(day: _selected),
          ]);
        },
      ),
    );
  }
}

/// All item movements on a day (including those outside visits).
class _DayMovements extends StatelessWidget {
  const _DayMovements({required this.day});
  final DateTime day;
  @override
  Widget build(BuildContext context) {
    return DataBuilder<List<Movement>>(
      load: () => AppServices.I.repo.movementsOn(day),
      watch: day,
      builder: (c, moves) {
        final shown = moves.where((m) => m.action != 'create').toList();
        if (shown.isEmpty) return const SizedBox();
        return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          SectionTitle(context.t('visit.whatMoved')),
          GoldCard(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Column(children: [for (final m in shown) MovementTile(m, showItem: true)]),
          ),
        ]);
      },
    );
  }
}
