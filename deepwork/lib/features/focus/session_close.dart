import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/tokens.dart';
import '../../data/database.dart';
import '../../data/providers.dart';
import '../../ui/widgets.dart';
import 'focus_controller.dart';

const _resultLabels = {
  'done': ('Done', 'Finished it'),
  'partly': ('Partly done', 'Made progress'),
  'stuck': ('Stuck', 'Hit a wall'),
};

/// Shown when a session completes: result, a note, next steps when stuck.
class SessionCloseCard extends ConsumerStatefulWidget {
  const SessionCloseCard({super.key});
  @override
  ConsumerState<SessionCloseCard> createState() => _SessionCloseCardState();
}

class _SessionCloseCardState extends ConsumerState<SessionCloseCard> {
  String? result;
  final note = TextEditingController();
  final steps = <TextEditingController>[TextEditingController()];
  bool markDone = false;
  bool saving = false;

  @override
  void initState() {
    super.initState();
    final opts = _options();
    if (opts.length == 1) result = opts.first;
  }

  List<String> _options() {
    final s = ref.read(settingsProvider);
    return ['done', 'partly', 'stuck'].where((r) => s.b('sessionClose.results.$r')).toList();
  }

  @override
  void dispose() {
    note.dispose();
    for (final c in steps) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(settingsProvider);
    final p = context.pal;
    final opts = _options();
    final noteMode = s.s('sessionClose.note');
    final st = ref.watch(focusProvider);
    final task = (ref.watch(tasksProvider).value ?? const <TaskItem>[]).where((t) => t.id == st.taskId).firstOrNull;
    final showStuck = result == 'stuck' && s.b('sessionClose.stuckPrompt');
    final canSave = (opts.isEmpty || result != null) && !(noteMode == 'required' && note.text.trim().isEmpty) && !saving;

    Color tone(String r) => r == 'done' ? p.success : r == 'stuck' ? p.warning : p.accent;

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeOutCubic,
      builder: (c, v, child) => Opacity(opacity: v, child: Transform.translate(offset: Offset(0, 16 * (1 - v)), child: child)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 440),
        child: AppCard(
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Text('Session complete', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 2),
            Text('How did it go?', style: TextStyle(color: p.muted, fontSize: 13.5)),
            if (opts.isNotEmpty) ...[
              const SizedBox(height: 14),
              IntrinsicHeight(
                child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                for (final r in opts) ...[
                  Expanded(
                    child: Pressable(
                      onTap: () => setState(() => result = r),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 160),
                        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 6),
                        decoration: BoxDecoration(
                          color: result == r ? tone(r).withValues(alpha: 0.12) : p.card2.withValues(alpha: 0.6),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: result == r ? tone(r).withValues(alpha: 0.55) : p.border),
                        ),
                        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                          Text(_resultLabels[r]!.$1, style: TextStyle(fontWeight: FontWeight.w600, color: result == r ? tone(r) : p.fg)),
                          const SizedBox(height: 2),
                          Text(_resultLabels[r]!.$2, textAlign: TextAlign.center, maxLines: 2, style: TextStyle(color: p.muted, fontSize: 10.5)),
                        ]),
                      ),
                    ),
                  ),
                  if (r != opts.last) const SizedBox(width: 8),
                ],
              ]),
              ),
            ],
            if (noteMode != 'hidden') ...[
              const SizedBox(height: 14),
              Text('What did I get done?${noteMode == 'optional' ? ' (optional)' : ''}', style: TextStyle(color: p.muted, fontSize: 13, fontWeight: FontWeight.w500)),
              const SizedBox(height: 6),
              TextField(controller: note, minLines: 2, maxLines: 4, onChanged: (_) => setState(() {}), decoration: const InputDecoration(hintText: 'A sentence is enough.')),
            ],
            AnimatedSize(
              duration: const Duration(milliseconds: 250),
              child: !showStuck
                  ? const SizedBox(width: double.infinity)
                  : Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                      const SizedBox(height: 14),
                      Text("What's the smallest next step?", style: TextStyle(color: p.muted, fontSize: 13, fontWeight: FontWeight.w500)),
                      const SizedBox(height: 6),
                      for (var i = 0; i < steps.length; i++)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Row(children: [
                            Expanded(
                              child: TextField(
                                controller: steps[i],
                                autofocus: i > 0 && i == steps.length - 1,
                                decoration: InputDecoration(hintText: i == 0 ? 'e.g. Write the first heading' : 'Another step'),
                                onSubmitted: (_) => setState(() => steps.add(TextEditingController())),
                              ),
                            ),
                            if (steps.length > 1) IconBtn(Icons.close_rounded, tooltip: 'Remove step', onPressed: () => setState(() => steps.removeAt(i).dispose())),
                          ]),
                        ),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: TextButton.icon(onPressed: () => setState(() => steps.add(TextEditingController())), icon: const Icon(Icons.add_rounded, size: 18), label: const Text('Add step')),
                      ),
                      Text('Each step becomes a task${s.on('priorities') ? '; the first is added to today’s priorities' : ''}.', style: TextStyle(color: p.muted, fontSize: 12)),
                    ]),
            ),
            if (task != null && task.status != 'done') ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.only(left: 12),
                decoration: BoxDecoration(color: p.card2.withValues(alpha: 0.6), borderRadius: BorderRadius.circular(12)),
                child: Row(children: [
                  Expanded(child: Text('Mark “${task.title}” complete', maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 13.5))),
                  Switch(value: markDone, onChanged: (v) => setState(() => markDone = v)),
                ]),
              ),
            ],
            const SizedBox(height: 16),
            Btn('Save session', kind: BtnKind.primary, large: true, expand: true, onPressed: canSave ? _save : null),
          ]),
        ),
      ),
    );
  }

  Future<void> _save() async {
    setState(() => saving = true);
    final s = ref.read(settingsProvider);
    await ref.read(focusProvider.notifier).close(
          result: result ?? 'done',
          note: s.s('sessionClose.note') == 'hidden' ? '' : note.text.trim(),
          markTaskDone: markDone,
          nextSteps: result == 'stuck' && s.b('sessionClose.stuckPrompt') ? steps.map((c) => c.text).toList() : const [],
        );
  }
}
