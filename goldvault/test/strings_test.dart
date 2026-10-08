import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:goldvault/core/strings_en.dart';
import 'package:goldvault/core/strings_kn.dart';
import 'package:goldvault/data/constants.dart';

void main() {
  // Every literal key used in the UI.
  final used = <String>{};
  for (final f in Directory('lib').listSync(recursive: true).whereType<File>().where((f) => f.path.endsWith('.dart'))) {
    for (final m in RegExp(r"\.t\('([a-zA-Z0-9_.]+)'").allMatches(f.readAsStringSync())) {
      used.add(m.group(1)!);
    }
  }
  // Keys built at runtime.
  final dynamicKeys = {
    for (final s in Opt.statuses) 'status.$s',
    for (final s in ['serial', 'name', 'weight', 'category', 'location', 'date', 'purchase']) 'sort.$s',
    for (final s in ['deposit', 'withdraw', 'both', 'check', 'rent']) 'visit.p.$s',
    for (final s in ['no_passphrase', 'not_signed_in', 'wrong_passphrase', 'bad_file']) 'backup.err.$s',
    for (final k in ['keep', 'take', 'planned_visit', 'custom']) 'rem.kind.$k',
    for (final r in ['none', 'weekly', 'monthly', 'yearly']) 'rem.repeat.$r',
    for (final w in ['sun', 'sat2', 'sat4']) 'hol.$w',
  };

  test('every string used in the app has English text', () {
    expect(used.length, greaterThan(250));
    final missing = {...used, ...dynamicKeys}.where((k) => !en.containsKey(k)).toList()..sort();
    expect(missing, isEmpty);
  });

  test('Kannada covers every English string', () {
    final missing = en.keys.where((k) => !kn.containsKey(k)).toList()..sort();
    expect(missing, isEmpty);
    // Placeholders must match so values are filled in correctly.
    for (final k in en.keys) {
      final ph = RegExp(r'\{(\w+)\}');
      expect(ph.allMatches(kn[k]!).map((m) => m.group(1)).toSet(), ph.allMatches(en[k]!).map((m) => m.group(1)).toSet(),
          reason: k);
    }
  });

  test('Kannada labels for all option lists', () {
    for (final o in [...Opt.banks, ...Opt.lockerSizes, ...Opt.categories, ...Opt.itemTypes]) {
      expect(kn.containsKey('opt.$o'), isTrue, reason: o);
    }
  });
}
