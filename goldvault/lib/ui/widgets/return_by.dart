import 'package:flutter/material.dart';

import '../../core/app_services.dart';
import '../../core/format.dart';
import '../../core/strings.dart';
import '../../core/theme.dart';
import '../../data/models.dart';
import '../../services/notifications.dart';
import 'fields.dart';

/// "How long has it been out?" e.g. "3 days 4 hrs".
String outFor(BuildContext context, DateTime since, [DateTime? now]) {
  final d = (now ?? DateTime.now()).difference(since);
  if (d.isNegative) return context.t('dur.justNow');
  final days = d.inDays;
  final hours = d.inHours % 24;
  final mins = d.inMinutes % 60;
  if (days > 0) {
    return hours > 0 ? '${context.t('dur.days', {'n': days})} ${context.t('dur.hours', {'n': hours})}' : context.t('dur.days', {'n': days});
  }
  if (d.inHours > 0) return '${context.t('dur.hours', {'n': d.inHours})} ${context.t('dur.mins', {'n': mins})}';
  return context.t('dur.mins', {'n': d.inMinutes < 1 ? 1 : d.inMinutes});
}

/// Optional "return by" choice made while taking jewellery out.
class ReturnByChoice {
  bool on = false;
  String date = Fmt.isoDate(DateTime.now().add(const Duration(days: 7)));
  String? time;
  bool untilBack = true;
  bool alarm = true;

  /// Applies the user's defaults (Settings → Alerts & alarms).
  Future<void> loadDefaults() async {
    final p = await AppServices.I.repo.prefs();
    on = p.returnByDefault;
    date = Fmt.isoDate(DateTime.now().add(Duration(days: p.returnByDays)));
    time = p.alertTime;
    alarm = p.alarmByDefault;
  }

  /// Creates the "put back in locker" alarm if switched on.
  Future<void> save({required S s, required List<Item> items, int? lockerId}) async {
    if (!on || items.isEmpty) return;
    final repo = AppServices.I.repo;
    final l = lockerId == null ? null : await repo.location(lockerId);
    await repo.saveReminder(Reminder(
      kind: 'keep',
      title: s.t('rem.keepTitle', {'where': l?.name ?? s.t('rem.theLocker')}),
      dueDate: date,
      time: time,
      repeat: untilBack ? 'until_back' : 'none',
      locationId: lockerId,
      itemIds: items.map((e) => e.id!).toList(),
      alarm: alarm,
      notes: items.map((i) => '${i.name} (${i.serial})').join(', '),
    ));
    await Notifier.requestPermission();
    if (alarm) await Notifier.requestExactAlarms();
  }
}

class ReturnByFields extends StatelessWidget {
  const ReturnByFields({super.key, required this.choice, required this.onChanged});
  final ReturnByChoice choice;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    final c = choice;
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      SwitchListTile(
        contentPadding: EdgeInsets.zero,
        secondary: const Icon(Icons.alarm_add, color: GV.gold, size: 28),
        title: Text(context.t('ret.title')),
        subtitle: Text(context.t('ret.sub')),
        value: c.on,
        onChanged: (v) {
          c.on = v;
          onChanged();
        },
      ),
      if (c.on) ...[
        Row(children: [
          Expanded(
            child: DateIn(
              label: context.t('ret.date'),
              value: c.date,
              allowClear: false,
              onChanged: (v) {
                c.date = v!;
                onChanged();
              },
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: TimeIn(
              label: context.t('common.time'),
              value: c.time,
              onChanged: (v) {
                c.time = v;
                onChanged();
              },
            ),
          ),
        ]),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: Text(context.t('ret.untilBack')),
          subtitle: Text(context.t('ret.untilBackSub')),
          value: c.untilBack,
          onChanged: (v) {
            c.untilBack = v;
            onChanged();
          },
        ),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: Text(context.t('rem.alarm')),
          value: c.alarm,
          onChanged: (v) {
            c.alarm = v;
            onChanged();
          },
        ),
      ],
    ]);
  }
}
