import 'dart:convert';

import 'package:deepwork/core/settings.dart';
import 'package:deepwork/core/util/format.dart';
import 'package:deepwork/data/backup_format.dart';
import 'package:deepwork/data/demo.dart';
import 'package:deepwork/data/repository.dart';
import 'package:deepwork/features/backup/backup_service.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers.dart';

void main() {
  test('backup → JSON → restore reproduces every record and keeps device-only settings', () async {
    final db = memoryDb();
    await Repository(db).seedDefaults();
    await loadDemoData(db);
    final settings = AppSettings.defaults().set('priorities.count', 4).set('lock.enabled', true).set('lock.pinHash', 'secret');
    final file = await buildBackup(db, settings);
    final encoded = file.encode();
    expect(encoded, isNot(contains('secret')), reason: 'PIN hash must never be exported');
    final counts = file.counts;
    expect(counts['sessions'], greaterThan(50));

    final other = memoryDb();
    await Repository(other).seedDefaults();
    final current = AppSettings.defaults().set('lock.enabled', true).set('lock.pinHash', 'mine');
    final restored = await restoreBackup(other, parseBackup(encoded), current);
    expect(restored.priorityCount, 4);
    expect(restored['lock.pinHash'], 'mine');
    expect(restored.b('demoLoaded'), isTrue);
    final again = await buildBackup(other, restored);
    expect(again.counts, counts);
    await db.close();
    await other.close();
  });

  test('backups from the web version (same schema) are accepted', () {
    final web = jsonEncode({
      'app': 'deepwork',
      'schema_version': 1,
      'exported_at': '2026-10-02T10:00:00.000Z',
      'data': {
        'settings': {'priorities': {'count': 2}},
        'tasks': [
          {'id': 't1', 'title': 'Write', 'status': 'done', 'is_priority': true, 'priority_date': '2026-10-02', 'created_at': 1, 'completed_at': 2},
        ],
        'sessions': [
          {'id': 's1', 'task_id': 't1', 'planned_duration': 1500, 'actual_duration': 1500, 'started_at': 1, 'ended_at': 2, 'result': 'done', 'note': ''},
        ],
      },
    });
    final f = parseBackup(web);
    expect(f.counts['tasks'], 1);
    expect(f.counts['reviews'], 0);
  });

  test('rejects files that are not Deepwork backups or are from a newer version', () {
    expect(() => parseBackup('nope'), throwsA(isA<BackupFormatException>()));
    expect(() => parseBackup('{"app":"other","data":{}}'), throwsA(isA<BackupFormatException>()));
    expect(() => parseBackup('{"app":"deepwork","schema_version":99,"data":{}}'), throwsA(isA<BackupFormatException>()));
  });

  test('CSV export escapes quotes and commas', () async {
    final db = memoryDb();
    await Repository(db).createTask(title: 'Say "hi", then go');
    final csv = await buildCsvs(db);
    expect(csv['tasks'], contains('"Say ""hi"", then go"'));
    await db.close();
  });

  test('clearing demo data leaves real data alone', () async {
    final db = memoryDb();
    await Repository(db).seedDefaults();
    await Repository(db).createTask(title: 'Mine');
    await loadDemoData(db);
    await clearDemoData(db);
    final tasks = await db.select(db.tasks).get();
    expect(tasks.map((t) => t.title), ['Mine']);
    expect(await db.select(db.sessions).get(), isEmpty);
    await db.close();
  });

  group('weekly backup schedule', () {
    final now = DateTime(2026, 10, 7, 12); // Wednesday
    AppSettings connected({int? last, int day = 0}) => AppSettings.defaults().edit((m) {
          m['modules']['backup'] = true;
          m['backup']['connected'] = true;
          m['backup']['day'] = day;
          m['backup']['lastBackupAt'] = last;
        });

    test('due right after connecting', () => expect(isBackupDue(connected(), now), isTrue));
    test('not due when backed up since the last scheduled day', () {
      final sunday = DateTime(2026, 10, 4, 9).millisecondsSinceEpoch;
      expect(isBackupDue(connected(last: sunday), now), isFalse);
      expect(dateKey(nextBackupDate(connected(last: sunday), now)), '2026-10-11');
    });
    test('due when the last backup is older than the most recent backup day', () {
      final lastWeek = DateTime(2026, 10, 1).millisecondsSinceEpoch;
      expect(isBackupDue(connected(last: lastWeek), now), isTrue);
    });
    test('never due when disconnected or turned off', () {
      expect(isBackupDue(AppSettings.defaults(), now), isFalse);
      expect(isBackupDue(connected().set('modules.backup', false), now), isFalse);
    });
  });
}
