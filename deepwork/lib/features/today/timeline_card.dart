import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/tokens.dart';
import '../../core/util/format.dart';
import '../../data/database.dart';
import '../../data/providers.dart';
import '../../ui/task_picker.dart';
import '../../ui/widgets.dart';
import '../focus/focus_screen.dart' show Ticking;
import 'priorities_card.dart' show DragChip;

/// Hourly timeline of time blocks. Drag tasks (from the tray or priorities) onto a slot, drag a
/// block to move it, tap a slot to add a block, tap a block to edit it or start focus.
class TimelineCard extends ConsumerWidget {
  const TimelineCard({super.key, required this.blocks, required this.tasks, required this.projects, required this.tray, required this.today});
  final List<TimeBlock> blocks;
  final List<TaskItem> tasks;
  final List<Project> projects;
  final List<TaskItem> tray;
  final String today;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(settingsProvider);
    final p = context.pal;
    final start = timeToMinutes(s.s('timeBlocks.dayStart'));
    final end = (timeToMinutes(s.s('timeBlocks.dayEnd'))).clamp(start + s.i('timeBlocks.blockLength'), 24 * 60);
    final len = s.i('timeBlocks.blockLength');
    final compact = context.density.compact;
    final slotH = len == 15 ? (compact ? 30.0 : 34.0) : len == 30 ? (compact ? 38.0 : 44.0) : (compact ? 48.0 : 58.0);
    final slots = [for (var m = start; m < end; m += len) m];
    final taskMap = {for (final t in tasks) t.id: t};
    final projectMap = {for (final x in projects) x.id: x};
    final scheduled = blocks.map((b) => b.taskId).toSet();
    final trayItems = tray.where((t) => !scheduled.contains(t.id) && t.status != 'done').toList();
    final repo = ref.read(repositoryProvider);

    Future<void> onDrop(String data, int minute) async {
      if (data.startsWith('block:')) {
        await repo.moveBlock(data.substring(6), minute);
      } else if (data.startsWith('task:')) {
        await repo.createBlock(minute, len, data.substring(5), date: today);
        if (context.mounted) toast(context, 'Scheduled');
      }
    }

    Future<void> addAt(int minute) async {
      final picked = await pickTask(context, ref, title: 'Block at ${formatClock(minutesToTime(minute))}', description: 'Choose a task for this block.', noneLabel: 'Empty block (add a label later)');
      if (picked == null) return;
      await repo.createBlock(minute, len, picked.task?.id, label: picked.task == null ? 'Focus block' : '', date: today);
    }

