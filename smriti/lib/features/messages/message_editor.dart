import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/tokens.dart';
import '../../data/providers.dart';
import '../../widgets/common.dart';
import 'library_screen.dart';
import 'message_engine.dart';
import 'message_store.dart';

/// Festival ids and English names from assets/festivals/festivals.json.
final festivalNamesProvider = FutureProvider<Map<String, String>>((ref) async {
  final j = jsonDecode(await rootBundle.loadString('assets/festivals/festivals.json')) as Map<String, dynamic>;
  return {
    for (final f in j['festivals'] as List) f['id'] as String: (f['name'] as Map)['en'] as String,
  };
});

Future<void> openMessageEditor(BuildContext context,
        {MessageTemplate? original, Lang lang = Lang.en, Occasion occasion = Occasion.birthday}) =>
    Navigator.of(context, rootNavigator: true).push(MaterialPageRoute(
      builder: (_) => MessageEditorScreen(original: original, lang: lang, occasion: occasion),
    ));

const placeholders = <String, String>{
  '{nickname}': 'Name they go by',
  '{name}': 'First name',
  '{age}': 'Age (60)',
  '{age_th}': 'Age (60th)',
  '{years_married}': 'Years married',
  '{years_th}': 'Years (25th)',
  '{couple_names}': 'Both names',
  '{relation}': 'Relationship',
  '{festival}': 'Festival name',
  '{my_name}': 'Your name',
};

/// Write a new message, or edit one (built-in edits are saved as your copy).
class MessageEditorScreen extends ConsumerStatefulWidget {
  const MessageEditorScreen({super.key, this.original, required this.lang, required this.occasion});

  final MessageTemplate? original;
  final Lang lang;
  final Occasion occasion;

  @override
  ConsumerState<MessageEditorScreen> createState() => _MessageEditorScreenState();
}

class _MessageEditorScreenState extends ConsumerState<MessageEditorScreen> {
  late final _text = TextEditingController(text: widget.original?.text ?? '');
  late Occasion _occasion = widget.original?.occasion ?? widget.occasion;
  late Tone _tone = widget.original?.tone ?? Tone.short;
  late Lang _lang = widget.original?.lang ?? widget.lang;
  late final Set<String> _relations = {...?widget.original?.relations.where((r) => r != 'any')};
  late String? _festival = widget.original?.festival;

  void _insert(String p) {
    final sel = _text.selection;
    final pos = sel.isValid ? sel.start : _text.text.length;
    _text.text = _text.text.replaceRange(pos, sel.isValid ? sel.end : pos, p);
    _text.selection = TextSelection.collapsed(offset: pos + p.length);
    setState(() {});
  }

  Future<void> _save() async {
    if (_text.text.trim().isEmpty) return showToast(context, 'Please write the message');
    await MessageStore(ref.read(databaseProvider)).save(
      original: widget.original,
      occasion: _occasion,
      relations: _relations.toList(),
      tone: _tone,
      lang: _lang,
      festival: _festival,
      text: _text.text.trim(),
    );
    HapticFeedback.lightImpact();
    if (!mounted) return;
    showToast(context, 'Saved to My messages');
    Navigator.pop(context);
  }

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final fests = ref.watch(festivalNamesProvider).value ?? const {};
    final editingBuiltIn = widget.original != null && !widget.original!.custom;
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.original == null ? 'Write a message' : 'Edit message'),
        actions: [
          if (widget.original?.custom ?? false)
            IconButton(
              tooltip: 'Delete',
              icon: Icon(Icons.delete_outline, color: c.alert),
              onPressed: () async {
                await MessageStore(ref.read(databaseProvider)).delete(widget.original!);
                if (context.mounted) Navigator.pop(context);
              },
            ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 120),
        children: [
          if (editingBuiltIn)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Text('Your edited copy will replace this message everywhere.', style: context.text.bodySmall),
            ),
          TextField(
            controller: _text,
            minLines: 4,
            maxLines: 10,
            textCapitalization: TextCapitalization.sentences,
            onChanged: (_) => setState(() {}),
            decoration: const InputDecoration(hintText: 'Happy birthday, {nickname}! …'),
          ),
          const SizedBox(height: 8),
          Text('Tap to insert — filled in automatically when you send:', style: context.text.bodySmall),
          const SizedBox(height: 6),
          Wrap(spacing: 6, runSpacing: 6, children: [
            for (final e in placeholders.entries)
              ActionChip(label: Text(e.value), tooltip: e.key, onPressed: () => _insert(e.key)),
          ]),
          const SizedBox(height: 12),
          if (_text.text.isNotEmpty) ...[
            const SectionLabel('Preview'),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(color: c.raised, borderRadius: BorderRadius.circular(16)),
              child: Text(sampleContext.fill(_text.text), style: context.text.bodyLarge),
            ),
          ],
          const SectionLabel('Occasion'),
          Wrap(spacing: 6, runSpacing: 6, children: [
            for (final o in Occasion.values)
              ChoiceChip(
                label: Text(o.label),
                selected: _occasion == o,
                showCheckmark: false,
                labelStyle: context.text.titleSmall?.copyWith(color: _occasion == o ? c.bg : c.text),
                onSelected: (_) => setState(() => _occasion = o),
              ),
          ]),
          if (_occasion == Occasion.festival) ...[
            const SectionLabel('Festival'),
            DropdownButtonFormField<String?>(
              initialValue: _festival,
              items: [
                const DropdownMenuItem(value: null, child: Text('Any festival')),
                for (final e in fests.entries) DropdownMenuItem(value: e.key, child: Text(e.value)),
              ],
              onChanged: (v) => setState(() => _festival = v),
            ),
          ],
          const SectionLabel('For'),
          Wrap(spacing: 6, runSpacing: 6, children: [
            FilterChip(
              label: const Text('Anyone'),
              selected: _relations.isEmpty,
              showCheckmark: false,
              labelStyle: context.text.titleSmall?.copyWith(color: _relations.isEmpty ? c.bg : c.text),
              onSelected: (_) => setState(_relations.clear),
            ),
            for (final e in relationFilters.entries)
              FilterChip(
                label: Text(e.value),
                selected: _relations.contains(e.key),
                showCheckmark: false,
                labelStyle: context.text.titleSmall?.copyWith(color: _relations.contains(e.key) ? c.bg : c.text),
                onSelected: (v) => setState(() => v ? _relations.add(e.key) : _relations.remove(e.key)),
              ),
          ]),
          const SectionLabel('Tone'),
          Wrap(spacing: 6, runSpacing: 6, children: [
            for (final t in Tone.values)
              ChoiceChip(
                label: Text(t.label),
                selected: _tone == t,
                showCheckmark: false,
                labelStyle: context.text.titleSmall?.copyWith(color: _tone == t ? c.bg : c.text),
                onSelected: (_) => setState(() => _tone = t),
              ),
          ]),
          const SectionLabel('Language'),
          SegmentedButton<Lang>(
            showSelectedIcon: false,
            segments: [for (final l in Lang.values) ButtonSegment(value: l, label: Text(l.label))],
            selected: {_lang},
            onSelectionChanged: (s) => setState(() => _lang = s.first),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: FilledButton(onPressed: _save, child: const Text('Save message')),
        ),
      ),
    );
  }
}
