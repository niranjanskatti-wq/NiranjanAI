import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:googleapis/drive/v3.dart' as drive;
import 'package:gv_saf/gv_saf.dart';
import 'package:path/path.dart' as p;

import '../core/crypto.dart';
import '../core/format.dart';
import '../core/secure_store.dart';
import '../data/repository.dart';
import '../data/schema.dart';
import 'google_service.dart';
import 'photo_store.dart';

class BackupInfo {
  final String id;
  final String name;
  final DateTime? created;
  final int? size;
  const BackupInfo(this.id, this.name, this.created, this.size);
}

class BackupException implements Exception {
  final String code; // no_target / no_access / not_signed_in / wrong_passphrase / bad_file
  BackupException(this.code);
  @override
  String toString() => 'BackupException($code)';
}

/// Weekly schedule chosen by the user.
class BackupSchedule {
  final bool enabled;
  final int weekday; // DateTime.monday .. DateTime.sunday
  final int hour;
  final int minute;
  final bool wifiOnly;
  const BackupSchedule({
    this.enabled = false,
    this.weekday = DateTime.sunday,
    this.hour = 2,
    this.minute = 0,
    this.wifiOnly = true,
  });

  /// The most recent scheduled moment at or before [now].
  DateTime lastSlot(DateTime now) {
    var d = DateTime(now.year, now.month, now.day, hour, minute);
    while (d.weekday != weekday || d.isAfter(now)) {
      d = DateTime(d.year, d.month, d.day - 1, hour, minute);
    }
    return d;
  }

  DateTime nextSlot(DateTime now) {
    final last = lastSlot(now);
    return DateTime(last.year, last.month, last.day + 7, hour, minute);
  }
}

/// Full backup: every database row (as JSON) plus all photo files, streamed
/// through AES-256-GCM. No password is needed: files are locked with a key built
/// into GoldVault, so only the GoldVault app can open them, on any phone.
/// (Older backups made with a personal backup password still restore.)
class BackupService {
  BackupService({
    required this.repo,
    required this.secure,
    required this.photos,
    required this.google,
    required this.tempDir,
  });

  final VaultRepo repo;
  final SecureStore secure;
  final PhotoStore photos;
  final GoogleService google;
  final Directory tempDir;

  static const folderName = 'GoldVault Backups';
  static const keep = 8;
  static const _tEnd = 0, _tManifest = 1, _tData = 2, _tPhoto = 3;
  static const _builtInKey = 'GoldVault/backup/v2/7f3c9a2e-5b14-4d8e-a6c1-0e9b2d4f8a31';
  static const autoFileName = 'GoldVault-auto-backup.gvb';

  // ------------------------------------------------------------ schedule

  Future<BackupSchedule> schedule() async {
    final s = await repo.allSettings();
    final t = (s['backup_time'] ?? '02:00').split(':');
    return BackupSchedule(
      enabled: s['backup_enabled'] != '0', // on unless switched off
      weekday: int.tryParse(s['backup_day'] ?? '') ?? DateTime.sunday,
      hour: int.tryParse(t[0]) ?? 2,
      minute: t.length > 1 ? int.tryParse(t[1]) ?? 0 : 0,
      wifiOnly: s['backup_wifi_only'] != '0',
    );
  }

  Future<void> saveSchedule(BackupSchedule s) async {
    await repo.setSetting('backup_enabled', s.enabled ? '1' : '0');
    await repo.setSetting('backup_day', '${s.weekday}');
    await repo.setSetting('backup_time',
        '${s.hour.toString().padLeft(2, '0')}:${s.minute.toString().padLeft(2, '0')}');
    await repo.setSetting('backup_wifi_only', s.wifiOnly ? '1' : '0');
  }

  Future<DateTime?> lastBackup() async => Fmt.parse(await repo.getSetting('last_backup'));

  Future<bool> isDue([DateTime? now]) async {
    final s = await schedule();
    if (!s.enabled) return false;
    final n = now ?? DateTime.now();
    final last = await lastBackup();
    return last == null || last.isBefore(s.lastSlot(n));
  }

  // ------------------------------------------------------------ local file

