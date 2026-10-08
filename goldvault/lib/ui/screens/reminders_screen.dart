import 'package:flutter/material.dart';

import '../../core/app_services.dart';
import '../../core/format.dart';
import '../../core/strings.dart';
import '../../core/theme.dart';
import '../../data/models.dart';
import '../../services/reminder_engine.dart';
import '../widgets/common.dart';
import '../widgets/fields.dart';
import '../widgets/tiles.dart';

class RemindersScreen extends StatelessWidget {
  const RemindersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(context.t('rem.title'))),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: null,
        onPressed: () => _add(context),
        icon: const Icon(Icons.add_alarm),
        label: Text(context.t('rem.add')),
      ),
      body: DataBuilder<(List<DueItem>, int, int)>(
        load: () async {
          final e = AppServices.I.reminders;
          return (await e.upcoming(horizonDays: 90), await e.notReturnedDays(), await e.rentLeadDays());
        },
        builder: (context, r) {
          final (list, days, lead) = r;
          return ListView(padding: const EdgeInsets.fromLTRB(16, 0, 16, 120), children: [
            GoldCard(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(context.t('rem.rules'), style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                const SizedBox(height: 6),
                Text(context.t('rem.rulesBody', {'days': days, 'lead': lead}), style: const TextStyle(color: GV.muted)),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(onPressed: () => editReminderRules(context), child: Text(context.t('common.change'))),
                ),
              ]),
            ),
            const SizedBox(height: 14),
            if (list.isEmpty)
              EmptyState(icon: Icons.notifications_none, text: context.t('dash.noReminders'))
            else
              GoldCard(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Column(children: [
                  for (final d in list)
                    DueTile(
                      d,
                      trailing: d.reminderId == null
                          ? null
                          : IconButton(
                              tooltip: context.t('rem.done'),
                              icon: const Icon(Icons.check_circle_outline, color: GV.ok, size: 28),
                              onPressed: () => AppServices.I.repo.setReminderDone(d.reminderId!, true),
                            ),
                    ),
                ]),
              ),
          ]);
        },
      ),
    );
  }

  Future<void> _add(BuildContext context) async {
    final title = TextEditingController();
    var date = DateTime.now().add(const Duration(days: 1));
    int? loc;
    final ok = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (c) => StatefulBuilder(
        builder: (c, set) => Padding(
          padding: EdgeInsets.fromLTRB(20, 0, 20, 24 + MediaQuery.of(c).viewInsets.bottom),
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Text(context.t('rem.add'), style: Theme.of(c).textTheme.titleLarge),
            gap,
            TextIn(title, context.t('rem.what'), hint: context.t('rem.whatHint')),
            gap,
            DateIn(label: context.t('common.date'), value: Fmt.isoDate(date), allowClear: false, onChanged: (v) => set(() => date = DateTime.parse(v!))),
            gap,
            LocationPick(label: context.t('rem.lockerOptional'), value: loc, lockersOnly: true, onChanged: (v) => set(() => loc = v)),
            const SizedBox(height: 20),
            FilledButton(onPressed: () => Navigator.pop(c, true), child: Text(context.t('common.save'))),
          ]),
        ),
      ),
    );
    if (ok != true) return;
    final repo = AppServices.I.repo;
    final l = loc == null ? null : await repo.location(loc!);
    final text = title.text.trim();
    if (text.isEmpty && l == null) return;
    await repo.saveReminder(Reminder(
      kind: l != null && text.isEmpty ? 'planned_visit' : 'custom',
      title: text.isEmpty ? l!.name : text,
      dueDate: Fmt.isoDate(date),
      locationId: l?.id,
    ));
  }
}

Future<void> editReminderRules(BuildContext context) async {
  final repo = AppServices.I.repo;
  final e = AppServices.I.reminders;
  final days = TextEditingController(text: '${await e.notReturnedDays()}');
  final lead = TextEditingController(text: '${await e.rentLeadDays()}');
  if (!context.mounted) return;
  final ok = await showDialog<bool>(
    context: context,
    builder: (c) => AlertDialog(
      title: Text(context.t('rem.rules')),
      content: Column(mainAxisSize: MainAxisSize.min, children: [
        TextIn(days, context.t('rem.notReturnedDays'), number: true, suffix: context.t('common.days')),
        gap,
        TextIn(lead, context.t('rem.rentLead'), number: true, suffix: context.t('common.days')),
      ]),
      actions: [
        TextButton(onPressed: () => Navigator.pop(c, false), child: Text(context.t('common.cancel'))),
        FilledButton(onPressed: () => Navigator.pop(c, true), child: Text(context.t('common.save'))),
      ],
    ),
  );
  if (ok != true) return;
  final d = int.tryParse(days.text.trim());
  final l = int.tryParse(lead.text.trim());
  if (d != null && d > 0) await repo.setSetting('not_returned_days', '$d');
  if (l != null && l >= 0) await repo.setSetting('rent_lead_days', '$l');
  repo.revision.value++;
}
