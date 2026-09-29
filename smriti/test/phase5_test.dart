import 'package:drift/drift.dart' hide isNull;
import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smriti/core/util/occurrence.dart';
import 'package:smriti/data/database.dart';
import 'package:smriti/data/providers.dart';
import 'package:smriti/data/repository.dart';
import 'package:smriti/features/festivals/festival_alarms.dart';
import 'package:smriti/features/festivals/festival_model.dart';
import 'package:smriti/features/wishmode/wish_mode_repo.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  setUpAll(tzdata.initializeTimeZones);

  late AppDatabase db;
  setUp(() => db = AppDatabase(NativeDatabase.memory()));
  tearDown(() => db.close());

  test('built-in festivals load with dates and no Eid', () async {
    final all = await FestivalRepo.loadAll(db);
    expect(all.length, 29);
    expect(all.any((f) => f.name.toLowerCase().contains('eid')), isFalse);
    final diwali = all.firstWhere((f) => f.assetId == 'diwali_lakshmi_puja');
    expect(diwali.nextFrom(const Day(2026, 9, 29)), const Day(2026, 11, 8));
    expect(diwali.nextFrom(const Day(2026, 11, 9)), const Day(2027, 10, 29));
  });

  test('editing, resetting and switching off a festival', () async {
    final repo = FestivalRepo(db);
    var holi = (await FestivalRepo.loadAll(db)).firstWhere((f) => f.assetId == 'holi');
    await repo.setDate(holi, 2027, const Day(2027, 3, 23));
    holi = (await FestivalRepo.loadAll(db)).firstWhere((f) => f.assetId == 'holi');
    expect(holi.dates[2027], const Day(2027, 3, 23));
    expect(holi.editedYears, {2027});
    expect(holi.calendarDates[2027], const Day(2027, 3, 22));

    await repo.setDate(holi, 2027, null);
    holi = (await FestivalRepo.loadAll(db)).firstWhere((f) => f.assetId == 'holi');
    expect(holi.dates[2027], const Day(2027, 3, 22));

    await repo.setEnabled(holi, false);
    holi = (await FestivalRepo.loadAll(db)).firstWhere((f) => f.assetId == 'holi');
    expect(holi.enabled, isFalse);
  });

  test('your own festival: same date every year, or specific dates', () async {
    final repo = FestivalRepo(db);
    await repo.addCustom(name: 'Village jatre', month: 2, day: 10);
    await repo.addCustom(name: 'Temple utsava', dates: {2027: const Day(2027, 4, 2)});
    final all = await FestivalRepo.loadAll(db);
    final jatre = all.firstWhere((f) => f.name == 'Village jatre');
    expect(jatre.custom, isTrue);
    expect(jatre.nextFrom(const Day(2026, 9, 29)), const Day(2027, 2, 10));
    final utsava = all.firstWhere((f) => f.name == 'Temple utsava');
    expect(utsava.nextFrom(const Day(2026, 9, 29)), const Day(2027, 4, 2));
    await repo.deleteCustom(jatre);
    expect((await FestivalRepo.loadAll(db)).any((f) => f.name == 'Village jatre'), isFalse);
  });

  test('festivals appear alongside events in the combined list', () async {
    final c = ProviderContainer(overrides: [databaseProvider.overrideWithValue(db)]);
    addTearDown(c.dispose);
    c.listen(allEntriesProvider, (_, _) {});
    await Future<void>.delayed(const Duration(milliseconds: 200));
    final entries = c.read(allEntriesProvider);
    expect(entries.whereType<FestivalEntry>().length, 13); // switched on by default
  });

  test('festival reminders on the morning of each festival', () async {
    final ist = tz.getLocation('Asia/Kolkata');
    final alarms = await festivalAlarms(db, tz.TZDateTime(ist, 2026, 9, 29, 10));
    final diwali = alarms.firstWhere((a) => a.title.contains('Diwali'));
    expect(diwali.when, tz.TZDateTime(ist, 2026, 11, 8, 8));
    expect(diwali.kind, 'fest');
    await db.setSetting('festivalReminders', 'false');
    expect(await festivalAlarms(db, tz.TZDateTime(ist, 2026, 9, 29, 10)), isEmpty);
  });

  test('Wish Mode sessions keep progress so you can pause and continue', () async {
    final people = Repository(db);
    final a = await people.insertPerson(PeopleCompanion.insert(name: 'Asha', relationship: const Value('sister')));
    final b = await people.insertPerson(PeopleCompanion.insert(name: 'Bala', relationship: const Value('brother')));
    final repo = WishModeRepo(db);
    final id = await repo.create(title: 'Raksha Bandhan wishes', festivalKey: 'b:raksha_bandhan', date: '2027-08-17', people: [(a, null), (b, null)]);
    final items = await (db.select(db.wishSessionItems)..where((i) => i.sessionId.equals(id))).get();
    await repo.setStatus(items.first.id, 'wished', message: 'Happy Rakhi!');

    final c = ProviderContainer(overrides: [databaseProvider.overrideWithValue(db)]);
    addTearDown(c.dispose);
    c.listen(openSessionsProvider, (_, _) {});
    await Future<void>.delayed(const Duration(milliseconds: 200));
    final open = c.read(openSessionsProvider).value!;
    expect(open.single.total, 2);
    expect(open.single.done, 1);

    await repo.finish(id);
    await Future<void>.delayed(const Duration(milliseconds: 200));
    expect(c.read(openSessionsProvider).value, isEmpty);
  });
}
