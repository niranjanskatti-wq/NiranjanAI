import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/theme/tokens.dart';
import '../../core/util/format.dart';
import '../../data/enums.dart';
import '../../data/providers.dart';
import '../../widgets/common.dart';
import 'export_service.dart';

const xlsxMime = 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet';

/// Saves bytes where the user chooses (e.g. Downloads) and says so.
Future<void> saveBytes(BuildContext context, Uint8List bytes, String name, String mime) async {
  final uri = await FilePicker.saveFile(fileName: name, bytes: bytes, mimeType: mime, dialogTitle: 'Save $name');
  if (uri != null && context.mounted) showToast(context, 'Saved $name');
}

Future<void> shareBytes(Uint8List bytes, String name, String mime) =>
    SharePlus.instance.share(ShareParams(files: [XFile.fromData(bytes, name: name, mimeType: mime)], fileNameOverrides: [name]));

enum _Who { everyone, people, stars }

/// Export all events to a neatly formatted Excel file.
class ExportScreen extends ConsumerStatefulWidget {
  const ExportScreen({super.key});

  @override
  ConsumerState<ExportScreen> createState() => _ExportScreenState();
}

class _ExportScreenState extends ConsumerState<ExportScreen> {
  _Who _who = _Who.everyone;
  final _people = <int>{};
  int _stars = 4;
  int? _month;
  EventType? _type;
  bool _numbers = true, _notes = true, _busy = false;
  Uint8List? _bytes;
  String _name = '';

  Future<void> _build() async {
    setState(() => _busy = true);
    HapticFeedback.lightImpact();
    final bytes = await ExportService(ref.read(databaseProvider), groupNames: await loadGroupNames(ref)).build(ExportOptions(
      personIds: _who == _Who.people ? {..._people} : null,
      minStars: _who == _Who.stars ? _stars : 0,
      month: _month,
      types: _type == null ? null : {_type!},
      includeNumbers: _numbers,
      includeNotes: _notes,
    ));
    setState(() {
      _bytes = Uint8List.fromList(bytes);
      _name = ExportService.fileName();
      _busy = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final people = ref.watch(peopleProvider).value ?? const [];
    return Scaffold(
      appBar: AppBar(title: const Text('Export to Excel')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 120),
        children: [
          Text('Makes an Excel file with four sheets: All Events, By Month, People and Important Dates. '
              'It opens in Excel, Google Sheets and WPS Office.', style: context.text.bodySmall),
          const SectionLabel('Who'),
          Wrap(spacing: 6, runSpacing: 6, children: [
            for (final (w, label) in [(_Who.everyone, 'Everyone'), (_Who.people, 'Choose people'), (_Who.stars, 'By stars')])
              ChoiceChip(
                label: Text(label),
                selected: _who == w,
                showCheckmark: false,
                labelStyle: context.text.titleSmall?.copyWith(color: _who == w ? c.bg : c.text),
                onSelected: (_) => setState(() => _who = w),
              ),
          ]),
          if (_who == _Who.stars)
            Row(children: [
              Text('At least', style: context.text.bodyMedium),
              Stars(value: _stars, size: 26, onChanged: (v) => setState(() => _stars = v)),
            ]),
          if (_who == _Who.people)
            for (final p in people)
              CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                value: _people.contains(p.id),
                onChanged: (v) => setState(() => v! ? _people.add(p.id) : _people.remove(p.id)),
                title: Text(p.name),
              ),
          const SectionLabel('Only'),
          Row(children: [
            Expanded(
              child: DropdownButtonFormField<int?>(
                initialValue: _month,
                decoration: const InputDecoration(labelText: 'Month'),
                items: [
                  const DropdownMenuItem(value: null, child: Text('Any month')),
                  for (var m = 1; m <= 12; m++) DropdownMenuItem(value: m, child: Text(monthNames[m - 1])),
                ],
                onChanged: (v) => setState(() => _month = v),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: DropdownButtonFormField<EventType?>(
                initialValue: _type,
                isExpanded: true,
                decoration: const InputDecoration(labelText: 'Event type'),
                items: [
                  const DropdownMenuItem(value: null, child: Text('All types')),
                  for (final t in EventType.values.where((t) => !t.isFestival))
                    DropdownMenuItem(value: t, child: Text(t.label, overflow: TextOverflow.ellipsis)),
                ],
                onChanged: (v) => setState(() => _type = v),
              ),
            ),
          ]),
          const SectionLabel('Include'),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Phone numbers'),
            subtitle: const Text('Turn off before sharing with family'),
            value: _numbers,
            onChanged: (v) => setState(() => _numbers = v),
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Notes'),
            value: _notes,
            onChanged: (v) => setState(() => _notes = v),
          ),
          if (_bytes != null) ...[
            const SizedBox(height: 12),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                  Row(children: [
                    Icon(Icons.table_chart_outlined, color: c.call),
                    const SizedBox(width: 10),
                    Expanded(child: Text(_name, style: context.text.titleMedium)),
                  ]),
                  const SizedBox(height: 12),
                  FilledButton.icon(
                    onPressed: () => saveBytes(context, _bytes!, _name, xlsxMime),
                    icon: const Icon(Icons.download_rounded),
                    label: const Text('Save to phone (Downloads)'),
                  ),
                  const SizedBox(height: 8),
                  OutlinedButton.icon(
                    onPressed: () => shareBytes(_bytes!, _name, xlsxMime),
                    icon: const Icon(Icons.ios_share),
                    label: const Text('Share: WhatsApp, email, Google Drive…'),
                  ),
                ]),
              ),
            ),
          ],
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: FilledButton(
            onPressed: _busy || (_who == _Who.people && _people.isEmpty) ? null : _build,
            child: Text(_busy ? 'Making the file…' : (_bytes == null ? 'Export' : 'Export again')),
          ),
        ),
      ),
    );
  }
}

/// personId → group names; filled in by Phase 7 groups.
Future<Map<int, List<String>>> Function(WidgetRef ref) loadGroupNames = (_) async => const {};
