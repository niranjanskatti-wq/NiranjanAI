import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/tokens.dart';
import '../../data/providers.dart';
import '../../widgets/common.dart';
import 'notification_service.dart';
import 'reminder_model.dart';
import 'reminders_screen.dart';

final _settingProvider =
    StreamProvider.family<String?, String>((ref, key) => ref.watch(databaseProvider).watchSetting(key));

/// Reminders section of Settings: defaults for new events, morning time,
/// monthly summary, sounds and the reliability guide.
class ReminderSettingsSection extends ConsumerWidget {
  const ReminderSettingsSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final db = ref.read(databaseProvider);
    final person = decodeSpecs(ref.watch(_settingProvider('defaultPersonReminders')).value, defaultPersonReminders);
    final other = decodeSpecs(ref.watch(_settingProvider('defaultOtherReminders')).value, defaultOtherReminders);
    final morning = int.tryParse(ref.watch(_settingProvider('morningMinute')).value ?? '') ?? 480;
    final monthly = ref.watch(_settingProvider('monthlySummary')).value != 'false';

    bool has(List<ReminderSpec> l, ReminderKind k, [int days = 0]) =>
        l.any((s) => s.kind == k && (k != ReminderKind.daysBefore || s.daysBefore == days));

    Future<void> togglePerson(ReminderKind k, bool on) async {
      final l = [...person]..removeWhere((s) => s.kind == k);
      if (on) l.add(ReminderSpec(k, minute: k == ReminderKind.morning ? morning : 480));
      await db.setSetting('defaultPersonReminders', encodeSpecs(l));
    }

    Future<void> toggleOther(int days, bool on) async {
      final l = [...other]..removeWhere((s) => s.kind == ReminderKind.daysBefore && s.daysBefore == days);
      if (on) l.add(ReminderSpec(ReminderKind.daysBefore, daysBefore: days, minute: 540));
      await db.setSetting('defaultOtherReminders', encodeSpecs(l));
    }

    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      const Padding(padding: EdgeInsets.symmetric(horizontal: 12), child: SectionLabel('Reminders')),
      ListTile(
        leading: const Icon(Icons.verified_outlined),
        title: const Text('Make alarms reliable'),
        subtitle: const Text('Permissions and battery steps for your phone brand'),
        trailing: const Icon(Icons.chevron_right_rounded),
        onTap: () => context.push('/reliability'),
      ),
      ListTile(
        leading: const Icon(Icons.wb_sunny_outlined),
        title: const Text('Morning time'),
        subtitle: const Text('Used for new morning reminders, belated nudges and "Snooze until morning"'),
        trailing: Text(fmtMinute(morning), style: context.text.titleSmall),
        onTap: () async {
          final m = await pickMinute(context, morning);
          if (m != null) await db.setSetting('morningMinute', '$m');
        },
      ),
      const Padding(
        padding: EdgeInsets.fromLTRB(16, 8, 16, 0),
        child: Text('For new birthdays and anniversaries'),
      ),
      SwitchListTile(
        title: const Text('Morning reminder on the day'),
        value: has(person, ReminderKind.morning),
        onChanged: (v) => togglePerson(ReminderKind.morning, v),
      ),
      SwitchListTile(
        title: const Text('Midnight alarm'),
        value: has(person, ReminderKind.midnight),
        onChanged: (v) => togglePerson(ReminderKind.midnight, v),
      ),
      const Padding(
        padding: EdgeInsets.fromLTRB(16, 8, 16, 0),
        child: Text('For new important dates'),
      ),
      SwitchListTile(
        title: const Text('7 days before'),
        value: has(other, ReminderKind.daysBefore, 7),
        onChanged: (v) => toggleOther(7, v),
      ),
      SwitchListTile(
        title: const Text('1 day before'),
        value: has(other, ReminderKind.daysBefore, 1),
        onChanged: (v) => toggleOther(1, v),
      ),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Text('These only apply to events you add from now on. Change any event on its Reminders page.',
            style: context.text.bodySmall),
      ),
      const SizedBox(height: 8),
      SwitchListTile(
        title: const Text('Monthly summary'),
        subtitle: const Text('On the 1st at 9 AM: everything coming up that month'),
        value: monthly,
        onChanged: (v) => db.setSetting('monthlySummary', '$v'),
      ),
      ListTile(
        leading: const Icon(Icons.music_note_outlined),
        title: const Text('Hear the sounds'),
        subtitle: const Text('Tick-tock, bells, chime, birthday tune'),
        trailing: const Icon(Icons.chevron_right_rounded),
        onTap: () => pickSound(context, AlarmSound.tickTock),
      ),
      ListTile(
        leading: const Icon(Icons.alarm_on_outlined),
        title: const Text('Test the midnight alarm'),
        subtitle: const Text('Rings in 1 minute. Lock your phone to see the full-screen alert.'),
        onTap: () async {
          await NotificationService.requestNotifications();
          await NotificationService.testAlarm();
          if (context.mounted) showToast(context, 'Test alarm in 1 minute');
        },
      ),
    ]);
  }
}
