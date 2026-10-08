import 'package:intl/intl.dart';

/// Indian-style formatting helpers (lakh/crore grouping, ₹ currency).
class Fmt {
  Fmt._();

  static final NumberFormat _rupee =
      NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);
  static final NumberFormat _rupee2 =
      NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 2);
  static final NumberFormat _weight = NumberFormat('#,##,##0.###', 'en_IN');
  static final NumberFormat _int = NumberFormat('#,##,##0', 'en_IN');

  static String rupees(num? v, {bool paise = false}) {
    if (v == null) return '—';
    return paise ? _rupee2.format(v) : _rupee.format(v);
  }

  /// Weight in grams, e.g. "1,24,560.25 g".
  static String grams(num? v) => v == null ? '—' : '${_weight.format(v)} g';

  static String number(num? v) => v == null ? '—' : _int.format(v);

  static String decimal(num? v) => v == null ? '' : _weight.format(v);

  static final DateFormat _date = DateFormat('d MMM yyyy');
  static final DateFormat _dateTime = DateFormat('d MMM yyyy, h:mm a');
  static final DateFormat _time = DateFormat('h:mm a');
  static final DateFormat _iso = DateFormat('yyyy-MM-dd');
  static final DateFormat _isoDt = DateFormat("yyyy-MM-dd'T'HH:mm:ss");

  static String date(DateTime? d) => d == null ? '—' : _date.format(d);
  static String dateTime(DateTime? d) => d == null ? '—' : _dateTime.format(d);
  static String time(DateTime? d) => d == null ? '—' : _time.format(d);

  /// Storage formats (local time, sortable strings).
  static String isoDate(DateTime d) => _iso.format(d);
  static String isoDateTime(DateTime d) => _isoDt.format(d);

  static DateTime? parse(String? s) =>
      (s == null || s.isEmpty) ? null : DateTime.tryParse(s);

  /// "HH:mm" -> display "h:mm a".
  static String hhmm(String? s) {
    if (s == null || s.isEmpty) return '—';
    final p = s.split(':');
    if (p.length < 2) return s;
    final d = DateTime(2000, 1, 1, int.tryParse(p[0]) ?? 0, int.tryParse(p[1]) ?? 0);
    return _time.format(d);
  }

  static String serial(int n) => 'GV-${n.toString().padLeft(4, '0')}';

  /// Parse user-typed numbers that may contain Indian separators.
  static double? parseNum(String? s) {
    if (s == null) return null;
    final t = s.replaceAll(',', '').replaceAll('₹', '').trim();
    if (t.isEmpty) return null;
    return double.tryParse(t);
  }

  static DateTime dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);
}
