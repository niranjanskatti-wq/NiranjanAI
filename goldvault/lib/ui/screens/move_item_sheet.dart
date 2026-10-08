import 'package:flutter/material.dart';

import '../../core/app_services.dart';
import '../../core/format.dart';
import '../../core/strings.dart';
import '../../data/constants.dart';
import '../../data/models.dart';
import '../widgets/common.dart';
import '../widgets/fields.dart';

/// Move an item or change its status. [dispose] = sold / exchanged / gifted.
Future<void> showMoveItemSheet(BuildContext context, Item item, {bool dispose = false}) async {
  final statuses = dispose ? Opt.disposedStatuses : Opt.activeStatuses;
  var status = dispose ? Opt.sold : (item.status == Opt.inLocker ? Opt.atHome : Opt.inLocker);
  if (!statuses.contains(status)) status = statuses.first;
  int? loc;
  final note = TextEditingController();
  var date = DateTime.now();
  var time = TimeOfDay.now();

  final ok = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    builder: (c) => StatefulBuilder(builder: (c, set) {
      final placed = Opt.placedStatuses.contains(status);
      return Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(c).viewInsets.bottom),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Text(dispose ? context.t('move.disposeTitle') : context.t('move.title'), style: Theme.of(c).textTheme.titleLarge),
            const SizedBox(height: 4),
            Text('${item.name} · ${item.serial}', style: const TextStyle(fontSize: 15)),
            gap,
            Wrap(spacing: 8, runSpacing: 8, children: [
              for (final s in statuses)
                ChoiceChip(
                  label: Text(context.s.status(s), style: const TextStyle(fontSize: 16)),
                  selected: status == s,
                  onSelected: (_) => set(() {
                    status = s;
                    loc = null;
                  }),
                ),
            ]),
            gap,
            if (placed)
              LocationPick(
                label: context.t('item.location'),
                value: loc,
                lockersOnly: status == Opt.inLocker,
                placesOnly: status == Opt.atHome,
                exclude: item.status == status ? item.locationId : null,
                onChanged: (v) => set(() => loc = v),
              )
            else
              TextIn(note, dispose ? context.t('move.disposeNote') : context.t('item.statusNote'),
                  hint: dispose ? context.t('move.disposeHint') : context.t('item.statusNoteHint')),
            gap,
            Row(children: [
              Expanded(child: DateIn(label: context.t('common.date'), value: Fmt.isoDate(date), allowClear: false, onChanged: (v) => set(() => date = DateTime.parse(v!)))),
              const SizedBox(width: 10),
              Expanded(
                child: TimeIn(
                  label: context.t('common.time'),
                  value: '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}',
                  onChanged: (v) {
                    final p = v!.split(':');
                    set(() => time = TimeOfDay(hour: int.parse(p[0]), minute: int.parse(p[1])));
                  },
                ),
              ),
            ]),
            if (status == Opt.inLocker) ...[
              const SizedBox(height: 10),
              Text(context.t('move.visitTip'), style: const TextStyle(color: Colors.white60, fontSize: 13.5)),
            ],
            const SizedBox(height: 20),
            FilledButton(
              onPressed: () {
                if (placed && loc == null) {
                  toast(c, context.t('item.needLocation'));
                  return;
                }
                Navigator.pop(c, true);
              },
              child: Text(context.t('common.save')),
            ),
          ]),
        ),
      );
    }),
  );
  if (ok != true) return;
  if (dispose && context.mounted) {
    final sure = await confirm(context, context.s.status(status), context.t('move.disposeConfirm', {'name': item.name}));
    if (!sure) return;
  }
  await AppServices.I.repo.moveItem(
    item.id!,
    toLocationId: loc,
    toStatus: status,
    at: DateTime(date.year, date.month, date.day, time.hour, time.minute),
    note: note.text,
  );
}
