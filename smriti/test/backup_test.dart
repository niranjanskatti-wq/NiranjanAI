import 'dart:io';

import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:smriti/data/database.dart';
import 'package:smriti/data/repository.dart';
import 'package:smriti/features/backup/backup_service.dart';

class _FakePaths extends Fake with MockPlatformInterfaceMixin implements PathProviderPlatform {
  _FakePaths(this.root);

  final Directory root;

  String _dir(String name) => (Directory('${root.path}/$name')..createSync(recursive: true)).path;

  @override
  Future<String?> getApplicationDocumentsPath() async => _dir('docs');
  @override
  Future<String?> getTemporaryPath() async => _dir('tmp');
  @override
  Future<String?> getExternalStoragePath() async => _dir('external');
}

void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;

  test('backup holds the data and photos, keeps the newest 4, and restores', () async {
    final root = await Directory.systemTemp.createTemp('smriti_backup');
    PathProviderPlatform.instance = _FakePaths(root);
    final docs = Directory('${root.path}/docs');
    final dbFile = File('${docs.path}/smriti.sqlite');
    final db = AppDatabase(NativeDatabase(dbFile));
    final id = await Repository(db).insertPerson(PeopleCompanion.insert(name: 'Ramesh Katti', nickname: const Value('Appa')));
    await Directory('${docs.path}/photos').create();
    await File('${docs.path}/photos/p_1.jpg').writeAsBytes([1, 2, 3]);
    await db.into(db.photoMemories).insert(PhotoMemoriesCompanion.insert(personId: id, year: 2025, path: '${docs.path}/photos/p_1.jpg'));

    final svc = BackupService(db);
    final file = await svc.create();
    final bytes = await file.readAsBytes();
    final manifest = BackupService.inspect(bytes)!;
    expect(manifest['photos'], 1);
    expect(manifest['schema'], db.schemaVersion);
    expect(await db.getSetting('lastBackup'), isNotNull);

    // Weekly: nothing new is made the same day.
    expect(await svc.autoIfDue(), isFalse);
    await db.setSetting('lastBackup', DateTime.now().subtract(const Duration(days: 8)).toIso8601String());
    expect(await svc.autoIfDue(), isTrue);

    // Old ones are pruned.
    for (var i = 0; i < 5; i++) {
      await Future<void>.delayed(const Duration(milliseconds: 1100));
      await svc.create();
    }
    expect((await BackupService.list()).length, BackupService.keep);

    // Restore into a changed state.
    await Repository(db).insertPerson(PeopleCompanion.insert(name: 'Someone new'));
    await db.close();
    await File('${docs.path}/photos/p_1.jpg').delete();
    await BackupService.restoreFiles(bytes);
    final back = AppDatabase(NativeDatabase(dbFile));
    final people = await Repository(back).allPeople();
    expect(people.map((p) => p.name), ['Ramesh Katti']);
    expect((await back.select(back.photoMemories).get()).single.year, 2025);
    expect(await File('${docs.path}/photos/p_1.jpg').readAsBytes(), [1, 2, 3]);
    await back.close();

    expect(BackupService.inspect([1, 2, 3]), isNull);
    await root.delete(recursive: true);
  });
}