    return AppCard(
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        CardHeader(icon: Icons.calendar_today_rounded, title: 'Time blocks', subtitle: '${formatClock(s.s('timeBlocks.dayStart'))} – ${formatClock(s.s('timeBlocks.dayEnd'))}'),
        if (trayItems.isNotEmpty) ...[
          Text('Long-press a task and drag it onto the timeline, or tap a slot.', style: TextStyle(color: p.muted, fontSize: 12)),
          const SizedBox(height: 8),
          SizedBox(
            height: 36,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: trayItems.length,
              separatorBuilder: (_, _) => const SizedBox(width: 6),
              itemBuilder: (c, i) {
                final t = trayItems[i];
                final color = t.projectId == null ? p.muted : colorFromHex(projectMap[t.projectId]?.color ?? '#8A8A99');
                final chip = Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(color: p.card2.withValues(alpha: 0.6), borderRadius: BorderRadius.circular(99), border: Border.all(color: p.border)),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    Dot(color, size: 7),
                    const SizedBox(width: 6),
                    ConstrainedBox(constraints: const BoxConstraints(maxWidth: 180), child: Text(t.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500))),
                  ]),
                );
                return LongPressDraggable<String>(data: 'task:${t.id}', feedback: DragChip(title: t.title), childWhenDragging: Opacity(opacity: 0.4, child: chip), child: chip);
              },
            ),
          ),
          const SizedBox(height: 12),
        ],
        Ticking(
          interval: const Duration(seconds: 30),
          builder: (context) {
            final now = DateTime.now();
            final nowMin = now.hour * 60 + now.minute;
            return SizedBox(
              height: slots.length * slotH,
              child: Stack(children: [
                for (var i = 0; i < slots.length; i++)
                  Positioned(
                    top: i * slotH,
                    left: 0,
                    right: 0,
                    height: slotH,
                    child: _Slot(minute: slots[i], showLabel: slots[i] % 60 == 0 || len == 60, onTap: () => addAt(slots[i]), onDrop: (d) => onDrop(d, slots[i])),
                  ),
                if (nowMin >= start && nowMin < end && today == todayKey())
                  Positioned(
                    top: (nowMin - start) / len * slotH - 4,
                    left: 52,
                    right: 0,
                    child: IgnorePointer(child: Row(children: [Dot(p.accent, size: 8), Expanded(child: Container(height: 1.2, color: p.accent.withValues(alpha: 0.8)))])),
                  ),
                for (final b in blocks)
                  if (timeToMinutes(b.endTime) > start && timeToMinutes(b.startTime) < end)
                    Builder(builder: (context) {
                      final sMin = timeToMinutes(b.startTime).clamp(start, end);
                      final eMin = timeToMinutes(b.endTime).clamp(start, end);
                      final top = (sMin - start) / len * slotH;
                      final h = ((eMin - sMin) / len * slotH - 4).clamp(slotH * 0.6, double.infinity);
                      final task = b.taskId == null ? null : taskMap[b.taskId];
                      final color = task?.projectId == null ? p.accent : colorFromHex(projectMap[task!.projectId]?.color ?? '#7C7CFF');
                      return Positioned(
                        top: top + 2,
                        left: 52,
                        right: 0,
                        height: h,
                        child: _Block(block: b, task: task, color: color, height: h, onTap: () => editBlock(context, ref, b)),
                      );
                    }),
              ]),
            );
          },
        ),
      ]),
    );
  }
}

class _Slot extends StatelessWidget {
  const _Slot({required this.minute, required this.showLabel, required this.onTap, required this.onDrop});
  final int minute;
  final bool showLabel;
  final VoidCallback onTap;
  final ValueChanged<String> onDrop;

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    return DragTarget<String>(
      onAcceptWithDetails: (d) => onDrop(d.data),
      builder: (context, candidates, _) => Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        SizedBox(
          width: 48,
          child: Transform.translate(
            offset: const Offset(0, -7),
            child: Text(showLabel ? formatClock(minutesToTime(minute)) : '', textAlign: TextAlign.right, style: TextStyle(color: p.muted, fontSize: 11, fontFeatures: tabular)),
          ),
        ),
        const SizedBox(width: 4),
        Expanded(
          child: Semantics(
            button: true,
            label: 'Add block at ${formatClock(minutesToTime(minute))}',
            child: InkWell(
              onTap: onTap,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 120),
                decoration: BoxDecoration(
                  color: candidates.isNotEmpty ? p.accentSoft : Colors.transparent,
                  border: Border(top: BorderSide(color: p.border.withValues(alpha: 0.7))),
                ),
              ),
            ),
          ),
        ),
      ]),
    );
  }
}

class _Block extends StatelessWidget {
  const _Block({required this.block, required this.task, required this.color, required this.height, required this.onTap});
  final TimeBlock block;
  final TaskItem? task;
  final Color color;
  final double height;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    final done = task?.status == 'done';
    final title = task?.title ?? (block.label.isEmpty ? 'Block' : block.label);
    final body = Container(
      decoration: BoxDecoration(
        color: Color.alphaBlend(color.withValues(alpha: 0.16), p.card),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      clipBehavior: Clip.antiAlias,
      child: Row(children: [
        Container(width: 4, color: color),
        Expanded(
          child: InkWell(
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              child: Column(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: done ? p.muted : p.fg, decoration: done ? TextDecoration.lineThrough : null)),
                if (height > 38)
                  Text('${formatClock(block.startTime)} – ${formatClock(block.endTime)}', maxLines: 1, style: TextStyle(color: p.muted, fontSize: 11, fontFeatures: tabular)),
              ]),
            ),
          ),
        ),
        Padding(padding: const EdgeInsets.symmetric(horizontal: 6), child: Icon(Icons.drag_indicator_rounded, size: 16, color: p.muted.withValues(alpha: 0.7))),
      ]),
    );
    return LongPressDraggable<String>(
      data: 'block:${block.id}',
      feedback: DragChip(title: title),
      childWhenDragging: Opacity(opacity: 0.4, child: body),
      child: body,
    );
  }
}

