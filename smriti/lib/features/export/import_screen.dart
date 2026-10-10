import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/tokens.dart';
import '../../data/providers.dart';
import '../../widgets/common.dart';
import 'export_screen.dart';
import 'export_service.dart';
import 'import_service.dart';

/// Bulk-add or restore from Excel, with a preview before anything is saved.
class ImportScreen extends ConsumerStatefulWidget {
  const ImportScreen({super.key});

  @override
  ConsumerState<ImportScreen> createState() => _ImportScreenState();
}

class _ImportScreenState extends ConsumerState<ImportScreen> {
  List<ImportRow>? _rows;
  bool _busy = false;
  String? _file;

  Future<void> _pick() async {
    final f = await FilePicker.pickFile(type: FileType.custom, allowedExtensions: const ['xlsx'], dialogTitle: 'Choose Excel file');
    if (f == null) return;
    setState(() => _busy = true);
    try {
      final bytes = await f.xFile.readAsBytes();
      final rows = await ImportService(ref.read(databaseProvider)).preview(bytes);
      setState(() {
        _rows = rows;
        _file = f.name;
      });
    } catch (e) {
      if (mounted) showToast(context, 'That file could not be read. Is it an .xlsx Excel file?');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _apply() async {
    setState(() => _busy = true);
    final n = await ImportService(ref.read(databaseProvider)).apply(_rows!);
    HapticFeedback.lightImpact();
    if (!mounted) return;
    showToast(context, 'Added $n rows');
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final rows = _rows;
    final ready = rows?.where((r) => r.status == ImportStatus.ready).length ?? 0;
    final dup = rows?.where((r) => r.status == ImportStatus.duplicate).length ?? 0;
    final err = rows?.where((r) => r.status == ImportStatus.error).length ?? 0;
    return Scaffold(
      appBar: AppBar(title: const Text('Import from Excel')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 120),
        children: [
          Text('Add many people and dates at once, or bring everything back on a new phone from a Smriti export. '
              'Nothing is saved until you confirm.', style: context.text.bodyMedium),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: () async {
              final b = Uint8List.fromList(ExportService.template());
              await saveBytes(context, b, 'Smriti import template.xlsx', xlsxMime);
            },
            icon: const Icon(Icons.description_outlined),
            label: const Text('Get the blank template'),
          ),
          const SizedBox(height: 8),
          FilledButton.icon(
            onPressed: _busy ? null : _pick,
            icon: const Icon(Icons.upload_file_rounded),
            label: Text(_file == null ? 'Choose Excel file' : 'Choose another file'),
          ),
          if (rows != null) ...[
            const SizedBox(height: 16),
            Text(_file ?? '', style: context.text.titleMedium),
            const SizedBox(height: 4),
            Wrap(spacing: 8, children: [
              _pill(context, '$ready to add', c.call),
              _pill(context, '$dup already in Smriti', c.muted),
              _pill(context, '$err with problems', c.alert),
            ]),
            const SizedBox(height: 8),
            for (final r in [
              ...rows.where((r) => r.status == ImportStatus.error),
              ...rows.where((r) => r.status == ImportStatus.ready),
              ...rows.where((r) => r.status == ImportStatus.duplicate),
            ])
              Card(
                margin: const EdgeInsets.only(bottom: 6),
                color: r.status == ImportStatus.error ? c.alert.withValues(alpha: 0.10) : null,
                child: ListTile(
                  dense: true,
                  leading: Icon(
                    switch (r.status) {
                      ImportStatus.ready => Icons.add_circle_outline,
                      ImportStatus.duplicate => Icons.content_copy_outlined,
                      ImportStatus.error => Icons.error_outline,
                    },
                    color: switch (r.status) {
                      ImportStatus.ready => c.call,
                      ImportStatus.duplicate => c.muted,
                      ImportStatus.error => c.alert,
                    },
                  ),
                  title: Text(r.summary),
                  subtitle: Text('${r.sheet}, row ${r.row}${r.problem == null ? '' : ' · ${r.problem}'}'),
                ),
              ),
          ],
        ],
      ),
      bottomNavigationBar: rows == null
          ? null
          : SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                child: FilledButton(
                  onPressed: ready == 0 || _busy ? null : _apply,
                  child: Text(ready == 0 ? 'Nothing new to add' : 'Add $ready${err > 0 ? ' (skip $err with problems)' : ''}'),
                ),
              ),
            ),
    );
  }

  Widget _pill(BuildContext context, String t, Color color) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(999), border: Border.all(color: color)),
        child: Text(t, style: context.text.labelMedium?.copyWith(color: color)),
      );
}
