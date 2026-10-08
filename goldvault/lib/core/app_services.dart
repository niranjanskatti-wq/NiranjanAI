import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite_sqlcipher/sqflite.dart' as cipher;
import 'package:sqflite_sqlcipher/sqlite_api.dart';

import '../data/repository.dart';
import '../data/schema.dart';
import '../services/backup_service.dart';
import '../services/export_service.dart';
import '../services/google_service.dart';
import '../services/photo_store.dart';
import '../services/reminder_engine.dart';
import '../services/sheets_sync.dart';
import 'secure_store.dart';

/// Simple service locator. Created once per isolate (UI or background).
class AppServices {
  AppServices._({
    required this.secure,
    required this.repo,
    required this.photos,
    required this.google,
    required this.sheets,
    required this.backup,
    required this.export,
    required this.reminders,
  });

  static AppServices? _instance;
  static AppServices get I => _instance!;

  final SecureStore secure;
  final VaultRepo repo;
  final PhotoStore photos;
  final GoogleService google;
  final SheetsSync sheets;
  final BackupService backup;
  final ExportService export;
  final ReminderEngine reminders;

  /// Test hook: build services around an already-open database.
  @visibleForTesting
  static AppServices initWith({
    required Database db,
    required SecureStore secure,
    required Directory dataDir,
    required Uint8List photoKey,
  }) {
    final repo = VaultRepo(db);
    final photos = PhotoStore(Directory(p.join(dataDir.path, 'photos')), photoKey);
    final google = GoogleService(repo);
    final tmp = Directory(p.join(dataDir.path, 'tmp'));
    return _instance = AppServices._(
      secure: secure,
      repo: repo,
      photos: photos,
      google: google,
      sheets: SheetsSync(repo, google),
      backup: BackupService(repo: repo, secure: secure, photos: photos, google: google, tempDir: tmp),
      export: ExportService(repo, Directory(p.join(tmp.path, 'exports'))),
      reminders: ReminderEngine(repo),
    );
  }

  static Future<AppServices> init() async {
    if (_instance != null) return _instance!;
    final secure = SecureStore();
    final docs = await getApplicationDocumentsDirectory();
    final tmp = Directory(p.join((await getTemporaryDirectory()).path, 'goldvault'));

    // SQLCipher: the whole database file is AES-256 encrypted with a random
    // key that never leaves the Android Keystore-backed secure storage.
    final db = await cipher.openDatabase(
      p.join(docs.path, 'goldvault.db'),
      password: await secure.dbKey(),
      version: kSchemaVersion,
      onCreate: (db, v) async {
        await createSchema(db);
        await seedDefaults(db);
      },
      onUpgrade: (db, from, to) => upgradeSchema(db, from),
    );
    final repo = VaultRepo(db);
    final photos = PhotoStore(Directory(p.join(docs.path, 'photos')), await secure.photoKey());
    final google = GoogleService(repo);
    return _instance = AppServices._(
      secure: secure,
      repo: repo,
      photos: photos,
      google: google,
      sheets: SheetsSync(repo, google),
      backup: BackupService(repo: repo, secure: secure, photos: photos, google: google, tempDir: tmp),
      export: ExportService(repo, Directory(p.join(tmp.path, 'exports'))),
      reminders: ReminderEngine(repo),
    );
  }
}
