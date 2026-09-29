import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart' as p;
import 'package:permission_handler/permission_handler.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/theme/tokens.dart';
import '../../data/providers.dart';
import '../../widgets/common.dart';
import '../reminders/notification_service.dart';
import 'backup_service.dart';

final _when = DateFormat('d MMM yyyy, h:mm a');

class BackupScreen extends ConsumerStatefulWidget {
  const BackupScreen({super.key});

  @override
  ConsumerState<BackupScreen> createState() => _BackupScreenState();
}

class _BackupScreenState extends ConsumerState<BackupScreen> {
  List<File> _files = const [];
  String _folder = '';
  bool _auto = true, _busy = false;
  DateTime? _last;

  @override
  void initState() {
    super.initState();
    _askStorage().then((_) => _refresh());
  }

  /// Android 9 and 10 need permission to write to Download.
  Future<void> _askStorage() async {
    final sdk = await NotificationService.sdkInt();
    if (sdk > 0 && sdk <= 29) await Permission.storage.request();
  }

  Future<void> _refresh() async {
    final db = ref.read(databaseProvider);
    final dir = await BackupService.folder();
    final files = await BackupService.list(dir);
    final auto = await db.getSetting('autoBackup') != 'false';
    final last = DateTime.tryParse(await db.getSetting('lastBackup') ?? '');
    if (mounted) {
      setState(() {
        _files = files;
        _folder = dir.path;
        _auto = auto;
        _last = last;
      });
    }
  }

  Future<void> _backupNow() async {
    setState(() => _busy = true);
    try {
      final f = await BackupService(ref.read(databaseProvider)).create();
      HapticFeedback.lightImpact();
      if (mounted) showToast(context, 'Saved ${p.basename(f.path)}');
    } catch (e) {
      if (mounted) showToast(context, 'Backup failed: $e');
    }
    if (mounted) setState(() => _busy = false);
    await _refresh();
  }

  Future<void> _restore(List<int> bytes) async {
    final manifest = BackupService.inspect(bytes);
    if (manifest == null) {
      showToast(context, 'That file is not a Smriti backup.');
      return;
    }
    final created = DateTime.tryParse(manifest['created'] as String? ?? '');
    final ok = await confirm(
      context,
      title: 'Restore this backup?',
      message: 'Everything in Smriti will be replaced with the backup from '
          '${created == null ? 'this file' : _when.format(created)} (${manifest['photos']} photos). '
          'Smriti will close afterwards — just open it again.',
      action: 'Restore',
      danger: true,
    );
    if (!ok) return;
    setState(() => _busy = true);
    // Keep a safety copy of the current data first.
    try {
      await BackupService(ref.read(databaseProvider)).create();
    } catch (_) {}
    await ref.read(databaseProvider).close();
    await BackupService.restoreFiles(bytes);
    await SystemNavigator.pop();
    exit(0);
  }

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return Scaffold(
      appBar: AppBar(title: const Text('Backup & restore')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 40),
        children: [
          Text('A backup has everything: people, events, reminders, messages, wish history and photos.',
              style: context.text.bodyMedium),
          const SizedBox(height: 12),
          Card(
            child: SwitchListTile(
              title: const Text('Automatic weekly backup'),
              subtitle: Text(_last == null ? 'No backup yet' : 'Last: ${_when.format(_last!)}'),
              value: _auto,
              onChanged: (v) async {
                await ref.read(databaseProvider).setSetting('autoBackup', '$v');
                _refresh();
              },
            ),
          ),
          const SizedBox(height: 8),
          FilledButton.icon(
            onPressed: _busy ? null : _backupNow,
            icon: const Icon(Icons.backup_outlined),
            label: Text(_busy ? 'Working…' : 'Back up now'),
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: _busy
                ? null
                : () async {
                    final f = await FilePicker.pickFile(
                        type: FileType.custom, allowedExtensions: const ['zip'], dialogTitle: 'Choose a Smriti backup');
                    if (f != null && context.mounted) await _restore(await f.xFile.readAsBytes());
                  },
            icon: const Icon(Icons.restore_rounded),
            label: const Text('Restore from a file…'),
          ),
          const SizedBox(height: 16),
          SectionLabel('Backups on this phone (last ${BackupService.keep} kept)'),
          Text(_folder, style: context.text.bodySmall),
          const SizedBox(height: 8),
          if (_files.isEmpty) Text('None yet.', style: context.text.bodyMedium?.copyWith(color: c.muted)),
          for (final f in _files)
            Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                leading: const Icon(Icons.inventory_2_outlined),
                title: Text(p.basenameWithoutExtension(f.path)),
                subtitle: Text('${(f.lengthSync() / 1024 / 1024).toStringAsFixed(1)} MB'),
                trailing: PopupMenuButton<String>(
                  onSelected: (v) async {
                    if (v == 'restore') await _restore(await f.readAsBytes());
                    if (v == 'share') await SharePlus.instance.share(ShareParams(files: [XFile(f.path)]));
                  },
                  itemBuilder: (_) => const [
                    PopupMenuItem(value: 'share', child: Text('Share (Google Drive, email…)')),
                    PopupMenuItem(value: 'restore', child: Text('Restore')),
                  ],
                ),
              ),
            ),
          const SizedBox(height: 12),
          Text('Tip: share a backup to Google Drive now and then, so it is safe even if you lose the phone.',
              style: context.text.bodySmall),
        ],
      ),
    );
  }
}
