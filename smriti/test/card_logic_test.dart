import 'package:flutter_test/flutter_test.dart';
import 'package:smriti/core/util/occurrence.dart';
import 'package:smriti/features/cards/card_screen.dart';
import 'package:smriti/features/cards/card_templates.dart';
import 'package:smriti/features/wish/wish_service.dart';

void main() {
  test('there are more than 20 designs with unique ids', () {
    expect(cardTemplates.length, greaterThanOrEqualTo(20));
    expect(cardTemplates.map((t) => t.id).toSet().length, cardTemplates.length);
  });

  test('festival cards put that festival first', () {
    for (final (id, first) in [
      ('makar_sankranti', 'kites'),
      ('holi', 'holi'),
      ('raksha_bandhan', 'rakhi'),
      ('christmas', 'christmas'),
      ('kannada_rajyotsava', 'kannada'),
    ]) {
      final list = templatesFor(CardData(kind: CardKind.festival, headline: '', festivalId: id));
      expect(list.first.id, first, reason: id);
      expect(list.length, cardTemplates.length);
    }
    final diwali = templatesFor(const CardData(kind: CardKind.festival, headline: '', festivalId: 'diwali_lakshmi_puja'));
    expect(diwali.take(3).map((t) => t.id), containsAll(['toran', 'diyas', 'fireworks']));
  });

  test('birthday and anniversary cards start with their own designs', () {
    expect(templatesFor(const CardData(kind: CardKind.birthday, headline: '')).take(3).every((t) => t.kinds.contains(CardKind.birthday)),
        isTrue);
    expect(templatesFor(const CardData(kind: CardKind.anniversary, headline: '')).first.kinds, contains(CardKind.anniversary));
  });

  test('festival headline from the festival name', () {
    final d = cardDataFor(WishTarget(
      date: const Day(2026, 11, 8),
      recipients: const [],
      festivalId: 'diwali_lakshmi_puja',
      festivalName: 'Diwali (Lakshmi Puja)',
    ));
    expect(d.kind, CardKind.festival);
    expect(d.headline, 'Happy Diwali');
    final n = cardDataFor(WishTarget(
        date: const Day(2026, 10, 12), recipients: const [], festivalId: 'navratri_begins', festivalName: 'Navratri begins'));
    expect(n.headline, 'Happy Navratri');
  });
}
