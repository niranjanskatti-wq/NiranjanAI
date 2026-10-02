import 'package:flutter_test/flutter_test.dart';
import 'package:smriti/core/util/phone.dart';

void main() {
  test('Indian numbers in every common format become +91', () {
    for (final raw in [
      '9845012345',
      '98450 12345',
      '098450 12345',
      '+91 98450 12345',
      '+91-98450-12345',
      '91 9845012345',
      '0091 98450 12345',
      '(+91) 98450-12345',
    ]) {
      expect(normalizePhone(raw), '+919845012345', reason: raw);
    }
  });

  test('landline with STD code', () {
    expect(normalizePhone('080 2345 6789'), '+918023456789');
  });

  test('foreign numbers keep their country code', () {
    expect(normalizePhone('+1 (415) 555-0100'), '+14155550100');
    expect(normalizePhone('0044 20 7946 0000'), '+442079460000');
  });

  test('empty or junk input', () {
    expect(normalizePhone(null), isNull);
    expect(normalizePhone('  '), isNull);
    expect(normalizePhone('abc'), isNull);
  });

  test('samePhone compares normalised numbers', () {
    expect(samePhone('98450 12345', '+919845012345'), isTrue);
    expect(samePhone('98450 12345', '98450 12346'), isFalse);
    expect(samePhone(null, null), isFalse);
  });

  test('display format', () {
    expect(formatPhone('+919845012345'), '+91 98450 12345');
    expect(formatPhone('+14155550100'), '+14155550100');
  });
}
