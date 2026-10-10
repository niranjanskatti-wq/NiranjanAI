import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/tokens.dart';
import '../../data/database.dart';
import '../../data/enums.dart';
import '../../data/models.dart';
import '../../data/providers.dart';
import '../../widgets/common.dart';
import 'notification_service.dart';
import 'reminder_model.dart';

final remindersForProvider = StreamProvider.family<List<ReminderSpec>, int>(
    (ref, id) => ref.watch(repoProvider).watchReminders(id).map((l) => l.map(ReminderSpec.fromRow).toList()));

/// eventId → reminders, for bell icons in lists.
final allRemindersProvider = StreamProvider<Map<int, List<ReminderSpec>>>((ref) =>
    ref.watch(repoProvider).watchAllReminders().map((rows) {
      final m = <int, List<ReminderSpec>>{};
      for (final r in rows) {
        m.putIfAbsent(r.eventId, () => []).add(ReminderSpec.fromRow(r));
      }
      return m;
    }));

Future<int?> pickMinute(BuildContext context, int minute) async {
  final t = await showTimePicker(context: context, initialTime: TimeOfDay(hour: minute ~/ 60, minute: minute % 60));
  return t == null ? null : t.hour * 60 + t.minute;
}

/// One page of simple switches and times for an event's reminders.
class RemindersScreen extends ConsumerStatefulWidget {
  const RemindersScreen({super.key, required this.eventId});

  final int eventId;

  @override
  ConsumerState<RemindersScreen> createState() => _RemindersScreenState();
}

class _RemindersScreenState extends ConsumerState<RemindersScreen> {
  List<ReminderSpec>? _specs;

  Future<void> _save(List<ReminderSpec> specs) async {
    setState(() => _specs = specs);
    await ref.read(repoProvider).setReminders(widget.eventId, specs);
    if (specs.any((s) => s.enabled)) await _ensurePermissions();
  }

  Future<void> _ensurePermissions() async {
    if (!NotificationService.supported) return;
    if (!await NotificationService.notificationsEnabled()) await NotificationService.requestNotifications();
    if (!await NotificationService.exactAllowed()) await NotificationService.requestExact();
  }

  ReminderSpec? _find(ReminderKind k) => _specs!.where((s) => s.kind == k).firstOrNull;

  void _toggle(ReminderKind k, bool on, {int minute = 480, int days = 0}) {
    final list = [..._specs!];
    list.removeWhere((s) => s.kind == k);
    if (on) list.add(ReminderSpec(k, minute: minute, daysBefore: days));
    _save(list);
  }

  void _replace(ReminderSpec old, ReminderSpec next) {
    final list = [..._specs!];
    final i = list.indexOf(old);
    if (i >= 0) list[i] = next;
    _save(list);
  }

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final entry = ref.watch(entryProvider(widget.eventId)).value;
    final loaded = ref.watch(remindersForProvider(widget.eventId)).value;
    _specs ??= loaded;
    if (entry == null || _specs == null) return const Scaffold();
    final e = entry.event;
    final specs = _specs!;
    final morning = _find(ReminderKind.morning);
    final onDay = specs.where((s) => s.kind == ReminderKind.custom).toList()..sort((a, b) => a.minute.compareTo(b.minute));
    final midnight = _find(ReminderKind.midnight);
    final gift = _find(ReminderKind.gift);
    final before = specs.where((s) => s.kind == ReminderKind.daysBefore).toList()
      ..sort((a, b) => b.daysBefore.compareTo(a.daysBefore));
    final person = entry.people.where((p) => !p.isMe).firstOrNull;
    final abroad = person?.timeZone != null;
    final sound = AlarmSound.parse(e.sound);

    Widget timeChip(int minute, ValueChanged<int> set) => ActionChip(
          label: Text(fmtMinute(minute), style: const TextStyle(fontFeatures: [FontFeature.tabularFigures()])),
          onPressed: () async {
            final m = await pickMinute(context, minute);
            if (m != null) set(m);
          },
        );

