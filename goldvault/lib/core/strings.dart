import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import 'strings_en.dart';
import 'strings_kn.dart';

/// English + Kannada strings. Keys missing in Kannada fall back to English.
class S {
  S(this.lang);
  final String lang;

  static const supported = [Locale('en', 'IN'), Locale('kn', 'IN')];

  static S of(BuildContext context) => Localizations.of<S>(context, S) ?? S('en');

  Map<String, String> get _map => lang == 'kn' ? kn : en;

  String t(String key, [Map<String, Object?> args = const {}]) {
    var s = _map[key] ?? en[key];
    if (s == null) {
      assert(() {
        debugPrint('Missing string: $key');
        return true;
      }());
      s = key;
    }
    args.forEach((k, v) => s = s!.replaceAll('{$k}', '$v'));
    return s!;
  }

  /// Labels for stored option codes (banks, categories, statuses, …).
  /// Falls back to the code itself (e.g. for user-typed values).
  String opt(String? code) {
    if (code == null || code.isEmpty) return '';
    return _map['opt.$code'] ?? en['opt.$code'] ?? code;
  }

  String status(String code) => t('status.$code');
}

class SDelegate extends LocalizationsDelegate<S> {
  const SDelegate();
  @override
  bool isSupported(Locale locale) => ['en', 'kn'].contains(locale.languageCode);
  @override
  Future<S> load(Locale locale) => SynchronousFuture(S(locale.languageCode));
  @override
  bool shouldReload(SDelegate old) => false;
}

extension Tr on BuildContext {
  S get s => S.of(this);
  String t(String key, [Map<String, Object?> args = const {}]) => S.of(this).t(key, args);
}
