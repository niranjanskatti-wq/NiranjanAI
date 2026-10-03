import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/settings.dart';
import '../../data/backup_format.dart';
import '../../data/demo.dart';
import '../../data/providers.dart';
import '../../ui/widgets.dart';
import '../focus/focus_controller.dart';
import 'backup_section.dart' show BackupPreview;
import 'controls.dart';

/// Writes files to the cache and opens the Android share sheet (save to Files, Drive, email…).
Future<void> shareFiles(Map<String, String> files, String subject) async {
  final dir = await getTemporaryDirectory();
  final xfiles = <XFile>[];
  for (final e in files.entries) {
    final f = File('${dir.path}/${e.key}');
    await f.writeAsString(e.value);
    xfiles.add(XFile(f.path, mimeType: e.key.endsWith('.csv') ? 'text/csv' : 'application/json'));
  }
  await SharePlus.instance.share(ShareParams(files: xfiles, subject: subject, title: subject));
}

class DataSection extends ConsumerStatefulWidget {
  const DataSection({super.key});
  @override
  ConsumerState<DataSection> createState() => _DataSectionState();
}

class _DataSectionState extends ConsumerState<DataSection> {
  String? busy;

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(settingsProvider);
    final ctl = settingsCtl(ref);
    final db = ref.read(databaseProvider);

    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      SettingsSection(title: 'Export', children: [
        SettingsRow(
          label: 'Full backup (JSON)',
          description: 'Everything, including settings. Can be imported later.',
          trailing: Btn('Export', icon: Icons.data_object_rounded, small: true, onPressed: () async {
            final file = await buildBackup(db, ctl.current);
            await shareFiles({backupFilename(): file.encode()}, 'Deepwork backup');
          }),
        ),
        SettingsRow(
          label: 'Spreadsheets (CSV)',
          description: 'Sessions, tasks and distractions as three files.',
          trailing: Btn('Export', icon: Icons.table_chart_outlined, small: true, onPressed: () async {
            final csv = await buildCsvs(db);
            final d = DateFormat('yyyy-MM-dd').format(DateTime.now());
            await shareFiles({for (final e in csv.entries) 'deepwork-${e.key}-$d.csv': e.value}, 'Deepwork CSV export');
          }),
        ),
      ]),
      SettingsSection(title: 'Import', children: [
        SettingsRow(
          label: 'Import from a JSON backup',
          description: "You'll see a preview before anything changes.",
          trailing: Btn('Choose file', icon: Icons.upload_file_rounded, small: true, onPressed: _import),
        ),
      ]),
      SettingsSection(title: 'Demo data', children: [
        SettingsRow(
          label: 'Load demo data',
          description: 'About 60 days of sample sessions, tasks and reviews to preview Insights. Kept separate from your own data.',
          trailing: Btn(busy == 'demo' ? 'Loading…' : s.b('demoLoaded') ? 'Reload' : 'Load', small: true, onPressed: busy != null
              ? null
              : () async {
                  setState(() => busy = 'demo');
                  final n = await loadDemoData(db);
                  await ctl.set('demoLoaded', true);
                  if (!context.mounted) return;
                  setState(() => busy = null);
                  toast(context, 'Loaded $n demo sessions');
                }),
        ),
        SettingsRow(
          label: 'Clear demo data',
          description: 'Removes only demo records.',
          trailing: Btn('Clear', small: true, onPressed: busy != null || !s.b('demoLoaded')
              ? null
              : () async {
                  setState(() => busy = 'clear');
                  await clearDemoData(db);
                  await ctl.set('demoLoaded', false);
                  if (!context.mounted) return;
                  setState(() => busy = null);
                  toast(context, 'Demo data cleared');
                }),
        ),
      ]),
      SettingsSection(title: 'Reset & delete', children: [
        SettingsRow(
          label: 'Reset all settings',
          description: 'Restores default settings. Your tasks, sessions and reviews are kept; app lock and Drive connection are kept.',
          trailing: Btn('Reset', icon: Icons.restart_alt_rounded, small: true, onPressed: () async {
            if (!await confirm(context, title: 'Reset all settings to defaults?', confirmLabel: 'Reset', danger: true)) return;
            final cur = ctl.current;
            await ctl.replace(AppSettings.defaults().edit((m) {
              m['lock'] = deepCopy(cur.json['lock']);
              m['backup'] = deepCopy(cur.json['backup']);
              m['demoLoaded'] = cur.json['demoLoaded'];
              m['modules']['backup'] = cur.on('backup');
            }));
            if (context.mounted) toast(context, 'Settings reset');
          }),
        ),
        SettingsRow(
          label: 'Delete all data',
          description: 'Permanently erases everything on this phone. Backups in Google Drive are not touched.',
          trailing: Btn('Delete', icon: Icons.delete_forever_rounded, kind: BtnKind.danger, small: true, onPressed: () async {
            if (!await confirm(context,
                title: 'Delete all data?',
                description: 'All tasks, sessions, distractions, reviews and settings on this phone will be erased. This cannot be undone. Consider exporting a backup first.',
                confirmLabel: 'Continue',
                danger: true)) {
              return;
            }
            if (!context.mounted) return;
            if (!await confirm(context, title: 'Are you absolutely sure?', confirmLabel: 'Delete everything', danger: true, typeToConfirm: 'DELETE')) return;
            ref.read(focusProvider.notifier).reset();
            await deleteAllData(db);
            await ctl.replace(AppSettings.defaults());
            if (context.mounted) toast(context, 'All data deleted');
          }),
        ),
      ]),
    ]);
  }

  Future<void> _import() async {
    try {
      final f = await FilePicker.pickFile(type: FileType.any);
      if (f == null) return;
      final parsed = parseBackup(utf8.decode(await f.readAsBytes()));
      if (!mounted) return;
      await showAppSheet(context, title: 'Import this backup?', description: 'All current data on this phone will be replaced.', builder: (ctx) {
        return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          BackupPreview(file: parsed),
          const SizedBox(height: 16),
          Row(children: [
            Btn('Cancel', kind: BtnKind.ghost, onPressed: () => Navigator.pop(ctx)),
            const Spacer(),
            Btn('Import', icon: Icons.download_rounded, kind: BtnKind.danger, onPressed: () async {
              if (!await confirm(ctx, title: 'Replace all data?', description: 'This cannot be undone.', confirmLabel: 'Import', danger: true)) return;
              final ctl = settingsCtl(ref);
              final next = await restoreBackup(ref.read(databaseProvider), parsed, ctl.current);
              await ctl.replace(next);
              if (ctx.mounted) Navigator.pop(ctx);
              if (mounted) toast(context, 'Backup imported');
            }),
          ]),
        ]);
      });
    } on BackupFormatException catch (e) {
      if (mounted) toast(context, e.message, error: true);
    } catch (e) {
      if (mounted) toast(context, 'Could not read that file.', error: true);
    }
  }
}
