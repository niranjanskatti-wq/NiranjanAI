import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/tokens.dart';
import '../../core/util/format.dart';
import '../../core/util/occurrence.dart';
import '../../data/enums.dart';
import '../../data/providers.dart';
import '../../widgets/common.dart';
import '../../widgets/pickers.dart';
import '../messages/library_screen.dart';
import 'festival_model.dart';

/// All festivals: switch on/off, see the next date, add your own.
class FestivalsScreen extends ConsumerWidget {
  const FestivalsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.c;
    final today = ref.watch(todayProvider).value ?? Day.today();
    final all = ref.watch(festivalsProvider);
    final repo = FestivalRepo(ref.read(databaseProvider));
    final sorted = [...all]..sort((a, b) {
        final da = a.nextFrom(today), db = b.nextFrom(today);
        if (da == null) return 1;
        if (db == null) return -1;
        return da.compareTo(db);
      });
    return Scaffold(
      appBar: AppBar(title: const Text('Festivals')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => addFestival(context, ref),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Add my own festival'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
        children: [
          Text('Dates follow the Mahalakshmi calendar system. Switched-on festivals appear on Home with a '
              'countdown and a reminder on the day.', style: context.text.bodySmall),
          const SizedBox(height: 12),
          for (final f in sorted)
            Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                leading: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: f.enabled ? groupColor(EventGroup.festival) : c.raised,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.celebration_outlined, color: f.enabled ? Colors.white : c.muted),
                ),
                title: Text(f.name),
                subtitle: Text([
                  if (f.nextFrom(today) case final d?) '${fmtWeekday(d)} · ${relativeDays(today.daysUntil(d))}'
                  else 'No upcoming date',
                  if (f.custom) 'Yours',
                  if (f.editedYears.isNotEmpty) 'Date edited',
                ].join(' · ')),
                trailing: Switch(value: f.enabled, onChanged: (v) => repo.setEnabled(f, v)),
                onTap: () => context.push('/festival?key=${Uri.encodeQueryComponent(f.key)}'),
              ),
            ),
        ],
      ),
    );
  }
}

/// Add your own festival or special day.
Future<void> addFestival(BuildContext context, WidgetRef ref) async {
  final name = TextEditingController();
  var yearly = true;
  DateParts? date;
  final ok = await showDialog<bool>(
    context: context,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setD) => AlertDialog(
        title: const Text('Add a festival'),
        content: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          TextField(
            controller: name,
            autofocus: true,
            textCapitalization: TextCapitalization.words,
            decoration: const InputDecoration(labelText: 'Name', hintText: 'e.g. Village jatre'),
          ),
          const SizedBox(height: 12),
          SegmentedButton<bool>(
            showSelectedIcon: false,
            segments: const [
              ButtonSegment(value: true, label: Text('Same date yearly')),
              ButtonSegment(value: false, label: Text('Changes yearly')),
            ],
            selected: {yearly},
            onSelectionChanged: (s) => setD(() => yearly = s.first),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: () async {
              final d = await pickDate(ctx, initial: date, yearRequired: !yearly, allowYear: !yearly, title: 'Date');
              if (d != null) setD(() => date = d);
            },
            icon: const Icon(Icons.calendar_today_outlined),
            label: Text(date == null ? 'Pick date' : fmtEventDate(day: date!.day, month: date!.month, year: date!.year)),
          ),
          if (!yearly)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text('You can add more years on the festival page.', style: ctx.text.bodySmall),
            ),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(
            onPressed: name.text.trim().isEmpty || date == null ? null : () => Navigator.pop(ctx, true),
            child: const Text('Add'),
          ),
        ],
      ),
    ),
  );
  if (ok != true || date == null) return;
  final d = date!;
  await FestivalRepo(ref.read(databaseProvider)).addCustom(
    name: name.text.trim(),
    month: yearly ? d.month : null,
    day: yearly ? d.day : null,
    dates: yearly ? const {} : {d.year!: Day(d.year!, d.month, d.day)},
  );
  if (context.mounted) showToast(context, 'Added ${name.text.trim()}');
}

/// One festival: start Wish Mode, switch on/off, fix dates, rename, who to suggest.
class FestivalScreen extends ConsumerWidget {
  const FestivalScreen({super.key, required this.festivalKey});

