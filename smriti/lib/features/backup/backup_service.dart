import 'dart:convert';
import 'dart:io';

import 'package:archive/archive_io.dart';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../../data/database.dart';

/// Full backups (database + photos) as a .zip in Download/Smriti Backups.
class BackupService {
  BackupService(this.db);

  final AppDatabase db;

  static const keep = 4;
  static const prefix = 'Smriti backup';
  static final _stamp = DateFormat('yyyy-MM-dd HH.mm.ss');

  /// Download/Smriti Backups when the phone allows it, otherwise the app's own folder.
  static Future<Directory> folder() async {
    final public = Directory('/storage/emulated/0/Download/Smriti Backups');
    try {
      await public.create(recursive: true);
      final probe = File(p.join(public.path, '.smriti'));
      await probe.writeAsString('ok');
      return public;
    } catch (_) {
      final own = Directory(p.join((await getExternalStorageDirectory() ?? await getApplicationDocumentsDirectory()).path, 'Backups'));
      await own.create(recursive: true);
      return own;
    }
  }

  static Future<Directory> _docs() => getApplicationDocumentsDirectory();

  /// Makes a backup and keeps only the newest [keep]. Returns the file.
  Future<File> create({bool automatic = false}) async {
    final tmp = await getTemporaryDirectory();
    final snap = File(p.join(tmp.path, 'smriti_snapshot.sqlite'));
    if (await snap.exists()) await snap.delete();
    // A consistent copy even while the app is using the database.
    await db.customStatement("VACUUM INTO '${snap.path.replaceAll("'", "''")}'");

    final archive = Archive();
    final dbBytes = await snap.readAsBytes();
    archive.addFile(ArchiveFile('smriti.sqlite', dbBytes.length, dbBytes));
    final photos = Directory(p.join((await _docs()).path, 'photos'));
    var photoCount = 0;
    if (await photos.exists()) {
      await for (final f in photos.list()) {
        if (f is File) {
          final b = await f.readAsBytes();
          archive.addFile(ArchiveFile('photos/${p.basename(f.path)}', b.length, b));
          photoCount++;
        }
      }
    }
    final manifest = utf8.encode(jsonEncode({
      'app': 'Smriti',
      'schema': db.schemaVersion,
      'created': DateTime.now().toIso8601String(),
      'photos': photoCount,
      'automatic': automatic,
    }));
    archive.addFile(ArchiveFile('manifest.json', manifest.length, manifest));

    final dir = await folder();
    final out = File(p.join(dir.path, '$prefix ${_stamp.format(DateTime.now())}.zip'));
    await out.writeAsBytes(ZipEncoder().encode(archive)!, flush: true);
    await snap.delete();
    await db.setSetting('lastBackup', DateTime.now().toIso8601String());
    await _prune(dir);
    return out;
  }

  Future<void> _prune(Directory dir) async {
    final files = await list(dir);
    for (final f in files.skip(keep)) {
      try {
        await f.delete();
      } catch (_) {}
    }
  }

  /// Backups in [dir] (default folder), newest first.
  static Future<List<File>> list([Directory? dir]) async {
    final d = dir ?? await folder();
    if (!await d.exists()) return [];
    final files = <File>[];
    await for (final f in d.list()) {
      if (f is File && p.basename(f.path).startsWith(prefix) && f.path.endsWith('.zip')) files.add(f);
    }
    files.sort((a, b) => b.lastModifiedSync().compareTo(a.lastModifiedSync()));
    return files;
  }

  /// Makes a backup when the last one is older than the chosen interval
  /// (Settings: daily or weekly, weekly by default).
  Future<bool> autoIfDue() async {
    if (await db.getSetting('autoBackup') == 'false') return false;
    final every = int.tryParse(await db.getSetting('backupEvery') ?? '') ?? 7;
    final last = DateTime.tryParse(await db.getSetting('lastBackup') ?? '');
    if (last != null && DateTime.now().difference(last).inHours < every * 24 - 2) return false;
    try {
      await create(automatic: true);
      return true;
    } catch (e) {
      debugPrint('Automatic backup failed: $e');
      return false;
    }
  }

  /// Checks a backup and returns its manifest, or null if it isn't one.
  static Map<String, dynamic>? inspect(List<int> bytes) {
    try {
      final a = ZipDecoder().decodeBytes(bytes);
      final m = a.findFile('manifest.json');
      if (m == null || a.findFile('smriti.sqlite') == null) return null;
      final j = jsonDecode(utf8.decode(m.content as List<int>)) as Map<String, dynamic>;
      return j['app'] == 'Smriti' ? j : null;
    } catch (_) {
      return null;
    }
  }

  /// Replaces the database and photos with the backup. The caller must close
  /// the open database first and restart the app afterwards.
  static Future<void> restoreFiles(List<int> bytes, {Directory? docs}) async {
    final a = ZipDecoder().decodeBytes(bytes);
    final base = docs ?? await _docs();
    final dbFile = File(p.join(base.path, 'smriti.sqlite'));
    for (final suffix in ['-wal', '-shm', '-journal']) {
      final f = File('${dbFile.path}$suffix');
      if (await f.exists()) await f.delete();
    }
    await dbFile.writeAsBytes(a.findFile('smriti.sqlite')!.content as List<int>, flush: true);
    final photos = Directory(p.join(base.path, 'photos'));
    await photos.create(recursive: true);
    for (final f in a.files.where((f) => f.isFile && f.name.startsWith('photos/'))) {
      await File(p.join(photos.path, p.basename(f.name))).writeAsBytes(f.content as List<int>, flush: true);
    }
  }
}
