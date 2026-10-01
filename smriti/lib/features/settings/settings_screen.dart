import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:home_widget/home_widget.dart';
import 'package:go_router/go_router.dart';

import '../autocall/auto_call.dart';
import '../home/home_screen.dart';
import '../lock/app_lock.dart';
import '../autosms/auto_sms.dart';
import '../highlight/highlight.dart';
import '../messages/message_engine.dart' show AgeInWishes, AgeLines, MessageContext;
import '../wish/share_sheet.dart' show ageInWishesProvider;
import '../widget/home_widget_service.dart';
import '../widget/widget_glow.dart';
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
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Text('Text size', style: context.text.titleSmall),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Wrap(spacing: 8, runSpacing: 8, children: [
              for (final t in AppTextSize.values)
                ChoiceChip(
                  label: Text(t.short, style: TextStyle(fontSize: 13 * t.scale)),
                  selected: t == (ref.watch(appTextSizeProvider).value ?? AppTextSize.m),
                  onSelected: (_) => db.setSetting('appTextSize', t.name),
                ),
            ]),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 6, 12, 0),
            child: Text(
                'Letters on Home and every other page: '
                '${(ref.watch(appTextSizeProvider).value ?? AppTextSize.m).label.toLowerCase()}',
                style: context.text.bodySmall?.copyWith(color: c.muted)),
          ),
          const SizedBox(height: 8),
          tile(Icons.auto_awesome_rounded, 'Highlight coming dates',
              (ref.watch(highlightProvider).value ?? const HighlightPrefs()).on
                  ? '${(ref.watch(highlightProvider).value ?? const HighlightPrefs()).style.label} · '
                      '${(ref.watch(highlightProvider).value ?? const HighlightPrefs()).window.label.toLowerCase()}'
                  : 'Off',
              () => context.push('/highlight')),          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Text('Home top card', style: context.text.titleSmall),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: SegmentedButton<HeroSize>(
              showSelectedIcon: false,
              segments: [for (final h in HeroSize.values) ButtonSegment(value: h, label: Text(h.label))],
              selected: {ref.watch(heroSizeProvider).value ?? HeroSize.big},
              onSelectionChanged: (s) => db.setSetting('homeHero', s.first.name),
            ),
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Text('List rows', style: context.text.titleSmall),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: SegmentedButton<RowSize>(
              showSelectedIcon: false,
              segments: [for (final r in RowSize.values) ButtonSegment(value: r, label: Text(r.label))],
              selected: {ref.watch(rowSizeProvider).value ?? RowSize.normal},
              onSelectionChanged: (s) => db.setSetting('rowSize', s.first.name),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 6, 12, 0),
            child: Text('Compact fits more dates on Home, Calendar and profiles.',
                style: context.text.bodySmall?.copyWith(color: c.muted)),
          ),
          const SizedBox(height: 12),
          const Padding(padding: EdgeInsets.symmetric(horizontal: 12), child: SectionLabel('Wishes')),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Text('Add the age or years to messages', style: context.text.titleSmall),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: SegmentedButton<AgeInWishes>(
              showSelectedIcon: false,
              segments: [for (final a in AgeInWishes.values) ButtonSegment(value: a, label: Text(a.label))],
              selected: {ref.watch(ageInWishesProvider).value ?? AgeInWishes.start},
              onSelectionChanged: (s) => db.setSetting('ageInWishes', s.first.name),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 6, 12, 0),
            child: Text(
                'e.g. "Happy 60th birthday, Appa! 🎂" or "Happy 25th anniversary! 25 beautiful years together 💞". '
                'You can still switch it off for one wish. Dates without a year show "Add age" when you wish.',
                style: context.text.bodySmall?.copyWith(color: c.muted)),
          ),
          const _AgeLineTile(birthday: true),
          const _AgeLineTile(birthday: false),
          const SizedBox(height: 12),
          const Padding(padding: EdgeInsets.symmetric(horizontal: 12), child: SectionLabel('Festivals')),
          tile(Icons.celebration_outlined, 'Festivals', 'Switch on or off, edit dates, add your own',
              () => context.push('/festivals')),
          tile(Icons.tune_rounded, 'What Home shows', 'Hide festivals or bills to see only your people',
              () => showWhatToShow(context)),
          const FestivalReminderSwitches(),
          const SizedBox(height: 12),
          const ReminderSettingsSection(),
          const SizedBox(height: 12),
          const Padding(padding: EdgeInsets.symmetric(horizontal: 12), child: SectionLabel('Contacts')),
          tile(Icons.group_add_outlined, 'Add many from contacts', 'Tick several people, then add their dates',
              () => context.push('/import/contacts')),
          tile(Icons.cake_outlined, 'Import birthdays from contacts', 'Finds dates already saved in your phone',
              () => context.push('/import/birthdays')),
          tile(Icons.event_note_outlined, 'Import from Google Calendar', 'Birthdays, anniversaries and dates saved there',
              () => context.push('/import/calendar')),
          tile(Icons.content_copy_outlined, 'Check for duplicates', 'People saved twice, same-day dates, anniversaries to join as a couple',
              () => context.push('/duplicates')),
          tile(Icons.sync_rounded, 'Check contacts for changed numbers', 'Also happens each time you open Smriti',
              () async {
            await ContactSync(ref.read(repoProvider)).run();
            if (context.mounted) showToast(context, 'Contacts checked');
          }),
          const SizedBox(height: 12),
          const Padding(padding: EdgeInsets.symmetric(horizontal: 12), child: SectionLabel('People')),
          tile(Icons.workspaces_outline, 'Groups', 'Family, Office, College friends…', () => context.push('/groups')),
          tile(Icons.card_giftcard_outlined, 'Gift planner', 'Ideas, budgets and what is still to buy', () => context.push('/gifts')),
          tile(Icons.inventory_2_outlined, 'Archived people', null, () => context.push('/archived')),
          const SizedBox(height: 12),
          const AutoCallSettings(),
          const SizedBox(height: 12),
          const AutoSmsSettings(),
          const SizedBox(height: 12),
          const Padding(padding: EdgeInsets.symmetric(horizontal: 12), child: SectionLabel('Privacy & extras')),
          const _LockSwitch(),
          tile(Icons.event_available_outlined, 'Phone calendar', 'Copy dates into Google Calendar',
              () => context.push('/calendar-sync')),
          tile(Icons.widgets_outlined, 'Home-screen widgets', 'Next up, Countdown, Coming up or Today', () async {
            final supported = await HomeWidget.isRequestPinWidgetSupported() ?? false;
            if (!context.mounted) return;
            if (!supported) {
              showToast(context, 'Long-press your home screen, tap Widgets, then find Smriti');
              return;
            }
            final name = await showModalBottomSheet<String>(
              context: context,
              useRootNavigator: true,
              builder: (ctx) => SafeArea(
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
                    child: Text('Add a widget', style: ctx.text.titleLarge),
                  ),
                  for (final e in HomeWidgetService.styles.entries)
                    ListTile(
                      leading: const Icon(Icons.widgets_outlined),
                      title: Text(e.value.$1),
                      subtitle: Text(e.value.$2),
                      onTap: () => Navigator.pop(ctx, e.key),
                    ),
                  const SizedBox(height: 8),
                ]),
              ),
            );
            if (name != null) await HomeWidget.requestPinWidget(qualifiedAndroidName: name);
          }),
          tile(Icons.flare_rounded, 'Widget size & flash',
              'Text size · flash: ${(ref.watch(widgetGlowProvider).value ?? const WidgetGlow()).summary}',
              () => context.push('/widget-glow')),
          const SizedBox(height: 12),
          const Padding(padding: EdgeInsets.symmetric(horizontal: 12), child: SectionLabel('Backup & Excel')),
          tile(Icons.backup_outlined, 'Backup & restore', 'Automatic every week · Download/Smriti Backups',
              () => context.push('/backup')),
          tile(Icons.table_chart_outlined, 'Export to Excel', 'All events, by month, people, important dates',
              () => context.push('/export')),
          tile(Icons.upload_file_rounded, 'Import from Excel', 'Add many at once, or move to a new phone',
              () => context.push('/import')),
          const SizedBox(height: 24),
          Center(
            child: Text('Smriti 0.1', style: context.text.bodySmall?.copyWith(color: c.muted)),
          ),
          Center(
            child: Text('Everything stays on this phone.', style: context.text.bodySmall),
          ),
        ],
      ),
    );
  }
}

