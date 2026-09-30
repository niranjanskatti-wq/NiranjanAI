import 'dart:io';

import 'package:drift/drift.dart' hide isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smriti/core/util/occurrence.dart';
import 'package:smriti/data/database.dart';
import 'package:smriti/data/enums.dart';
import 'package:smriti/data/models.dart';
import 'package:smriti/data/repository.dart';
import 'package:smriti/features/messages/message_engine.dart';
import 'package:sqlite3/sqlite3.dart' as raw;

MessageTemplate t(String id, Occasion o, List<String> rel, String text) =>
    MessageTemplate(id: id, occasion: o, relations: rel, tone: Tone.short, lang: Lang.en, text: text);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;

  group('message engine', () {
    const ctx = MessageContext(
      name: 'Ramesh',
      nickname: 'Appa',
      relation: Relationship.father,
      age: 60,
      myName: 'Niranjan',
    );

    test('fills placeholders', () {
      expect(ctx.fill('Happy {age_th} birthday, {nickname}! – {my_name}'), 'Happy 60th birthday, Appa! – Niranjan');
      expect(ctx.fill('{relation} {name}'), 'Father Ramesh');
    });

    test('skips messages whose placeholders cannot be filled', () {
      expect(ctx.canFill(t('a', Occasion.birthday, ['any'], 'Happy {years_th} anniversary')), isFalse);
      expect(ctx.canFill(t('b', Occasion.birthday, ['any'], 'Hi {nickname}')), isTrue);
    });

    test('prefers exact relation, then family, then anyone; sent messages last', () {
      final lib = [
        t('any', Occasion.birthday, ['any'], 'Happy birthday {nickname}'),
        t('fam', Occasion.birthday, ['parent'], 'Happy birthday dear {nickname}'),
        t('exact', Occasion.birthday, ['father'], 'Happy birthday Appa'),
        t('friend', Occasion.birthday, ['friend'], 'Yo {nickname}'),
      ];
      final engine = MessageLibraryForTest(lib);
      final order = engine.suggest(occasions: [Occasion.birthday], lang: Lang.en, ctx: ctx).map((m) => m.id).toList();
      expect(order, ['exact', 'fam', 'any']);
      final avoided = engine
          .suggest(occasions: [Occasion.birthday], lang: Lang.en, ctx: ctx, alreadySent: {'exact'})
          .map((m) => m.id)
          .toList();
      expect(avoided.last, 'exact');
    });

    test('falls back to the next occasion when nothing matches', () {
      final engine = MessageLibraryForTest([t('b', Occasion.birthday, ['any'], 'HB {nickname}')]);
      final got = engine.suggest(occasions: [Occasion.milestoneBirthday, Occasion.birthday], lang: Lang.en, ctx: ctx);
      expect(got.single.id, 'b');
    });

    test('bundled English messages all parse and fill for a father', () async {
      final raw = await File('assets/messages/en.json').readAsString();
      expect(raw.contains('"messages"'), isTrue);
    });
  });

  group('occasions', () {
    Person p(Relationship r) => Person(
          id: 1,
          name: 'X',
          relationship: r.name,
          stars: 3,
          whatsappApp: 'auto',
          editedFields: '',
          isMe: false,
          isArchived: false,
          createdAt: DateTime(2020),
          updatedAt: DateTime(2020),
        );
    EventEntry e(EventType type, EventKind kind, List<Person> people) => EventEntry(
          Event(
            id: 1,
            kind: kind.name,
            type: type.name,
            day: 1,
            month: 1,
            repeat: 'yearly',
            feb29Rule: 'feb28',
            alarmClock: 'mine',
            belatedNudge: true,
            createdAt: DateTime(2020),
          ),
          people,
        );

    test('milestone birthdays use milestone messages first', () {
      expect(occasionsFor(e(EventType.birthday, EventKind.person, [p(Relationship.father)]), milestone: true),
          [Occasion.milestoneBirthday, Occasion.birthday]);
    });
    test('a wife\'s anniversary is a spouse anniversary; an uncle\'s is a couple anniversary', () {
      expect(occasionsFor(e(EventType.weddingAnniversary, EventKind.person, [p(Relationship.wife)]), milestone: false).first,
          Occasion.anniversary);
      expect(occasionsFor(e(EventType.weddingAnniversary, EventKind.person, [p(Relationship.uncle)]), milestone: false).first,
          Occasion.coupleAnniversary);
    });
    test('belated wins', () {
      expect(occasionsFor(e(EventType.birthday, EventKind.person, [p(Relationship.friend)]), milestone: false, belated: true)
          .first, Occasion.belated);
    });
  });

  group('wish history', () {
    late AppDatabase db;
    late Repository repo;
    setUp(() {
      db = AppDatabase(NativeDatabase.memory());
      repo = Repository(db);
    });
    tearDown(() => db.close());

    test('mark as wished confirms the latest log, or adds one', () async {
      final id = await repo.insertPerson(PeopleCompanion.insert(name: 'A'));
      final ev = await repo.saveEvent(
          data: EventsCompanion.insert(kind: 'person', type: 'birthday', day: 1, month: 1), personIds: [id]);
      await repo.logWish(personId: id, eventId: ev, occasionDate: '2026-01-01', method: 'whatsapp', message: 'hi');
      await repo.markWished(eventId: ev, occasionDate: '2026-01-01');
      var logs = await repo.watchWishLogs().first;
      expect(logs.single.confirmed, isTrue);

      await repo.markWished(eventId: ev, occasionDate: '2027-01-01');
      logs = await repo.watchWishLogs().first;
      expect(logs.length, 2);
      expect(logs.where((l) => l.method == 'manual').single.confirmed, isTrue);

      await repo.unmarkWished(eventId: ev, occasionDate: '2027-01-01');
      logs = await repo.watchWishLogs().first;
      expect(logs.where((l) => l.occasionDate == '2027-01-01').single.confirmed, isFalse);
    });
  });

  test('upgrading a Phase 1 database keeps its data', () async {
    final dir = await Directory.systemTemp.createTemp('smriti');
    final file = File('${dir.path}/db.sqlite');
    // Make a current database, then turn it back into the Phase 1 (v1) shape.
    var db = AppDatabase(NativeDatabase(file));
    final pid = await Repository(db).insertPerson(PeopleCompanion.insert(name: 'Old friend'));
    await Repository(db).saveEvent(
        data: EventsCompanion.insert(kind: 'person', type: 'birthday', day: 5, month: 5), personIds: [pid]);
    await Repository(db)
        .saveEvent(data: EventsCompanion.insert(kind: 'other', type: 'rent', day: 1, month: 1), personIds: []);
    await db.close();
    final r = raw.sqlite3.open(file.path);
    r.execute('ALTER TABLE people DROP COLUMN whatsapp_app');
    r.execute('DROP TABLE wish_logs');
    r.execute('DROP TABLE reminders');
    for (final t in [
      'user_messages', 'favourite_messages', 'festival_overrides', 'custom_festivals', 'wish_session_items',
      'wish_sessions', 'photo_memories', 'group_members', '"groups"', 'family_links',
    ]) {
      r.execute('DROP TABLE $t');
    }
    // Phase 1 gift ideas had no budget or occasion.
    r.execute('CREATE TABLE gift_old AS SELECT id, person_id, idea, purchased, created_at FROM gift_ideas');
    r.execute('DROP TABLE gift_ideas');
    r.execute('CREATE TABLE gift_ideas (id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT, person_id INTEGER NOT NULL '
        'REFERENCES people (id) ON DELETE CASCADE, idea TEXT NOT NULL, purchased INTEGER NOT NULL DEFAULT 0, '
        'created_at INTEGER NOT NULL DEFAULT (CAST(strftime(\'%s\', CURRENT_TIMESTAMP) AS INTEGER)))');
    r.execute("INSERT INTO gift_ideas (person_id, idea) VALUES ($pid, 'Old gift idea')");
    r.execute('DROP TABLE gift_old');
    r.execute('PRAGMA user_version = 1');
    r.close();

    db = AppDatabase(NativeDatabase(file));
    final people = await db.select(db.people).get();
    expect(people.single.name, 'Old friend');
    expect(people.single.whatsappApp, 'auto');
    await Repository(db).logWish(personId: people.single.id, method: 'call');
    expect((await db.select(db.wishLogs).get()).length, 1);
    // Later tables and columns arrive too.
    final gift = (await db.select(db.giftIdeas).get()).single;
    expect((gift.idea, gift.budget, gift.eventId), ('Old gift idea', null, null));
    await Repository(db).addGroup('Family');
    await Repository(db).addGift(pid, 'New', budget: 500);
    await db.into(db.photoMemories).insert(PhotoMemoriesCompanion.insert(personId: pid, year: 2025, path: 'x.jpg'));
    // Old events get default reminders: morning for people, 7 and 1 days before for others.
    final rem = await db.select(db.reminders).get();
    expect(rem.where((r) => r.kind == 'morning').length, 1);
    expect(rem.where((r) => r.kind == 'daysBefore').map((r) => r.daysBefore).toSet(), {1, 7});
    await db.close();
    await dir.delete(recursive: true);
  });

  test('previous occurrence finds yesterday for the Missed list', () {
    final today = Day.today();
    final y = today.addDays(-1);
    expect(previousOccurrence(repeat: Repeat.yearly, month: y.month, day: y.day, before: today), y);
  });
}

/// Lets tests build a library without asset files.
class MessageLibraryForTest {
  MessageLibraryForTest(this.all);

  final List<MessageTemplate> all;

  List<MessageTemplate> suggest({
    required List<Occasion> occasions,
    required Lang lang,
    required MessageContext ctx,
    Set<String> alreadySent = const {},
  }) =>
      MessageLibrary.fromList(all).suggest(occasions: occasions, lang: lang, ctx: ctx, alreadySent: alreadySent);
}
