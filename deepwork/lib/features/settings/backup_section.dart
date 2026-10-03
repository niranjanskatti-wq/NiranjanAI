import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/theme/tokens.dart';
import '../../core/util/format.dart';
import '../../data/backup_format.dart';
import '../../data/providers.dart';
import '../../services/drive.dart';
import '../../services/native.dart';
import '../../ui/widgets.dart';
import '../backup/backup_service.dart';
import 'controls.dart';

class BackupSection extends ConsumerStatefulWidget {
  const BackupSection({super.key});
  @override
  ConsumerState<BackupSection> createState() => _BackupSectionState();
}

class _BackupSectionState extends ConsumerState<BackupSection> {
  String? busy;

  Future<void> _connect() async {
    setState(() => busy = 'connect');
    final ctl = settingsCtl(ref);
    try {
      final token = await DriveClient.instance.interactiveToken();
      final account = await DriveClient.instance.accountEmail(token);
      await ctl.edit((m) {
        m['backup']['connected'] = true;
        m['backup']['account'] = account;
        m['backup']['needsReconnect'] = false;
        m['backup']['lastError'] = null;
        m['modules']['backup'] = true;
      });
      if (mounted) toast(context, 'Google Drive connected');
      if (ctl.current['backup.lastBackupAt'] == null) {
        final (outcome, _) = await runBackup(ctl, ref.read(databaseProvider), interactive: true);
        if (outcome == BackupOutcome.ok && mounted) toast(context, 'First backup saved to Drive');
      }
    } catch (e) {
      if (mounted) toast(context, '$e', error: true);
    } finally {
      if (mounted) setState(() => busy = null);
    }
  }

  Future<void> _backupNow() async {
    setState(() => busy = 'backup');
    final (outcome, msg) = await runBackup(settingsCtl(ref), ref.read(databaseProvider), interactive: true);
    if (!mounted) return;
    setState(() => busy = null);
    if (outcome == BackupOutcome.ok) {
      toast(context, 'Backed up to Google Drive');
    } else if (msg != null) {
      toast(context, msg, error: true);
    }
  }

  Future<void> _disconnect() async {
    if (!await confirm(context,
        title: 'Disconnect Google Drive?',
        description: 'Automatic backups stop and the sign-in is removed from this phone. Backups already in Drive are kept.',
        confirmLabel: 'Disconnect',
        danger: true)) {
      return;
    }
    await DriveClient.instance.disconnect(await DriveClient.instance.silentToken());
    await settingsCtl(ref).edit((m) {
      m['backup']['connected'] = false;
      m['backup']['account'] = null;
      m['backup']['needsReconnect'] = false;
      m['backup']['lastError'] = null;
      m['modules']['backup'] = false;
    });
    if (mounted) toast(context, 'Disconnected from Google Drive');
  }

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(settingsProvider);
    final p = context.pal;
    final ctl = settingsCtl(ref);