Future<void> editBlock(BuildContext context, WidgetRef ref, TimeBlock block) async {
  var start = block.startTime;
  var end = block.endTime;
  String? taskId = block.taskId;
  final label = TextEditingController(text: block.label);
  final repo = ref.read(repositoryProvider);
  await showAppSheet(
    context,
    title: 'Edit block',
    builder: (ctx) => StatefulBuilder(builder: (ctx, setState) {
      final p = ctx.pal;
      final tasks = ref.read(tasksProvider).value ?? const <TaskItem>[];
      final task = tasks.where((t) => t.id == taskId).firstOrNull;
      final valid = timeToMinutes(end) > timeToMinutes(start);
      Future<void> save() async => repo.updateBlock(block.id, TimeBlocksCompanion(startTime: Value(start), endTime: Value(end), label: Value(label.text.trim()), taskId: Value(taskId)));
      return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Text('Task', style: TextStyle(color: p.muted, fontSize: 13, fontWeight: FontWeight.w500)),
        const SizedBox(height: 6),
        InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () async {
            final picked = await pickTask(ctx, ref, title: 'Choose task', noneLabel: 'No task');
            if (picked != null) setState(() => taskId = picked.task?.id);
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
            decoration: BoxDecoration(color: p.card2.withValues(alpha: 0.6), borderRadius: BorderRadius.circular(12), border: Border.all(color: p.border)),
            child: Text(task?.title ?? 'No task — tap to choose', style: TextStyle(color: task == null ? p.muted : p.fg)),
          ),
        ),
        if (task == null) ...[
          const SizedBox(height: 14),
          Text('Label', style: TextStyle(color: p.muted, fontSize: 13, fontWeight: FontWeight.w500)),
          const SizedBox(height: 6),
          TextField(controller: label, decoration: const InputDecoration(hintText: 'e.g. Deep work')),
        ],
        const SizedBox(height: 14),
        Row(children: [
          Text('Start', style: TextStyle(color: p.muted)),
          const SizedBox(width: 8),
          TimeButton(value: start, onChanged: (v) => setState(() => start = v)),
          const Spacer(),
          Text('End', style: TextStyle(color: p.muted)),
          const SizedBox(width: 8),
          TimeButton(value: end, onChanged: (v) => setState(() => end = v)),
        ]),
        if (!valid) Padding(padding: const EdgeInsets.only(top: 8), child: Text('End time must be after start time.', style: TextStyle(color: p.warning, fontSize: 12))),
        const SizedBox(height: 18),
        Row(children: [
          Btn('Delete', icon: Icons.delete_outline_rounded, kind: BtnKind.dangerGhost, onPressed: () async {
            if (await confirm(ctx, title: 'Delete this block?', confirmLabel: 'Delete', danger: true)) {
              await repo.deleteBlock(block.id);
              if (ctx.mounted) Navigator.pop(ctx);
            }
          }),
          const Spacer(),
          Btn('Save', onPressed: valid
              ? () async {
                  await save();
                  if (ctx.mounted) Navigator.pop(ctx);
                }
              : null),
          if (task?.status != 'done') ...[
            const SizedBox(width: 8),
            Btn('Focus', icon: Icons.play_arrow_rounded, kind: BtnKind.primary, onPressed: valid
                ? () async {
                    await save();
                    final minutes = (timeToMinutes(end) - timeToMinutes(start)).clamp(1, 180);
                    if (ctx.mounted) Navigator.pop(ctx);
                    if (context.mounted) context.go('/focus?${taskId != null ? 'task=$taskId&' : ''}minutes=$minutes');
                  }
                : null),
          ],
        ]),
      ]);
    }),
  );
}
