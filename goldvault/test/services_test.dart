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
import 'package:goldvault/services/holiday_calendar.dart';
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
      // Planned visit alarm: the day before, at the default alert time.
      final planned = due.firstWhere((d) => d.kind == DueKind.plannedVisit);
      expect(planned.notifyAt, DateTime(2026, 10, 8, 9));
      // Daily nags (from the background job) are only for overdue rent / items.
      final notify = await engine.dueForNotification(now: now);
      expect(notify.map((d) => d.kind).toSet(), {DueKind.rent, DueKind.notReturned});

      // Logging the visit completes the plan; returning the chain clears that reminder.
      await repo.logVisit(Visit(locationId: sbi.id!, visitDate: '2026-10-09', timeIn: '10:00'), deposit: [chain.id!]);
      final after = await engine.upcoming(now: now);
      // (Kannada Rajyotsava on 1 Nov also shows up as a holiday warning.)
      expect(after.where((d) => d.kind != DueKind.holiday).map((d) => d.kind), [DueKind.rent]);
      expect(after.where((d) => d.kind == DueKind.holiday).single.title, 'Kannada Rajyotsava');

      // Far from the due date, rent is not yet nagging.
      await repo.markRentPaid(sbi.id!);
      expect(await engine.dueForNotification(now: now), isEmpty);
    });
  });

  group('alarms & bank holidays', () {
    late VaultRepo repo;
    setUp(() async => repo = await openTestRepo());

    test('bank holiday rules: Sundays, 2nd/4th Saturdays and the holiday list', () async {
      final cal = await HolidayCalendar.load(repo);
      expect(cal.namedOn(DateTime(2026, 10, 2)), ['Gandhi Jayanti']);
      expect(cal.weekendOn(DateTime(2026, 10, 10)), 'sat2'); // 2nd Saturday
      expect(cal.weekendOn(DateTime(2026, 10, 3)), isNull); // 1st Saturday
      expect(cal.weekendOn(DateTime(2026, 10, 11)), 'sun');
      expect(cal.isClosed(DateTime(2026, 10, 12)), isFalse);

      // A festival added by the family joins the weekend into one long closure.
      await repo.saveHoliday(const Holiday(name: 'Ayudha Pooja', date: '2026-10-23'));
      final closures = (await HolidayCalendar.load(repo)).closures(DateTime(2026, 10, 20), DateTime(2026, 10, 31));
      final c = closures.firstWhere((c) => c.hasNamedHoliday);
      expect(c.start, DateTime(2026, 10, 23)); // Fri
      expect(c.end, DateTime(2026, 10, 25)); // Sat (4th) + Sun
      expect(c.days, 3);

      // Warning 2 days before at the alert time, and switchable.
      final due = await ReminderEngine(repo).upcoming(now: DateTime(2026, 10, 15), horizonDays: 30);
      final h = due.firstWhere((d) => d.kind == DueKind.holiday && d.date == DateTime(2026, 10, 23));
      expect(h.notifyAt, DateTime(2026, 10, 21, 9));
      expect(h.days, 3);
      await repo.setPref('holiday_alerts', false);
      final off = await ReminderEngine(repo).upcoming(now: DateTime(2026, 10, 15), horizonDays: 30);
      expect(off.where((d) => d.kind == DueKind.holiday), isEmpty);

      // Rules can be switched off too.
      await repo.setPref('closed_sat_2_4', false);
      expect((await HolidayCalendar.load(repo)).isClosed(DateTime(2026, 10, 10)), isFalse);
    });

    test('alarm reminders: exact time, repeat, on/off, auto-done when kept in locker', () async {
      final sbi = (await repo.locations()).first;
      final ring = await repo.createItem(
          const Item(name: 'Ring', category: 'Gold', status: Opt.atHome, grossWt: 4).copyWith(locationId: (await repo.locations()).last.id));
      final id = await repo.saveReminder(Reminder(
        kind: 'keep',
        title: 'Keep ring in SBI',
        dueDate: '2026-10-20',
        time: '18:30',
        locationId: sbi.id,
        itemIds: [ring.id!],
      ));
      var due = await ReminderEngine(repo).upcoming(now: DateTime(2026, 10, 15));
      final k = due.firstWhere((d) => d.reminderId == id);
      expect(k.kind, DueKind.keep);
      expect(k.notifyAt, DateTime(2026, 10, 20, 18, 30));
      expect(k.alarm, isTrue);

      await repo.setReminderEnabled(id, false);
      due = await ReminderEngine(repo).upcoming(now: DateTime(2026, 10, 15));
      expect(due.where((d) => d.reminderId == id), isEmpty);
      await repo.setReminderEnabled(id, true);

      // Depositing the ring completes the reminder.
      await repo.logVisit(Visit(locationId: sbi.id!, visitDate: '2026-10-19', timeIn: '11:00'), deposit: [ring.id!]);
      expect((await repo.reminder(id))!.done, isTrue);

      // Repeating reminders roll forward instead of finishing.
      final m = await repo.saveReminder(const Reminder(kind: 'custom', title: 'Check locker', dueDate: '2026-10-31', repeat: 'monthly'));
      due = await ReminderEngine(repo).upcoming(now: DateTime(2026, 10, 15), horizonDays: 60);
      expect(due.where((d) => d.reminderId == m).map((d) => d.date), [DateTime(2026, 10, 31), DateTime(2026, 12, 1)]);
      await repo.setReminderDone(m, true);
      expect((await repo.reminder(m))!.dueDate, '2026-12-01');
      expect((await repo.reminder(m))!.done, isFalse);
    });

    test('time taken out, and "until put back" alarms that keep ringing daily', () async {
      final locs = await repo.locations();
      final sbi = locs.first;
      final home = locs.last;
      final chain = await repo.createItem(
          const Item(name: 'Chain', category: 'Gold', status: Opt.inLocker, grossWt: 8).copyWith(locationId: sbi.id));
      await repo.logVisit(Visit(locationId: sbi.id!, visitDate: '2026-10-01', timeIn: '11:00', timeOut: '11:30'),
          withdraw: [chain.id!], withdrawTo: home.id);
      final out = await repo.takenOutTimes();
      expect(out[chain.id], DateTime(2026, 10, 1, 11, 30));

      final id = await repo.saveReminder(Reminder(
        kind: 'keep', title: 'Put chain back', dueDate: '2026-10-05', time: '10:00',
        repeat: 'until_back', locationId: sbi.id, itemIds: [chain.id!],
      ));
      expect((await repo.returnByTimes('09:00'))[chain.id], DateTime(2026, 10, 5, 10));

      // Three days late: today's alarm is overdue and it keeps ringing daily.
      final due = (await ReminderEngine(repo).upcoming(now: DateTime(2026, 10, 8, 12)))
          .where((d) => d.reminderId == id)
          .toList();
      expect(due.first.notifyAt, DateTime(2026, 10, 8, 10));
      expect(due.first.isOverdue(DateTime(2026, 10, 9)), isTrue);
      expect(due[1].notifyAt, DateTime(2026, 10, 9, 10));

      // Putting it back stops the alarm and clears the time out.
      await repo.logVisit(Visit(locationId: sbi.id!, visitDate: '2026-10-08', timeIn: '15:00'), deposit: [chain.id!]);
      expect((await repo.reminder(id))!.done, isTrue);
      expect((await repo.takenOutTimes()).containsKey(chain.id), isFalse);

      // Marking an "until put back" alarm done finishes it (no roll forward).
      final id2 = await repo.saveReminder(const Reminder(kind: 'keep', title: 'x', dueDate: '2026-10-05', repeat: 'until_back'));
      await repo.setReminderDone(id2, true);
      expect((await repo.reminder(id2))!.done, isTrue);
    });

    test('master switch and per-type switches', () async {
      final sbi = (await repo.locations()).first;
      await repo.saveLocker(id: sbi.id, name: sbi.name, info: const LockerInfo(bank: 'SBI', rentDueDate: '2026-10-20'));
      expect((await ReminderEngine(repo).upcoming(now: DateTime(2026, 10, 15))).any((d) => d.kind == DueKind.rent), isTrue);
      await repo.setPref('rent_alerts', false);
      expect((await ReminderEngine(repo).upcoming(now: DateTime(2026, 10, 15))).any((d) => d.kind == DueKind.rent), isFalse);
      expect((await repo.prefs()).notifications, isTrue);
      await repo.setPref('notif_enabled', false);
      expect((await repo.prefs()).notifications, isFalse);
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
      await repo.setPref('show_values', true);
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
      expect(tabs.first.header, contains('Est. value (₹)'));
      await svc.repo.setPref('show_values', false);
      final hidden = await ReportBuilder(svc.repo).build();
      expect(hidden.first.header, isNot(contains('Est. value (₹)')));
      expect(hidden.first.rows.first.length, hidden.first.header.length);
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
