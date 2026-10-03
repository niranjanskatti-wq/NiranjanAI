import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/settings.dart';
import '../../core/theme/tokens.dart';
import '../../core/util/format.dart';
import '../../data/database.dart';
import '../../data/providers.dart';
import '../../services/audio.dart';
import '../../ui/widgets.dart';
import '../focus/progress_ring.dart';
import '../tasks/tasks_screen.dart' show ProjectManager;
import 'controls.dart';

class CustomizeSection extends ConsumerStatefulWidget {
  const CustomizeSection({super.key});
  @override
  ConsumerState<CustomizeSection> createState() => _CustomizeSectionState();
}

class _CustomizeSectionState extends ConsumerState<CustomizeSection> {
  final _keys = {for (final k in ['Priorities', 'Time blocks', 'Tasks', 'Focus timer', 'Progress ring', 'Distractions', 'Session close', 'Breaks', 'Sounds', 'Streaks', 'Evening review', 'Weekly review', 'Insights', 'Daily goal']) k: GlobalKey()};
  final presetCtrl = TextEditingController();
  double ringPreview = 0.62;
  String? previewing;

  @override
  void dispose() {
    presetCtrl.dispose();
    if (previewing != null) AmbientPlayer.instance.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(settingsProvider);
    final p = context.pal;
    final ctl = settingsCtl(ref);
    Future<void> reset(String section) => ctl.replace(ctl.current.resetSection(section));
    String off(String m) => s.on(m) ? '' : ' (module off)';
    Widget anchor(String k, Widget child) => KeyedSubtree(key: _keys[k], child: child);

    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Wrap(spacing: 6, runSpacing: 6, children: [
        for (final k in _keys.keys)
          PillChip(label: k, onTap: () {
            final c = _keys[k]!.currentContext;
            if (c != null) Scrollable.ensureVisible(c, duration: const Duration(milliseconds: 350), curve: Curves.easeOutCubic);
          }),
      ]),
      const SizedBox(height: 20),

      anchor('Priorities', SettingsSection(title: 'Top priorities${off('priorities')}', action: ResetButton(label: 'Top priorities', onReset: () => reset('priorities')), children: [
        SettingsRow(label: 'Priorities per day', trailing: Segmented<int>(small: true, value: s.priorityCount, onChanged: (v) => ctl.set('priorities.count', v), options: [for (var i = 1; i <= 5; i++) (i, '$i')])),
        SettingsRow(label: 'Section label', below: CommitField(value: s.priorityLabel, onCommit: (v) => ctl.set('priorities.label', v.trim().isEmpty ? 'Top priorities' : v.trim()))),
      ])),

      anchor('Time blocks', SettingsSection(title: 'Time blocks${off('timeBlocks')}', action: ResetButton(label: 'Time blocks', onReset: () => reset('timeBlocks')), children: [
        SettingsRow(label: 'Day starts', trailing: TimeButton(value: s.s('timeBlocks.dayStart'), onChanged: (v) => ctl.set('timeBlocks.dayStart', v))),
        SettingsRow(
          label: 'Day ends',
          description: timeToMinutes(s.s('timeBlocks.dayEnd')) <= timeToMinutes(s.s('timeBlocks.dayStart')) ? 'Must be after the start time.' : null,
          trailing: TimeButton(value: s.s('timeBlocks.dayEnd'), onChanged: (v) => ctl.set('timeBlocks.dayEnd', v)),
        ),
        SettingsRow(label: 'Block length', trailing: Segmented<int>(small: true, value: s.i('timeBlocks.blockLength'), onChanged: (v) => ctl.set('timeBlocks.blockLength', v), options: const [(15, '15m'), (30, '30m'), (60, '60m')])),
        SwitchRow(label: 'Show on weekends', value: s.b('timeBlocks.showWeekends'), onChanged: (v) => ctl.set('timeBlocks.showWeekends', v)),
      ])),

      anchor('Tasks', SettingsSection(title: 'Tasks${off('tasks')}', action: ResetButton(label: 'Task fields', onReset: () => reset('tasks')), children: [
        const SettingsRow(label: 'Project tags', description: 'Create, rename, recolor or delete.', below: ProjectManager()),
        SettingsRow(
          label: 'Visible fields',
          below: Wrap(spacing: 6, runSpacing: 6, children: [
            for (final f in taskFields.entries)
              PillChip(
                label: f.value,
                active: s.strings('tasks.visibleFields').contains(f.key),
                onTap: () => ctl.edit((m) {
                  final list = (m['tasks']['visibleFields'] as List).cast<String>().toList();
                  list.contains(f.key) ? list.remove(f.key) : list.add(f.key);
                  m['tasks']['visibleFields'] = list;
                }),
              ),
          ]),
        ),
      ])),

      anchor('Focus timer', SettingsSection(title: 'Focus timer', action: ResetButton(label: 'Focus timer', onReset: () => reset('focus')), children: [
        SettingsRow(
          label: 'Presets',
          description: 'Tap × to remove.',
          below: Wrap(spacing: 6, runSpacing: 6, crossAxisAlignment: WrapCrossAlignment.center, children: [
            for (final m in s.presets)
              Container(
                height: 34,
                padding: const EdgeInsets.only(left: 12),
                decoration: BoxDecoration(color: p.card2.withValues(alpha: 0.6), borderRadius: BorderRadius.circular(99), border: Border.all(color: p.border)),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Text('$m min', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, fontFeatures: tabular)),
                  IconButton(
                    visualDensity: VisualDensity.compact,
                    iconSize: 15,
                    tooltip: 'Remove $m minute preset',
                    onPressed: s.presets.length <= 1
                        ? null
                        : () => ctl.edit((mm) {
                              final list = (mm['focus']['presets'] as List).cast<num>().map((e) => e.toInt()).where((e) => e != m).toList();
                              mm['focus']['presets'] = list;
                              if (!list.contains(mm['focus']['defaultDuration'])) mm['focus']['defaultDuration'] = list.first;
                            }),
                    icon: const Icon(Icons.close_rounded),
                  ),
                ]),
              ),
            SizedBox(
              width: 120,
              child: TextField(
                controller: presetCtrl,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(hintText: 'min', suffixIcon: IconButton(icon: const Icon(Icons.add_rounded, size: 18), tooltip: 'Add preset', onPressed: _addPreset)),
                onSubmitted: (_) => _addPreset(),
              ),
            ),
          ]),
        ),
        SettingsRow(
          label: 'Default duration',
          trailing: DropdownButton<int>(
            value: s.presets.contains(s.i('focus.defaultDuration')) ? s.i('focus.defaultDuration') : s.presets.first,
            underline: const SizedBox(),
            items: [for (final m in s.presets) DropdownMenuItem(value: m, child: Text('$m min'))],
            onChanged: (v) => v == null ? null : ctl.set('focus.defaultDuration', v),
          ),
        ),
        SwitchRow(label: 'Allow custom duration', value: s.b('focus.allowCustom'), onChanged: (v) => ctl.set('focus.allowCustom', v)),
        SettingsRow(label: 'Timer mode', trailing: Segmented<String>(small: true, value: s.s('focus.mode'), onChanged: (v) => ctl.set('focus.mode', v), options: const [('countdown', 'Countdown'), ('countup', 'Count-up')])),
        SwitchRow(label: 'Hide seconds', value: s.b('focus.hideSeconds'), onChanged: (v) => ctl.set('focus.hideSeconds', v)),
        SwitchRow(label: 'Require a task', description: 'Off allows untitled sessions.', value: s.b('focus.requireTask'), onChanged: (v) => ctl.set('focus.requireTask', v)),
        SwitchRow(label: 'Keep screen awake', description: 'During sessions and breaks.', value: s.b('focus.wakeLock'), onChanged: (v) => ctl.set('focus.wakeLock', v)),
      ])),

      anchor('Progress ring', SettingsSection(title: 'Progress ring', action: ResetButton(label: 'Progress ring', onReset: () => reset('ring')), children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 14),
          child: Row(children: [
            ProgressRing(
              size: 112,
              progress: ringPreview,
              status: RingStatus.active,
              style: s.s('ring.style'),
              glow: s.b('ring.glow'),
              completionAnimation: false,
              child: Text('${(ringPreview * 100).round()}%', style: const TextStyle(fontWeight: FontWeight.w600, fontFeatures: tabular)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Preview', style: TextStyle(color: p.muted, fontSize: 13)),
                Slider(value: ringPreview, onChanged: (v) => setState(() => ringPreview = v)),
              ]),
            ),
          ]),
        ),
        SettingsRow(label: 'Style', trailing: Segmented<String>(small: true, value: s.s('ring.style'), onChanged: (v) => ctl.set('ring.style', v), options: const [('thin', 'Thin'), ('bold', 'Bold'), ('segmented', 'Segmented')])),
        SwitchRow(label: 'Glow', value: s.b('ring.glow'), onChanged: (v) => ctl.set('ring.glow', v)),
        SwitchRow(label: 'Completion animation', value: s.b('ring.completionAnimation'), onChanged: (v) => ctl.set('ring.completionAnimation', v)),
      ])),

      anchor('Distractions', _ReasonsSection(off: off('distractions'))),

      anchor('Session close', SettingsSection(title: 'Session close${off('sessionClose')}', action: ResetButton(label: 'Session close', onReset: () => reset('sessionClose')), children: [
        SettingsRow(
          label: 'Result options',
          description: 'Which results you can pick.',
          below: Wrap(spacing: 6, children: [
            for (final (k, l) in const [('done', 'Done'), ('partly', 'Partly done'), ('stuck', 'Stuck')])
              PillChip(label: l, active: s.b('sessionClose.results.$k'), onTap: () => ctl.set('sessionClose.results.$k', !s.b('sessionClose.results.$k'))),
          ]),
        ),
        SettingsRow(
          label: '“What did I get done?” note',
          below: Segmented<String>(small: true, value: s.s('sessionClose.note'), onChanged: (v) => ctl.set('sessionClose.note', v), options: const [('required', 'Required'), ('optional', 'Optional'), ('hidden', 'Hidden')]),
        ),
        SwitchRow(label: '“Stuck” next-step prompt', description: 'Ask for the smallest next step and turn it into tasks.', value: s.b('sessionClose.stuckPrompt'), onChanged: (v) => ctl.set('sessionClose.stuckPrompt', v)),
      ])),

      anchor('Breaks', SettingsSection(title: 'Breaks${off('breaks')}', action: ResetButton(label: 'Breaks', onReset: () => reset('breaks')), children: [
        SettingsRow(label: 'Short break', trailing: NumStepper(value: s.i('breaks.short'), min: 1, max: 60, suffix: 'min', onChanged: (v) => ctl.set('breaks.short', v))),
        SettingsRow(label: 'Long break', trailing: NumStepper(value: s.i('breaks.long'), min: 1, max: 120, suffix: 'min', onChanged: (v) => ctl.set('breaks.long', v))),
        SettingsRow(label: 'Long break after', trailing: NumStepper(value: s.i('breaks.longAfter'), min: 1, max: 12, suffix: 'sessions', onChanged: (v) => ctl.set('breaks.longAfter', v))),
        SwitchRow(label: 'Auto-start next session', description: 'Start the next session when a break ends.', value: s.b('breaks.autoStartNext'), onChanged: (v) => ctl.set('breaks.autoStartNext', v)),
      ])),

      anchor('Sounds', SettingsSection(title: 'Ambient sounds${off('ambient')}', action: ResetButton(label: 'Ambient sounds', onReset: () => reset('ambient')), children: [
        for (final e in ambientSounds.entries)
          SettingsRow(
            label: e.value,
            trailing: Row(mainAxisSize: MainAxisSize.min, children: [
              IconBtn(previewing == e.key ? Icons.stop_rounded : Icons.play_arrow_rounded, size: 36, tooltip: previewing == e.key ? 'Stop ${e.value}' : 'Preview ${e.value}', onPressed: () {
                if (previewing == e.key) {
                  AmbientPlayer.instance.stop();
                  setState(() => previewing = null);
                } else {
                  AmbientPlayer.instance.play(e.key, s.d('ambient.volume'));
                  setState(() => previewing = e.key);
                }
              }),
              Switch(
                value: s.strings('ambient.available').contains(e.key),
                onChanged: (v) => ctl.edit((m) {
                  final list = (m['ambient']['available'] as List).cast<String>().toList();
                  v ? list.add(e.key) : list.remove(e.key);
                  m['ambient']['available'] = list;
                }),
              ),
            ]),
          ),
        SettingsRow(
          label: 'Volume',
          below: Slider(value: s.d('ambient.volume'), onChanged: (v) {
            AmbientPlayer.instance.setVolume(v);
            ctl.set('ambient.volume', v);
          }),
        ),
        SwitchRow(label: 'Play by default', description: 'Preselect a sound when starting a session.', value: s.b('ambient.defaultOn'), onChanged: (v) => ctl.set('ambient.defaultOn', v)),
        if (s.b('ambient.defaultOn'))
          SettingsRow(
            label: 'Default sound',
            trailing: DropdownButton<String>(
              value: s.s('ambient.defaultSound'),
              underline: const SizedBox(),
              items: [for (final e in ambientSounds.entries) DropdownMenuItem(value: e.key, child: Text(e.value))],
              onChanged: (v) => v == null ? null : ctl.set('ambient.defaultSound', v),
            ),
          ),
      ])),

      anchor('Streaks', SettingsSection(title: 'Streaks${off('streaks')}', action: ResetButton(label: 'Streaks', onReset: () => reset('streaks')), children: [
        SettingsRow(
          label: 'Rule',
          below: Segmented<String>(small: true, value: s.s('streaks.rule'), onChanged: (v) => ctl.set('streaks.rule', v), options: const [('strict', 'Strict daily'), ('neverMissTwice', 'Never miss twice'), ('weekdays', 'Weekdays only')]),
        ),
        SettingsRow(
          label: 'A day counts when I complete',
          below: Wrap(spacing: 10, runSpacing: 10, crossAxisAlignment: WrapCrossAlignment.center, children: [
            Segmented<String>(
              small: true,
              value: s.s('streaks.countsAs'),
              onChanged: (v) => ctl.edit((m) {
                m['streaks']['countsAs'] = v;
                m['streaks']['amount'] = v == 'minutes' ? 60 : 1;
              }),
              options: const [('session', 'Sessions'), ('minutes', 'Focus minutes'), ('tasks', 'Tasks')],
            ),
            NumStepper(
              value: s.i('streaks.amount'),
              min: 1,
              max: s.s('streaks.countsAs') == 'minutes' ? 600 : 20,
              step: s.s('streaks.countsAs') == 'minutes' ? 15 : 1,
              suffix: s.s('streaks.countsAs') == 'minutes' ? 'min' : s.s('streaks.countsAs') == 'session' ? 'session(s)' : 'task(s)',
              onChanged: (v) => ctl.set('streaks.amount', v),
            ),
          ]),
        ),
      ])),

      anchor('Evening review', SettingsSection(title: 'Evening review${off('eveningReview')}', action: ResetButton(label: 'Evening review', onReset: () => reset('eveningReview')), children: [
        SettingsRow(label: 'Review time', description: 'The review card appears on Today after this time.', trailing: TimeButton(value: s.s('eveningReview.time'), onChanged: (v) => ctl.set('eveningReview.time', v))),
        SettingsRow(
          label: 'Questions',
          below: StringListEditor(items: s.strings('eveningReview.questions'), onChanged: (v) => ctl.set('eveningReview.questions', v), emptyText: 'No questions. The review will show stats and priorities only.'),
        ),
      ])),

      anchor('Weekly review', SettingsSection(title: 'Weekly review${off('weeklyReview')}', action: ResetButton(label: 'Weekly review', onReset: () => reset('weeklyReview')), children: [
        SettingsRow(
          label: 'Day',
          trailing: DropdownButton<int>(
            value: s.i('weeklyReview.day'),
            underline: const SizedBox(),
            items: [for (var i = 0; i < 7; i++) DropdownMenuItem(value: i, child: Text(dayNames[i]))],
            onChanged: (v) => v == null ? null : ctl.set('weeklyReview.day', v),
          ),
        ),
        SettingsRow(label: 'Time', trailing: TimeButton(value: s.s('weeklyReview.time'), onChanged: (v) => ctl.set('weeklyReview.time', v))),
        SettingsRow(label: 'Questions', below: StringListEditor(items: s.strings('weeklyReview.questions'), onChanged: (v) => ctl.set('weeklyReview.questions', v))),
      ])),

      anchor('Insights', SettingsSection(title: 'Insights${off('insights')}', action: ResetButton(label: 'Insights', onReset: () => reset('insights')), children: [
        SettingsRow(
          label: 'Default date range',
          below: Segmented<int>(small: true, value: s.i('insights.defaultRange'), onChanged: (v) => ctl.set('insights.defaultRange', v), options: const [(7, '7d'), (14, '14d'), (30, '30d'), (90, '90d'), (0, 'All')]),
        ),
        SettingsRow(label: 'Visible charts', below: _toggleChips(s, ctl, 'insights.charts', chartOptions)),
        SettingsRow(label: 'Visible insight cards', description: s.on('insightCards') ? null : 'Insight cards module is off.', below: _toggleChips(s, ctl, 'insights.cards', insightCardOptions)),
      ])),

      anchor('Daily goal', SettingsSection(title: 'Daily goal', action: ResetButton(label: 'Daily goal', onReset: () => reset('dailyGoal')), children: [
        SettingsRow(
          label: 'Measure',
          trailing: Segmented<String>(
            small: true,
            value: s.s('dailyGoal.type'),
            onChanged: (v) => ctl.edit((m) {
              m['dailyGoal']['type'] = v;
              m['dailyGoal']['target'] = v == 'minutes' ? 120 : v == 'sessions' ? 4 : 3;
            }),
            options: const [('minutes', 'Minutes'), ('sessions', 'Sessions'), ('tasks', 'Tasks')],
          ),
        ),
        SettingsRow(
          label: 'Target',
          trailing: NumStepper(
            value: s.i('dailyGoal.target'),
            min: 1,
            max: s.s('dailyGoal.type') == 'minutes' ? 960 : 50,
            step: s.s('dailyGoal.type') == 'minutes' ? 15 : 1,
            suffix: s.s('dailyGoal.type') == 'minutes' ? 'min' : s.s('dailyGoal.type'),
            onChanged: (v) => ctl.set('dailyGoal.target', v),
          ),
        ),
      ])),
    ]);
  }

  Widget _toggleChips(AppSettings s, SettingsController ctl, String path, Map<String, (String, String?)> options) => Wrap(spacing: 6, runSpacing: 6, children: [
        for (final e in options.entries)
          PillChip(
            label: e.value.$1,
            active: s.strings(path).contains(e.key),
            onTap: () => ctl.edit((m) {
              final parts = path.split('.');
              final list = (m[parts[0]][parts[1]] as List).cast<String>().toList();
              list.contains(e.key) ? list.remove(e.key) : list.add(e.key);
              m[parts[0]][parts[1]] = list;
            }),
          ),
      ]);

  void _addPreset() {
    final n = int.tryParse(presetCtrl.text.trim());
    if (n == null || n < 1 || n > 300) {
      toast(context, 'Use 1–300 minutes.', error: true);
      return;
    }
    settingsCtl(ref).edit((m) {
      final list = {...(m['focus']['presets'] as List).cast<num>().map((e) => e.toInt()), n}.toList()..sort();
      m['focus']['presets'] = list;
    });
    presetCtrl.clear();
  }
}

