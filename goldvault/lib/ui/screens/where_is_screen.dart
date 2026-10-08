import 'package:flutter/material.dart';

import '../../core/app_services.dart';
import '../../core/format.dart';
import '../../core/strings.dart';
import '../../core/theme.dart';
import '../../data/repository.dart';
import '../widgets/common.dart';
import '../widgets/tiles.dart';
import 'item_detail_screen.dart';

/// "Where is my …?" – instant answer with location and last move time.
class WhereIsScreen extends StatefulWidget {
  const WhereIsScreen({super.key});
  @override
  State<WhereIsScreen> createState() => _WhereIsScreenState();
}

class _WhereIsScreenState extends State<WhereIsScreen> {
  String _q = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(context.t('where.title'))),
      body: Column(children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
          child: TextField(
            autofocus: true,
            style: const TextStyle(fontSize: 19),
            decoration: InputDecoration(
              prefixIcon: const Icon(Icons.travel_explore, color: GV.gold),
              hintText: context.t('where.hint'),
            ),
            onChanged: (v) => setState(() => _q = v),
          ),
        ),
        Expanded(
          child: _q.trim().isEmpty
              ? EmptyState(icon: Icons.diamond_outlined, text: context.t('where.prompt'))
              : DataBuilder<List<WhereIs>>(
                  load: () => AppServices.I.repo.whereIs(_q),
                  watch: _q,
                  builder: (c, list) {
                    if (list.isEmpty) return EmptyState(icon: Icons.search_off, text: context.t('picker.none'));
                    return ListView(padding: const EdgeInsets.fromLTRB(16, 0, 16, 40), children: [
                      for (final w in list) _answer(context, w),
                    ]);
                  },
                ),
        ),
      ]),
    );
  }

  Widget _answer(BuildContext context, WhereIs w) {
    final i = w.item;
    final color = w.location == null ? statusColor(i.status) : Color(w.location!.color);
    final place = w.location?.name ?? i.statusNote ?? context.s.status(i.status);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: GoldCard(
        accent: color,
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ItemDetailScreen(itemId: i.id!))),
        child: Row(children: [
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('${i.name}  ·  ${i.serial}', style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
              const SizedBox(height: 8),
              Row(children: [
                Icon(w.location?.isLocker == true ? Icons.account_balance : Icons.place_outlined, color: color, size: 26),
                const SizedBox(width: 8),
                Expanded(child: Text(place, style: TextStyle(fontSize: 20, color: color, fontWeight: FontWeight.w800))),
              ]),
              const SizedBox(height: 6),
              StatusChip(i.status),
              if (w.takenOut != null) OutLine(outSince: w.takenOut!),
              if (w.lastMove != null) ...[
                const SizedBox(height: 6),
                Text(MovementTile.describe(context, w.lastMove!), style: const TextStyle(color: GV.muted)),
                Text(context.t('where.since', {'date': Fmt.dateTime(w.lastMove!.at)}), style: const TextStyle(color: GV.muted)),
              ],
            ]),
          ),
          const Icon(Icons.chevron_right, color: GV.gold),
        ]),
      ),
    );
  }
}
