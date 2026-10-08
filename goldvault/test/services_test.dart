import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:goldvault/core/app_services.dart';
import 'package:goldvault/core/crypto.dart';
import 'package:goldvault/core/format.dart';
import 'package:goldvault/data/constants.dart';
import 'package:goldvault/data/models.dart';
import 'package:goldvault/data/repository.dart';
import 'package:goldvault/services/backup_service.dart';
import 'package:goldvault/services/reminder_engine.dart';
import 'package:goldvault/services/report_data.dart';

import 'helpers.dart';

void main() {
  group('crypto', () {
    test('seal/open round trip and tamper detection', () {
      final key = Crypto.randomBytes(32);
      final msg = Uint8List.fromList(utf8.encode('Locker 123, key 456'));
      final sealed = Crypto.seal(key, msg);
      expect(Crypto.open(key, sealed), msg);
      sealed[sealed.length - 1] ^= 1;
      expect(() => Crypto.open(key, sealed), throwsA(anything));
      expect(() => Crypto.open(Crypto.randomBytes(32), Crypto.seal(key, msg)), throwsA(anything));
    });

    test('streamed container spans multiple chunks and rejects wrong passphrase', () async {
      final dir = await Directory.systemTemp.createTemp('gv_crypto');
      final f = File('${dir.path}/x.gvb');
      final data = Crypto.randomBytes(EncryptedWriter.chunkSize * 2 + 12345);
      final w = await EncryptedWriter.create(f, 'correct horse', iterations: 1000);
      w.add(data.sublist(0, 1000));
      w.add(data.sublist(1000));
      await w.close();
      expect(await f.readAsBytes(), isNot(contains(data.sublist(0, 64))));

      final r = await EncryptedReader.open(f, 'correct horse');
      expect(await r.read(data.length), data);
      expect(await r.atEnd(), isTrue);
      await r.close();

      final bad = await EncryptedReader.open(f, 'wrong');
      await expectLater(bad.read(1), throwsA(anything));
      await bad.close();

      // Truncated file must not silently succeed.
      final bytes = await f.readAsBytes();
      await f.writeAsBytes(bytes.sublist(0, bytes.length - 100));
      final t = await EncryptedReader.open(f, 'correct horse');
      await expectLater(t.read(data.length), throwsA(anything));
      await t.close();
    });
  });

  group('backup', () {
    late AppServices svc;
    setUp(() async => svc = await testServices());

    test('encrypted backup restores data and photos on a "new phone"', () async {
      final repo = svc.repo;
      final sbi = (await repo.locations()).first.id!;
      final photo = await svc.photos.save(Uint8List.fromList(List.generate(5000, (i) => i % 256)));
      final it = await repo.createItem(
        Item(name: 'Kasu mala', category: 'Gold', purity: '22K', grossWt: 80, locationId: sbi, status: Opt.inLocker),
        photos: [photo],
      );
      await repo.logVisit(Visit(locationId: sbi, visitDate: '2026-03-12', timeIn: '11:30'));
      final file = await svc.backup.writeBackupFile('family-secret');
      expect(await file.length(), greaterThan(5000));
      // Nothing readable inside.
      expect(latin1.decode(await file.readAsBytes()).contains('Kasu mala'), isFalse);

      // Fresh install: different photo key, empty data.
      final fresh = await testServices();
      expect((await fresh.repo.items(const ItemQuery())), isEmpty);
      await expectLater(
        fresh.backup.restoreFromFile(file, 'nope'),
        throwsA(isA<BackupException>().having((e) => e.code, 'code', 'wrong_passphrase')),
      );
      final manifest = await fresh.backup.restoreFromFile(file, 'family-secret');
      expect(manifest['items'], 1);
      final restored = await fresh.repo.items(const ItemQuery());
      expect(restored.single.name, 'Kasu mala');
      expect(restored.single.serial, it.serial);
      expect((await fresh.repo.visits()).length, 1);
      final photos = await fresh.repo.photosFor(restored.single.id!);
      expect((await fresh.photos.load(photos.single.file))!.length, 5000);
    });

    test('rejects files that are not backups', () async {
      final dir = await Directory.systemTemp.createTemp('gv_bad');
      final f = File('${dir.path}/x.gvb')..writeAsStringSync('hello world, not a backup at all');
      await expectLater(svc.backup.restoreFromFile(f, 'x'), throwsA(isA<BackupException>()));
    });

    test('weekly schedule: due after the chosen slot, not before', () async {
      await svc.backup.saveSchedule(const BackupSchedule(enabled: true, weekday: DateTime.sunday, hour: 2, minute: 0));
      // Sunday 4 Oct 2026, 03:00 -> slot 02:00 same day.
      final sunday = DateTime(2026, 10, 4, 3);
      expect(await svc.backup.isDue(sunday), isTrue);
      await svc.repo.setSetting('last_backup', Fmt.isoDateTime(DateTime(2026, 10, 4, 2, 30)));
      expect(await svc.backup.isDue(sunday), isFalse);
      expect(await svc.backup.isDue(DateTime(2026, 10, 10, 23)), isFalse); // Saturday
      expect(await svc.backup.isDue(DateTime(2026, 10, 11, 2, 1)), isTrue); // next Sunday
      const s = BackupSchedule(enabled: true, weekday: DateTime.wednesday, hour: 21, minute: 30);
      expect(s.nextSlot(DateTime(2026, 10, 8)), DateTime(2026, 10, 14, 21, 30));
    });
  });

  group('reminders', () {
    late VaultRepo repo;
    setUp(() async => repo = await openTestRepo());

    test('rent due, items not returned, and planned visits', () async {
      final sbi = (await repo.locations()).first;
      await repo.saveLocker(id: sbi.id, name: sbi.name, info: const LockerInfo(bank: 'SBI', rentDueDate: '2026-10-20', annualRent: 2500));
      final chain = await repo.createItem(
          const Item(name: 'Chain', category: 'Gold', status: Opt.inLocker, grossWt: 8).copyWith(locationId: sbi.id));
      await repo.moveItem(chain.id!, toStatus: Opt.repair, at: DateTime(2026, 8, 1), note: 'Shop');
      await repo.saveReminder(ReminderEngine.planned(sbi, DateTime(2026, 10, 9)));

      final engine = ReminderEngine(repo);
      final now = DateTime(2026, 10, 8, 9);
      final due = await engine.upcoming(now: now);
      expect(due.map((d) => d.kind), containsAll([DueKind.rent, DueKind.notReturned, DueKind.plannedVisit]));
      final notify = await engine.dueForNotification(now: now);
      expect(notify.map((d) => d.kind).toSet(), {DueKind.rent, DueKind.notReturned, DueKind.plannedVisit});

      // Logging the visit completes the plan; returning the chain clears that reminder.
      await repo.logVisit(Visit(locationId: sbi.id!, visitDate: '2026-10-09', timeIn: '10:00'), deposit: [chain.id!]);
      final after = await engine.upcoming(now: now);
      expect(after.map((d) => d.kind), [DueKind.rent]);

      // Far from the due date, rent is not yet nagging.
      await repo.markRentPaid(sbi.id!);
      expect(await engine.dueForNotification(now: now), isEmpty);
    });
  });

  group('reports & exports (offline)', () {
    late AppServices svc;
    setUp(() async {
      svc = await testServices();
      final repo = svc.repo;
      final locs = await repo.locations();
      for (var n = 0; n < 30; n++) {
        await repo.createItem(Item(
          name: 'Bangle $n',
          category: n.isEven ? 'Gold' : 'Silver',
          purity: n.isEven ? '22K' : '925 silver',
          grossWt: 10.0 + n,
          locationId: locs[n % locs.length].id,
          status: locs[n % locs.length].isLocker ? Opt.inLocker : Opt.atHome,
          owner: n % 3 == 0 ? 'Amma' : 'Appa',
        ));
      }
      await repo.saveRates(const Rates(gold24: 7200, silver: 92));
    });

    test('report has the five sheet tabs plus one per active locker', () async {
      final tabs = await ReportBuilder(svc.repo).build();
      expect(tabs.map((t) => t.title), [
        'Inventory',
        'Lockers',
        'Locker Visits',
        'Movement History',
        'Locations',
        'Locker - SBI Bank Locker',
        'Locker - HDFC Bank Locker',
      ]);
      expect(tabs.first.rows.length, 30);
      expect(tabs.first.header.first, 'Serial No');
    });

    test('Excel export is a valid xlsx with all tabs', () async {
      final f = await svc.export.excel();
      final zip = ZipDecoder().decodeBytes(await f.readAsBytes());
      final wb = utf8.decode(zip.findFile('xl/workbook.xml')!.content as List<int>);
      for (final t in ['Inventory', 'Lockers', 'Locker Visits', 'Movement History', 'Locations']) {
        expect(wb, contains('name="$t"'));
      }
      expect(wb, isNot(contains('name="Sheet1"')));
    });

    test('PDF report renders', () async {
      Uint8List font(String n) => File('assets/fonts/$n').readAsBytesSync();
      final f = await svc.export.pdf(
          regularFont: font('Lato-Regular.ttf'), boldFont: font('Lato-Bold.ttf'), titleFont: font('PlayfairDisplay.ttf'));
      final head = String.fromCharCodes((await f.readAsBytes()).take(5));
      expect(head, '%PDF-');
      expect(await f.length(), greaterThan(2000));
    });
  });
}
