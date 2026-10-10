import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';

import '../../core/app_services.dart';
import '../../core/format.dart';
import '../../core/strings.dart';
import '../../core/theme.dart';
import '../../data/models.dart';
import '../../services/holiday_calendar.dart';
import '../widgets/bank_glance.dart';
import '../widgets/common.dart';
import '../widgets/fields.dart';
import 'alert_settings_screen.dart';
import 'reminder_form_screen.dart';

const holidayRed = Color(0xFFEF6C6C);

/// Bank holiday calendar: closed days, upcoming closures and the editable
/// holiday list. Shown next to the visit log.
class HolidaysView extends StatefulWidget {
  const HolidaysView({super.key});
  @override
  State<HolidaysView> createState() => _HolidaysViewState();
}

class _HolidaysViewState extends State<HolidaysView> {
  DateTime _focused = DateTime.now();
  DateTime _selected = Fmt.dateOnly(DateTime.now());
  CalendarFormat _format = CalendarFormat.month;

  Future<(HolidayCalendar, List<Holiday>, Prefs)> _load() async {
    final repo = AppServices.I.repo;
    return (await HolidayCalendar.load(repo), await repo.holidays(), await repo.prefs());
  }

  @override
  Widget build(BuildContext context) {
    return DataBuilder<(HolidayCalendar, List<Holiday>, Prefs)>(
      load: _load,
      builder: (context, d) {
        final (cal, all, prefs) = d;
        final today = Fmt.dateOnly(DateTime.now());
        final upcoming = BankGlance.coming(cal, prefs, today, max: 100);
        final named = cal.namedOn(_selected);
        final weekend = cal.weekendOn(_selected);
        final selectedHolidays = all.where((h) => h.fallsOn(_selected)).toList();

        return ListView(padding: const EdgeInsets.fromLTRB(12, 0, 12, 120), children: [
          GoldCard(
            padding: const EdgeInsets.fromLTRB(8, 4, 8, 12),
            child: TableCalendar<String>(
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
              onDaySelected: (sel, foc) => setState(() {
                _selected = Fmt.dateOnly(sel);
                _focused = foc;
              }),
              onDayLongPressed: (day, foc) => Navigator.push(
                  context, MaterialPageRoute(builder: (_) => ReminderFormScreen(kind: 'custom', date: Fmt.dateOnly(day)))),
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
                weekendTextStyle: const TextStyle(fontSize: 16, color: GV.text),
                todayDecoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: GV.gold, width: 1.5)),
                todayTextStyle: const TextStyle(fontSize: 16, color: GV.gold, fontWeight: FontWeight.w800),
                selectedDecoration: const BoxDecoration(shape: BoxShape.circle, gradient: GV.goldGradient),
                selectedTextStyle: const TextStyle(fontSize: 16, color: Color(0xFF1A1405), fontWeight: FontWeight.w800),
              ),
              calendarBuilders: CalendarBuilders<String>(
                defaultBuilder: (c, day, focused) => _day(cal, day),
                todayBuilder: (c, day, focused) => _day(cal, day, today: true),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 12, 8, 0),
            child: Wrap(spacing: 16, runSpacing: 6, children: [
              _legend(const BoxDecoration(color: holidayRed, shape: BoxShape.circle), context.t('hol.legendHoliday')),
              _legend(BoxDecoration(shape: BoxShape.circle, color: holidayRed.withValues(alpha: 0.45)), context.t('hol.legendWeekend')),
            ]),
          ),
          SectionTitle(Fmt.date(_selected)),
          GoldCard(
            child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              if (named.isEmpty && weekend == null)
                Text(context.t('hol.open'), style: const TextStyle(color: GV.ok, fontSize: 16))
              else ...[
                Text(context.t('hol.closed'), style: const TextStyle(color: holidayRed, fontSize: 17, fontWeight: FontWeight.w800)),
                for (final n in named) Text('• $n', style: const TextStyle(fontSize: 16)),
                if (weekend != null) Text('• ${context.t('hol.$weekend')}', style: const TextStyle(fontSize: 16)),
              ],
              for (final h in selectedHolidays.where((h) => !h.enabled))
                Text('• ${h.name} (${context.t('hol.off')})', style: const TextStyle(color: GV.muted)),
              const SizedBox(height: 12),
              Wrap(spacing: 10, runSpacing: 10, children: [
                FilledButton.icon(
                  icon: const Icon(Icons.alarm_add),
                  label: Text(context.t('cal.addAlarm')),
                  onPressed: () => Navigator.push(
                      context, MaterialPageRoute(builder: (_) => ReminderFormScreen(kind: 'custom', date: _selected))),
                ),
                OutlinedButton.icon(
                  icon: const Icon(Icons.add),
                  label: Text(context.t('hol.addHere')),
                  onPressed: () => editHoliday(context, date: _selected),
                ),
                for (final h in selectedHolidays)
                  OutlinedButton.icon(
                    icon: const Icon(Icons.edit_outlined),
                    label: Text(h.name),
                    onPressed: () => editHoliday(context, existing: h),
                  ),
              ]),
            ]),
          ),
          SectionTitle(context.t('hol.upcoming'),
              trailing: IconButton(
                tooltip: context.t('alerts.title'),
                icon: const Icon(Icons.tune, color: GV.gold),
                onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AlertSettingsScreen())),
              )),
          if (!prefs.holidayAlerts || !prefs.notifications)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Text(context.t('hol.alertsOff'), style: const TextStyle(color: GV.goldLight)),
            ),
          if (upcoming.isEmpty)
            Text(context.t('hol.noneUpcoming'), style: const TextStyle(color: GV.muted))
          else
            GoldCard(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Column(children: [
                for (final c in upcoming.take(10))
                  ListTile(
                    leading: const CircleAvatar(backgroundColor: Color(0x33EF6C6C), child: Icon(Icons.beach_access, color: holidayRed)),
                    title: Text(c.label((w) => context.t('hol.$w'))),
                    subtitle: Text([
                      c.days > 1 ? '${Fmt.date(c.start)} – ${Fmt.date(c.end)}' : Fmt.date(c.start),
                      context.t('hol.closedDays', {'n': c.days}),
                      if (prefs.holidayAlerts && prefs.notifications)
                        context.t('hol.alertOn', {'date': Fmt.date(c.start.subtract(Duration(days: prefs.holidayLeadDays)))}),
                    ].join(' · ')),
                    trailing: IconButton(
                      tooltip: context.t('hol.remindTake'),
                      icon: const Icon(Icons.alarm_add, color: GV.gold),
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ReminderFormScreen(
                            kind: 'take',
                            date: _lastOpenDayBefore(cal, c.start),
                          ),
                        ),
                      ),
                    ),
                  ),
              ]),
            ),
          SectionTitle(context.t('hol.list'),
              trailing: IconButton(
                icon: const Icon(Icons.add_circle_outline, color: GV.gold, size: 28),
                onPressed: () => editHoliday(context, date: _selected),
              )),
          Padding(
            padding: const EdgeInsets.only(bottom: 10, left: 4, right: 4),
            child: Text(context.t('hol.listHelp'), style: const TextStyle(color: GV.muted, fontSize: 14)),
          ),
          GoldCard(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Column(children: [
              for (final h in all)
                ListTile(
                  title: Text(h.name, style: TextStyle(color: h.enabled ? GV.text : GV.muted)),
                  subtitle: Text(h.yearly
                      ? '${_md(h.md!)} · ${context.t('hol.everyYear')}'
                      : Fmt.date(Fmt.parse(h.date))),
                  onTap: () => editHoliday(context, existing: h),
                  trailing: Switch(
                    value: h.enabled,
                    onChanged: (v) => AppServices.I.repo.saveHoliday(Holiday(id: h.id, name: h.name, date: h.date, md: h.md, enabled: v)),
                  ),
                ),
            ]),
          ),
        ]);
      },
    );
  }

  static String _md(String md) {
    final p = md.split('-');
    return Fmt.date(DateTime(2000, int.parse(p[0]), int.parse(p[1]))).replaceAll(' 2000', '');
  }

  /// The last working day before a closure (default date for "take out" alarms).
  static DateTime _lastOpenDayBefore(HolidayCalendar cal, DateTime start) {
    var d = start.subtract(const Duration(days: 1));
    for (var i = 0; i < 10 && cal.isClosed(d); i++) {
      d = d.subtract(const Duration(days: 1));
    }
    return d;
  }

  Widget _legend(BoxDecoration dec, String text) => Row(mainAxisSize: MainAxisSize.min, children: [
        Container(width: 12, height: 12, decoration: dec),
        const SizedBox(width: 6),
        Text(text, style: const TextStyle(fontSize: 13.5, color: GV.muted)),
      ]);

  Widget? _day(HolidayCalendar cal, DateTime day, {bool today = false}) {
    final named = cal.namedOn(day).isNotEmpty;
    final weekend = cal.weekendOn(day) != null;
    if (!named && !weekend) return null;
    return Center(
      child: Container(
        width: 38,
        height: 38,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          // Festival holidays: solid red. Sundays / 2nd & 4th Saturdays: lighter red.
          color: named ? holidayRed : holidayRed.withValues(alpha: 0.45),
          border: today ? Border.all(color: GV.gold, width: 2) : null,
        ),
        child: Text('${day.day}',
            style: TextStyle(
              fontSize: 16,
              fontWeight: today || named ? FontWeight.w800 : FontWeight.w600,
              color: Colors.white,
            )),
      ),
    );
  }
}

