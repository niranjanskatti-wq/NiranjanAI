import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/tokens.dart';
import '../../data/providers.dart';
import '../../ui/widgets.dart';

SettingsController settingsCtl(WidgetRef ref) => ref.read(settingsProvider.notifier);

class ResetButton extends StatelessWidget {
  const ResetButton({super.key, required this.label, required this.onReset});
  final String label;
  final Future<void> Function() onReset;
  @override
  Widget build(BuildContext context) => Btn('Reset', icon: Icons.restart_alt_rounded, kind: BtnKind.ghost, small: true, onPressed: () async {
        if (await confirm(context, title: 'Reset $label to defaults?', confirmLabel: 'Reset')) {
          await onReset();
          if (context.mounted) toast(context, '$label reset');
        }
      });
}

/// Edit, add, remove and reorder a list of strings (review questions).
class StringListEditor extends StatefulWidget {
  const StringListEditor({super.key, required this.items, required this.onChanged, this.addHint = 'Add a question', this.emptyText});
  final List<String> items;
  final ValueChanged<List<String>> onChanged;
  final String addHint;
  final String? emptyText;
  @override
  State<StringListEditor> createState() => _StringListEditorState();
}

class _StringListEditorState extends State<StringListEditor> {
  final add = TextEditingController();
  @override
  void dispose() {
    add.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    final items = widget.items;
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      ReorderableListView(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        buildDefaultDragHandles: false,
        onReorderItem: (from, to) {
          final next = [...items];
          final m = next.removeAt(from);
          next.insert(to, m);
          widget.onChanged(next);
        },
        children: [
          for (var i = 0; i < items.length; i++)
            Padding(
              key: ValueKey('$i:${items[i]}'),
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(children: [
                ReorderableDragStartListener(index: i, child: Padding(padding: const EdgeInsets.all(6), child: Icon(Icons.drag_indicator_rounded, size: 18, color: p.muted.withValues(alpha: 0.7)))),
                Expanded(
                  child: CommitField(
                    value: items[i],
                    onCommit: (v) {
                      if (v.trim().isEmpty) return;
                      final next = [...items];
                      next[i] = v.trim();
                      widget.onChanged(next);
                    },
                  ),
                ),
                IconBtn(Icons.close_rounded, size: 34, tooltip: 'Remove', onPressed: () => widget.onChanged([...items]..removeAt(i))),
              ]),
            ),
        ],
      ),
      if (items.isEmpty && widget.emptyText != null) Padding(padding: const EdgeInsets.symmetric(vertical: 6), child: Text(widget.emptyText!, style: TextStyle(color: p.muted, fontSize: 13))),
      Row(children: [
        const SizedBox(width: 30),
        Expanded(child: TextField(controller: add, decoration: InputDecoration(hintText: widget.addHint), onSubmitted: (_) => _add())),
        const SizedBox(width: 6),
        IconBtn(Icons.add_rounded, filled: true, size: 36, tooltip: 'Add', onPressed: _add),
      ]),
    ]);
  }

  void _add() {
    final v = add.text.trim();
    if (v.isEmpty) return;
    widget.onChanged([...widget.items, v]);
    add.clear();
  }
}

/// Text field that commits on submit / focus loss (avoids writing settings on every keystroke).
class CommitField extends StatefulWidget {
  const CommitField({super.key, required this.value, required this.onCommit, this.hint});
  final String value;
  final ValueChanged<String> onCommit;
  final String? hint;
  @override
  State<CommitField> createState() => _CommitFieldState();
}

class _CommitFieldState extends State<CommitField> {
  late final c = TextEditingController(text: widget.value);
  final f = FocusNode();
  @override
  void initState() {
    super.initState();
    f.addListener(() {
      if (!f.hasFocus) _commit();
    });
  }

  @override
  void didUpdateWidget(CommitField old) {
    super.didUpdateWidget(old);
    if (old.value != widget.value && !f.hasFocus) c.text = widget.value;
  }

  void _commit() {
    if (c.text != widget.value) widget.onCommit(c.text);
  }

  @override
  void dispose() {
    c.dispose();
    f.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => TextField(controller: c, focusNode: f, decoration: InputDecoration(hintText: widget.hint), onSubmitted: (_) => _commit());
}