    if (!s.b('backup.connected')) {
      return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        SettingsSection(title: 'Google Drive', children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Container(width: 40, height: 40, decoration: BoxDecoration(color: p.accentSoft, borderRadius: BorderRadius.circular(12)), child: Icon(Icons.cloud_outlined, color: p.accent)),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    const Text('Weekly backup to your Google Drive', style: TextStyle(fontWeight: FontWeight.w600)),
                    Text('Saved to a “Deepwork Backups” folder. The app can only access files it creates.', style: TextStyle(color: p.muted, fontSize: 13)),
                  ]),
                ),
              ]),
              const SizedBox(height: 14),
              Btn(busy == 'connect' ? 'Connecting…' : 'Connect Google Drive', icon: Icons.cloud_outlined, kind: BtnKind.primary, onPressed: busy == null ? _connect : null),
            ]),
          ),
        ]),
        const _AndroidSetupHelp(),
      ]);
    }

    final last = s['backup.lastBackupAt'] as num?;
    final due = isBackupDue(s);
    final needs = s.b('backup.needsReconnect');
    final error = s['backup.lastError'] as String?;
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      if (needs || error != null) ...[
        AppCard(
          borderColor: p.warning.withValues(alpha: 0.45),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Icon(Icons.warning_amber_rounded, color: p.warning),
            const SizedBox(width: 12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(needs ? 'Google needs you to reconnect' : 'The last backup did not complete', style: const TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 3),
                Text(needs ? 'Reconnect to keep weekly backups running. Nothing else is affected.' : error!, style: TextStyle(color: p.muted, fontSize: 13)),
                const SizedBox(height: 10),
                Btn(needs ? 'Reconnect' : 'Retry', kind: BtnKind.primary, small: true, onPressed: busy == null ? _backupNow : null),
              ]),
            ),
          ]),
        ),
        const Gap(),
      ],
      SettingsSection(title: 'Status', children: [
        SettingsRow(label: 'Account', description: s['backup.account'] as String? ?? 'Connected', trailing: Btn('Disconnect', kind: BtnKind.ghost, small: true, onPressed: _disconnect)),
        SwitchRow(label: 'Automatic weekly backup', description: 'Runs when you open the app (online) once a backup is due.', value: s.on('backup'), onChanged: (v) => ctl.set('modules.backup', v)),
        SettingsRow(label: 'Last successful backup', description: last == null ? 'Never' : '${DateFormat('MMM d, yyyy · h:mm a').format(DateTime.fromMillisecondsSinceEpoch(last.toInt()))} (${relativeDays(last.toInt())})'),
        SettingsRow(label: 'Next backup', description: !s.on('backup') ? 'Paused' : due ? 'Due now' : DateFormat('EEEE, MMM d').format(nextBackupDate(s))),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 14),
          child: Wrap(spacing: 8, runSpacing: 8, children: [
            Btn(busy == 'backup' ? 'Backing up…' : 'Back up now', icon: Icons.cloud_upload_outlined, kind: BtnKind.primary, onPressed: busy == null ? _backupNow : null),
            Btn('Restore from Google Drive', icon: Icons.cloud_download_outlined, onPressed: busy == null ? () => _restore(context) : null),
          ]),
        ),
      ]),
      SettingsSection(title: 'Schedule', children: [
        SettingsRow(
          label: 'Backup day',
          trailing: DropdownButton<int>(
            value: s.i('backup.day'),
            underline: const SizedBox(),
            items: [for (var i = 0; i < 7; i++) DropdownMenuItem(value: i, child: Text(dayNames[i]))],
            onChanged: (v) => v == null ? null : ctl.set('backup.day', v),
          ),
        ),
        SettingsRow(
          label: 'Keep the last',
          description: 'Older backups created by Deepwork are deleted from Drive.',
          trailing: NumStepper(value: s.i('backup.retention'), min: 1, max: 52, suffix: 'backups', onChanged: (v) => ctl.set('backup.retention', v)),
        ),
      ]),
    ]);
  }

  Future<void> _restore(BuildContext context) async {
    await showAppSheet(context, title: 'Restore from Google Drive', description: 'Choose a backup to preview.', builder: (ctx) => const _RestoreList());
  }
}

class _RestoreList extends ConsumerStatefulWidget {
  const _RestoreList();
  @override
  ConsumerState<_RestoreList> createState() => _RestoreListState();
}

class _RestoreListState extends ConsumerState<_RestoreList> {
  List<DriveBackupFile>? files;
  BackupFile? preview;
  String? previewName, error;
  bool loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<String> _token() async => await DriveClient.instance.silentToken() ?? await DriveClient.instance.interactiveToken();

