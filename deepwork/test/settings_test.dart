import 'package:deepwork/core/settings.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('stored values merge over defaults; new keys get defaults', () {
    final s = AppSettings.fromJson({
      'modules': {'tasks': false},
      'priorities': {'count': 5},
      'unknown': 1,
    });
    expect(s.on('tasks'), isFalse);
    expect(s.on('insights'), isTrue);
    expect(s.priorityCount, 5);
    expect(s.priorityLabel, 'Top priorities');
    expect(s.json.containsKey('unknown'), isFalse);
  });

  test('focus module can never be turned off', () {
    expect(AppSettings.fromJson({'modules': {'focus': false}}).on('focus'), isTrue);
  });

  test('home layout always lists every section once', () {
    final s = AppSettings.fromJson({
      'appearance': {
        'homeLayout': [
          {'id': 'timeline', 'visible': false},
          {'id': 'timeline', 'visible': true},
          {'id': 'bogus', 'visible': true},
        ],
      },
    });
    final ids = s.homeLayout.map((e) => e['id']).toList();
    expect(ids.first, 'timeline');
    expect(s.homeLayout.first['visible'], isFalse);
    expect(ids.toSet().length, homeSections.length);
    expect(ids.length, homeSections.length);
  });

  test('wrong types fall back to defaults', () {
    final s = AppSettings.fromJson({'focus': {'defaultDuration': 'abc', 'presets': 'x'}});
    expect(s.i('focus.defaultDuration'), 25);
    expect(s.presets, [15, 25, 45, 60, 90]);
  });

  test('free-form maps (blocked app labels) survive a round trip', () {
    final s = AppSettings.defaults().edit((m) => m['blocking']['labels'] = {'com.x': 'X'});
    final again = AppSettings.fromJson(s.json);
    expect(again['blocking.labels'], {'com.x': 'X'});
  });

  test('set, edit and reset per section', () {
    var s = AppSettings.defaults().set('breaks.short', 7).set('modules.backup', true);
    expect(s.i('breaks.short'), 7);
    s = s.resetSection('breaks');
    expect(s.i('breaks.short'), 5);
    s = s.set('modules.tasks', false).resetModules();
    expect(s.on('tasks'), isTrue);
    expect(s.on('backup'), isTrue, reason: 'backup stays as connected');
  });
}