  Future<File> writeBackupFile({String? passphrase, File? target}) async {
    await tempDir.create(recursive: true);
    final out = target ??
        File(p.join(tempDir.path,
            'GoldVault-backup-${Fmt.isoDateTime(DateTime.now()).replaceAll(':', '').replaceAll('T', '_')}.gvb'));
    final w = await EncryptedWriter.create(out, passphrase ?? _builtInKey);
    final files = await repo.allPhotoFiles();
    final data = await repo.dumpAll();
    final manifest = {
      'app': 'GoldVault',
      'format': 1,
      'schema': kSchemaVersion,
      'created': Fmt.isoDateTime(DateTime.now()),
      'photoKey': base64Encode(photos.key),
      'items': data['items']?.length ?? 0,
      'photos': files.length,
    };
    _entry(w, _tManifest, 'manifest.json', utf8.encode(jsonEncode(manifest)));
    _entry(w, _tData, 'data.json', utf8.encode(jsonEncode(data)));
    for (final name in files.toSet()) {
      final f = photos.fileFor(name);
      if (await f.exists()) _entry(w, _tPhoto, name, await f.readAsBytes());
    }
    w.add([_tEnd]);
    await w.close();
    return out;
  }

  void _entry(EncryptedWriter w, int type, String name, List<int> bytes) {
    final n = utf8.encode(name);
    final h = ByteData(1 + 2 + n.length + 8)
      ..setUint8(0, type)
      ..setUint16(1, n.length);
    final hb = h.buffer.asUint8List()..setRange(3, 3 + n.length, n);
    ByteData.sublistView(hb).setUint64(3 + n.length, bytes.length);
    w.add(hb);
    w.add(bytes);
  }

  /// Reads a backup file, then replaces all local data with it.
  /// [passphrase] is only for old backups made with a personal password.
  Future<Map<String, dynamic>> restoreFromFile(File f, [String? passphrase]) async {
    final EncryptedReader r;
    try {
      r = await EncryptedReader.open(f, passphrase ?? _builtInKey);
    } on FormatException {
      throw BackupException('bad_file');
    }
    final staging = Directory(p.join(tempDir.path, 'restore_${DateTime.now().millisecondsSinceEpoch}'));
    await staging.create(recursive: true);
    Map<String, dynamic>? manifest;
    Map<String, dynamic>? data;
    final photoNames = <String>[];
    try {
      while (true) {
        final type = (await r.read(1))[0];
        if (type == _tEnd) break;
        final nlen = ByteData.sublistView(await r.read(2)).getUint16(0);
        final name = utf8.decode(await r.read(nlen));
        final len = ByteData.sublistView(await r.read(8)).getUint64(0);
        final bytes = await r.read(len);
        switch (type) {
          case _tManifest:
            manifest = jsonDecode(utf8.decode(bytes)) as Map<String, dynamic>;
            break;
          case _tData:
            data = jsonDecode(utf8.decode(bytes)) as Map<String, dynamic>;
            break;
          case _tPhoto:
            final safe = p.basename(name);
            await File(p.join(staging.path, safe)).writeAsBytes(bytes);
            photoNames.add(safe);
            break;
        }
      }
    } on FormatException {
      await staging.delete(recursive: true);
      throw BackupException('bad_file');
    } catch (e) {
      await staging.delete(recursive: true);
      // AES-GCM tag failure on the first chunk = wrong passphrase.
      throw BackupException('wrong_passphrase');
    } finally {
      await r.close();
    }
    if (manifest == null || data == null || manifest['app'] != 'GoldVault') {
      await staging.delete(recursive: true);
      throw BackupException('bad_file');
    }

    // Everything decrypted fine: swap in.
    await repo.restoreAll(data, keepSettings: const {'google_email', 'google_id', 'last_backup', 'backup_enabled', 'backup_day', 'backup_time', 'backup_wifi_only', 'auto_backup_uri', 'auto_backup_name'});
    final key = base64Decode(manifest['photoKey'] as String);
    await secure.setPhotoKey(key);
    photos.setKey(key);
    for (final old in await photos.allFiles()) {
      await old.delete();
    }
    await photos.dir.create(recursive: true);
    for (final name in photoNames) {
      await File(p.join(staging.path, name)).rename(photos.fileFor(name).path).catchError(
          (_) async => File(p.join(staging.path, name)).copy(photos.fileFor(name).path));
    }
    await staging.delete(recursive: true);
    return manifest;
  }

  // ------------------------------------------------- automatic backup file

  /// The file (usually in Google Drive) chosen once for automatic backups.
  Future<SafTarget?> autoTarget() async {
    final uri = await repo.getSetting('auto_backup_uri');
    if (uri == null || uri.isEmpty) return null;
    return SafTarget(uri, await repo.getSetting('auto_backup_name'), uri.contains('com.google.android.apps.docs'));
  }

  Future<void> setAutoTarget(SafTarget? t) async {
    final old = await repo.getSetting('auto_backup_uri');
    if (old != null && old != t?.uri) await GvSaf.release(old);
    await repo.setSetting('auto_backup_uri', t?.uri);
    await repo.setSetting('auto_backup_name', t?.name);
  }

