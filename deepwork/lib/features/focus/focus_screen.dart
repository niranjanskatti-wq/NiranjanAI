import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/settings.dart';
import '../../core/theme/tokens.dart';
import '../../core/util/format.dart';
import '../../data/database.dart';
import '../../data/providers.dart';
import '../../services/audio.dart';
import '../../services/native.dart';
import '../../ui/widgets.dart';
import 'focus_controller.dart';
import 'progress_ring.dart';
import 'session_close.dart';

const soundIcons = {'rain': Icons.water_drop_outlined, 'cafe': Icons.local_cafe_outlined, 'white': Icons.air_rounded, 'brown': Icons.waves_rounded};

class FocusScreen extends ConsumerWidget {
  const FocusScreen({super.key, this.initialTaskId, this.initialMinutes});
  final String? initialTaskId;
  final int? initialMinutes;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final phase = ref.watch(focusProvider.select((s) => s.phase));
    return Scaffold(
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 350),
        child: phase == FocusPhase.idle
            ? FocusSetup(key: const ValueKey('setup'), initialTaskId: initialTaskId, initialMinutes: initialMinutes)
            : const FocusSessionView(key: ValueKey('session')),
      ),
    );
  }
}

bool requireTaskEffective(AppSettings s) => s.b('focus.requireTask') && (s.on('tasks') || s.on('priorities'));

// =============================================================================== setup

class FocusSetup extends ConsumerStatefulWidget {
  const FocusSetup({super.key, this.initialTaskId, this.initialMinutes});
  final String? initialTaskId;
  final int? initialMinutes;
  @override
  ConsumerState<FocusSetup> createState() => _FocusSetupState();
}

class _FocusSetupState extends ConsumerState<FocusSetup> {
  String? taskId;
  late int minutes;
  bool custom = false;
  final customCtrl = TextEditingController();
  final newTaskCtrl = TextEditingController();
  String? sound;

  @override
  void initState() {
    super.initState();
    final s = ref.read(settingsProvider);
    taskId = widget.initialTaskId;
    minutes = widget.initialMinutes ?? s.i('focus.defaultDuration');
    custom = !s.presets.contains(minutes);
    if (custom) customCtrl.text = '$minutes';
    final st = ref.read(focusProvider);
    final def = s.s('ambient.defaultSound');
    sound = st.sound ?? (s.b('ambient.defaultOn') && s.strings('ambient.available').contains(def) ? def : null);
  }

  @override
  void didUpdateWidget(FocusSetup old) {
    super.didUpdateWidget(old);
    if (widget.initialTaskId != null && widget.initialTaskId != old.initialTaskId) setState(() => taskId = widget.initialTaskId);
    if (widget.initialMinutes != null && widget.initialMinutes != old.initialMinutes) setState(() => minutes = widget.initialMinutes!);
  }

