import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/tokens.dart';
import '../../data/providers.dart';
import '../../widgets/common.dart';
import '../contacts/contact_sync.dart';
import '../reminders/reminder_settings.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.c;
    final me = ref.watch(meProvider).value;
    final mode = ref.watch(themeModeProvider).value ?? ThemeMode.system;
    final db = ref.read(databaseProvider);

    Widget tile(IconData icon, String title, String? sub, VoidCallback onTap) => ListTile(
          leading: Icon(icon),
          title: Text(title),
          subtitle: sub == null ? null : Text(sub),
          trailing: const Icon(Icons.chevron_right_rounded),
          onTap: onTap,
        );

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(8, 0, 8, 40),
        children: [
          Card(
            margin: const EdgeInsets.symmetric(horizontal: 8),
            child: ListTile(
              contentPadding: const EdgeInsets.fromLTRB(14, 8, 14, 8),
              leading: PersonAvatar(person: me, size: 48),
              title: Text(me?.name ?? 'Add your details', style: context.text.titleLarge),
              subtitle: const Text('Your name, birthday and anniversary'),
              trailing: const Icon(Icons.chevron_right_rounded),
              onTap: () => me == null ? context.push('/me/new') : context.push('/person/${me.id}'),
            ),
          ),
          const SizedBox(height: 8),
          const Padding(padding: EdgeInsets.symmetric(horizontal: 12), child: SectionLabel('Appearance')),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: SegmentedButton<ThemeMode>(
              showSelectedIcon: false,
              segments: const [
                ButtonSegment(value: ThemeMode.system, label: Text('Phone setting')),
                ButtonSegment(value: ThemeMode.light, label: Text('Light')),
                ButtonSegment(value: ThemeMode.dark, label: Text('Dark')),
              ],
              selected: {mode},
              onSelectionChanged: (s) => db.setSetting('themeMode', s.first.name),
            ),
          ),
          const SizedBox(height: 12),
          const ReminderSettingsSection(),
          const SizedBox(height: 12),
          const Padding(padding: EdgeInsets.symmetric(horizontal: 12), child: SectionLabel('Contacts')),
          tile(Icons.group_add_outlined, 'Add many from contacts', 'Tick several people, then add their dates',
              () => context.push('/import/contacts')),
          tile(Icons.cake_outlined, 'Import birthdays from contacts', 'Finds dates already saved in your phone',
              () => context.push('/import/birthdays')),
          tile(Icons.sync_rounded, 'Check contacts for changed numbers', 'Also happens each time you open Smriti',
              () async {
            await ContactSync(ref.read(repoProvider)).run();
            if (context.mounted) showToast(context, 'Contacts checked');
          }),
          const SizedBox(height: 12),
          const Padding(padding: EdgeInsets.symmetric(horizontal: 12), child: SectionLabel('People')),
          tile(Icons.inventory_2_outlined, 'Archived people', null, () => context.push('/archived')),
          const SizedBox(height: 12),
          const Padding(padding: EdgeInsets.symmetric(horizontal: 12), child: SectionLabel('Coming in later updates')),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Text(
              ''
              'Festivals & Wish Mode · Excel export and backup · Widget and app lock',
              style: context.text.bodySmall,
            ),
          ),
          const SizedBox(height: 24),
          Center(
            child: Text('Smriti · Phase 1', style: context.text.bodySmall?.copyWith(color: c.muted)),
          ),
          Center(
            child: Text('Everything stays on this phone.', style: context.text.bodySmall),
          ),
        ],
      ),
    );
  }
}