class _ReasonsSection extends ConsumerStatefulWidget {
  const _ReasonsSection({required this.off});
  final String off;
  @override
  ConsumerState<_ReasonsSection> createState() => _ReasonsSectionState();
}

class _ReasonsSectionState extends ConsumerState<_ReasonsSection> {
  final add = TextEditingController();

  @override
  void dispose() {
    add.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final off = widget.off;
    final s = ref.watch(settingsProvider);
    final p = context.pal;
    final reasons = ref.watch(reasonsProvider).value ?? const <DistractionReason>[];
    final repo = ref.read(repositoryProvider);
    final ctl = settingsCtl(ref);
    return SettingsSection(
      title: 'Distraction logging$off',
      action: ResetButton(label: 'Distraction logging', onReset: () async {
        await repo.resetReasons();
        await ctl.replace(ctl.current.resetSection('distractions'));
      }),
      children: [
        SettingsRow(
          label: 'Reasons',
          description: 'Drag to reorder. Past logs keep their original label.',
          below: Column(children: [
            ReorderableListView(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              buildDefaultDragHandles: false,
              onReorderItem: (from, to) {
                final ids = reasons.map((r) => r.id).toList();
                final m = ids.removeAt(from);
                ids.insert(to, m);
                repo.reorderReasons(ids);
              },
              children: [
                for (var i = 0; i < reasons.length; i++)
                  Padding(
                    key: ValueKey(reasons[i].id),
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Row(children: [
                      ReorderableDragStartListener(index: i, child: Padding(padding: const EdgeInsets.all(6), child: Icon(Icons.drag_indicator_rounded, size: 18, color: p.muted.withValues(alpha: 0.7)))),
                      Expanded(child: CommitField(value: reasons[i].label, onCommit: (v) => v.trim().isEmpty ? null : repo.renameReason(reasons[i].id, v.trim()))),
                      IconBtn(Icons.close_rounded, size: 34, tooltip: 'Delete ${reasons[i].label}', onPressed: reasons.length <= 1
                          ? null
                          : () async {
                              if (await confirm(context, title: 'Delete “${reasons[i].label}”?', description: 'Past distractions keep this label.', confirmLabel: 'Delete', danger: true)) {
                                await repo.deleteReason(reasons[i].id);
                              }
                            }),
                    ]),
                  ),
              ],
            ),
            Row(children: [
              const SizedBox(width: 30),
              Expanded(child: TextField(controller: add, decoration: const InputDecoration(hintText: 'Add a reason'), onSubmitted: (v) => v.trim().isEmpty ? null : repo.addReason(v.trim()).then((_) => add.clear()))),
              const SizedBox(width: 6),
              IconBtn(Icons.add_rounded, filled: true, size: 36, tooltip: 'Add reason', onPressed: () => add.text.trim().isEmpty ? null : repo.addReason(add.text.trim()).then((_) => add.clear())),
            ]),
          ]),
        ),
        SwitchRow(label: 'Optional note', description: 'Show a note field when logging a distraction.', value: s.b('distractions.noteEnabled'), onChanged: (v) => ctl.set('distractions.noteEnabled', v)),
      ],
    );
  }
}