    return Scaffold(
      appBar: AppBar(title: const Text('Reminders')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 40),
        children: [
          Text('${entry.title} · ${entry.typeLabel}', style: context.text.bodySmall),
          const SizedBox(height: 12),
          Card(
            child: Column(children: [
              SwitchListTile(
                title: const Text('Midnight alarm'),
                subtitle: const Text('Full screen at 11:59:50 PM, 10-second tick-tock, chime at 12:00'),
                value: midnight != null,
                onChanged: (v) => _toggle(ReminderKind.midnight, v),
              ),
              if (midnight != null && abroad)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                  child: SegmentedButton<String>(
                    showSelectedIcon: false,
                    segments: [
                      const ButtonSegment(value: 'mine', label: Text('My midnight')),
                      ButtonSegment(value: 'theirs', label: Text('${person!.shortName}\'s midnight')),
                    ],
                    selected: {e.alarmClock},
                    onSelectionChanged: (s) => ref
                        .read(repoProvider)
                        .updateEvent(e.id, EventsCompanion(alarmClock: Value(s.first))),
                  ),
                ),
              const Divider(),
              SwitchListTile(
                title: const Text('Morning reminder'),
                subtitle: const Text('On the day'),
                value: morning != null,
                onChanged: (v) => _toggle(ReminderKind.morning, v, minute: 480),
                secondary: morning == null ? null : timeChip(morning.minute, (m) => _replace(morning, morning.copyWith(minute: m))),
              ),
              const Divider(),
              ListTile(
                title: const Text('More times on the day'),
                subtitle: Text(onDay.isEmpty ? 'Add as many as you like' : '${onDay.length} more'),
                trailing: TextButton.icon(
                  onPressed: () async {
                    final m = await pickMinute(context, 1080);
                    if (m != null && !onDay.any((s) => s.minute == m)) {
                      _save([...specs, ReminderSpec(ReminderKind.custom, minute: m)]);
                    }
                  },
                  icon: const Icon(Icons.add_rounded, size: 18),
                  label: const Text('Add'),
                ),
              ),
              for (final s in onDay)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 4, 0),
                  child: Row(children: [
                    Icon(Icons.notifications_active_outlined, size: 18, color: c.muted),
                    const SizedBox(width: 10),
                    Expanded(child: Text('On the day', style: context.text.titleSmall)),
                    timeChip(s.minute, (m) => _replace(s, s.copyWith(minute: m))),
                    IconButton(
                      tooltip: 'Remove',
                      onPressed: () => _save([...specs]..remove(s)),
                      icon: Icon(Icons.close_rounded, color: c.muted),
                    ),
                  ]),
                ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                child: Wrap(spacing: 6, runSpacing: 6, children: [
                  for (final (m, label) in const [(360, '6 AM'), (720, '12 PM'), (1080, '6 PM'), (1260, '9 PM')])
                    if (!onDay.any((s) => s.minute == m) && morning?.minute != m)
                      ActionChip(
                        label: Text('+ $label'),
                        onPressed: () => _save([...specs, ReminderSpec(ReminderKind.custom, minute: m)]),
                      ),
                ]),
              ),
            ]),
          ),
          const SizedBox(height: 12),
          InfoCard(
            title: 'Before the day',
            trailing: TextButton.icon(
              onPressed: () async {
                final days = await _askDays(context, 'Remind me how many days before?', 3);
                if (days != null) _save([...specs, ReminderSpec(ReminderKind.daysBefore, daysBefore: days, minute: 540)]);
              },
              icon: const Icon(Icons.add_rounded, size: 18),
              label: const Text('Add'),
            ),
            children: [
              if (before.isEmpty) Text('Add 1, 3, 7 or any number of days before.', style: context.text.bodyMedium),
              for (final s in before)
                Row(children: [
                  Expanded(
                    child: Text('${s.daysBefore} day${s.daysBefore == 1 ? '' : 's'} before',
                        style: context.text.titleMedium),
                  ),
                  timeChip(s.minute, (m) => _replace(s, s.copyWith(minute: m))),
                  IconButton(
                    tooltip: 'Remove',
                    onPressed: () => _save([...specs]..remove(s)),
                    icon: Icon(Icons.close_rounded, color: c.muted),
                  ),
                ]),
              Wrap(spacing: 6, children: [
                for (final d in [1, 3, 7])
                  if (!before.any((s) => s.daysBefore == d))
                    ActionChip(
                      label: Text('+ $d day${d == 1 ? '' : 's'}'),
                      onPressed: () => _save([...specs, ReminderSpec(ReminderKind.daysBefore, daysBefore: d, minute: 540)]),
                    ),
              ]),
            ],
          ),
          if (entry.kind != EventKind.other) ...[
            const SizedBox(height: 12),
            Card(
              child: SwitchListTile(
                title: const Text('Gift reminder'),
                subtitle: Text(gift == null ? 'A nudge to buy the gift' : '${gift.daysBefore} days before at ${fmtMinute(gift.minute)}'),
                value: gift != null,
                onChanged: (v) => _toggle(ReminderKind.gift, v, minute: 600, days: 7),
                secondary: gift == null
                    ? null
                    : ActionChip(
                        label: Text('${gift.daysBefore} days'),
                        onPressed: () async {
                          final d = await _askDays(context, 'Gift reminder: days before', gift.daysBefore);
                          if (d != null) _replace(gift, gift.copyWith(daysBefore: d));
                        },
                      ),
              ),
            ),
            const SizedBox(height: 12),
            Card(
              child: SwitchListTile(
                title: const Text('Belated nudge'),
                subtitle: const Text('If not marked as wished, remind me the next morning'),
                value: e.belatedNudge,
                onChanged: (v) => ref.read(repoProvider).updateEvent(e.id, EventsCompanion(belatedNudge: Value(v))),
              ),
            ),
          ],
          const SizedBox(height: 12),
          Card(
            child: ListTile(
              leading: const Icon(Icons.music_note_outlined),
              title: const Text('Sound'),
              subtitle: Text(sound.label),
              trailing: const Icon(Icons.chevron_right_rounded),
              onTap: () async {
                final s = await pickSound(context, sound);
                if (s != null) await ref.read(repoProvider).updateEvent(e.id, EventsCompanion(sound: Value(s.name)));
              },
            ),
          ),
          const SizedBox(height: 20),
          const SectionLabel('Shortcuts'),
          OutlinedButton.icon(
            onPressed: () => _applyTo(context, entry),
            icon: const Icon(Icons.copy_all_outlined),
            label: const Text('Apply these reminders to…'),
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: () => _copyFrom(context, entry),
            icon: const Icon(Icons.download_outlined),
            label: const Text('Copy reminders from another person'),
          ),
          const SizedBox(height: 16),
          Text('Stars never change reminders. Every event gets exactly what you switch on here.',
              style: context.text.bodySmall, textAlign: TextAlign.center),
        ],
      ),
    );
  }

  Future<int?> _askDays(BuildContext context, String title, int initial) async {
    final t = TextEditingController(text: '$initial');
    final v = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: TextField(
          controller: t,
          autofocus: true,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(suffixText: 'days'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(ctx, t.text), child: const Text('OK')),
        ],
      ),
    );
    final n = int.tryParse(v ?? '');
    return n == null || n < 1 || n > 365 ? null : n;
  }

  /// Copies this event's reminders to the same kind of event for chosen people.
  Future<void> _applyTo(BuildContext context, EventEntry entry) async {
    final all = ref.read(entriesProvider).value ?? const <EventEntry>[];
    final same = all.where((x) => x.event.id != entry.event.id && x.type == entry.type).toList();
    if (same.isEmpty) {
      showToast(context, 'No other ${entry.typeLabel.toLowerCase()}s yet');
      return;
    }
    final chosen = <int>{...same.map((x) => x.event.id)};
    final ok = await showModalBottomSheet<bool>(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => SafeArea(
          child: SizedBox(
            height: MediaQuery.of(ctx).size.height * 0.75,
            child: Column(children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 4),
                child: Row(children: [
                  Expanded(child: Text('Apply to ${entry.typeLabel.toLowerCase()}s', style: ctx.text.headlineSmall)),
                  TextButton(
                    onPressed: () => setS(() => chosen.length == same.length
                        ? chosen.clear()
                        : chosen.addAll(same.map((x) => x.event.id))),
                    child: Text(chosen.length == same.length ? 'None' : 'Everyone'),
                  ),
                ]),
              ),
              Expanded(
                child: ListView(children: [
                  for (final x in same)
                    CheckboxListTile(
                      value: chosen.contains(x.event.id),
                      onChanged: (v) => setS(() => v! ? chosen.add(x.event.id) : chosen.remove(x.event.id)),
                      title: Text(x.title),
                      subtitle: Text(x.relationLine),
                    ),
                ]),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: FilledButton(
                  onPressed: () => Navigator.pop(ctx, true),
                  child: Text('Apply to ${chosen.length}'),
                ),
              ),
            ]),
          ),
        ),
      ),
    );
    if (ok != true || chosen.isEmpty) return;
    await ref.read(repoProvider).setRemindersForMany(chosen, _specs!);
    if (context.mounted) showToast(context, 'Applied to ${chosen.length}');
  }

  Future<void> _copyFrom(BuildContext context, EventEntry entry) async {
    final all = ref.read(entriesProvider).value ?? const <EventEntry>[];
    final others = all.where((x) => x.event.id != entry.event.id && x.kind != EventKind.other).toList();
    final chosen = await showModalBottomSheet<EventEntry>(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      builder: (ctx) => SafeArea(
        child: SizedBox(
          height: MediaQuery.of(ctx).size.height * 0.7,
          child: ListView(children: [
            for (final x in others)
              ListTile(
                title: Text(x.title),
                subtitle: Text(x.typeLabel),
                onTap: () => Navigator.pop(ctx, x),
              ),
          ]),
        ),
      ),
    );
    if (chosen == null) return;
    final specs = await ref.read(repoProvider).remindersFor(chosen.event.id);
    await _save(specs);
    if (context.mounted) showToast(context, 'Copied from ${chosen.title}');
  }
}

Future<AlarmSound?> pickSound(BuildContext context, AlarmSound current) => showModalBottomSheet<AlarmSound>(
      context: context,
      useRootNavigator: true,
      builder: (ctx) => SafeArea(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          for (final s in AlarmSound.values)
            ListTile(
              leading: Icon(s == current ? Icons.radio_button_checked : Icons.radio_button_off, color: ctx.c.goldText),
              title: Text(s.label),
              trailing: s == AlarmSound.vibrate
                  ? null
                  : IconButton(
                      tooltip: 'Preview',
                      icon: const Icon(Icons.play_circle_outline),
                      onPressed: () => NotificationService.preview(s),
                    ),
              onTap: () => Navigator.pop(ctx, s),
            ),
          const SizedBox(height: 8),
        ]),
      ),
    );
