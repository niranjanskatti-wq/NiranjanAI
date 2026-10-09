import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:intl/intl.dart';
import 'package:file_picker/file_picker.dart';
import 'package:gv_saf/gv_saf.dart';
import 'package:path/path.dart' as p;
import 'package:share_plus/share_plus.dart';

import '../../core/app_services.dart';
import '../../core/format.dart';
import '../../core/strings.dart';
import '../../core/theme.dart';
import '../../services/background.dart';
import '../../services/backup_service.dart';
import '../../services/notifications.dart';
import '../widgets/common.dart';

/// Google Sheets sync, Excel/PDF export, and Drive backup/restore.
class CloudScreen extends StatefulWidget {
  const CloudScreen({super.key});
  @override
  State<CloudScreen> createState() => _CloudScreenState();
}

class _CloudScreenState extends State<CloudScreen> {
  String? _busy; // which action is running

  AppServices get svc => AppServices.I;

  Future<void> _run(String key, Future<void> Function() f) async {
    if (_busy != null) return;
    setState(() => _busy = key);
    try {
      await f();
    } on BackupException catch (e) {
      if (mounted) toast(context, context.t('backup.err.${e.code}'));
    } on SafException catch (e) {
      if (mounted) toast(context, e.code == 'no_access' ? context.t('backup.err.no_access') : '${context.t('cloud.error')}: ${e.message ?? e.code}');
    } on GoogleSignInException catch (e) {
      if (mounted) {
        toast(context, e.code == GoogleSignInExceptionCode.canceled ? context.t('cloud.cancelled') : '${context.t('cloud.signInFailed')} (${e.code.name})');
      }
    } on SocketException {
      if (mounted) toast(context, context.t('cloud.offline'));
    } catch (e) {
      if (mounted) toast(context, '${context.t('cloud.error')}: $e');
    } finally {
      if (mounted) setState(() => _busy = null);
      svc.repo.revision.value++;
    }
  }