  final String festivalKey;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.c;
    final f = ref.watch(festivalsProvider).where((x) => x.key == festivalKey).firstOrNull;
    if (f == null) return Scaffold(appBar: AppBar());
    final repo = FestivalRepo(ref.read(databaseProvider));
    final today = ref.watch(todayProvider).value ?? Day.today();
    final next = f.nextFrom(today);
    final years = f.dates.keys.toList()..sort();
    return Scaffold(
      appBar: AppBar(
        title: Text(f.name),
        actions: [
          IconButton(
            tooltip: 'Rename',
            icon: const Icon(Icons.edit_outlined),
            onPressed: () async {
              final t = TextEditingController(text: f.name);
              final n = await showDialog<String>(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('Rename'),
                  content: TextField(controller: t, autofocus: true),
                  actions: [
                    TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
                    TextButton(onPressed: () => Navigator.pop(ctx, t.text), child: const Text('Save')),
                  ],
                ),
              );
              if (n != null && n.trim().isNotEmpty) await repo.setName(f, n.trim());
            },
          ),
          if (f.custom)
            IconButton(
              tooltip: 'Delete',
              icon: Icon(Icons.delete_outline, color: c.alert),
              onPressed: () async {
                if (!await confirm(context, title: 'Delete ${f.name}?', message: 'This removes your festival.', action: 'Delete', danger: true)) {
                  return;
                }
                await repo.deleteCustom(f);
                if (context.mounted) context.pop();
              },
            ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 40),
        children: [
          if (next != null) ...[
            Text(fmtWeekday(next), style: context.text.headlineMedium),
            Text(relativeDays(today.daysUntil(next)), style: context.text.bodySmall),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: () => context.push('/wish-mode/new?festival=${Uri.encodeQueryComponent(f.key)}'),
              icon: const Icon(Icons.auto_awesome),
              label: const Text('Start Wish Mode'),
            ),
          ],
          if (f.note.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(f.note, style: context.text.bodySmall),
          ],
          const SizedBox(height: 8),
          Card(
            child: SwitchListTile(
              title: const Text('Show on Home and remind me'),
              value: f.enabled,
              onChanged: (v) => repo.setEnabled(f, v),
            ),
          ),
          const SizedBox(height: 12),
          InfoCard(
            title: 'Suggest in Wish Mode',
            children: [
              Wrap(spacing: 6, runSpacing: 6, children: [
                FilterChip(
                  label: const Text('Everyone'),
                  selected: f.suggest.isEmpty || f.suggest.contains('all'),
                  showCheckmark: false,
                  onSelected: (_) => repo.setSuggest(f, const ['all']),
                ),
                for (final r in [...relationFilters.keys, 'mentor'])
                  FilterChip(
                    label: Text(relationFilters[r] ?? 'Mentor'),
                    selected: f.suggest.contains(r) ||
                        f.suggest.any((s) => Relationship.values.any((x) => x.name == s && relationFilterFor(x) == r)),
                    showCheckmark: false,
                    onSelected: (v) {
                      final l = f.suggest.where((s) => s != 'all').toList();
                      v ? l.add(r) : l.remove(r);
                      repo.setSuggest(f, l);
                    },
                  ),
              ]),
            ],
          ),
          const SizedBox(height: 12),
          if (f.month != null)
            Card(
              child: ListTile(
                title: const Text('Every year on'),
                subtitle: Text(fmtEventDate(day: f.day!, month: f.month!)),
                trailing: const Icon(Icons.edit_calendar_outlined),
                onTap: () async {
                  final d = await pickDate(context, initial: DateParts(f.day!, f.month!), allowYear: false);
                  if (d != null) await repo.setYearlyDate(f, d.month, d.day);
                },
              ),
            )
          else
            InfoCard(
              title: 'Dates by year',
              trailing: f.custom
                  ? TextButton.icon(
                      onPressed: () async {
                        final d = await pickDate(context, yearRequired: true, title: 'Add a year');
                        if (d != null) await repo.setDate(f, d.year!, Day(d.year!, d.month, d.day));
                      },
                      icon: const Icon(Icons.add_rounded, size: 18),
                      label: const Text('Add'),
                    )
                  : null,
              children: [
                for (final y in years)
                  Row(children: [
                    SizedBox(width: 52, child: Text('$y', style: context.text.titleSmall)),
                    Expanded(
                      child: Text(fmtWeekday(f.dates[y]!),
                          style: context.text.bodyMedium?.copyWith(
                            fontWeight: f.editedYears.contains(y) ? FontWeight.w700 : null,
                            color: y < today.year ? c.muted : c.text,
                          )),
                    ),
                    if (f.editedYears.contains(y))
                      TextButton(onPressed: () => repo.setDate(f, y, null), child: const Text('Reset')),
                    IconButton(
                      tooltip: 'Change $y date',
                      icon: const Icon(Icons.edit_calendar_outlined, size: 20),
                      onPressed: () async {
                        final cur = f.dates[y]!;
                        final d = await pickDate(context,
                            initial: DateParts(cur.day, cur.month, y), yearRequired: true, title: '${f.name} $y');
                        if (d != null) await repo.setDate(f, y, Day(d.year!, d.month, d.day));
                      },
                    ),
                  ]),
                if (!f.custom)
                  Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text('Changed dates are shown in bold. "Reset" puts back the calendar date.',
                        style: context.text.bodySmall),
                  ),
              ],
            ),
        ],
      ),
    );
  }
}

/// The library family a relationship belongs to (e.g. sister → sibling).
String relationFilterFor(Relationship r) => switch (r) {
      Relationship.father || Relationship.mother => 'parent',
      Relationship.wife || Relationship.husband => 'spouse',
      Relationship.son || Relationship.daughter => 'child',
      Relationship.brother || Relationship.sister => 'sibling',
      Relationship.grandfather || Relationship.grandmother => 'grandparent',
      Relationship.uncle || Relationship.aunt || Relationship.inLaw => 'elder',
      Relationship.niece || Relationship.nephew => 'young',
      Relationship.cousin => 'cousin',
      Relationship.colleague || Relationship.boss || Relationship.client || Relationship.mentor => 'work',
      _ => 'friend',
    };
