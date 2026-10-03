import 'dart:convert';

// Settings are a JSON document (same shape as Deepwork's backup format). Stored values are
// merged over [defaultSettings] so keys added in later versions always get a default.

class ModuleInfo {
  const ModuleInfo(this.key, this.label, this.description, {this.locked = false});
  final String key;
  final String label;
  final String description;
  final bool locked;
}

const modules = <ModuleInfo>[
  ModuleInfo('priorities', 'Top priorities', 'The few things that matter most today.'),
  ModuleInfo('timeBlocks', 'Hourly time blocks', 'Plan your day on an hourly timeline.'),
  ModuleInfo('tasks', 'Task list', 'Projects, estimates, due dates and status.'),
  ModuleInfo('subtasks', 'Subtasks', 'A checklist inside each task.'),
  ModuleInfo('focus', 'Focus timer', 'The core of the app. Always on.', locked: true),
  ModuleInfo('distractions', 'Distraction logging', 'Log what pulls you away without stopping the timer.'),
  ModuleInfo('sessionClose', 'Session close', 'Record the result and a note after each session.'),
  ModuleInfo('breaks', 'Break reminders', 'Suggested breaks and a break timer.'),
  ModuleInfo('appBlocking', 'App blocking', 'Pause distracting apps during focus sessions.'),
  ModuleInfo('ambient', 'Ambient sounds', 'Rain, café, white and brown noise.'),
  ModuleInfo('streaks', 'Streaks', 'Consecutive days that meet your rule.'),
  ModuleInfo('eveningReview', 'Evening review', 'A two-minute look back at the day.'),
  ModuleInfo('weeklyReview', 'Weekly review', 'A ten-minute look back at the week.'),
  ModuleInfo('insights', 'Insights & charts', 'Charts of focus, distractions and completion.'),
  ModuleInfo('insightCards', 'Insight cards', 'Plain-language observations from your data.'),
  ModuleInfo('summary', 'Daily summary strip', 'Focus time, tasks done and goal progress.'),
  ModuleInfo('backup', 'Google Drive backup', 'Weekly automatic backup to your own Drive.'),
  ModuleInfo('notifications', 'Notifications', 'Reminders and timer alerts.'),
];

/// Today's sections that can be reordered and hidden. Value = module that must be on (or null).
const homeSections = <String, (String, String?)>{
  'startFocus': ('Start focus button', null),
  'summary': ('Daily summary strip', 'summary'),
  'streak': ('Streak', 'streaks'),
  'eveningReview': ('Evening review card', 'eveningReview'),
  'weeklyReview': ('Weekly review card', 'weeklyReview'),
  'priorities': ('Top priorities', 'priorities'),
  'timeline': ('Time blocks', 'timeBlocks'),
  'backup': ('Backup status', 'backup'),
};

const chartOptions = <String, (String, String?)>{
  'focusHours': ('Focus hours', null),
  'distractionReasons': ('Distractions by reason', 'distractions'),
  'completionRate': ('Completion rate', null),
  'heatmap': ('Best hours heatmap', null),
  'byProject': ('Sessions by project', 'tasks'),
};

const insightCardOptions = <String, (String, String?)>{
  'interruptionTime': ('When interruptions happen', 'distractions'),
  'bestLength': ('Best session length', null),
  'priorityCompletion': ('Priority completion', 'priorities'),
  'topDistraction': ('Top distraction', 'distractions'),
  'bestDay': ('Best day of the week', null),
  'trend': ('Focus trend', null),
  'bestTime': ('Best focus time', null),
  'stuckProject': ('Where you get stuck', 'tasks'),
};

const ambientSounds = <String, String>{'rain': 'Rain', 'cafe': 'Café', 'white': 'White noise', 'brown': 'Brown noise'};

const taskFields = <String, String>{
  'project': 'Project tag',
  'estimate': 'Estimated sessions',
  'sessions': 'Sessions spent vs. estimate',
  'dueDate': 'Due date',
  'flag': 'Priority flag',
  'status': 'Status',
  'subtasks': 'Subtask progress',
};

const accentPresets = ['#7C7CFF', '#5B8DEF', '#22C3A6', '#4ADE80', '#F59E0B', '#F472B6', '#EF6F6C', '#A78BFA'];

