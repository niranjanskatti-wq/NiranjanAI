import 'package:flutter/material.dart';

import '../../core/app_services.dart';
import '../../core/format.dart';
import '../../core/strings.dart';
import '../../core/theme.dart';
import '../../data/models.dart';
import '../widgets/common.dart';
import 'location_detail_screen.dart';
import 'locker_form_screen.dart';

class _Locs {
  final List<Location> locs;
  final Map<int, LockerInfo> lockers;
  final Map<int?, Totals> totals;
  final bool ratesSet;
  _Locs(this.locs, this.lockers, this.totals, this.ratesSet);
}

class LocationsScreen extends StatefulWidget {
  const LocationsScreen({super.key});
  @override
  State<LocationsScreen> createState() => _LocationsScreenState();
}

class _LocationsScreenState extends State<LocationsScreen> {
  bool _showClosed = false;

  Future<_Locs> _load() async {
    final repo = AppServices.I.repo;
    return _Locs(await repo.locations(includeClosed: _showClosed), await repo.allLockerInfo(),
        await repo.totalsByLocation(), (await repo.valueRates()).isSet);
  }

  /// Totals for a location including its sub-locations.
  static Totals _sum(Location l, _Locs d) {
    final t = Totals();
    void addFrom(int id) {
      final x = d.totals[id];
      if (x == null) return;
      t.items += x.items;
      t.pieces += x.pieces;
      t.gold += x.gold;
      t.silver += x.silver;
      t.platinum += x.platinum;
      t.value += x.value;
    }

    addFrom(l.id!);
    for (final c in d.locs.where((c) => c.parentId == l.id)) {
      addFrom(c.id!);
    }
    return t;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(context.t('loc.title')),
        actions: [
          IconButton(
            tooltip: context.t('loc.showClosed'),
            iconSize: 28,
            icon: Icon(_showClosed ? Icons.inventory_2 : Icons.inventory_2_outlined),
            onPressed: () => setState(() => _showClosed = !_showClosed),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: null,
        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const LockerFormScreen())),
        icon: const Icon(Icons.add_card, size: 26),
        label: Text(context.t('loc.addLocker')),
      ),
      body: DataBuilder<_Locs>(
        load: _load,
        watch: _showClosed,
        builder: (context, d) {
          final tops = d.locs.where((l) => l.parentId == null).toList()
            ..sort((a, b) {
              if (a.isClosed != b.isClosed) return a.isClosed ? 1 : -1;
              if (a.isLocker != b.isLocker) return a.isLocker ? -1 : 1;
              return a.sortOrder.compareTo(b.sortOrder);
            });
          return ListView(padding: const EdgeInsets.fromLTRB(16, 4, 16, 120), children: [
            for (final (n, l) in tops.indexed) ...[
              FadeIn(index: n, child: _card(context, l, d)),
              const SizedBox(height: 14),
            ],
            OutlinedButton.icon(
              icon: const Icon(Icons.add_home_outlined),
              label: Text(context.t('loc.addPlace')),
              onPressed: () async {
                final name = await promptText(context, context.t('loc.addPlace'), label: context.t('loc.placeName'));
                if (name != null) await AppServices.I.repo.addPlace(name);
              },
            ),
            if (d.totals[null] != null) ...[
              const SizedBox(height: 14),
              GoldCard(
                child: Row(children: [
                  const Icon(Icons.directions_walk, color: Color(0xFF4FC3F7), size: 30),
                  const SizedBox(width: 12),
                  Expanded(child: Text(context.t('loc.outside'), style: const TextStyle(fontSize: 16))),
                  Text(context.t('dash.itemsN', {'n': d.totals[null]!.items}), style: const TextStyle(color: GV.muted)),
                ]),
              ),
            ],
          ]);
        },
      ),
    );
  }

  Widget _card(BuildContext context, Location l, _Locs d) {
    final t = _sum(l, d);
    final info = d.lockers[l.id];
    final color = Color(l.color);
    final subs = d.locs.where((c) => c.parentId == l.id).toList();
    return Opacity(
      opacity: l.isClosed ? 0.55 : 1,
      child: GoldCard(
        accent: color,
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => LocationDetailScreen(locationId: l.id!))),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(color: color.withValues(alpha: 0.16), borderRadius: BorderRadius.circular(14)),
              child: Icon(l.isLocker ? Icons.account_balance : Icons.home_outlined, color: color, size: 28),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(l.name, style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w800)),
                Text(
                  l.isClosed
                      ? context.t('loc.closedOn', {'date': Fmt.date(Fmt.parse(l.closedAt))})
                      : l.isLocker
                          ? [context.s.opt(info?.bank), if (info?.branch != null) info!.branch!].join(' · ')
                          : subs.map((s) => s.name).join(' · '),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: GV.muted, fontSize: 14),
                ),
              ]),
            ),
            const Icon(Icons.chevron_right, color: GV.gold),
          ]),
          const SizedBox(height: 14),
          Row(children: [
            _metric(context.t('loc.items'), Fmt.number(t.items), GV.text),
            _metric(context.t('dash.goldShort'), Fmt.grams(t.gold), GV.gold),
            _metric(context.t('dash.silverShort'), Fmt.grams(t.silver), GV.silver),
          ]),
          if (d.ratesSet) ...[
            const SizedBox(height: 8),
            Row(children: [
              Text('${context.t('dash.value')}: ', style: const TextStyle(color: GV.muted)),
              RevealText(Fmt.rupees(t.value), style: const TextStyle(color: GV.ok, fontWeight: FontWeight.w700, fontSize: 16)),
            ]),
          ],
        ]),
      ),
    );
  }

  Widget _metric(String label, String value, Color c) => Expanded(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label, style: const TextStyle(color: GV.muted, fontSize: 13)),
          const SizedBox(height: 2),
          FittedBox(fit: BoxFit.scaleDown, child: Text(value, style: TextStyle(color: c, fontSize: 17, fontWeight: FontWeight.w800))),
        ]),
      );
}