  @override
  void dispose() {
    customCtrl.dispose();
    newTaskCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(settingsProvider);
    final p = context.pal;
    final tasks = ref.watch(tasksProvider).value ?? const <TaskItem>[];
    final projects = {for (final x in ref.watch(projectsProvider).value ?? const <Project>[]) x.id: x};
    final sessions = ref.watch(sessionsProvider).value ?? const <FocusSession>[];
    final today = watchToday(ref);
    final requireTask = requireTaskEffective(s);
    int rank(TaskItem t) => t.isPriority && t.priorityDate == today ? 0 : t.dueDate == today ? 1 : t.flagged ? 2 : 3;
    final open = tasks.where((t) => t.status != 'done').toList()
      ..sort((a, b) => rank(a) != rank(b) ? rank(a).compareTo(rank(b)) : a.priorityOrder != b.priorityOrder ? a.priorityOrder.compareTo(b.priorityOrder) : a.sort.compareTo(b.sort));
    final selected = open.where((t) => t.id == taskId).firstOrNull;
    final spent = selected == null ? 0 : sessions.where((x) => x.taskId == selected.id && x.result != 'interrupted').length;
    final canStart = (!requireTask || selected != null) && minutes > 0;

    return Stack(children: [
      PageBody(bottomPadding: 120, children: [
        const PageHeader(title: 'Focus', subtitle: 'Pick one thing. Give it your full attention.'),
        AppCard(
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            CardHeader(
              title: requireTask ? 'Task' : 'Task (optional)',
              action: selected?.estimateSessions != null && s.on('tasks')
                  ? Text('$spent/${selected!.estimateSessions} sessions', style: TextStyle(color: p.muted, fontSize: 12, fontFeatures: tabular))
                  : null,
            ),
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 280),
              child: ListView(shrinkWrap: true, children: [
                if (!requireTask) _TaskOption(title: 'Untitled session', subtitle: 'No task attached', active: taskId == null, onTap: () => setState(() => taskId = null)),
                for (final t in open)
                  _TaskOption(
                    title: t.title,
                    subtitle: [if (t.isPriority && t.priorityDate == today) 'Priority', if (t.projectId != null) projects[t.projectId]?.name].whereType<String>().join(' · '),
                    color: t.projectId == null ? null : colorFromHex(projects[t.projectId]?.color ?? '#7C7CFF'),
                    active: taskId == t.id,
                    onTap: () => setState(() => taskId = t.id),
                  ),
                if (open.isEmpty) Padding(padding: const EdgeInsets.all(8), child: Text('No open tasks yet. Add one below.', style: TextStyle(color: p.muted))),
              ]),
            ),
            const SizedBox(height: 10),
            Row(children: [
              Expanded(
                child: TextField(
                  controller: newTaskCtrl,
                  decoration: const InputDecoration(hintText: 'New task…'),
                  textInputAction: TextInputAction.done,
                  onSubmitted: (_) => _addTask(),
                ),
              ),
              const SizedBox(width: 8),
              IconBtn(Icons.add_rounded, filled: true, tooltip: 'Add task', onPressed: _addTask),
            ]),
          ]),
        ),
        const Gap(),
        AppCard(
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            CardHeader(title: 'Duration', action: Text(s.s('focus.mode') == 'countdown' ? 'Countdown' : 'Count-up', style: TextStyle(color: p.muted, fontSize: 12))),
            Wrap(spacing: 8, runSpacing: 8, crossAxisAlignment: WrapCrossAlignment.center, children: [
              for (final m in s.presets)
                PillChip(
                  label: '$m min',
                  height: 40,
                  active: !custom && minutes == m,
                  onTap: () => setState(() {
                    minutes = m;
                    custom = false;
                    customCtrl.clear();
                  }),
                ),
              if (s.b('focus.allowCustom'))
                SizedBox(
                  width: 110,
                  child: TextField(
                    controller: customCtrl,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      hintText: 'Custom',
                      suffixText: 'min',
                      enabledBorder: custom ? OutlineInputBorder(borderRadius: BorderRadius.circular(999), borderSide: BorderSide(color: p.accent.withValues(alpha: 0.6))) : OutlineInputBorder(borderRadius: BorderRadius.circular(999), borderSide: BorderSide(color: p.border)),
                      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(999), borderSide: BorderSide(color: p.accent)),
                    ),
                    onChanged: (v) {
                      final n = int.tryParse(v);
                      setState(() {
                        if (n != null && n > 0 && n <= 300) {
                          minutes = n;
                          custom = true;
                        }
                      });
                    },
                  ),
                ),
            ]),
          ]),
        ),
        if (s.on('ambient') && s.strings('ambient.available').isNotEmpty) ...[
          const Gap(),
          AppCard(
            child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              const CardHeader(title: 'Ambient sound'),
              SoundPicker(sound: sound, onChanged: (v) => setState(() => sound = v)),
            ]),
          ),
        ],
      ]),
      Positioned(
        left: 0,
        right: 0,
        bottom: 0,
        child: Container(
          padding: const EdgeInsets.fromLTRB(16, 24, 16, 14),
          decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.bottomCenter, end: Alignment.topCenter, colors: [p.bg, p.bg, p.bg.withValues(alpha: 0)], stops: const [0, 0.6, 1])),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 720),
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                Btn('Start $minutes-minute session', icon: Icons.play_arrow_rounded, kind: BtnKind.primary, large: true, expand: true, onPressed: canStart ? _start : null),
                if (!canStart && requireTask)
                  Padding(padding: const EdgeInsets.only(top: 8), child: Text('Choose a task to start. You can allow untitled sessions in Settings.', style: TextStyle(color: p.muted, fontSize: 12))),
              ]),
            ),
          ),
        ),
      ),
    ]);
  }

  Future<void> _addTask() async {
    final title = newTaskCtrl.text.trim();
    if (title.isEmpty) return;
    final t = await ref.read(repositoryProvider).createTask(title: title);
    newTaskCtrl.clear();
    setState(() => taskId = t.id);
  }

  Future<void> _start() async {
    final s = ref.read(settingsProvider);
    await ref.read(focusProvider.notifier).start(taskId: taskId, minutes: minutes, sound: s.on('ambient') ? sound : null);
  }
}

