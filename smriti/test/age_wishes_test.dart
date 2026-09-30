import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smriti/core/util/occurrence.dart';
import 'package:smriti/data/database.dart';
import 'package:smriti/data/enums.dart';
import 'package:smriti/data/models.dart';
import 'package:smriti/data/repository.dart';
import 'package:smriti/features/events/age_input.dart';
import 'package:smriti/features/messages/message_engine.dart';

void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;

  const bday = MessageContext(name: 'Ramesh', nickname: 'Appa', age: 60, type: EventType.birthday);
  const anniv = MessageContext(yearsMarried: 25, type: EventType.weddingAnniversary);
  const work = MessageContext(yearsMarried: 5, type: EventType.workAnniversary);

  test('warm age lines in each language', () {
    expect(bday.ageLine(Lang.en), 'Happy 60th birthday, Appa! 🎂');
    expect(bday.ageLine(Lang.hi), 'Appa, आपको 60वें जन्मदिन की हार्दिक शुभकामनाएँ! 🎂');
    expect(bday.ageLine(Lang.kn), 'Appa, 60ನೇ ಹುಟ್ಟುಹಬ್ಬದ ಹಾರ್ದಿಕ ಶುಭಾಶಯಗಳು! 🎂');
    expect(anniv.ageLine(Lang.en), 'Happy 25th anniversary! 25 beautiful years together 💞');
    expect(work.ageLine(Lang.en), 'Congratulations on 5 years! 🎉');
    expect(const MessageContext(name: 'X', type: EventType.birthday).ageLine(Lang.en), isNull);
  });

  test('the line goes at the start or end, never twice, and can be taken out', () {
    const msg = 'Wishing you health and happiness always.';
    final start = bday.withAge(msg, Lang.en, AgeInWishes.start);
    expect(start, 'Happy 60th birthday, Appa! 🎂\n\n$msg');
    expect(bday.withAge(msg, Lang.en, AgeInWishes.end), '$msg\n\nHappy 60th birthday, Appa! 🎂');
    expect(bday.withAge(msg, Lang.en, AgeInWishes.off), msg);
    expect(bday.withAge(start, Lang.en, AgeInWishes.start), start, reason: 'already says 60');
    expect(bday.withAge('Happy 60th, Appa!', Lang.en, AgeInWishes.start), 'Happy 60th, Appa!');
    expect(bday.withoutAge(start, Lang.en), msg);
    expect(bday.withAge('Wishing you 160 blessings', Lang.en, AgeInWishes.start), startsWith('Happy 60th'),
        reason: '160 is not 60');
  });

  test('entering the age saves the birth year', () async {
    final db = AppDatabase(NativeDatabase.memory());
    final repo = Repository(db);
    final p = await repo.insertPerson(PeopleCompanion.insert(name: 'Shanta'));
    final id = await repo.saveEvent(
        data: EventsCompanion.insert(kind: 'person', type: 'birthday', day: 19, month: 11), personIds: [p]);
    final entry = (await repo.watchEntry(id).first)!;
    await saveYears(repo, entry, 60, const Day(2026, 11, 19));
    expect((await repo.getPerson(p))!.birthYear, 1966);
    final after = (await repo.watchEntry(id).first)!;
    expect(Upcoming(after, const Day(2026, 11, 19), 0).years, 60);
    await db.close();
  });
}
