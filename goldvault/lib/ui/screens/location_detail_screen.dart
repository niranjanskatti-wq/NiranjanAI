import 'package:flutter/material.dart';

import '../../core/app_services.dart';
import '../../core/format.dart';
import '../../core/security.dart';
import '../../core/strings.dart';
import '../../core/theme.dart';
import '../../data/models.dart';
import '../../services/reminder_engine.dart';
import '../widgets/common.dart';
import '../widgets/tiles.dart';
import 'item_form_screen.dart';
import 'locker_form_screen.dart';
import 'visit_detail_screen.dart';
import 'visit_form_screen.dart';

class _LocDetail {
  final Location loc;
  final LockerInfo? info;
  final List<Location> subs;
  final List<Item> items;
  final Map<int, String> photos;
  final Map<int, Location> all;
  final List<Visit> visits;
  final Rates rates;
  _LocDetail(this.loc, this.info, this.subs, this.items, this.photos, this.all, this.visits, this.rates);
}

class LocationDetailScreen extends StatelessWidget {
  const LocationDetailScreen({super.key, required this.locationId});
  final int locationId;

  Future<_LocDetail?> _load() async {
    final repo = AppServices.I.repo;
    final l = await repo.location(locationId);
    if (l == null) return null;
    final all = await repo.locationMap();
    return _LocDetail(
      l,
      await repo.lockerInfo(locationId),
      all.values.where((x) => x.parentId == locationId && !x.isClosed).toList(),
      await repo.itemsAt(locationId, includeChildren: true),
      await repo.firstPhotos(),
      all,
      l.isLocker ? (await repo.visits(locationId: locationId)).take(10).toList() : const [],
      await repo.rates(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SecureScreen(
      child: DataBuilder<_LocDetail?>(
        load: _load,
        builder: (context, d) {
          if (d == null) return const Scaffold(body: SizedBox());
          final l = d.loc;
          final t = Totals();
          for (final i in d.items) {
            t.add(i, d.rates);
          }
          final color = Color(l.color);
          return Scaffold(
            appBar: AppBar(
              title: Text(l.name),
              actions: [
                if (l.isLocker && !l.isClosed)
                  IconButton(
                    iconSize: 28,
                    tooltip: context.t('common.edit'),
                    icon: const Icon(Icons.edit_outlined),
                    onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => LockerFormScreen(location: l, info: d.info))),
                  ),
                PopupMenuButton<String>(
                  color: GV.surface2,
                  onSelected: (v) => _menu(context, v, d),
                  itemBuilder: (c) => [
                    if (!l.isLocker) PopupMenuItem(value: 'rename', child: Text(context.t('loc.rename'))),
                    if (l.isLocker && !l.isClosed) PopupMenuItem(value: 'close', child: Text(context.t('loc.close'))),
                    if (l.isClosed) PopupMenuItem(value: 'reopen', child: Text(context.t('loc.reopen'))),
                    PopupMenuItem(value: 'delete', child: Text(context.t('loc.delete'))),
                  ],
                ),
              ],
            ),
            floatingActionButton: l.isClosed
                ? null
                : AddOrnamentFab(onPressed: () => showAddOrnamentSheet(context, locationId: d.subs.isEmpty || l.isLocker ? l.id : d.subs.first.id)),
            body: ListView(padding: const EdgeInsets.fromLTRB(16, 0, 16, 120), children: [
              GoldCard(
                accent: color,
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(children: [
                    Dot(color, size: 14),
                    const SizedBox(width: 10),
                    Text(l.isLocker ? context.t('loc.bankLocker') : context.t('loc.place'), style: const TextStyle(color: GV.muted)),
                    if (l.isClosed) ...[
                      const Spacer(),
                      Text(context.t('loc.closedOn', {'date': Fmt.date(Fmt.parse(l.closedAt))}), style: const TextStyle(color: GV.danger)),
                    ],
                  ]),
                  const SizedBox(height: 14),
                  Row(children: [
                    _metric(context.t('loc.items'), Fmt.number(t.items)),
                    _metric(context.t('dash.goldShort'), Fmt.grams(t.gold)),
                    _metric(context.t('dash.silverShort'), Fmt.grams(t.silver)),
                  ]),
                  if (d.rates.isSet) ...[
                    const SizedBox(height: 10),
                    Row(children: [
                      Text('${context.t('dash.value')}: ', style: const TextStyle(color: GV.muted)),
                      RevealText(Fmt.rupees(t.value), style: const TextStyle(color: GV.ok, fontWeight: FontWeight.w700, fontSize: 16)),
                    ]),
                  ],
                ]),
              ),
              if (l.isLocker && !l.isClosed) ...[
                const SizedBox(height: 14),
                Row(children: [
                  Expanded(
                    child: FilledButton.icon(
                      icon: const Icon(Icons.event_note),
                      label: Text(context.t('visit.log')),
                      onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => VisitFormScreen(locationId: l.id))),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.event_available),
                      label: Text(context.t('visit.plan')),
                      onPressed: () => planVisit(context, l),
                    ),
                  ),
                ]),
              ],
              if (d.info != null) ...[
                SectionTitle(context.t('locker.details')),
                _lockerFacts(context, d.info!),
              ],
              if (!l.isLocker) ...[
                SectionTitle(context.t('loc.subs'),
                    trailing: IconButton(
                      iconSize: 28,
                      icon: const Icon(Icons.add_circle_outline, color: GV.gold),
                      onPressed: () async {
                        final name = await promptText(context, context.t('loc.addSub'), label: context.t('loc.placeName'));
                        if (name != null) await AppServices.I.repo.addPlace(name, parentId: l.id);
                      },
                    )),
                if (d.subs.isEmpty)
                  Text(context.t('loc.noSubs'), style: const TextStyle(color: GV.muted))
                else
                  GoldCard(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Column(children: [
                      for (final s in d.subs)
                        ListTile(
                          leading: const Icon(Icons.inventory_2_outlined),
                          title: Text(s.name),
                          subtitle: Text(context.t('dash.itemsN', {'n': d.items.where((i) => i.locationId == s.id).length})),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => LocationDetailScreen(locationId: s.id!))),
                        ),
                    ]),
                  ),
              ],
              SectionTitle(context.t('loc.itemsHere')),
              if (d.items.isEmpty)
                Text(context.t('loc.noItems'), style: const TextStyle(color: GV.muted))
              else
                for (final (n, i) in d.items.indexed) ItemCard(item: i, photo: d.photos[i.id], locations: d.all, index: n),
              if (d.visits.isNotEmpty) ...[
                SectionTitle(context.t('visit.recent')),
                GoldCard(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Column(children: [
                    for (final v in d.visits)
                      ListTile(
                        leading: const Icon(Icons.event_note),
                        title: Text(Fmt.date(v.date)),
                        subtitle: Text('${Fmt.hhmm(v.timeIn)} – ${Fmt.hhmm(v.timeOut)}${v.visitors == null ? '' : ' · ${v.visitors}'}'),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => VisitDetailScreen(visitId: v.id!))),
                      ),
                  ]),
                ),
              ],
            ]),
          );
        },
      ),
    );
  }

  Widget _metric(String label, String value) => Expanded(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label, style: const TextStyle(color: GV.muted, fontSize: 13)),
          FittedBox(fit: BoxFit.scaleDown, child: Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: GV.gold))),
        ]),
      );

  Widget _lockerFacts(BuildContext context, LockerInfo i) {
    final due = Fmt.parse(i.rentDueDate);
    final rows = <(String, String?, bool)>[
      (context.t('locker.bank'), context.s.opt(i.bank), false),
      (context.t('locker.branch'), i.branch, false),
      (context.t('locker.address'), i.branchAddress, false),
      (context.t('locker.number'), i.lockerNo, true),
      (context.t('locker.key'), i.keyNo, true),
      (context.t('locker.size'), context.s.opt(i.size), false),
      (context.t('locker.opened'), i.openedDate == null ? null : Fmt.date(Fmt.parse(i.openedDate)), false),
      (context.t('locker.holders'), i.holders, false),
      (context.t('locker.joint'), i.jointHolders, false),
      (context.t('locker.nominee'), i.nominee, false),
      (context.t('locker.rent'), i.annualRent == null ? null : Fmt.rupees(i.annualRent), true),
      (context.t('locker.rentDue'), due == null ? null : Fmt.date(due), false),
      (context.t('locker.contact'), i.bankContact, true),
      (context.t('item.notes'), i.notes, false),
    ];
    return GoldCard(
      padding: const EdgeInsets.fromLTRB(18, 8, 18, 8),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        for (final (k, v, sensitive) in rows)
          if (v != null && v.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 7),
              child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                SizedBox(width: 130, child: Text(k, style: const TextStyle(color: GV.muted, fontSize: 15))),
                Expanded(
                  child: sensitive
                      ? Align(alignment: Alignment.centerLeft, child: RevealText(v, style: const TextStyle(fontSize: 16.5, fontWeight: FontWeight.w600)))
                      : Text(v, style: const TextStyle(fontSize: 16.5, fontWeight: FontWeight.w600)),
                ),
              ]),
            ),
        if (due != null) ...[
          const SizedBox(height: 6),
          OutlinedButton.icon(
            icon: const Icon(Icons.task_alt),
            label: Text(context.t('locker.rentPaid')),
            onPressed: () async {
              final ok = await confirm(context, context.t('locker.rentPaid'),
                  context.t('locker.rentPaidBody', {'date': Fmt.date(DateTime(due.year + 1, due.month, due.day))}));
              if (ok) await AppServices.I.repo.markRentPaid(i.locationId!);
            },
          ),
        ],
      ]),
    );
  }

  Future<void> _menu(BuildContext context, String v, _LocDetail d) async {
    final repo = AppServices.I.repo;
    switch (v) {
      case 'rename':
        final name = await promptText(context, context.t('loc.rename'), initial: d.loc.name);
        if (name != null) await repo.renameLocation(d.loc.id!, name);
        break;
      case 'close':
        await closeLockerFlow(context, d.loc);
        break;
      case 'reopen':
        await repo.reopenLocation(d.loc.id!);
        break;
      case 'delete':
        if (!await repo.canDeleteLocation(d.loc.id!)) {
          if (context.mounted) toast(context, context.t('loc.cantDelete'));
          return;
        }
        if (!context.mounted) return;
        if (await confirm(context, context.t('loc.delete'), d.loc.name, danger: true)) {
          await repo.deleteLocation(d.loc.id!);
          if (context.mounted) Navigator.pop(context);
        }
        break;
    }
  }
}

Future<void> planVisit(BuildContext context, Location l) async {
  final d = await showDatePicker(
    context: context,
    initialDate: DateTime.now().add(const Duration(days: 1)),
    firstDate: DateTime.now().subtract(const Duration(days: 1)),
    lastDate: DateTime(2100),
    helpText: context.t('visit.plan'),
  );
  if (d == null) return;
  await AppServices.I.repo.saveReminder(ReminderEngine.planned(l, d));
  if (context.mounted) toast(context, context.t('visit.planned', {'date': Fmt.date(d)}));
}