class _TaskOption extends StatelessWidget {
  const _TaskOption({required this.title, this.subtitle, this.color, required this.active, required this.onTap});
  final String title;
  final String? subtitle;
  final Color? color;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    return Pressable(
      onTap: onTap,
      scale: 0.99,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        margin: const EdgeInsets.only(bottom: 4),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: active ? p.accentSoft : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: active ? p.accent.withValues(alpha: 0.55) : Colors.transparent),
        ),
        child: Row(children: [
          Container(
            width: 18,
            height: 18,
            decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: active ? p.accent : p.border, width: 2)),
            child: active ? Center(child: Dot(p.accent, size: 8)) : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(title, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w500)),
              if (subtitle != null && subtitle!.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Row(children: [
                    if (color != null) ...[Dot(color!, size: 7), const SizedBox(width: 6)],
                    Flexible(child: Text(subtitle!, style: TextStyle(color: p.muted, fontSize: 12), overflow: TextOverflow.ellipsis)),
                  ]),
                ),
            ]),
          ),
        ]),
      ),
    );
  }
}

class SoundPicker extends ConsumerStatefulWidget {
  const SoundPicker({super.key, required this.sound, required this.onChanged});
  final String? sound;
  final ValueChanged<String?> onChanged;
  @override
  ConsumerState<SoundPicker> createState() => _SoundPickerState();
}

class _SoundPickerState extends ConsumerState<SoundPicker> {
  double? _vol;
  @override
  Widget build(BuildContext context) {
    final s = ref.watch(settingsProvider);
    final p = context.pal;
    final vol = _vol ?? s.d('ambient.volume');
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Wrap(spacing: 8, runSpacing: 8, children: [
        PillChip(label: 'Off', active: widget.sound == null, leading: Icon(Icons.volume_off_rounded, size: 15, color: widget.sound == null ? p.accent : p.muted), onTap: () => widget.onChanged(null)),
        for (final e in ambientSounds.entries.where((e) => s.strings('ambient.available').contains(e.key)))
          PillChip(
            label: e.value,
            active: widget.sound == e.key,
            leading: Icon(soundIcons[e.key], size: 15, color: widget.sound == e.key ? p.accent : p.muted),
            onTap: () => widget.onChanged(e.key),
          ),
      ]),
      const SizedBox(height: 10),
      Row(children: [
        Icon(Icons.volume_up_rounded, size: 18, color: p.muted),
        Expanded(
          child: Slider(
            value: vol,
            onChanged: (v) {
              setState(() => _vol = v);
              AmbientPlayer.instance.setVolume(v);
            },
            onChangeEnd: (v) => ref.read(settingsProvider.notifier).set('ambient.volume', v),
          ),
        ),
        SizedBox(width: 38, child: Text('${(vol * 100).round()}%', textAlign: TextAlign.right, style: TextStyle(color: p.muted, fontSize: 12, fontFeatures: tabular))),
      ]),
    ]);
  }
}

// =============================================================================== session

class FocusSessionView extends ConsumerStatefulWidget {
  const FocusSessionView({super.key});
  @override
  ConsumerState<FocusSessionView> createState() => _FocusSessionViewState();
}

class _FocusSessionViewState extends ConsumerState<FocusSessionView> with SingleTickerProviderStateMixin {
  late final Ticker _ticker = createTicker((_) {
    if (mounted) setState(() {});
  });
  bool? _suggestLong;

  @override
  void initState() {
    super.initState();
    _syncTicker(ref.read(focusProvider).phase);
  }

