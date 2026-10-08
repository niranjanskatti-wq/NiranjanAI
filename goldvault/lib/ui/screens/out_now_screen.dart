import 'package:flutter/material.dart';

import '../../core/app_services.dart';
import '../../core/strings.dart';
import '../../core/theme.dart';
import '../../data/constants.dart';
import '../../data/models.dart';
import '../../data/repository.dart';
import '../widgets/common.dart';
import '../widgets/tiles.dart';

/// Every ornament currently out of the bank lockers, with how long it has
/// been out and when it should go back. Overdue ones first.
class OutNowScreen extends StatelessWidget {
  const OutNowScreen({super.key});

  Future<(List<Item>, Map<int, DateTime>, Map<int, DateTime>, Map<int, String>, Map<int, Location>)> _load() async {
    final repo = AppServices.I.repo;
    final p = await repo.prefs();
    final out = await repo.takenOutTimes();
    final back = await repo.returnByTimes(p.alertTime);
    final items = (await repo.items(ItemQuery(statuses: Opt.activeStatuses.toSet())))
        .where((i) => i.status != Opt.inLocker && (out.containsKey(i.id) || Opt.outStatuses.contains(i.status)))
        .toList();
    final now = DateTime.now();
    int rank(Item i) => (back[i.id]?.isBefore(now) ?? false) ? 0 : 1;
    items.sort((a, b) {
      final r = rank(a).compareTo(rank(b));
      if (r != 0) return r;
      return (out[a.id] ?? now).compareTo(out[b.id] ?? now); // longest out first
    });
    return (items, out, back, await repo.firstPhotos(), await repo.locationMap());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(context.t('ret.screen'))),
      body: DataBuilder<(List<Item>, Map<int, DateTime>, Map<int, DateTime>, Map<int, String>, Map<int, Location>)>(
        load: _load,
        builder: (context, d) {
          final (items, out, back, photos, locs) = d;
          if (items.isEmpty) return EmptyState(icon: Icons.lock_outline, text: context.t('ret.none'));
          final late = items.where((i) => back[i.id]?.isBefore(DateTime.now()) ?? false).length;
          return ListView(padding: const EdgeInsets.fromLTRB(16, 0, 16, 40), children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(4, 0, 4, 12),
              child: Text(
                context.t('ret.summary', {'n': items.length}) + (late > 0 ? ' · ${context.t('ret.lateN', {'n': late})}' : ''),
                style: TextStyle(color: late > 0 ? GV.danger : GV.muted, fontWeight: late > 0 ? FontWeight.w700 : null),
              ),
            ),
            for (final (n, i) in items.indexed)
              ItemCard(item: i, photo: photos[i.id], locations: locs, index: n, outSince: out[i.id], returnBy: back[i.id]),
          ]);
        },
      ),
    );
  }
}
