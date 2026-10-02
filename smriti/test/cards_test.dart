// Renders every greeting card design into one sheet for review.
// Run: flutter test test/cards_test.dart --update-goldens --tags screenshots
@Tags(['screenshots'])
library;

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smriti/features/cards/card_templates.dart';

Future<void> _loadFont(String family, List<String> files) async {
  final loader = FontLoader(family);
  for (final f in files) {
    loader.addFont(File(f).readAsBytes().then((b) => ByteData.view(b.buffer)));
  }
  await loader.load();
}

void main() {
  setUpAll(() async {
    const f = 'assets/fonts';
    await _loadFont('Manrope', ['$f/Manrope-500.ttf', '$f/Manrope-600.ttf']);
    await _loadFont('Cormorant', ['$f/CormorantGaramond-500Italic.ttf', '$f/CormorantGaramond-700.ttf']);
    await _loadFont('NotoDevanagari', ['$f/NotoSansDevanagari-400.ttf']);
    await _loadFont('NotoKannada', ['$f/NotoSansKannada-400.ttf']);
  });

  testWidgets('all card designs', (tester) async {
    const perRow = 6;
    const w = 300.0, h = 375.0;
    final rows = (cardTemplates.length / perRow).ceil();
    tester.view.physicalSize = const Size(perRow * w, 0) + Offset(0, rows * h);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    CardData dataFor(CardTemplate t) {
      final fest = t.festivals.isNotEmpty && t.kinds.contains(CardKind.festival);
      final kind = t.kinds.contains(CardKind.birthday) ? CardKind.birthday : t.kinds.first;
      return CardData(
        kind: fest ? CardKind.festival : kind,
        headline: fest ? 'Happy Diwali' : (kind == CardKind.anniversary ? 'Happy 25th Anniversary' : 'Happy Birthday'),
        name: kind == CardKind.anniversary ? 'Ravi & Priya' : 'Appa',
        message: 'Wishing you a year full of health, laughter and everything that makes you smile. '
            'Thank you for always being there for all of us.',
        footer: '— Niranjan',
        years: 60,
      );
    }

    await tester.pumpWidget(MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Material(
        child: Wrap(children: [
          for (final t in cardTemplates)
            SizedBox(width: w, height: h, child: GreetingCard(template: t, data: dataFor(t))),
        ]),
      ),
    ));
    await expectLater(find.byType(Wrap), matchesGoldenFile('../docs/screens/cards.png'));
  });

  testWidgets('Hindi and Kannada text', (tester) async {
    tester.view.physicalSize = const Size(600, 375);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(MaterialApp(
      home: Material(
        child: Row(children: [
          SizedBox(
              width: 300,
              child: GreetingCard(
                  template: templateById('rangoli'),
                  data: const CardData(kind: CardKind.festival, headline: 'दीपावली की शुभकामनाएँ', name: 'अम्मा',
                      message: 'आपके जीवन में सुख, समृद्धि और खुशियाँ सदा बनी रहें।'))),
          SizedBox(
              width: 300,
              child: GreetingCard(
                  template: templateById('lotus'),
                  data: const CardData(kind: CardKind.festival, headline: 'ಗಣೇಶ ಚತುರ್ಥಿಯ ಶುಭಾಶಯಗಳು', name: 'ಅಪ್ಪ',
                      message: 'ವಿಘ್ನ ನಿವಾರಕನು ನಿಮ್ಮ ಬಾಳನ್ನು ಬೆಳಗಲಿ.'))),
        ]),
      ),
    ));
    await expectLater(find.byType(Row), matchesGoldenFile('../docs/screens/cards_languages.png'));
  });
}