  void _syncTicker(FocusPhase phase) {
    final want = phase == FocusPhase.running || phase == FocusPhase.breakTime;
    if (want && !_ticker.isActive) _ticker.start();
    if (!want && _ticker.isActive) _ticker.stop();
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final st = ref.watch(focusProvider);
    final s = ref.watch(settingsProvider);
    final p = context.pal;
    ref.listen(focusProvider.select((x) => x.phase), (prev, next) {
      _syncTicker(next);
      if (next == FocusPhase.closed) {
        ref.read(focusProvider.notifier).suggestLongBreak().then((v) {
          if (mounted) setState(() => _suggestLong = v);
        });
      }
    });
    if (st.phase == FocusPhase.closed && _suggestLong == null) {
      ref.read(focusProvider.notifier).suggestLongBreak().then((v) {
        if (mounted) setState(() => _suggestLong = v);
      });
    }

    final tasks = ref.watch(tasksProvider).value ?? const <TaskItem>[];
    final task = tasks.where((t) => t.id == st.taskId).firstOrNull;
    final taskTitle = task?.title ?? (st.taskId != null ? 'Task' : 'Untitled session');
    final now = DateTime.now().millisecondsSinceEpoch;
    final hide = s.b('focus.hideSeconds');
    final el = st.elapsedSec(now);
    var progress = st.plannedSec == 0 ? 0.0 : el / st.plannedSec;
    var status = RingStatus.active;
    var display = formatTimer(st.countUp ? el : st.plannedSec - el, hideSeconds: hide);
    var caption = st.countUp ? 'of ${formatDuration(st.plannedSec)}' : 'remaining';
    switch (st.phase) {
      case FocusPhase.paused:
        status = RingStatus.paused;
        caption = 'paused';
      case FocusPhase.finished || FocusPhase.closed:
        status = RingStatus.complete;
        progress = st.actualSec >= st.plannedSec ? 1 : progress;
        display = formatDuration(st.actualSec);
        caption = 'focused';
      case FocusPhase.ended:
        status = RingStatus.interrupted;
        display = formatDuration(st.actualSec);
        caption = 'logged';
      case FocusPhase.breakTime || FocusPhase.breakOver:
        status = RingStatus.breakTime;
        final be = st.phase == FocusPhase.breakTime ? st.breakElapsedSec(now) : st.breakSec.toDouble();
        progress = st.breakSec == 0 ? 1 : be / st.breakSec;
        display = st.phase == FocusPhase.breakOver ? '0:00' : formatTimer(st.breakSec - be, hideSeconds: hide);
        caption = st.phase == FocusPhase.breakOver ? 'break over' : '${st.breakLong ? 'long' : 'short'} break';
      default:
    }
    final distractionCount = st.sessionId == null ? 0 : ref.watch(distractionCountProvider(st.sessionId!)).value ?? 0;
    final focus = ref.read(focusProvider.notifier);

    return SafeArea(
      child: LayoutBuilder(builder: (context, cons) {
        return SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: cons.maxHeight),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(children: [
                Row(children: [
                  IconBtn(Icons.arrow_back_rounded, tooltip: 'Back to Today', onPressed: () => context.go('/')),
                  const Spacer(),
                  if (s.on('ambient') && s.strings('ambient.available').isNotEmpty && st.inSession)
                    IconBtn(st.sound == null ? Icons.volume_off_rounded : Icons.volume_up_rounded, tooltip: 'Ambient sound', onPressed: () => _soundSheet(context)),
                ]),
                const SizedBox(height: 12),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  child: Text(
                    st.phase == FocusPhase.breakTime || st.phase == FocusPhase.breakOver ? 'Step away for a moment' : taskTitle,
                    key: ValueKey(taskTitle + st.phase.name),
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 19, fontWeight: FontWeight.w500, letterSpacing: -0.2, color: p.fg.withValues(alpha: 0.92)),
                  ),
                ),
                const SizedBox(height: 28),
                ProgressRing(
                  progress: progress,
                  status: status,
                  style: s.s('ring.style'),
                  glow: s.b('ring.glow'),
                  completionAnimation: s.b('ring.completionAnimation'),
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                    AnimatedDefaultTextStyle(
                      duration: const Duration(milliseconds: 700),
                      style: TextStyle(
                        fontSize: hide ? 46 : 58,
                        fontWeight: FontWeight.w600,
                        letterSpacing: -1.5,
                        color: status == RingStatus.interrupted ? p.muted : p.fg,
                        fontFeatures: tabular,
                        fontFamily: Theme.of(context).textTheme.bodyMedium?.fontFamily,
                      ),
                      child: Text(display),
                    ),
                    const SizedBox(height: 4),
                    Text(caption, style: TextStyle(color: p.muted, fontSize: 14)),
                    if (st.inSession && s.on('distractions') && distractionCount > 0)
                      Container(
                        margin: const EdgeInsets.only(top: 12),
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(color: p.card2, borderRadius: BorderRadius.circular(99)),
                        child: Text(pluralize(distractionCount, 'distraction'), style: TextStyle(color: p.muted, fontSize: 12)),
                      ),
                    if (st.inSession) const _BlockingChip(),
                  ]),
                ),
                const SizedBox(height: 36),
                if (st.inSession)
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 440),
                    child: Row(children: [
                      Expanded(
                        child: s.on('distractions')
                            ? _ControlButton(icon: Icons.bolt_rounded, label: 'Distracted', onTap: () => showDistractionSheet(context, ref))
                            : const SizedBox(),
                      ),
                      const SizedBox(width: 14),
                      Pressable(
                        onTap: st.phase == FocusPhase.running ? focus.pause : focus.resume,
                        scale: 0.9,
                        child: Container(
                          width: 64,
                          height: 64,
                          decoration: BoxDecoration(color: p.accent, shape: BoxShape.circle, boxShadow: [BoxShadow(color: p.accent.withValues(alpha: 0.45), blurRadius: 24, spreadRadius: -6, offset: const Offset(0, 8))]),
                          child: Icon(st.phase == FocusPhase.running ? Icons.pause_rounded : Icons.play_arrow_rounded, color: p.onAccent, size: 30, semanticLabel: st.phase == FocusPhase.running ? 'Pause' : 'Resume'),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(child: _ControlButton(icon: Icons.stop_rounded, label: 'End', onTap: () => showEndEarlySheet(context, ref))),
                    ]),
                  ),
                if (st.phase == FocusPhase.finished) const SessionCloseCard(),
                if (st.phase == FocusPhase.closed)
                  ResultCard(
                    success: true,
                    title: 'Session complete',
                    body: '${formatDuration(st.actualSec)} on $taskTitle.',
                    actions: [
                      if (s.on('breaks')) ...[
                        Btn(
                          'Start ${_suggestLong == true ? s.i('breaks.long') : s.i('breaks.short')}-minute ${_suggestLong == true ? 'long' : 'short'} break',
                          kind: BtnKind.primary,
                          large: true,
                          expand: true,
                          onPressed: () => focus.startBreak(long: _suggestLong == true),
                        ),
                        Row(children: [
                          Expanded(
                            child: Btn(_suggestLong == true ? 'Short (${s.i('breaks.short')}m)' : 'Long (${s.i('breaks.long')}m)', expand: true, onPressed: () => focus.startBreak(long: _suggestLong != true)),
                          ),
                          const SizedBox(width: 8),
                          Expanded(child: Btn('Next session', expand: true, onPressed: focus.startNext)),
                        ]),
                      ] else
                        Btn('Start another session', kind: BtnKind.primary, large: true, expand: true, onPressed: focus.startNext),
                      Btn('Done for now', kind: BtnKind.ghost, expand: true, onPressed: () {
                        focus.reset();
                        context.go('/');
                      }),
                    ],
                  ),
                if (st.phase == FocusPhase.ended)
                  ResultCard(
                    success: false,
                    title: 'Session ended early',
                    body: "${formatDuration(st.actualSec)} logged as interrupted${st.endReason != null ? ' · ${st.endReason}' : ''}. That's useful data, not a failure.",
                    actions: [
                      Btn('Start a new session', kind: BtnKind.primary, large: true, expand: true, onPressed: focus.reset),
                      Btn('Back to Today', kind: BtnKind.ghost, expand: true, onPressed: () {
                        focus.reset();
                        context.go('/');
                      }),
                    ],
                  ),
                if (st.phase == FocusPhase.breakTime) Btn('Skip break', icon: Icons.skip_next_rounded, large: true, onPressed: focus.skipBreak),
                if (st.phase == FocusPhase.breakOver)
                  ResultCard(
                    success: true,
                    title: "Break's over",
                    body: s.b('breaks.autoStartNext') ? 'Starting your next session…' : 'Ready when you are.',
                    actions: [
                      Btn('Start next session', icon: Icons.play_arrow_rounded, kind: BtnKind.primary, large: true, expand: true, onPressed: focus.startNext),
                      Btn('Done for now', kind: BtnKind.ghost, expand: true, onPressed: () {
                        focus.reset();
                        context.go('/');
                      }),
                    ],
                  ),
                const SizedBox(height: 24),
              ]),
            ),
          ),
        );
      }),
    );
  }

  void _soundSheet(BuildContext context) {
    showAppSheet(context, title: 'Ambient sound', builder: (ctx) => Consumer(builder: (ctx, ref, _) {
      final st = ref.watch(focusProvider);
      return SoundPicker(sound: st.sound, onChanged: (v) => ref.read(focusProvider.notifier).setSound(v));
    }));
  }
}