  Future<void> markBackedUp(int size) async {
    await repo.setSetting('last_backup', Fmt.isoDateTime(DateTime.now()));
    await repo.setSetting('last_backup_size', '$size');
  }

  /// Backs up to the chosen file, or to the Drive folder when signed in with
  /// Google. Used by the weekly job and by "Back up now".
  Future<String> autoBackup({bool interactive = false}) async {
    final t = await autoTarget();
    if (t != null) {
      final local = await writeBackupFile();
      try {
        final len = await local.length();
        try {
          await GvSaf.write(t.uri, local.path);
        } on SafException catch (e) {
          if (e.code == 'no_access') throw BackupException('no_access');
          rethrow;
        }
        await markBackedUp(len);
        return t.name ?? autoFileName;
      } finally {
        if (await local.exists()) await local.delete();
      }
    }
    if (google.configured && google.email.value != null) return backupToDrive(interactive: interactive);
    throw BackupException('no_target');
  }

  // ---------------------------------------------------------------- Drive

  Future<String> _folderId(drive.DriveApi api) async {
    final cached = await repo.getSetting('drive_folder_id');
    if (cached != null) {
      try {
        final f = await api.files.get(cached, $fields: 'id,trashed') as drive.File;
        if (f.trashed != true) return cached;
      } catch (_) {}
    }
    final q = "mimeType = 'application/vnd.google-apps.folder' and name = '$folderName' and trashed = false";
    final list = await api.files.list(q: q, spaces: 'drive', $fields: 'files(id,name)');
    String id;
    if (list.files != null && list.files!.isNotEmpty) {
      id = list.files!.first.id!;
    } else {
      final created = await api.files.create(
        drive.File(name: folderName, mimeType: 'application/vnd.google-apps.folder'),
        $fields: 'id',
      );
      id = created.id!;
    }
    await repo.setSetting('drive_folder_id', id);
    return id;
  }

  /// Full backup to Drive. Returns the uploaded file name.
  Future<String> backupToDrive({bool interactive = false}) async {
    final client = await google.client(interactive: interactive);
    if (client == null) throw BackupException('not_signed_in');
    File? local;
    try {
      final api = drive.DriveApi(client);
      final folder = await _folderId(api);
      local = await writeBackupFile();
      final name = p.basename(local.path);
      final len = await local.length();
      await api.files.create(
        drive.File(name: name, parents: [folder], description: 'GoldVault encrypted backup'),
        uploadMedia: drive.Media(local.openRead(), len, contentType: 'application/octet-stream'),
        uploadOptions: drive.ResumableUploadOptions(),
        $fields: 'id',
      );
      await _prune(api, folder);
      await markBackedUp(len);
      return name;
    } finally {
      client.close();
      if (local != null && await local.exists()) await local.delete();
    }
  }

  Future<List<BackupInfo>> _list(drive.DriveApi api, String folder) async {
    final out = <BackupInfo>[];
    String? token;
    do {
      final r = await api.files.list(
        q: "'$folder' in parents and trashed = false and name contains '.gvb'",
        orderBy: 'createdTime desc',
        pageToken: token,
        $fields: 'nextPageToken,files(id,name,createdTime,size)',
      );
      for (final f in r.files ?? <drive.File>[]) {
        out.add(BackupInfo(f.id!, f.name ?? '', f.createdTime?.toLocal(), int.tryParse(f.size ?? '')));
      }
      token = r.nextPageToken;
    } while (token != null);
    return out;
  }

  Future<void> _prune(drive.DriveApi api, String folder) async {
    final all = await _list(api, folder);
    for (final old in all.skip(keep)) {
      await api.files.delete(old.id);
    }
  }

  Future<List<BackupInfo>> listDriveBackups({bool interactive = true}) async {
    final client = await google.client(interactive: interactive);
    if (client == null) throw BackupException('not_signed_in');
    try {
      final api = drive.DriveApi(client);
      return await _list(api, await _folderId(api));
    } finally {
      client.close();
    }
  }

  Future<Map<String, dynamic>> restoreFromDrive(BackupInfo b, [String? passphrase]) async {
    final client = await google.client(interactive: true);
    if (client == null) throw BackupException('not_signed_in');
    final tmp = File(p.join(tempDir.path, 'download_${b.id}.gvb'));
    try {
      final media = await drive.DriveApi(client)
          .files
          .get(b.id, downloadOptions: drive.DownloadOptions.fullMedia) as drive.Media;
      await tempDir.create(recursive: true);
      final sink = tmp.openWrite();
      await media.stream.pipe(sink);
      return await restoreFromFile(tmp, passphrase);
    } finally {
      client.close();
      if (await tmp.exists()) await tmp.delete();
    }
  }
}
