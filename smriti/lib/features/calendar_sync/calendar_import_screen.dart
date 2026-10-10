import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/tokens.dart';
import '../../data/database.dart';
import '../../data/enums.dart';
import '../../data/providers.dart';
import '../../widgets/common.dart';
import 'calendar_import.dart';
import 'calendar_sync.dart';

const _months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];

/// Brings birthdays, anniversaries and other dates in from Google Calendar
/// (or any calendar on the phone). Nothing is saved until you confirm.
class CalendarImportScreen extends ConsumerStatefulWidget {
  const CalendarImportScreen({super.key});

  @override
  ConsumerState<CalendarImportScreen> createState() => _CalendarImportScreenState();
}

class _CalendarImportScreenState extends ConsumerState<CalendarImportScreen> {
  List<ImportGuess>? _guesses;
  String? _problem;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (!await CalendarSync.askPermission()) {
      setState(() => _problem = 'Smriti needs permission to read your calendar. Tap below to allow it.');
      return;
    }
    try {
      final events = await CalendarImport.read();
      final repo = ref.read(repoProvider);
      final guesses = buildGuesses(events, await repo.watchEntries().first, await repo.allPeople());
      if (mounted) setState(() => _guesses = guesses);
    } catch (e) {
      if (mounted) setState(() => _problem = 'Could not read the calendar: $e');
    }
  }

  Future<void> _import() async {
    setState(() => _saving = true);
    final n = await CalendarImport.apply(ref.read(databaseProvider), _guesses!);
    HapticFeedback.lightImpact();
    if (!mounted) return;
    showToast(context, n == 1 ? 'Added 1 date' : 'Added $n dates');
    Navigator.pop(context);
  }

  Future<void> _rename(ImportGuess g) async {
    final t = TextEditingController(text: g.kind == GuessKind.other ? g.title : g.names.join(' & '));
    final v = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(g.kind == GuessKind.other ? 'Title' : 'Whose ${g.kind.label.toLowerCase()}?'),
        content: TextField(
          controller: t,
          autofocus: true,
          textCapitalization: TextCapitalization.words,
          decoration: InputDecoration(
              helperText: g.kind == GuessKind.anniversary ? 'For a couple, write both names with &' : null),
          onSubmitted: (v) => Navigator.pop(ctx, v),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(ctx, t.text), child: const Text('Save')),
        ],
      ),
    );
    if (v == null || v.trim().isEmpty) return;
    setState(() {
      g.forMe = false;
      if (g.kind == GuessKind.other) {
        g.title = v.trim();
      } else {
        g.names = v.split('&').map((s) => s.trim()).where((s) => s.isNotEmpty).take(2).toList();
      }
      _recheck(g);
    });
  }

  void _setKind(ImportGuess g, GuessKind k) {
    setState(() {
      if (g.kind == k) return;
      if (k != GuessKind.other && g.names.isEmpty && !g.forMe) g.names = [g.title];
      g.kind = k;
      _recheck(g);
    });
  }

  void _recheck(ImportGuess g) {
    final people = ref.read(peopleProvider).value ?? const <Person>[];
    final entries = ref.read(entriesProvider).value ?? const [];
    g.duplicate = isDuplicate(g, entries, people, people.where((p) => p.isMe).firstOrNull);
    if (g.duplicate) g.selected = false;
  }

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final guesses = _guesses;
    final chosen = guesses?.where((g) => g.selected).length ?? 0;
    return Scaffold(
      appBar: AppBar(title: const Text('Import from calendar')),
      body: _problem != null
          ? Center(
              child: EmptyState(
                title: 'Calendar not available',
                message: _problem!,
                actionLabel: 'Try again',
                onAction: () {
                  setState(() => _problem = null);
                  _load();
                },
              ),
            )
          : guesses == null
              ? const Center(child: CircularProgressIndicator())
              : guesses.isEmpty
                  ? const Center(
                      child: EmptyState(
                        title: 'Nothing to import',
                        message: 'No yearly or monthly events, or upcoming all-day dates, were found in the '
                            'calendars on this phone.',
                      ),
                    )
                  : ListView(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 120),
                      children: [
                        Text(
                          'Found in Google Calendar and other calendars on this phone. Tick what to add; tap a '
                          'name to correct it, or the label to change what kind of day it is. Holidays and dates '
                          'already in Smriti are left out.',
                          style: context.text.bodySmall,
                        ),
                        const SizedBox(height: 8),
                        Row(children: [
                          TextButton(
                            onPressed: () => setState(() {
                              for (final g in guesses) {
                                g.selected = !g.duplicate;
                              }
                            }),
                            child: const Text('Select all'),
                          ),
                          TextButton(
                            onPressed: () => setState(() {
                              for (final g in guesses) {
                                g.selected = false;
                              }
                            }),
                            child: const Text('Clear'),
                          ),
                        ]),
                        for (final g in guesses) _row(context, g, c),
                      ],
                    ),
      bottomNavigationBar: guesses == null || guesses.isEmpty
          ? null
          : SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                child: FilledButton(
                  onPressed: chosen == 0 || _saving ? null : _import,
                  child: Text(_saving ? 'Adding…' : (chosen == 0 ? 'Tick the dates to add' : 'Add $chosen dates')),
                ),
              ),
            ),
    );
  }

  Widget _row(BuildContext context, ImportGuess g, SmritiColors c) {
    final color = switch (g.kind) {
      GuessKind.birthday => groupColor(EventGroup.birthday),
      GuessKind.anniversary => groupColor(EventGroup.anniversary),
      GuessKind.other => groupColor(EventGroup.important),
    };
    final when = '${g.day} ${_months[g.month - 1]}${g.year != null && g.kind == GuessKind.birthday ? ' ${g.year}' : ''}';
    final repeat = switch (g.repeat) {
      Repeat.yearly => 'every year',
      Repeat.monthly => 'every month',
      Repeat.once => '${g.event.year}',
    };
    return Opacity(
      opacity: g.duplicate ? 0.5 : 1,
      child: Card(
        margin: const EdgeInsets.only(bottom: 8),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(4, 8, 12, 8),
          child: Row(children: [
            Checkbox(
              value: g.selected,
              onChanged: g.duplicate ? null : (v) => setState(() => g.selected = v ?? false),
            ),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                InkWell(
                  onTap: () => _rename(g),
                  child: Row(children: [
                    Flexible(
                      child: Text(g.display,
                          style: context.text.titleMedium, maxLines: 1, overflow: TextOverflow.ellipsis),
                    ),
                    const SizedBox(width: 4),
                    Icon(Icons.edit_outlined, size: 14, color: c.muted),
                  ]),
                ),
                const SizedBox(height: 4),
                Row(children: [
                  PopupMenuButton<GuessKind>(
                    tooltip: 'What kind of day',
                    onSelected: (k) => _setKind(g, k),
                    itemBuilder: (_) => [for (final k in GuessKind.values) PopupMenuItem(value: k, child: Text(k.label))],
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.18),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Row(mainAxisSize: MainAxisSize.min, children: [
                        Text(g.kind.label,
                            style: TextStyle(fontFamily: sans, fontSize: 11, fontWeight: FontWeight.w700, color: color)),
                        Icon(Icons.arrow_drop_down_rounded, size: 16, color: color),
                      ]),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text('$when · $repeat',
                        style: context.text.bodySmall, maxLines: 1, overflow: TextOverflow.ellipsis),
                  ),
                ]),
                const SizedBox(height: 2),
                Text(
                  g.duplicate
                      ? 'Already in Smriti'
                      : (g.title == g.display ? g.event.calendar : '“${g.title}” · ${g.event.calendar}'),
                  style: context.text.bodySmall?.copyWith(color: c.muted, fontSize: 11),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ]),
            ),
          ]),
        ),
      ),
    );
  }
}