/// Secondary session control: icon above a short label.
class _ControlButton extends StatelessWidget {
  const _ControlButton({required this.icon, required this.label, required this.onTap});
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    return Semantics(
      button: true,
      label: label,
      excludeSemantics: true,
      child: Pressable(
        onTap: onTap,
        child: Container(
          height: 64,
          decoration: BoxDecoration(color: p.card2, borderRadius: BorderRadius.circular(radiusButton + 4), border: Border.all(color: p.border)),
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            Icon(icon, size: 20, color: p.fg),
            const SizedBox(height: 4),
            Text(label, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600)),
          ]),
        ),
      ),
    );
  }
}

class _BlockingChip extends ConsumerStatefulWidget {
  const _BlockingChip();
  @override
  ConsumerState<_BlockingChip> createState() => _BlockingChipState();
}

class _BlockingChipState extends ConsumerState<_BlockingChip> with WidgetsBindingObserver {
  bool? _enabled;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _check();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _check();
  }

  void _check() => NativeBridge.blockerEnabled().then((v) {
        if (mounted) setState(() => _enabled = v);
      });

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(settingsProvider);
    final p = context.pal;
    if (!NativeBridge.available || !s.on('appBlocking') || _enabled == null) return const SizedBox.shrink();
    final mode = s.s('blocking.mode');
    final n = s.strings('blocking.packages').length;
    final ready = _enabled! && (mode == 'allow' || n > 0);
    return Pressable(
      onTap: ready ? null : () => context.push('/settings/blocking'),
      child: Container(
        margin: const EdgeInsets.only(top: 10),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(color: ready ? p.accentSoft : p.card2, borderRadius: BorderRadius.circular(99)),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(Icons.block_rounded, size: 12, color: ready ? p.accent : p.muted),
          const SizedBox(width: 5),
          Text(
            !ready ? 'Set up app blocking' : mode == 'block' ? '${pluralize(n, 'app')} paused' : 'Only ${pluralize(n, 'app')} allowed',
            style: TextStyle(fontSize: 12, color: ready ? p.accent : p.muted),
          ),
        ]),
      ),
    );
  }
}

