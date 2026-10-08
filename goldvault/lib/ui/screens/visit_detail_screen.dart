import 'package:flutter/material.dart';

import '../../core/app_services.dart';
import '../../core/format.dart';
import '../../core/strings.dart';
import '../../core/theme.dart';
import '../../data/models.dart';
import '../../data/repository.dart';
import '../widgets/common.dart';
import '../widgets/tiles.dart';
import 'visit_form_screen.dart';

class VisitDetailScreen extends StatelessWidget {
  const VisitDetailScreen({super.key, required this.visitId});
  final int visitId;

  @override
  Widget build(BuildContext context) {
    return DataBuilder<(VisitWithMoves?, Location?)>(
      load: () async {
        final d = await AppServices.I.repo.visitDetail(visitId);
        return (d, d == null ? null : await AppServices.I.repo.location(d.visit.locationId));
      },
      builder: (context, r) {
        final (d, loc) = r;
        if (d == null) return const Scaffold(body: SizedBox());
        final v = d.visit;
        return Scaffold(
          appBar: AppBar(
            title: Text(context.t('visit.detail')),
            actions: [
              IconButton(
                iconSize: 28,
                icon: const Icon(Icons.edit_outlined),
                onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => VisitFormScreen(existing: v))),
              ),
              if (d.deposited.isEmpty && d.withdrawn.isEmpty)
                IconButton(
                  iconSize: 28,
                  icon: const Icon(Icons.delete_outline),
                  onPressed: () async {
                    if (await confirm(context, context.t('visit.delete'), Fmt.date(v.date), danger: true)) {
                      await AppServices.I.repo.deleteVisit(v.id!);
                      if (context.mounted) Navigator.pop(context);
                    }
                  },
                ),
            ],
          ),
          body: ListView(padding: const EdgeInsets.fromLTRB(16, 0, 16, 40), children: [
            GoldCard(
              accent: loc == null ? null : Color(loc.color),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(loc?.name ?? '', style: Theme.of(context).textTheme.headlineSmall),
                const SizedBox(height: 8),
                _row(Icons.calendar_month, Fmt.date(v.date)),
                _row(Icons.schedule, '${Fmt.hhmm(v.timeIn)} – ${Fmt.hhmm(v.timeOut)}'),
                if (v.visitors != null) _row(Icons.people_outline, v.visitors!),
                if (v.purpose != null) _row(Icons.flag_outlined, v.purpose!),
                if (v.notes != null) _row(Icons.notes, v.notes!),
              ]),
            ),
            SectionTitle('${context.t('visit.deposited')} (${d.deposited.length})'),
            _moves(context, d.deposited),
            SectionTitle('${context.t('visit.withdrawn')} (${d.withdrawn.length})'),
            _moves(context, d.withdrawn),
          ]),
        );
      },
    );
  }

  Widget _row(IconData i, String t) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(children: [Icon(i, color: GV.gold, size: 20), const SizedBox(width: 10), Expanded(child: Text(t, style: const TextStyle(fontSize: 16)))]),
      );

  Widget _moves(BuildContext context, List<Movement> m) => m.isEmpty
      ? Text(context.t('visit.noItems'), style: const TextStyle(color: GV.muted))
      : GoldCard(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Column(children: [for (final x in m) MovementTile(x, showItem: true)]),
        );
}