class _LockSwitch extends ConsumerWidget {
  const _LockSwitch();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final on = ref.watch(appLockProvider).value ?? false;
    return SwitchListTile(
      secondary: const Icon(Icons.fingerprint_rounded),
      title: const Text('Fingerprint lock'),
      subtitle: const Text("Your fingerprint or the phone's PIN opens Smriti"),
      value: on,
      onChanged: (v) async {
        if (!await AppLock.available()) {
          if (context.mounted) showToast(context, 'Set up a fingerprint or screen lock on the phone first');
          return;
        }
        final ok = await AppLock.unlock(reason: v ? 'Confirm to switch on the lock' : 'Confirm to switch off the lock');
        if (ok) await ref.read(databaseProvider).setSetting('appLock', '$v');
      },
    );
  }
}

/// Your own wording for the age line; {age_th} and friends are filled in for each person.
class _AgeLineTile extends ConsumerWidget {
  const _AgeLineTile({required this.birthday});
  final bool birthday;

  String get _key => birthday ? 'ageLineBirthday' : 'ageLineAnniversary';
  String get _default => birthday ? AgeLines.birthdayDefault : AgeLines.anniversaryDefault;

  static const _sample = MessageContext(name: '‹name›', nickname: '‹name›', age: 60, yearsMarried: 25);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final db = ref.read(databaseProvider);
    final mine = ref.watch(_settingProvider(_key)).value;
    final own = mine != null && mine.trim().isNotEmpty;
    final text = own ? mine : _default;
    return ListTile(
      leading: Text(birthday ? '🎂' : '💞', style: const TextStyle(fontSize: 22)),
      title: Text(birthday ? 'Birthday line' : 'Anniversary line'),
      subtitle: Text('${_sample.fill(text)}${own ? '  · yours' : ''}'),
      trailing: const Icon(Icons.edit_outlined),
      onTap: () async {
        final ctrl = TextEditingController(text: text);
        final tags = birthday ? ['{age_th}', '{age}', '{nickname}'] : ['{years_th}', '{years_married}', '{couple_names}'];
        final result = await showDialog<String>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: Text(birthday ? 'Your birthday line' : 'Your anniversary line'),
            content: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
              TextField(controller: ctrl, maxLines: 3, autofocus: true, textCapitalization: TextCapitalization.sentences),
              const SizedBox(height: 8),
              Text('Tap to insert:', style: Theme.of(ctx).textTheme.bodySmall),
              Wrap(spacing: 6, children: [
                for (final tag in tags)
                  ActionChip(
                    label: Text(switch (tag) {
                      '{age_th}' => '60th',
                      '{age}' => '60',
                      '{nickname}' => 'name',
                      '{years_th}' => '25th',
                      '{years_married}' => '25',
                      _ => 'couple names',
                    }),
                    onPressed: () {
                      final sel = ctrl.selection;
                      final at = sel.isValid ? sel.start : ctrl.text.length;
                      ctrl.text = ctrl.text.replaceRange(at, sel.isValid ? sel.end : at, tag);
                      ctrl.selection = TextSelection.collapsed(offset: at + tag.length);
                    },
                  ),
              ]),
            ]),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx, ''), child: const Text('Use Smriti\'s')),
              FilledButton(onPressed: () => Navigator.pop(ctx, ctrl.text.trim()), child: const Text('Save')),
            ],
          ),
        );
        if (result == null) return;
        // Empty means Smriti's own line.
        await db.setSetting(_key, result == _default ? '' : result);
      },
    );
  }
}

final _settingProvider = StreamProvider.family<String?, String>((ref, key) => ref.watch(databaseProvider).watchSetting(key));
