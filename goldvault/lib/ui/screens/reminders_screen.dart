import 'package:flutter/material.dart';

import '../../core/app_services.dart';
import '../../core/format.dart';
import '../../core/strings.dart';
import '../../core/theme.dart';
import '../../data/models.dart';
import '../../services/reminder_engine.dart';
import '../widgets/common.dart';
import '../widgets/tiles.dart';
import 'alert_settings_screen.dart';
import 'reminder_form_screen.dart';

class RemindersScreen extends StatelessWidget {
  const RemindersScreen({super.key});

  Future<(List<Reminder>, List<DueItem>, Prefs)> _load() async {
    final repo = AppServices.I.repo;
    final auto = (await AppServices.I.reminders.upcoming(horizonDays: 60)).where((d) => d.reminderId == null).toList();
    return (await repo.reminders(), auto, await repo.prefs());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(context.t('rem.title')),
        actions: [
          IconButton(
            iconSize: 28,
            tooltip: context.t('alerts.title'),
            icon: const Icon(Icons.tune),
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AlertSettingsScreen())),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: null,
        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ReminderFormScreen())),
        icon: const Icon(Icons.alarm_add),
        label: Text(context.t('rem.add')),
      ),
      body: DataBuilder<(List<Reminder>, List<DueItem>, Prefs)>(
        load: _load,
        builder: (context, r) {
          final (mine, auto, prefs) = r;
          return ListView(padding: const EdgeInsets.fromLTRB(16, 0, 16, 120), children: [
            if (!prefs.notifications)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: GoldCard(
                  accent: GV.danger,
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AlertSettingsScreen())),
                  child: Row(children: [
                    const Icon(Icons.notifications_off_outlined, color: GV.danger),
                    const SizedBox(width: 10),
                    Expanded(child: Text(context.t('alerts.allOff'))),
                  ]),
                ),
              ),
            SectionTitle(context.t('rem.mine')),
            if (mine.isEmpty)
              GoldCard(child: Text(context.t('rem.mineEmpty'), style: const TextStyle(color: GV.muted)))
            else
              GoldCard(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Column(children: [for (final m in mine) _ReminderTile(m, prefs.alertTime)]),
              ),
            SectionTitle(context.t('rem.auto')),
            if (auto.isEmpty)
              GoldCard(child: Text(context.t('dash.noReminders'), style: const TextStyle(color: GV.muted)))
            else
              GoldCard(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Column(children: [for (final d in auto) DueTile(d)]),
              ),
          ]);
        },
      ),
    );
  }
}

class _ReminderTile extends StatelessWidget {
  const _ReminderTile(this.r, this.defaultTime);
  final Reminder r;
  final String defaultTime;

  @override
  Widget build(BuildContext context) {
    final repo = AppServices.I.repo;
    final at = r.at(defaultTime);
    final overdue = at.isBefore(DateTime.now());
    final icon = switch (r.kind) { 'keep' => Icons.login, 'take' => Icons.logout, 'planned_visit' => Icons.event_available, _ => Icons.alarm };
    final color = !r.enabled ? GV.muted : (overdue ? GV.danger : GV.gold);
    return ListTile(
      leading: CircleAvatar(backgroundColor: color.withValues(alpha: 0.15), child: Icon(r.alarm ? Icons.alarm_on : icon, color: color)),
      title: Text(r.title, style: TextStyle(color: r.enabled ? GV.text : GV.muted)),
      subtitle: Text([
        '${context.t('rem.kind.${r.kind}')} · ${Fmt.dateTime(at)}',
        if (r.repeat != 'none') context.t('rem.repeat.${r.repeat}'),
        if (overdue) context.t('rem.overdue'),
      ].join(' · ')),
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ReminderFormScreen(existing: r))),
      trailing: Row(mainAxisSize: MainAxisSize.min, children: [
        Switch(value: r.enabled, onChanged: (v) => repo.setReminderEnabled(r.id!, v)),
        PopupMenuButton<String>(
          color: GV.surface2,
          onSelected: (v) async {
            if (v == 'done') await repo.setReminderDone(r.id!, true);
            if (v == 'delete' && context.mounted && await confirm(context, context.t('rem.delete'), r.title, danger: true)) {
              await repo.deleteReminder(r.id!);
            }
          },
          itemBuilder: (c) => [
            PopupMenuItem(value: 'done', child: Text(context.t('rem.done'))),
            PopupMenuItem(value: 'delete', child: Text(context.t('rem.delete'))),
          ],
        ),
      ]),
    );
  }
}