final Map<String, dynamic> defaultSettings = {
  'version': 1,
  'modules': {
    'priorities': true,
    'timeBlocks': true,
    'tasks': true,
    'subtasks': true,
    'focus': true,
    'distractions': true,
    'sessionClose': true,
    'breaks': true,
    'appBlocking': true,
    'ambient': true,
    'streaks': true,
    'eveningReview': true,
    'weeklyReview': true,
    'insights': true,
    'insightCards': true,
    'summary': true,
    'backup': false,
    'notifications': true,
  },
  'priorities': {'count': 3, 'label': 'Top priorities'},
  'timeBlocks': {'dayStart': '08:00', 'dayEnd': '18:00', 'blockLength': 60, 'showWeekends': true},
  'tasks': {
    'visibleFields': ['project', 'estimate', 'sessions', 'dueDate', 'flag', 'status', 'subtasks'],
  },
  'focus': {
    'presets': [15, 25, 45, 60, 90],
    'defaultDuration': 25,
    'allowCustom': true,
    'mode': 'countdown',
    'hideSeconds': false,
    'requireTask': true,
    'wakeLock': true,
  },
  'ring': {'style': 'bold', 'glow': true, 'completionAnimation': true},
  'distractions': {'noteEnabled': true},
  'sessionClose': {
    'results': {'done': true, 'partly': true, 'stuck': true},
    'note': 'optional',
    'stuckPrompt': true,
  },
  'breaks': {'short': 5, 'long': 15, 'longAfter': 4, 'autoStartNext': false},
  'ambient': {
    'available': ['rain', 'cafe', 'white', 'brown'],
    'volume': 0.5,
    'defaultOn': false,
    'defaultSound': 'rain',
  },
  'blocking': {'mode': 'block', 'packages': <String>[], 'labels': <String, dynamic>{}, 'logAttempts': true},
  'streaks': {'rule': 'neverMissTwice', 'countsAs': 'session', 'amount': 1},
  'eveningReview': {
    'questions': ['One thing to do differently tomorrow?'],
    'time': '20:00',
  },
  'weeklyReview': {
    'day': 0, // 0 = Sunday … 6 = Saturday
    'time': '17:00',
    'questions': ['What went well?', 'What should I cut?', 'Top 3 priorities for next week?'],
  },
  'insights': {
    'charts': ['focusHours', 'distractionReasons', 'completionRate', 'heatmap', 'byProject'],
    'cards': ['interruptionTime', 'bestLength', 'priorityCompletion', 'topDistraction', 'bestDay', 'trend', 'bestTime', 'stuckProject'],
    'defaultRange': 14,
  },
  'dailyGoal': {'type': 'minutes', 'target': 120},
  'notifications': {
    'morning': {'enabled': true, 'time': '08:30'},
    'evening': {'enabled': true},
    'weekly': {'enabled': true},
    'breakOver': true,
    'sessionComplete': true,
    'quietHours': {'enabled': false, 'start': '22:00', 'end': '07:00'},
  },
  'appearance': {
    'theme': 'dark',
    'accent': '#7C7CFF',
    'font': 'inter',
    'textSize': 'medium',
    'density': 'comfortable',
    'animations': 'full',
    'homeLayout': [
      {'id': 'startFocus', 'visible': true},
      {'id': 'summary', 'visible': true},
      {'id': 'streak', 'visible': true},
      {'id': 'eveningReview', 'visible': true},
      {'id': 'weeklyReview', 'visible': true},
      {'id': 'priorities', 'visible': true},
      {'id': 'timeline', 'visible': true},
      {'id': 'backup', 'visible': true},
    ],
  },
  'lock': {
    'enabled': false,
    'pinHash': null,
    'pinSalt': null,
    'pinLength': 4,
    'biometric': false,
    'autoLockMinutes': 5, // 0 = as soon as the app is left
  },
  'backup': {
    'day': 0,
    'retention': 8,
    'connected': false,
    'account': null,
    'lastBackupAt': null,
    'lastAttemptAt': null,
    'lastError': null,
    'needsReconnect': false,
  },
  'demoLoaded': false,
};

