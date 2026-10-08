import 'package:flutter/material.dart';

import '../../core/app_services.dart';
import '../../core/format.dart';
import '../../core/strings.dart';
import '../../core/theme.dart';
import '../../data/models.dart';
import '../../data/repository.dart';
import '../../services/reminder_engine.dart';
import '../widgets/common.dart';
import '../widgets/fields.dart';
import 'item_form_screen.dart';
import 'cloud_screen.dart';
import 'lock_screen.dart';
import 'out_now_screen.dart';
import 'reminder_form_screen.dart';
import 'reminders_screen.dart';
import 'where_is_screen.dart';
import '../widgets/tiles.dart';

class _Dash {
  final Totals all;
  final Map<String, Totals> byLocation;
  final Map<String, Color> locColors;
  final Map<String, Totals> byOwner;
  final Map<String, Totals> byCategory;
  final Rates rates;
  final List<Movement> recent;
  final List<DueItem> due;
  final Prefs prefs;
  final DateTime? lastBackup;
  _Dash(this.all, this.byLocation, this.locColors, this.byOwner, this.byCategory, this.rates, this.recent, this.due, this.prefs, this.lastBackup);
}

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key, required this.onOpenTab});
  final ValueChanged<int> onOpenTab;
  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _breakdown = 0;

  Future<_Dash> _load() async {
    final repo = AppServices.I.repo;
    final rates = await repo.valueRates();
    final items = (await repo.items(const ItemQuery())).where((i) => i.isActive).toList();
    final locs = await repo.locationMap();
    final all = Totals();
    final byLoc = <String, Totals>{};
    final colors = <String, Color>{};
    final byOwner = <String, Totals>{};
    final byCat = <String, Totals>{};
    for (final i in items) {
      all.add(i, rates);
      String locKey;
      if (i.locationId == null) {
        locKey = '~${i.status}';
      } else {
        final l = locs[i.locationId]!;
        final top = l.parentId == null ? l : (locs[l.parentId] ?? l);
        locKey = top.name;
        colors[locKey] = Color(top.color);
      }
      byLoc.putIfAbsent(locKey, Totals.new).add(i, rates);
      byOwner.putIfAbsent(i.owner ?? '', Totals.new).add(i, rates);
      byCat.putIfAbsent(i.category, Totals.new).add(i, rates);
    }
    return _Dash(all, byLoc, colors, byOwner, byCat, rates, await repo.recentMovements(limit: 8),
        await AppServices.I.reminders.listed(horizonDays: 60), await repo.prefs(),
        Fmt.parse(await repo.getSetting('last_backup')));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: AddOrnamentFab(onPressed: () => showAddOrnamentSheet(context)),
      body: DataBuilder<_Dash>(
        load: _load,
        builder: (context, d) => CustomScrollView(slivers: [
          SliverAppBar(
            pinned: true,
            expandedHeight: 110,
            backgroundColor: GV.bg,
            flexibleSpace: FlexibleSpaceBar(
              titlePadding: const EdgeInsetsDirectional.only(start: 20, bottom: 14),
              title: Row(mainAxisSize: MainAxisSize.min, children: [
                const Logo(size: 30),
                const SizedBox(width: 10),
                Text('GoldVault', style: Theme.of(context).appBarTheme.titleTextStyle),
              ]),
            ),
            actions: [
              IconButton(
                iconSize: 28,
                tooltip: context.t('dash.addAlarm'),
                icon: const Icon(Icons.alarm_add),
                onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ReminderFormScreen(kind: 'custom'))),
              ),
              IconButton(
                iconSize: 28,
                tooltip: context.t('rem.title'),
                icon: Badge(
                  isLabelVisible: d.due.any((e) => !e.date.isAfter(DateTime.now())),
                  child: const Icon(Icons.notifications_outlined),
                ),
                onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const RemindersScreen())),
              ),
              const SizedBox(width: 8),
            ],
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 120),
            sliver: SliverList.list(children: [
              if (d.prefs.backupNudge && d.all.items > 0 &&
                  (d.lastBackup == null || DateTime.now().difference(d.lastBackup!).inDays >= 7)) ...[
                GoldCard(
                  accent: GV.goldLight,
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CloudScreen())),
                  child: Row(children: [
                    const Icon(Icons.add_to_drive, color: GV.goldLight, size: 30),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(context.t('fbk.nudge'), style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
                        Text(
                          d.lastBackup == null ? context.t('backup.never') : context.t('backup.last', {'date': Fmt.date(d.lastBackup)}),
                          style: const TextStyle(color: GV.muted),
                        ),
                      ]),
                    ),
                    const Icon(Icons.chevron_right, color: GV.gold),
                  ]),
                ),
                const SizedBox(height: 12),
              ],
              FadeIn(child: _whereIs(context)),
              const SizedBox(height: 12),
              FadeIn(
                child: GoldCard(
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ReminderFormScreen(kind: 'custom'))),
                  child: Row(children: [
                    const Icon(Icons.alarm_add, color: GV.gold, size: 30),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(context.t('dash.setAlarm'), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                        const SizedBox(height: 2),
                        Text(context.t('dash.setAlarmSub'), style: const TextStyle(color: GV.muted, fontSize: 14)),
                      ]),
                    ),
                    const Icon(Icons.chevron_right, color: GV.gold),
                  ]),
                ),
              ),
              const SizedBox(height: 14),
              FadeIn(index: 1, child: _stats(context, d)),
              const SizedBox(height: 12),
              if (d.prefs.showValues) FadeIn(index: 2, child: _rates(context, d.rates)),
              if (d.prefs.dashBreakdown) ...[
                SectionTitle(context.t('dash.breakdown')),
                FadeIn(index: 3, child: _breakdownCard(context, d)),
              ],
              // Upcoming reminders / alarms – switch on or off right here.
              _toggleHeader(context, context.t('dash.upcoming'), 'dash_reminders', d.prefs.dashReminders,
                  extra: IconButton(
                    tooltip: context.t('dash.addAlarm'),
                    icon: const Icon(Icons.alarm_add, color: GV.gold, size: 28),
                    onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ReminderFormScreen(kind: 'custom'))),
                  )),
              if (d.prefs.dashReminders) ...[
                if (_reminders(d).isEmpty)
                  GoldCard(child: Text(context.t('dash.noReminders'), style: const TextStyle(color: GV.muted)))
                else
                  GoldCard(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Column(children: [
                      for (final r in _reminders(d).take(5)) DueTile(r),
                      TextButton(
                        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const RemindersScreen())),
                        child: Text(context.t('common.seeAll')),
                      ),
                    ]),
                  ),
              ],
              // Coming bank holidays – separate on/off.
              _toggleHeader(context, context.t('dash.holidays'), 'dash_holidays', d.prefs.dashHolidays),
              if (d.prefs.dashHolidays) ...[
                if (_holidays(d).isEmpty)
                  GoldCard(child: Text(context.t('hol.noneUpcoming'), style: const TextStyle(color: GV.muted)))
                else
                  GoldCard(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Column(children: [
                      for (final r in _holidays(d).take(4)) DueTile(r, onTap: () => widget.onOpenTab(3)),
                    ]),
                  ),
              ],
              if (d.prefs.dashRecent) ...[
              SectionTitle(context.t('dash.recent'),
                  trailing: TextButton(onPressed: () => widget.onOpenTab(3), child: Text(context.t('nav.visits')))),
              if (d.recent.isEmpty)
                GoldCard(child: Text(context.t('dash.noMoves'), style: const TextStyle(color: GV.muted)))
              else
                GoldCard(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Column(children: [for (final m in d.recent) MovementTile(m, showItem: true)]),
                ),
              ],
            ]),
          ),
        ]),
      ),
    );
  }

  static List<DueItem> _reminders(_Dash d) => d.due.where((x) => x.kind != DueKind.holiday).toList();
  static List<DueItem> _holidays(_Dash d) => d.due.where((x) => x.kind == DueKind.holiday).toList();

  /// Section title with its own on/off switch, so a hidden section can be
  /// turned back on straight from the home page.
  Widget _toggleHeader(BuildContext context, String title, String key, bool on, {Widget? extra}) => SectionTitle(
        title,
        trailing: Row(mainAxisSize: MainAxisSize.min, children: [
          if (on && extra != null) extra,
          Switch(value: on, onChanged: (v) => AppServices.I.repo.setPref(key, v)),
        ]),
      );

  Widget _whereIs(BuildContext context) => GoldCard(
        accent: GV.gold,
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const WhereIsScreen())),
        child: Row(children: [
          const Icon(Icons.travel_explore, color: GV.gold, size: 30),
          const SizedBox(width: 14),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(context.t('where.title'), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
              const SizedBox(height: 2),
              Text(context.t('where.hint'), style: const TextStyle(color: GV.muted, fontSize: 14)),
            ]),
          ),
          const Icon(Icons.chevron_right, color: GV.gold),
        ]),
      );

  Widget _stats(BuildContext context, _Dash d) {
    return Column(children: [
      Row(children: [
        Expanded(child: StatTile(label: context.t('dash.gold'), value: Fmt.grams(d.all.gold), icon: Icons.circle, color: GV.gold, sensitive: true)),
        const SizedBox(width: 12),
        Expanded(child: StatTile(label: context.t('dash.silver'), value: Fmt.grams(d.all.silver), icon: Icons.circle, color: GV.silver, sensitive: true)),
      ]),
      const SizedBox(height: 12),
      Row(children: [
        Expanded(
          child: StatTile(
            label: context.t('dash.items'),
            value: '${Fmt.number(d.all.items)}  ·  ${context.t('dash.pcs', {'n': Fmt.number(d.all.pieces)})}',
            icon: Icons.diamond_outlined,
            color: GV.goldLight,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: d.prefs.showValues
              ? StatTile(
                  label: context.t('dash.value'),
                  value: d.rates.isSet ? Fmt.rupees(d.all.value) : context.t('dash.setRates'),
                  icon: Icons.currency_rupee,
                  color: GV.ok,
                  sensitive: d.rates.isSet,
                )
              : StatTile(
                  label: context.t('dash.outNow'),
                  value: Fmt.number(d.byLocation.entries.where((e) => e.key.startsWith('~')).fold<int>(0, (n, e) => n + e.value.items)),
                  icon: Icons.directions_walk,
                  color: const Color(0xFF4FC3F7),
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const OutNowScreen())),
                ),
        ),
      ]),
    ]);
  }

  Widget _rates(BuildContext context, Rates r) => GoldCard(
        padding: const EdgeInsets.fromLTRB(18, 10, 8, 10),
        onTap: () => showRatesDialog(context),
        child: Row(children: [
          const Icon(Icons.trending_up, color: GV.gold),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              r.isSet
                  ? '${context.t('rates.gold24')} ${Fmt.rupees(r.gold24)}/g\n${context.t('rates.silver')} ${Fmt.rupees(r.silver)}/g'
                  : context.t('rates.notSet'),
              style: const TextStyle(fontSize: 15),
            ),
          ),
          TextButton(onPressed: () => showRatesDialog(context), child: Text(context.t('rates.update'))),
        ]),
      );

  Widget _breakdownCard(BuildContext context, _Dash d) {
    final data = switch (_breakdown) { 0 => d.byLocation, 1 => d.byOwner, _ => d.byCategory };
    final entries = data.entries.toList()..sort((a, b) => b.value.gold.compareTo(a.value.gold));
    final maxGold = entries.fold<double>(0, (m, e) => e.value.gold > m ? e.value.gold : m);
    String label(String k) {
      if (_breakdown == 0 && k.startsWith('~')) return context.s.status(k.substring(1));
      if (_breakdown == 1 && k.isEmpty) return context.t('dash.noOwner');
      if (_breakdown == 2) return context.s.opt(k);
      return k;
    }

    return GoldCard(
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        SegmentedButton<int>(
          showSelectedIcon: false,
          segments: [
            ButtonSegment(value: 0, label: Text(context.t('dash.byLocation'))),
            ButtonSegment(value: 1, label: Text(context.t('dash.byOwner'))),
            ButtonSegment(value: 2, label: Text(context.t('dash.byCategory'))),
          ],
          selected: {_breakdown},
          onSelectionChanged: (s) => setState(() => _breakdown = s.first),
        ),
        const SizedBox(height: 14),
        if (entries.isEmpty) Text(context.t('dash.empty'), style: const TextStyle(color: GV.muted)),
        for (final e in entries)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                if (_breakdown == 0) ...[Dot(d.locColors[e.key] ?? GV.muted), const SizedBox(width: 8)],
                Expanded(child: Text(label(e.key), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600))),
                Text(context.t('dash.itemsN', {'n': e.value.items}), style: const TextStyle(color: GV.muted)),
              ]),
              const SizedBox(height: 6),
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0, end: maxGold == 0 ? 0 : e.value.gold / maxGold),
                  duration: const Duration(milliseconds: 700),
                  curve: Curves.easeOutCubic,
                  builder: (_, v, _) => LinearProgressIndicator(value: v, minHeight: 8, color: GV.gold, backgroundColor: GV.surface2),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '${context.t('dash.goldShort')} ${Fmt.grams(e.value.gold)}   ·   ${context.t('dash.silverShort')} ${Fmt.grams(e.value.silver)}',
                style: const TextStyle(color: GV.muted, fontSize: 13.5),
              ),
            ]),
          ),
      ]),
    );
  }
}

