import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:goldvault/core/format.dart';
import 'package:goldvault/data/constants.dart';
import 'package:goldvault/data/models.dart';
import 'package:goldvault/data/repository.dart';
import 'package:goldvault/data/schema.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'helpers.dart';

Item gold(String name, {required int? loc, double gross = 10, double? net, String purity = '22K', String? owner, String? tags, String status = Opt.inLocker}) =>
    Item(name: name, category: 'Gold', purity: purity, grossWt: gross, netWt: net, locationId: loc, status: status, owner: owner, tags: tags);

void main() {
  late VaultRepo repo;
  late int sbi, hdfc, home, almirah;

  setUp(() async {
    repo = await openTestRepo();
    final locs = await repo.locations();
    sbi = locs.firstWhere((l) => l.name == 'SBI Bank Locker').id!;
    hdfc = locs.firstWhere((l) => l.name == 'HDFC Bank Locker').id!;
    home = locs.firstWhere((l) => l.name == 'Home').id!;
    almirah = locs.firstWhere((l) => l.name == 'Almirah').id!;
  });

  test('seeds SBI, HDFC lockers and Home with sub-locations', () async {
    final locs = await repo.locations();
    expect(locs.where((l) => l.isLocker).map((l) => l.name), ['SBI Bank Locker', 'HDFC Bank Locker']);
    expect(locs.where((l) => l.parentId == home).map((l) => l.name), containsAll(['Almirah', 'Safe', 'Drawer']));
    expect((await repo.lockerInfo(sbi))!.bank, 'SBI');
    expect((await repo.lockerInfo(hdfc))!.bank, 'HDFC');
  });

  test('assigns serial numbers GV-0001, GV-0002 … and logs creation', () async {
    expect(await repo.peekNextSerial(), 'GV-0001');
    final a = await repo.createItem(gold('Necklace', loc: sbi));
    final b = await repo.createItem(gold('Bangle', loc: sbi));
    expect(a.serial, 'GV-0001');
    expect(b.serial, 'GV-0002');
    expect(await repo.peekNextSerial(), 'GV-0003');
    final h = await repo.historyFor(a.id!);
    expect(h.single.action, 'create');
    expect(h.single.toName, 'SBI Bank Locker');
  });

  test('new lockers get their own colour and can be edited', () async {
    final id = await repo.saveLocker(
      name: 'ICICI Locker',
      info: const LockerInfo(bank: 'ICICI', lockerNo: '123', keyNo: 'K9', annualRent: 3500, rentDueDate: '2026-12-01'),
    );
    final l = (await repo.location(id))!;
    final used = (await repo.locations()).where((x) => x.isLocker && x.id != id).map((x) => x.color);
    expect(used, isNot(contains(l.color)));
    await repo.saveLocker(id: id, name: 'ICICI Locker (new branch)', info: const LockerInfo(bank: 'ICICI', lockerNo: '456'));
    expect((await repo.location(id))!.name, 'ICICI Locker (new branch)');
    expect((await repo.lockerInfo(id))!.lockerNo, '456');
  });

  test('visit deposits and withdrawals move items and record times', () async {
    final chain = await repo.createItem(gold('Chain', loc: almirah, status: Opt.atHome));
    final ring = await repo.createItem(gold('Ring', loc: sbi));
    await repo.logVisit(
      const Visit(locationId: 0, visitDate: '2026-03-12', timeIn: '11:30', timeOut: '12:05', visitors: 'Appa').copyWithLocation(sbi),
      deposit: [chain.id!],
      withdraw: [ring.id!],
      withdrawTo: almirah,
    );
    final c = (await repo.item(chain.id!))!;
    final r = (await repo.item(ring.id!))!;
    expect(c.locationId, sbi);
    expect(c.status, Opt.inLocker);
    expect(r.locationId, almirah);
    expect(r.status, Opt.atHome);

    // History is ordered by when things happened (the visit is backdated).
    final deposit = (await repo.historyFor(chain.id!)).firstWhere((m) => m.action == 'deposit');
    expect(deposit.movedAt, '2026-03-12T11:30:00');
    expect(deposit.toName, 'SBI Bank Locker');
    final withdraw = (await repo.historyFor(ring.id!)).firstWhere((m) => m.action == 'withdraw');
    expect(withdraw.movedAt, '2026-03-12T12:05:00');
    expect(withdraw.fromName, 'SBI Bank Locker');
    expect(withdraw.toName, 'Almirah');

    final visits = await repo.visits(locationId: sbi);
    final d = (await repo.visitDetail(visits.single.id!))!;
    expect(d.deposited.map((m) => m.itemName), ['Chain']);
    expect(d.withdrawn.map((m) => m.itemName), ['Ring']);
    expect((await repo.movementsOn(DateTime(2026, 3, 12))).length, 2);
  });

  test('withdrawing to "being worn" clears the location', () async {
    final n = await repo.createItem(gold('Mangalsutra', loc: sbi));
    await repo.logVisit(Visit(locationId: sbi, visitDate: '2026-06-02', timeIn: '16:15'),
        withdraw: [n.id!], withdrawStatus: Opt.worn, withdrawNote: 'Amma');
    final i = (await repo.item(n.id!))!;
    expect(i.locationId, isNull);
    expect(i.status, Opt.worn);
    expect(i.statusNote, 'Amma');
  });

  test('closing a locker requires moving items first and keeps history', () async {
    final i = await repo.createItem(gold('Haram', loc: hdfc));
    expect(() => repo.closeLocker(hdfc), throwsStateError);
    await repo.closeLocker(hdfc, moveToId: sbi);
    expect((await repo.location(hdfc))!.isClosed, isTrue);
    expect((await repo.locations()).any((l) => l.id == hdfc), isFalse);
    expect((await repo.locations(includeClosed: true)).any((l) => l.id == hdfc), isTrue);
    expect((await repo.item(i.id!))!.locationId, sbi);
    final h = await repo.historyFor(i.id!);
    expect(h.first.action, 'close');
    expect(h.first.fromName, 'HDFC Bank Locker');
  });

  test('sold / gifted items stay in history but leave the totals', () async {
    final a = await repo.createItem(gold('Old chain', loc: sbi, gross: 20, net: 19));
    await repo.createItem(gold('Bangle', loc: sbi, gross: 12));
    await repo.moveItem(a.id!, toStatus: Opt.exchanged, note: 'Exchanged for new chain');
    final t = (await repo.totalsByLocation())[sbi]!;
    expect(t.items, 1);
    expect(t.gold, 12);
    expect((await repo.item(a.id!))!.status, Opt.exchanged);
    expect((await repo.historyFor(a.id!)).first.toStatus, Opt.exchanged);
  });

  test('location totals split gold and silver and include values', () async {
    await repo.createItem(gold('Chain', loc: sbi, gross: 10, net: 9.5, purity: '22K'));
    await repo.createItem(const Item(name: 'Plate', category: 'Silver', purity: '925 silver', grossWt: 100, locationId: 0, status: Opt.inLocker)
        .copyWith(locationId: sbi));
    await repo.saveRates(const Rates(gold24: 7000, silver: 90));
    // Current prices are hidden unless switched on.
    expect((await repo.totalsByLocation())[sbi]!.value, 0);
    await repo.setPref('show_values', true);
    final t = (await repo.totalsByLocation())[sbi]!;
    expect(t.gold, 9.5);
    expect(t.silver, 100);
    expect(t.value, closeTo(9.5 * 22 / 24 * 7000 + 100 * 0.925 * 90, 0.01));
  });

  test('search by name, serial, owner, tag and location; sort by weight', () async {
    await repo.createItem(gold('Kasu mala', loc: sbi, gross: 80, owner: 'Lakshmi', tags: 'wedding, heirloom'));
    await repo.createItem(gold('Ring', loc: almirah, gross: 4, owner: 'Ravi', status: Opt.atHome));
    await repo.createItem(gold('Jhumka', loc: hdfc, gross: 15, owner: 'Lakshmi'));
    Future<List<String>> names(ItemQuery q) async => (await repo.items(q)).map((i) => i.name).toList();
    expect(await names(const ItemQuery(text: 'kasu')), ['Kasu mala']);
    expect(await names(const ItemQuery(text: 'GV-0002')), ['Ring']);
    expect(await names(const ItemQuery(text: 'lakshmi')), ['Kasu mala', 'Jhumka']);
    expect(await names(const ItemQuery(text: 'heirloom')), ['Kasu mala']);
    expect(await names(const ItemQuery(text: 'hdfc')), ['Jhumka']);
    expect(await names(ItemQuery(locationIds: {home})), ['Ring']); // includes sub-locations
    expect(await names(const ItemQuery(sort: 'weight', descending: true)), ['Kasu mala', 'Jhumka', 'Ring']);
    expect(await repo.owners(), ['Lakshmi', 'Ravi']);
    final w = await repo.whereIs('ring');
    expect(w.single.location!.name, 'Almirah');
    expect(w.single.lastMove, isNotNull);
  });

  test('rent paid moves due date forward a year', () async {
    await repo.saveLocker(id: sbi, name: 'SBI Bank Locker', info: const LockerInfo(bank: 'SBI', rentDueDate: '2026-04-01'));
    await repo.markRentPaid(sbi);
    expect((await repo.lockerInfo(sbi))!.rentDueDate, '2027-04-01');
  });

  test('locations with history cannot be deleted', () async {
    final id = await repo.addPlace('Temp shelf', parentId: home);
    expect(await repo.canDeleteLocation(id), isTrue);
    await repo.createItem(gold('Coin', loc: id, status: Opt.atHome));
    expect(await repo.canDeleteLocation(id), isFalse);
    expect(await repo.deleteLocation(id), isFalse);
  });

  test('dump and restore round-trip every table', () async {
    await repo.createItem(gold('Necklace', loc: sbi));
    await repo.logVisit(Visit(locationId: sbi, visitDate: Fmt.isoDate(DateTime.now()), timeIn: '10:00'));
    final dump = await repo.dumpAll();
    final other = await openTestRepo();
    await other.restoreAll(dump);
    expect((await other.items(const ItemQuery())).single.name, 'Necklace');
    expect((await other.visits()).length, 1);
    expect(await other.peekNextSerial(), 'GV-0002');
  });

  test('attach, reorder and remove photos on an existing ornament', () async {
    final i = await repo.createItem(gold('Necklace', loc: sbi), photos: ['a.gvp']);
    await repo.addPhotos(i.id!, ['b.gvp', 'c.gvp']);
    var ph = await repo.photosFor(i.id!);
    expect(ph.map((p) => p.file), ['a.gvp', 'b.gvp', 'c.gvp']);
    await repo.setMainPhoto(i.id!, ph[2].id!);
    expect((await repo.firstPhotos())[i.id], 'c.gvp');
    expect(await repo.removePhoto(ph[0].id!), 'a.gvp');
    ph = await repo.photosFor(i.id!);
    expect(ph.map((p) => p.file), ['c.gvp', 'b.gvp']);
    await repo.setBillPhoto(i.id!, 'bill.gvp');
    expect((await repo.item(i.id!))!.billPhoto, 'bill.gvp');
    expect(await repo.allPhotoFiles(), containsAll(['c.gvp', 'b.gvp', 'bill.gvp']));
  });

  test('upgrading a version-1 database keeps data and adds alarms + holidays', () async {
    final dir = await Directory.systemTemp.createTemp('gv_upgrade');
    final path = '${dir.path}/v1.db';
    sqfliteFfiInit();
    var db = await databaseFactoryFfi.openDatabase(path,
        options: OpenDatabaseOptions(version: 1, onCreate: (db, v) async {
          await createSchema(db, upTo: 1);
          await seedDefaults(db);
          await db.insert('reminders', {'kind': 'planned_visit', 'title': 'SBI', 'due_date': '2026-11-02'});
        }));
    await db.close();
    db = await databaseFactoryFfi.openDatabase(path,
        options: OpenDatabaseOptions(version: kSchemaVersion, onUpgrade: (db, from, to) => upgradeSchema(db, from)));
    final r = VaultRepo(db);
    final old = (await r.reminders()).single;
    expect(old.title, 'SBI');
    expect(old.enabled, isTrue);
    expect(old.repeat, 'none');
    expect((await r.holidays()).map((h) => h.name), contains('Kannada Rajyotsava'));
    await db.close();
  });

  test('purity factors', () {
    expect(Opt.purityFactor('24K'), 1);
    expect(Opt.purityFactor('22K'), closeTo(0.9167, 0.001));
    expect(Opt.purityFactor('925 silver'), 0.925);
    expect(Opt.purityFactor('PT950'), 0.95);
    expect(metalOf('Diamond', '18K'), Metal.gold);
    expect(metalOf('Diamond', 'PT950'), Metal.platinum);
  });

  test('Indian number formatting', () {
    expect(Fmt.rupees(1234567), '₹12,34,567');
    expect(Fmt.grams(125000.5), '1,25,000.5 g');
    expect(Fmt.serial(12), 'GV-0012');
    expect(Fmt.parseNum('1,25,000.50'), 125000.5);
  });
}

extension on Visit {
  Visit copyWithLocation(int id) => Visit(
        locationId: id,
        visitDate: visitDate,
        timeIn: timeIn,
        timeOut: timeOut,
        visitors: visitors,
        purpose: purpose,
        notes: notes,
      );
}