  Widget _btn(String key, IconData icon, String label, Future<void> Function() f, {bool filled = false}) {
    final busy = _busy == key;
    final child = busy
        ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.5))
        : Icon(icon);
    return SizedBox(
      width: double.infinity,
      child: filled
          ? FilledButton.icon(onPressed: _busy == null ? () => _run(key, f) : null, icon: child, label: Text(label))
          : OutlinedButton.icon(onPressed: _busy == null ? () => _run(key, f) : null, icon: child, label: Text(label)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(context.t('cloud.title'))),
      body: ValueListenableBuilder<String?>(
        valueListenable: svc.google.email,
        builder: (context, account, _) => DataBuilder<(Map<String, String?>, BackupSchedule, SafTarget?)>(
          load: () async => (await svc.repo.allSettings(), await svc.backup.schedule(), await svc.backup.autoTarget()),
          builder: (context, d) {
            final (s, sched, target) = d;
            return ListView(padding: const EdgeInsets.fromLTRB(16, 0, 16, 40), children: [
              GoldCard(
                child: Row(children: [
                  const Icon(Icons.wifi_off, color: GV.ok, size: 28),
                  const SizedBox(width: 12),
                  Expanded(child: Text(context.t('cloud.offlineNote'), style: const TextStyle(color: GV.muted))),
                ]),
              ),
              // Works without Google sign-in: Android's own "Save to" screen.
              SectionTitle(context.t('fbk.title')),
              _fileBackup(context, s, sched, target, account != null),
              SectionTitle(context.t('cloud.account')),
              _account(context, account),
              SectionTitle(context.t('sheet.title')),
              _sheets(context, s, account != null),
              SectionTitle(context.t('export.title')),
              GoldCard(
                child: Column(children: [
                  Text(context.t('export.body'), style: const TextStyle(color: GV.muted)),
                  const SizedBox(height: 12),
                  _btn('xlsx', Icons.grid_on, context.t('export.excel'), () async {
                    final f = await svc.export.excel();
                    await _share(f, 'GoldVault inventory (Excel)');
                  }),
                  const SizedBox(height: 10),
                  _btn('pdf', Icons.picture_as_pdf_outlined, context.t('export.pdf'), () async {
                    final f = await svc.export.pdf();
                    await _share(f, 'GoldVault report (PDF)');
                  }),
                ]),
              ),
              if (svc.google.configured) ...[
                SectionTitle(context.t('backup.title')),
                _backup(context, account != null),
              ],
            ]);
          },
        ),
      ),
    );
  }

  Future<void> _share(File f, String text) async {
    await SharePlus.instance.share(ShareParams(files: [XFile(f.path)], text: text, subject: text));
  }

  Widget _account(BuildContext context, String? a) {
    if (!svc.google.configured) {
      return GoldCard(child: Text(context.t('cloud.notConfigured'), style: const TextStyle(color: GV.muted)));
    }
    return GoldCard(
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Row(children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: GV.surface2,
            child: Icon(a == null ? Icons.person_outline : Icons.verified_user, color: GV.gold),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(a ?? context.t('cloud.signedOut'),
                style: const TextStyle(fontSize: 16)),
          ),
        ]),
        const SizedBox(height: 12),
        if (a == null)
          _btn('signin', Icons.login, context.t('cloud.signIn'), () async {
            await svc.google.signIn();
            await Notifier.requestPermission();
          }, filled: true)
        else
          _btn('signout', Icons.logout, context.t('cloud.signOut'), () async {
            if (await confirm(context, context.t('cloud.signOut'), context.t('cloud.signOutBody'))) await svc.google.signOut();
          }),
      ]),
    );
  }

  Widget _sheets(BuildContext context, Map<String, String?> s, bool signedIn) {
    final last = Fmt.parse(s['last_sync']);
    final dirty = s['sync_dirty'] == '1';
    final hasSheet = s['sheet_id'] != null;
    return GoldCard(
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Text(context.t('sheet.body'), style: const TextStyle(color: GV.muted)),
        const SizedBox(height: 10),
        Row(children: [
          Icon(dirty ? Icons.sync_problem : Icons.cloud_done_outlined, color: dirty ? GV.goldLight : GV.ok),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              last == null ? context.t('sheet.never') : context.t('sheet.last', {'date': Fmt.dateTime(last)}) + (dirty ? '\n${context.t('sheet.pending')}' : ''),
            ),
          ),
        ]),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: Text(context.t('sheet.auto')),
          subtitle: Text(context.t('sheet.autoSub')),
          value: s['auto_sync'] != '0',
          onChanged: (v) async {
            await svc.repo.setSetting('auto_sync', v ? '1' : '0');
            svc.repo.revision.value++;
          },
        ),
        _btn('sync', Icons.sync, context.t('sheet.syncNow'), () async {
          final tr = context.s;
          final r = await svc.sheets.syncNow(interactive: true);
          if (mounted) toast(this.context, r.ok ? tr.t('sheet.synced') : tr.t('backup.err.${r.message}'));
        }, filled: true),
        if (hasSheet) ...[
          const SizedBox(height: 10),
          _btn('share', Icons.person_add_alt, context.t('sheet.share'), () => _shareSheet(context)),
          const SizedBox(height: 10),
          _btn('link', Icons.link, context.t('sheet.copyLink'), () async {
            final msg = context.t('sheet.copied');
            final url = await svc.sheets.spreadsheetUrl();
            await Clipboard.setData(ClipboardData(text: url ?? ''));
            if (mounted) toast(this.context, msg);
          }),
        ],
      ]),
    );
  }

  Future<void> _shareSheet(BuildContext context) async {
    final email = TextEditingController();
    var edit = false;
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => StatefulBuilder(
        builder: (c, set) => AlertDialog(
          title: Text(context.t('sheet.share')),
          content: Column(mainAxisSize: MainAxisSize.min, children: [
            TextField(
              controller: email,
              keyboardType: TextInputType.emailAddress,
              decoration: InputDecoration(labelText: context.t('sheet.email')),
            ),
            const SizedBox(height: 14),
            SegmentedButton<bool>(
              segments: [
                ButtonSegment(value: false, label: Text(context.t('sheet.view')), icon: const Icon(Icons.visibility_outlined)),
                ButtonSegment(value: true, label: Text(context.t('sheet.edit')), icon: const Icon(Icons.edit_outlined)),
              ],
              selected: {edit},
              onSelectionChanged: (v) => set(() => edit = v.first),
            ),
          ]),
          actions: [
            TextButton(onPressed: () => Navigator.pop(c, false), child: Text(context.t('common.cancel'))),
            FilledButton(onPressed: () => Navigator.pop(c, true), child: Text(context.t('sheet.shareBtn'))),
          ],
        ),
      ),
    );
    final e = email.text.trim();
    if (ok != true || !e.contains('@')) return;
    await svc.sheets.share(e, canEdit: edit);
    if (mounted) toast(this.context, this.context.t('sheet.sharedWith', {'email': e}));
  }

  /// Optional extra: the "GoldVault Backups" folder via Google sign-in.
  Widget _backup(BuildContext context, bool signedIn) {
    return GoldCard(
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Text(context.t('backup.body'), style: const TextStyle(color: GV.muted)),
        const SizedBox(height: 12),
        _btn('backup', Icons.cloud_upload_outlined, context.t('backup.now'), () async {
          final done = context.t('notif.backupDone');
          final name = await svc.backup.backupToDrive(interactive: true);
          await Notifier.backup(done, name);
          if (mounted) toast(this.context, done);
        }),
        const SizedBox(height: 10),
        _btn('restore', Icons.settings_backup_restore, context.t('backup.restore'), () => _restore(context)),
      ]),
    );
  }

  Future<void> _saveSchedule(BackupSchedule n) async {
    await svc.backup.saveSchedule(n);
    await Background.schedule(svc);
    svc.repo.revision.value++;
  }

  Widget _scheduleFields(BuildContext context, BackupSchedule sched) {
    final locale = Localizations.localeOf(context).languageCode;
    String dayName(int wd) => DateFormat.EEEE(locale).format(DateTime(2024, 1, wd)); // 1 Jan 2024 = Monday
    BackupSchedule copy({int? weekday, int? hour, int? minute, bool? wifiOnly}) => BackupSchedule(
        enabled: true,
        weekday: weekday ?? sched.weekday,
        hour: hour ?? sched.hour,
        minute: minute ?? sched.minute,
        wifiOnly: wifiOnly ?? sched.wifiOnly);
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      const SizedBox(height: 4),
      Row(children: [
        Expanded(
          child: DropdownButtonFormField<int>(
            initialValue: sched.weekday,
            dropdownColor: GV.surface2,
            decoration: InputDecoration(labelText: context.t('backup.day')),
            items: [for (var d = 1; d <= 7; d++) DropdownMenuItem(value: d, child: Text(dayName(d)))],
            onChanged: (v) => _saveSchedule(copy(weekday: v)),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: InkWell(
            onTap: () async {
              final t = await showTimePicker(context: context, initialTime: TimeOfDay(hour: sched.hour, minute: sched.minute));
              if (t != null) await _saveSchedule(copy(hour: t.hour, minute: t.minute));
            },
            child: InputDecorator(
              decoration: InputDecoration(labelText: context.t('backup.time')),
              child: Text(Fmt.hhmm('${sched.hour}:${sched.minute}'), style: const TextStyle(fontSize: 17)),
            ),
          ),
        ),
      ]),
      SwitchListTile(
        contentPadding: EdgeInsets.zero,
        title: Text(context.t('backup.wifiOnly')),
        value: sched.wifiOnly,
        onChanged: (v) => _saveSchedule(copy(wifiOnly: v)),
      ),
      Text(context.t('backup.next', {'date': Fmt.dateTime(sched.nextSlot(DateTime.now()))}), style: const TextStyle(color: GV.muted)),
      const SizedBox(height: 12),
    ]);
  }

  /// Main backup card: automatic weekly backup to one file in Google Drive
  /// (chosen once, no password, no Google setup) plus manual backups.
  Widget _fileBackup(BuildContext context, Map<String, String?> s, BackupSchedule sched, SafTarget? target, bool signedIn) {
    final last = Fmt.parse(s['last_backup']);
    final auto = target != null || signedIn;
    return GoldCard(
      accent: GV.gold,
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Text(context.t('fbk.body'), style: const TextStyle(color: GV.muted)),
        const SizedBox(height: 10),
        Row(children: [
          Icon(last == null ? Icons.warning_amber : Icons.history, color: last == null ? GV.goldLight : GV.gold),
          const SizedBox(width: 8),
          Expanded(
            child: Text(last == null ? context.t('backup.never') : context.t('backup.last', {'date': Fmt.dateTime(last)}),
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
          ),
        ]),
        const SizedBox(height: 8),
        if (target != null)
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Icon(target.drive ? Icons.add_to_drive : Icons.folder_outlined, color: GV.ok, size: 28),
            title: Text(context.t('fbk.target', {'name': target.name ?? BackupService.autoFileName})),
            subtitle: target.drive ? Text(context.t('fbk.inDrive')) : null,
            trailing: TextButton(onPressed: _busy == null ? () => _run('target', () => _chooseTarget(context)) : null, child: Text(context.t('common.change'))),
          ),
        if (auto) ...[
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(context.t('backup.weekly')),
            subtitle: Text(context.t('fbk.autoSub')),
            value: sched.enabled,
            onChanged: (v) async {
              await _saveSchedule(BackupSchedule(enabled: v, weekday: sched.weekday, hour: sched.hour, minute: sched.minute, wifiOnly: sched.wifiOnly));
              await Notifier.requestPermission();
            },
          ),
          if (sched.enabled) _scheduleFields(context, sched),
          _btn('now', Icons.backup_outlined, context.t('backup.now'), () async {
            final done = context.t('fbk.saved');
            await svc.backup.autoBackup(interactive: true);
            if (mounted) toast(this.context, done);
          }, filled: true),
        ] else ...[
          Text(context.t('fbk.setupHelp'), style: const TextStyle(color: GV.goldLight)),
          const SizedBox(height: 10),
          _btn('target', Icons.add_to_drive, context.t('fbk.turnOn'), () => _chooseTarget(context), filled: true),
        ],
        const SizedBox(height: 10),
        _btn('fsave', Icons.save_alt, context.t('fbk.save'), () => _saveBackupFile(context)),
        const SizedBox(height: 10),
        _btn('fshare', Icons.share, context.t('fbk.share'), () => _shareBackupFile(context)),
        const SizedBox(height: 10),
        _btn('frestore', Icons.settings_backup_restore, context.t('fbk.restore'), () => _restoreFromFile(context)),
        const SizedBox(height: 8),
        Text(context.t('fbk.help'), style: const TextStyle(color: GV.muted, fontSize: 13.5)),
      ]),
    );
  }

  /// Asks once where automatic backups go (choose Drive), then backs up.
  Future<void> _chooseTarget(BuildContext context) async {
    final done = context.t('fbk.saved');
    final t = await GvSaf.create(BackupService.autoFileName);
    if (t == null) return;
    await svc.backup.setAutoTarget(t);
    final sched = await svc.backup.schedule();
    await _saveSchedule(BackupSchedule(enabled: true, weekday: sched.weekday, hour: sched.hour, minute: sched.minute, wifiOnly: sched.wifiOnly));
    await Notifier.requestPermission();
    await svc.backup.autoBackup();
    if (mounted) toast(this.context, done);
  }

  Future<void> _saveBackupFile(BuildContext context) async {
    final done = context.t('fbk.saved');
    final f = await svc.backup.writeBackupFile();
    try {
      final uri = await FilePicker.saveFile(
        fileName: p.basename(f.path),
        bytes: await f.readAsBytes(),
        dialogTitle: 'GoldVault backup',
      );
      if (uri != null) {
        await svc.backup.markBackedUp(await f.length());
        if (mounted) toast(this.context, done);
      }
    } finally {
      if (await f.exists()) await f.delete();
    }
  }

  Future<void> _shareBackupFile(BuildContext context) async {
    final f = await svc.backup.writeBackupFile();
    final r = await SharePlus.instance.share(ShareParams(files: [XFile(f.path)], subject: 'GoldVault backup'));
    if (r.status == ShareResultStatus.success) await svc.backup.markBackedUp(await f.length());
  }

  /// Confirms, then restores. Old backups made with a personal password ask
  /// for it.
  Future<void> _confirmAndRestore(String title, Future<Map<String, dynamic>> Function(String? pass) run) async {
    if (!mounted) return;
    final sure = await confirm(context, title, context.t('backup.restoreWarn'), ok: context.t('backup.restoreBtn'), danger: true);
    if (!sure) return;
    Map<String, dynamic> m;
    try {
      m = await run(null);
    } on BackupException catch (e) {
      if (e.code != 'wrong_passphrase' || !mounted) rethrow;
      final pass = await promptText(context, context.t('backup.oldPass'), label: context.t('backup.pass'), obscure: true);
      if (pass == null) return;
      m = await run(pass);
    }
    if (mounted) toast(context, context.t('backup.restored', {'n': m['items'] ?? 0}));
  }

  Future<void> _restoreFromFile(BuildContext context) async {
    final title = context.t('fbk.restore');
    final picked = await FilePicker.pickFile(dialogTitle: 'GoldVault backup');
    if (picked == null || !mounted) return;
    final tmp = File(p.join(svc.backup.tempDir.path, 'picked.gvb'));
    await svc.backup.tempDir.create(recursive: true);
    await tmp.writeAsBytes(await picked.readAsBytes(), flush: true);
    try {
      await _confirmAndRestore(title, (pass) => svc.backup.restoreFromFile(tmp, pass));
    } finally {
      if (await tmp.exists()) await tmp.delete();
    }
  }

  Future<void> _restore(BuildContext context) async {
    final list = await svc.backup.listDriveBackups();
    if (!mounted) return;
    if (list.isEmpty) {
      toast(this.context, this.context.t('backup.none'));
      return;
    }
    final pick = await showModalBottomSheet<BackupInfo>(
      context: this.context,
      builder: (c) => SafeArea(
        child: ListView(shrinkWrap: true, children: [
          Padding(padding: const EdgeInsets.fromLTRB(20, 0, 20, 8), child: Text(context.t('backup.choose'), style: Theme.of(c).textTheme.titleLarge)),
          for (final b in list)
            ListTile(
              leading: const Icon(Icons.cloud_outlined),
              title: Text(b.created == null ? b.name : Fmt.dateTime(b.created)),
              subtitle: Text(b.size == null ? b.name : '${(b.size! / (1024 * 1024)).toStringAsFixed(1)} MB'),
              onTap: () => Navigator.pop(c, b),
            ),
        ]),
      ),
    );
    if (pick == null || !mounted) return;
    await _confirmAndRestore(this.context.t('backup.restore'), (pass) => svc.backup.restoreFromDrive(pick, pass));
  }
}