class ResultCard extends StatelessWidget {
  const ResultCard({super.key, required this.success, required this.title, required this.body, required this.actions});
  final bool success;
  final String title, body;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeOutBack,
      builder: (c, v, child) => Opacity(opacity: v.clamp(0, 1), child: Transform.translate(offset: Offset(0, 16 * (1 - v)), child: child)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 400),
        child: AppCard(
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Icon(success ? Icons.check_circle_rounded : Icons.remove_circle_outline_rounded, color: success ? p.success : p.muted, size: 22),
              const SizedBox(width: 12),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(title, style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 3),
                  Text(body, style: TextStyle(color: p.muted, fontSize: 13.5, height: 1.4)),
                ]),
              ),
            ]),
            const SizedBox(height: 16),
            for (final a in actions) Padding(padding: const EdgeInsets.only(bottom: 8), child: a),
          ]),
        ),
      ),
    );
  }
}

// =============================================================================== sheets

Future<void> showDistractionSheet(BuildContext context, WidgetRef ref) async {
  final s = ref.read(settingsProvider);
  final reasons = ref.read(reasonsProvider).value ?? const <DistractionReason>[];
  final noteCtrl = TextEditingController();
  String? picked;
  Future<void> save(BuildContext ctx, String reason) async {
    await ref.read(focusProvider.notifier).logDistraction(reason, noteCtrl.text.trim());
    if (ctx.mounted) Navigator.pop(ctx);
    if (context.mounted) toast(context, 'Distraction logged. Back to it.');
  }

  await showAppSheet(
    context,
    title: 'What pulled you away?',
    description: 'The timer keeps running.',
    builder: (ctx) => StatefulBuilder(builder: (ctx, setState) {
      final p = ctx.pal;
      return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 8,
          crossAxisSpacing: 8,
          childAspectRatio: 3.4,
          children: [
            for (final r in reasons)
              Pressable(
                onTap: () => s.b('distractions.noteEnabled') ? setState(() => picked = r.label) : save(ctx, r.label),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: picked == r.label ? p.accentSoft : p.card2.withValues(alpha: 0.6),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: picked == r.label ? p.accent.withValues(alpha: 0.6) : p.border),
                  ),
                  child: Text(r.label, style: TextStyle(fontWeight: FontWeight.w500, color: picked == r.label ? p.accent : p.fg)),
                ),
              ),
          ],
        ),
        if (s.b('distractions.noteEnabled')) ...[
          const SizedBox(height: 12),
          TextField(controller: noteCtrl, decoration: const InputDecoration(hintText: 'Optional note')),
          const SizedBox(height: 14),
          Btn('Log distraction', kind: BtnKind.primary, expand: true, onPressed: picked == null ? null : () => save(ctx, picked!)),
        ],
      ]);
    }),
  );
}