/// Sections that have their own "Reset to defaults".
const resettableSections = [
  'priorities', 'timeBlocks', 'tasks', 'focus', 'ring', 'distractions', 'sessionClose', 'breaks', 'ambient', //
  'blocking', 'streaks', 'eveningReview', 'weeklyReview', 'insights', 'dailyGoal', 'notifications', 'appearance',
];

dynamic deepCopy(dynamic v) => v == null ? null : jsonDecode(jsonEncode(v));

dynamic _merge(dynamic d, dynamic s) {
  if (s == null) return deepCopy(d);
  if (d is Map) {
    if (s is! Map) return deepCopy(d);
    // Free-form maps (empty by default) are taken as stored.
    if (d.isEmpty) return Map<String, dynamic>.from(s);
    return {for (final k in d.keys) k as String: _merge(d[k], s[k])};
  }
  if (d is List) return s is List ? List<dynamic>.from(s) : deepCopy(d);
  if (d is num && s is num) return d is int && s is double && s == s.roundToDouble() ? s.toInt() : s;
  if (d != null && d.runtimeType != s.runtimeType && !(d is num && s is num)) return d;
  return s;
}

class AppSettings {
  AppSettings._(this.json);

  factory AppSettings.fromJson(Object? stored) {
    final merged = Map<String, dynamic>.from(_merge(defaultSettings, stored) as Map);
    // Home layout must contain every section exactly once.
    final layout = <Map<String, dynamic>>[];
    final seen = <String>{};
    for (final e in (merged['appearance']['homeLayout'] as List)) {
      final id = (e as Map)['id'];
      if (homeSections.containsKey(id) && seen.add(id as String)) layout.add({'id': id, 'visible': e['visible'] != false});
    }
    for (final e in defaultSettings['appearance']['homeLayout'] as List) {
      if (!seen.contains(e['id'])) layout.add(Map<String, dynamic>.from(e as Map));
    }
    merged['appearance']['homeLayout'] = layout;
    merged['modules']['focus'] = true;
    return AppSettings._(merged);
  }

  factory AppSettings.defaults() => AppSettings.fromJson(null);

  final Map<String, dynamic> json;

  dynamic operator [](String path) {
    dynamic cur = json;
    for (final p in path.split('.')) {
      if (cur is! Map) return null;
      cur = cur[p];
    }
    return cur;
  }

  /// Returns a copy with [path] set to [value].
  AppSettings set(String path, dynamic value) => edit((m) {
        final parts = path.split('.');
        Map cur = m;
        for (final p in parts.take(parts.length - 1)) {
          cur = cur[p] as Map;
        }
        cur[parts.last] = value;
      });

  /// Returns a copy after applying [fn] to a mutable deep copy of the JSON.
  AppSettings edit(void Function(Map<String, dynamic> m) fn) {
    final copy = Map<String, dynamic>.from(deepCopy(json) as Map);
    fn(copy);
    return AppSettings.fromJson(copy);
  }

  AppSettings resetSection(String section) => edit((m) {
        m[section] = deepCopy(defaultSettings[section]);
      });

  AppSettings resetModules() => edit((m) {
        final backupOn = m['modules']['backup'];
        m['modules'] = deepCopy(defaultSettings['modules']);
        m['modules']['backup'] = backupOn;
      });

  String encode() => jsonEncode(json);

  // ------------------------------------------------------------- typed helpers
  bool on(String module) => json['modules'][module] == true;
  int i(String path) => (this[path] as num).toInt();
  double d(String path) => (this[path] as num).toDouble();
  String s(String path) => this[path] as String;
  bool b(String path) => this[path] == true;
  List<String> strings(String path) => (this[path] as List).map((e) => e.toString()).toList();
  List<int> ints(String path) => (this[path] as List).map((e) => (e as num).toInt()).toList();

  int get priorityCount => i('priorities.count');
  String get priorityLabel => s('priorities.label');
  List<int> get presets => ints('focus.presets');
  List<Map<String, dynamic>> get homeLayout =>
      (json['appearance']['homeLayout'] as List).map((e) => Map<String, dynamic>.from(e as Map)).toList();
}
