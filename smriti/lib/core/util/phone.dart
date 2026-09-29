/// Normalises a phone number to international form, assuming India (+91)
/// when no country code is given.
///
/// "98450 12345", "098450 12345", "+91 98450 12345", "91-9845012345" and
/// "0091 9845012345" all become "+919845012345". Numbers with another country
/// code keep it. Returns null when there are no digits at all.
String? normalizePhone(String? raw, {String defaultCountryCode = '91'}) {
  if (raw == null) return null;
  final trimmed = raw.trim();
  final hasPlus = trimmed.startsWith('+');
  var digits = trimmed.replaceAll(RegExp(r'\D'), '');
  if (digits.isEmpty) return null;

  if (hasPlus) return '+$digits';
  if (digits.startsWith('00')) return '+${digits.substring(2)}';

  // Indian mobile or landline written without country code.
  if (digits.length == 10) return '+$defaultCountryCode$digits';
  if (digits.length == 11 && digits.startsWith('0')) {
    return '+$defaultCountryCode${digits.substring(1)}';
  }
  if (digits.length == 12 && digits.startsWith(defaultCountryCode)) return '+$digits';

  // Short codes or unusual formats: keep the digits as they are.
  return digits;
}

/// True when two numbers refer to the same phone after normalising.
bool samePhone(String? a, String? b) {
  final na = normalizePhone(a), nb = normalizePhone(b);
  return na != null && na == nb;
}

/// "+919845012345" → "+91 98450 12345" for display.
String formatPhone(String? normalized) {
  if (normalized == null || normalized.isEmpty) return '';
  if (normalized.startsWith('+91') && normalized.length == 13) {
    final n = normalized.substring(3);
    return '+91 ${n.substring(0, 5)} ${n.substring(5)}';
  }
  return normalized;
}