const endReasons = ['Something urgent came up', 'Out of energy', 'Meeting or interruption', 'Wrong task', 'Other'];

Future<void> showEndEarlySheet(BuildContext context, WidgetRef ref) async {
  final focus = ref.read(focusProvider.notifier);
  final short = ref.read(focusProvider).elapsedSec() < 60;
  final otherCtrl = TextEditingController();
  var other = false;
  await showAppSheet(
    context,
    title: 'End session early?',
    description: 'A quick reason helps you spot patterns later.',
    builder: (ctx) => StatefulBuilder(builder: (ctx, setState) {
      final p = ctx.pal;
      void end(String reason, bool finished) {
        Navigator.pop(ctx);
        focus.endEarly(reason: reason, finishedEarly: finished);
      }

      return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Pressable(
          onTap: () => end('Finished early', true),
          child: Container(
            height: 50,
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(color: p.success.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12), border: Border.all(color: p.success.withValues(alpha: 0.4))),
            child: Row(children: [Icon(Icons.check_circle_rounded, color: p.success, size: 18), const SizedBox(width: 10), Text('I finished early', style: TextStyle(color: p.success, fontWeight: FontWeight.w600))]),
          ),
        ),
        const SizedBox(height: 10),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 8,
          crossAxisSpacing: 8,
          childAspectRatio: 2.8,
          children: [
            for (final r in endReasons)
              Pressable(
                onTap: () => r == 'Other' ? setState(() => other = true) : end(r, false),
                child: Container(
                  alignment: Alignment.centerLeft,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: r == 'Other' && other ? p.accentSoft : p.card2.withValues(alpha: 0.6),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: r == 'Other' && other ? p.accent.withValues(alpha: 0.6) : p.border),
                  ),
                  child: Text(r, style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13.5)),
                ),
              ),
          ],
        ),
        if (other) ...[
          const SizedBox(height: 10),
          Row(children: [
            Expanded(child: TextField(controller: otherCtrl, autofocus: true, decoration: const InputDecoration(hintText: 'What happened?'))),
            const SizedBox(width: 8),
            Btn('End', kind: BtnKind.primary, onPressed: () => end(otherCtrl.text.trim().isEmpty ? 'Other' : otherCtrl.text.trim(), false)),
          ]),
        ],
        if (short) ...[
          const SizedBox(height: 10),
          Btn('Discard (under a minute, not logged)', kind: BtnKind.dangerGhost, expand: true, onPressed: () {
            Navigator.pop(ctx);
            focus.discard();
          }),
        ],
      ]);
    }),
  );
}

/// Keeps a widget's [Timer] alive only while mounted.
class Ticking extends StatefulWidget {
  const Ticking({super.key, required this.interval, required this.builder});
  final Duration interval;
  final WidgetBuilder builder;
  @override
  State<Ticking> createState() => _TickingState();
}

class _TickingState extends State<Ticking> {
  Timer? _t;
  @override
  void initState() {
    super.initState();
    _t = Timer.periodic(widget.interval, (_) => setState(() {}));
  }

  @override
  void dispose() {
    _t?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.builder(context);
}