Future<void> showRatesDialog(BuildContext context) async {
  final repo = AppServices.I.repo;
  final r = await repo.rates();
  if (!context.mounted) return;
  final g = TextEditingController(text: r.gold24 == 0 ? '' : Fmt.decimal(r.gold24));
  final s = TextEditingController(text: r.silver == 0 ? '' : Fmt.decimal(r.silver));
  final p = TextEditingController(text: r.platinum == 0 ? '' : Fmt.decimal(r.platinum));
  final ok = await showDialog<bool>(
    context: context,
    builder: (c) => AlertDialog(
      title: Text(context.t('rates.title')),
      content: SingleChildScrollView(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Text(context.t('rates.help'), style: const TextStyle(color: GV.muted)),
          gap,
          TextIn(g, context.t('rates.gold24'), number: true, suffix: '₹/g'),
          gap,
          TextIn(s, context.t('rates.silver'), number: true, suffix: '₹/g'),
          gap,
          TextIn(p, context.t('rates.platinum'), number: true, suffix: '₹/g'),
        ]),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(c, false), child: Text(context.t('common.cancel'))),
        FilledButton(onPressed: () => Navigator.pop(c, true), child: Text(context.t('common.save'))),
      ],
    ),
  );
  if (ok == true) {
    await repo.saveRates(Rates(
      gold24: Fmt.parseNum(g.text) ?? 0,
      silver: Fmt.parseNum(s.text) ?? 0,
      platinum: Fmt.parseNum(p.text) ?? 0,
    ));
  }
}
