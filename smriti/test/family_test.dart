import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smriti/core/util/occurrence.dart';
import 'package:smriti/data/database.dart';
import 'package:smriti/data/enums.dart';
import 'package:smriti/data/models.dart';
import 'package:smriti/data/repository.dart';
import 'package:smriti/features/family/family.dart';

void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;

  test('family links are saved both ways with the right word each way', () async {
    final db = AppDatabase(NativeDatabase.memory());
    final r = Repository(db);
    final fam = FamilyRepo(db);
    final meId = await r.insertPerson(PeopleCompanion.insert(name: 'Niranjan', isMe: const Value(true), relationship: const Value('self')));
    final dadId = await r.insertPerson(PeopleCompanion.insert(name: 'Dad'));
    final momId = await r.insertPerson(PeopleCompanion.insert(name: 'Mom'));
    final riaId = await r.insertPerson(PeopleCompanion.insert(name: 'Ria'));
    Future<Person> p(int id) async => (await r.allPeople()).firstWhere((x) => x.id == id);

    await fam.link(await p(meId), await p(dadId), FamilyRel.father);
    await fam.link(await p(meId), await p(momId), FamilyRel.mother);
    await fam.link(await p(dadId), await p(momId), FamilyRel.wife);
    await fam.link(await p(dadId), await p(riaId), FamilyRel.daughter);

    // Dad and Mom are no longer "Friend".
    expect(Relationship.parse((await p(dadId)).relationship), Relationship.father);
    expect(Relationship.parse((await p(momId)).relationship), Relationship.mother);

    String rels(List<Relative> l) => (l.map((x) => '${x.person.name}:${x.rel.name}').toList()..sort()).join(', ');
    // Dad is male (someone's father) so he is Mom's husband; I'm Dad's child (my gender is not known).
    expect(rels(await fam.relatives(momId)), contains('Dad:husband'));
    expect(rels(await fam.relatives(dadId)), 'Mom:wife, Niranjan:child, Ria:daughter');
    // Ria shares my father, so she shows as my sister without adding her separately.
    expect(rels(await fam.relatives(meId)), 'Dad:father, Mom:mother, Ria:sister');

    // Removing a link removes both directions; deleting a person removes their links.
    await fam.unlink(dadId, riaId);
    expect(rels(await fam.relatives(riaId)), '');
    await r.deletePerson(momId);
    expect(rels(await fam.relatives(dadId)), 'Niranjan:child');
    await db.close();
  });

  test('reciprocal words', () {
    expect(FamilyRel.father.reciprocal(Gender.female), FamilyRel.daughter);
    expect(FamilyRel.wife.reciprocal(Gender.male), FamilyRel.husband);
    expect(FamilyRel.grandmother.reciprocal(Gender.unknown), FamilyRel.grandchild);
    expect(FamilyRel.motherInLaw.reciprocal(Gender.male), FamilyRel.sonInLaw);
    expect(FamilyRel.uncle.reciprocal(Gender.female), FamilyRel.niece);
    expect(FamilyRel.cousin.reciprocal(Gender.male), FamilyRel.cousin);
  });

  test('phone "no year" dates (1604) never show as an age', () async {
    expect(realYear(1604), isNull);
    expect(realYear(0), isNull);
    expect(realYear(1966), 1966);
    expect(yearsOn(const Day(2026, 3, 9), 1604), isNull);

    final db = AppDatabase(NativeDatabase.memory());
    final r = Repository(db);
    final dad = await r.insertPerson(PeopleCompanion.insert(name: 'Dad', birthYear: const Value(1604)));
    await r.saveEvent(data: EventsCompanion.insert(kind: 'person', type: 'birthday', day: 9, month: 3), personIds: [dad]);
    final g = await r.insertPerson(PeopleCompanion.insert(name: 'Gajanan'));
    await r.saveEvent(
        data: EventsCompanion.insert(kind: 'person', type: 'weddingAnniversary', day: 1, month: 12, year: const Value(1604)),
        personIds: [g]);
    final up = computeUpcoming(await r.watchEntries().first, const Day(2026, 9, 30));
    expect(up.map((u) => u.ageText), everyElement(isNull));
    await db.close();
  });
}
