import 'dart:io';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:goldvault/core/app_services.dart';
import 'package:goldvault/core/crypto.dart';
import 'package:goldvault/core/secure_store.dart';
import 'package:goldvault/data/repository.dart';
import 'package:goldvault/data/schema.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

/// Fresh in-memory database with the real schema + seed data.
Future<Database> openTestDb() async {
  sqfliteFfiInit();
  return databaseFactoryFfi.openDatabase(
    inMemoryDatabasePath,
    options: OpenDatabaseOptions(
      version: kSchemaVersion,
      singleInstance: false,
      onCreate: (db, v) async {
        await createSchema(db);
        await seedDefaults(db);
      },
    ),
  );
}

Future<VaultRepo> openTestRepo() async => VaultRepo(await openTestDb());

/// Full service graph on a temp folder, with mocked secure storage.
Future<AppServices> testServices() async {
  FlutterSecureStorage.setMockInitialValues({});
  final dir = await Directory.systemTemp.createTemp('goldvault_test_');
  return AppServices.initWith(
    db: await openTestDb(),
    secure: SecureStore(),
    dataDir: dir,
    photoKey: Crypto.randomBytes(32),
  );
}