/// Add / edit / delete a bank holiday.
Future<void> editHoliday(BuildContext context, {Holiday? existing, DateTime? date}) async {
  final name = TextEditingController(text: existing?.name ?? '');
  var day = existing?.date ?? (date == null ? Fmt.isoDate(DateTime.now()) : Fmt.isoDate(date));
  if (existing?.md != null) {
    final p = existing!.md!.split('-');
    day = Fmt.isoDate(DateTime(DateTime.now().year, int.parse(p[0]), int.parse(p[1])));
  }
  var yearly = existing?.yearly ?? false;
  var enabled = existing?.enabled ?? true;
  final r = await showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    builder: (c) => StatefulBuilder(
      builder: (c, set) => Padding(
        padding: EdgeInsets.fromLTRB(20, 0, 20, 24 + MediaQuery.of(c).viewInsets.bottom),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Text(existing == null ? context.t('hol.add') : context.t('hol.edit'), style: Theme.of(c).textTheme.titleLarge),
          gap,
          TextIn(name, context.t('hol.name'), hint: context.t('hol.nameHint'), autofocus: existing == null),
          gap,
          DateIn(label: context.t('common.date'), value: day, allowClear: false, onChanged: (v) => set(() => day = v!)),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(context.t('hol.everyYear')),
            subtitle: Text(context.t('hol.everyYearSub')),
            value: yearly,
            onChanged: (v) => set(() => yearly = v),
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(context.t('hol.on')),
            value: enabled,
            onChanged: (v) => set(() => enabled = v),
          ),
          const SizedBox(height: 12),
          FilledButton(onPressed: () => Navigator.pop(c, 'save'), child: Text(context.t('common.save'))),
          if (existing != null) ...[
            const SizedBox(height: 8),
            TextButton(
              style: TextButton.styleFrom(foregroundColor: GV.danger),
              onPressed: () => Navigator.pop(c, 'delete'),
              child: Text(context.t('hol.delete')),
            ),
          ],
        ]),
      ),
    ),
  );
  final repo = AppServices.I.repo;
  if (r == 'delete' && existing != null) {
    await repo.deleteHoliday(existing.id!);
  } else if (r == 'save') {
    if (name.text.trim().isEmpty) return;
    final d = DateTime.parse(day);
    await repo.saveHoliday(Holiday(
      id: existing?.id,
      name: name.text.trim(),
      date: yearly ? null : day,
      md: yearly ? '${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}' : null,
      enabled: enabled,
    ));
  }
}