  Future<void> _load() async {
    setState(() {
      loading = true;
      error = null;
    });
    try {
      final f = await DriveClient.instance.listBackups(await _token());
      if (mounted) setState(() => files = f);
    } catch (e) {
      if (mounted) setState(() => error = '$e');
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  Future<void> _pick(DriveBackupFile f) async {
    setState(() => loading = true);
    try {
      final text = await DriveClient.instance.download(await _token(), f.id);
      final parsed = parseBackup(text);
      if (mounted) {
        setState(() {
          preview = parsed;
          previewName = f.name;
        });
      }
    } catch (e) {
      if (mounted) setState(() => error = '$e');
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    if (loading) return const Padding(padding: EdgeInsets.all(30), child: Center(child: CircularProgressIndicator()));
    if (error != null) {
      return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(error!, style: TextStyle(color: p.warning)),
        const SizedBox(height: 12),
        Btn('Try again', onPressed: _load),
      ]);
    }
    if (preview != null) {
      return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Text(previewName!, style: const TextStyle(fontWeight: FontWeight.w600)),
        const SizedBox(height: 10),
        BackupPreview(file: preview!),
        const SizedBox(height: 16),
        Row(children: [
          Btn('Back', kind: BtnKind.ghost, onPressed: () => setState(() => preview = null)),
          const Spacer(),
          Btn('Restore', kind: BtnKind.danger, onPressed: () async {
            if (!await confirm(context,
                title: 'Replace all data on this phone?',
                description: 'Your current tasks, sessions, reviews and settings will be replaced by this backup. Your app lock and Drive connection stay as they are.',
                confirmLabel: 'Restore',
                danger: true)) {
              return;
            }
            final ctl = settingsCtl(ref);
            final next = await restoreBackup(ref.read(databaseProvider), preview!, ctl.current);
            await ctl.replace(next);
            if (context.mounted) {
              Navigator.pop(context);
              toast(context, 'Backup restored');
            }
          }),
        ]),
      ]);
    }
    if (files!.isEmpty) return Padding(padding: const EdgeInsets.all(24), child: Text('No backups found in Drive yet.', textAlign: TextAlign.center, style: TextStyle(color: p.muted)));
    return Column(children: [
      for (final f in files!)
        ListTile(
          contentPadding: EdgeInsets.zero,
          title: Text(f.name, style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14)),
          trailing: Text(DateFormat('MMM d, h:mm a').format(f.modifiedTime), style: TextStyle(color: p.muted, fontSize: 12)),
          onTap: () => _pick(f),
        ),
    ]);
  }
}

class BackupPreview extends StatelessWidget {
  const BackupPreview({super.key, required this.file});
  final BackupFile file;
  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    final counts = file.counts;
    final date = file.exportedDate;
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Text('Created ${date == null ? 'at an unknown date' : DateFormat('EEEE, MMM d, yyyy · h:mm a').format(date)} · schema v${file.schema}', style: TextStyle(color: p.muted, fontSize: 13)),
      const SizedBox(height: 10),
      GridView.count(
        crossAxisCount: 2,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        childAspectRatio: 4,
        mainAxisSpacing: 6,
        crossAxisSpacing: 6,
        children: [
          for (final t in dataTables)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              decoration: BoxDecoration(color: p.card2.withValues(alpha: 0.7), borderRadius: BorderRadius.circular(10)),
              child: Row(children: [
                Expanded(child: Text(tableLabels[t]!, style: TextStyle(color: p.muted, fontSize: 12.5), overflow: TextOverflow.ellipsis)),
                Text('${counts[t]}', style: const TextStyle(fontWeight: FontWeight.w600, fontFeatures: tabular)),
              ]),
            ),
        ],
      ),
    ]);
  }
}

/// The values Google Cloud needs for the Android OAuth client (one-time setup, see README).
class _AndroidSetupHelp extends StatefulWidget {
  const _AndroidSetupHelp();
  @override
  State<_AndroidSetupHelp> createState() => _AndroidSetupHelpState();
}

class _AndroidSetupHelpState extends State<_AndroidSetupHelp> {
  (String, String)? info;
  @override
  void initState() {
    super.initState();
    NativeBridge.signingInfo().then((v) {
      if (mounted) setState(() => info = v);
    });
  }

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    return SettingsSection(title: 'One-time Google Cloud setup', children: [
      Padding(
        padding: const EdgeInsets.symmetric(vertical: 14),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Text(
            'Before connecting, create an Android OAuth client in Google Cloud Console (in a project with the Google Drive API enabled) using these two values. The README has step-by-step instructions. Tap a value to copy it.',
            style: TextStyle(color: p.muted, fontSize: 13, height: 1.4),
          ),
          if (info != null)
            for (final (k, v) in [('Package name', info!.$1), ('SHA-1 certificate fingerprint', info!.$2.isEmpty ? 'Unavailable' : info!.$2)])
              Padding(
                padding: const EdgeInsets.only(top: 10),
                child: InkWell(
                  borderRadius: BorderRadius.circular(10),
                  onTap: () {
                    Clipboard.setData(ClipboardData(text: v));
                    toast(context, 'Copied');
                  },
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(color: p.card2.withValues(alpha: 0.7), borderRadius: BorderRadius.circular(10)),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(k.toUpperCase(), style: TextStyle(color: p.muted, fontSize: 10.5, letterSpacing: 0.6)),
                      const SizedBox(height: 2),
                      SelectableText(v, style: const TextStyle(fontFamily: 'monospace', fontSize: 12.5)),
                    ]),
                  ),
                ),
              ),
        ]),
      ),
    ]);
  }
}
