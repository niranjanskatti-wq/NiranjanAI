import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:smriti/data/enums.dart';
import 'package:smriti/features/messages/message_engine.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MessageLibrary lib;
  setUpAll(() async => lib = await MessageLibrary.load());

  test('library has 600+ messages across English, Hindi and Kannada', () {
    expect(lib.all.length, greaterThanOrEqualTo(600));
    for (final l in Lang.values) {
      expect(lib.all.where((t) => t.lang == l).length, greaterThan(100), reason: l.name);
    }
  });

  test('ids are unique and placeholders are known', () {
    final ids = <String>{};
    const known = {
      'name', 'nickname', 'relation', 'age', 'age_th', 'years_married', 'years_th', 'couple_names', 'festival', 'my_name'
    };
    for (final t in lib.all) {
      expect(ids.add(t.id), isTrue, reason: 'duplicate ${t.id}');
      expect(known.containsAll(t.placeholders), isTrue, reason: t.text);
    }
  });

  test('at least 15 birthday messages for every relationship family', () {
    for (final r in Relationship.choices.where((r) => r != Relationship.custom)) {
      final n = lib.all.where((t) => t.occasion == Occasion.birthday && t.fit(r) >= 2).length;
      expect(n, greaterThanOrEqualTo(15), reason: r.name);
    }
  });

  test('at least 10 messages for every festival switched on by default', () {
    final fest = jsonDecode(File('assets/festivals/festivals.json').readAsStringSync()) as Map<String, dynamic>;
    for (final f in (fest['festivals'] as List).where((f) => f['enabled'] == true)) {
      final n = lib.all.where((t) => t.festival == f['id']).length;
      expect(n, greaterThanOrEqualTo(10), reason: f['id'] as String);
    }
  });

  test('every relationship gets a filled suggestion for every occasion in every language', () {
    for (final lang in Lang.values) {
      for (final r in Relationship.choices) {
        final ctx = MessageContext(
          name: 'Ravi',
          nickname: 'Ravi',
          relation: r,
          age: 60,
          yearsMarried: 25,
          coupleNames: 'Ravi & Priya',
          festival: 'Diwali',
          myName: 'Niranjan',
        );
        for (final occ in [
          [Occasion.birthday],
          [Occasion.milestoneBirthday, Occasion.birthday],
          [Occasion.coupleAnniversary, Occasion.general],
          [Occasion.belated, Occasion.general],
          [Occasion.festival],
          [Occasion.thankYou],
        ]) {
          final s = lib.suggest(occasions: occ, lang: lang, ctx: ctx, festivalId: 'diwali_lakshmi_puja');
          expect(s, isNotEmpty, reason: '${lang.name} ${r.name} ${occ.first.name}');
          expect(ctx.fill(s.first.text).contains('{'), isFalse);
        }
      }
    }
  });

  test('festival suggestions prefer that festival over generic ones', () {
    const ctx = MessageContext(nickname: 'Ravi', relation: Relationship.sister, festival: 'Raksha Bandhan');
    final s = lib.suggest(occasions: [Occasion.festival], lang: Lang.en, ctx: ctx, festivalId: 'raksha_bandhan');
    expect(s.first.festival, 'raksha_bandhan');
  });
}
