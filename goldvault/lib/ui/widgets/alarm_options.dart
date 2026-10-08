import 'package:flutter/material.dart';

import '../../core/strings.dart';
import '../../core/theme.dart';
import '../../data/models.dart';
import '../../services/alarm_scheduler.dart';

/// Editable alarm settings for one reminder.
class AlarmOptions {
  AlarmOptions({List<int>? alerts, this.sound = 'alarm', this.vibrate = true, this.snooze = 10})
      : alerts = {...(alerts ?? const [0])};

  final Set<int> alerts; // minutes before the due time
  String sound;
  bool vibrate;
  int snooze;

  factory AlarmOptions.fromPrefs(Prefs p) =>
      AlarmOptions(alerts: p.defaultAlerts, sound: p.defaultSound, vibrate: p.defaultVibrate, snooze: p.defaultSnooze);

  factory AlarmOptions.fromReminder(Reminder r) =>
      AlarmOptions(alerts: r.alerts, sound: r.soundMode, vibrate: r.vibrate, snooze: r.snooze);

  List<int> get sortedAlerts => (alerts.isEmpty ? <int>[0] : (alerts.toList()..sort()));
}

/// "Alert me: at the time · 1 day before · 1 week before …", sound, vibration
/// and snooze – every option can be changed for each reminder.
class AlarmOptionsEditor extends StatelessWidget {
  const AlarmOptionsEditor({super.key, required this.options, required this.onChanged, this.compact = false});
  final AlarmOptions options;
  final VoidCallback onChanged;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final o = options;
    final s = context.s;
    final chips = {...Reminder.alertPresets, ...o.alerts}.toList()..sort();
    String label(int m) => m == 0 ? context.t('alert.atTime') : context.t('alert.before', {'x': AlarmScheduler.beforeText(s, m)});

    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Text(context.t('alert.alertMe'), style: const TextStyle(color: GV.muted, fontSize: 15)),
      const SizedBox(height: 8),
      Wrap(spacing: 8, runSpacing: 8, children: [
        for (final m in chips)
          FilterChip(
            label: Text(label(m)),
            selected: o.alerts.contains(m),
            onSelected: (v) {
              if (v) {
                o.alerts.add(m);
              } else if (o.alerts.length > 1) {
                o.alerts.remove(m);
              }
              onChanged();
            },
          ),
        ActionChip(
          avatar: const Icon(Icons.add, size: 18, color: GV.gold),
          label: Text(context.t('alert.custom')),
          onPressed: () async {
            final m = await _customBefore(context);
            if (m != null) {
              o.alerts.add(m);
              onChanged();
            }
          },
        ),
      ]),
      const SizedBox(height: 16),
      Text(context.t('alert.sound'), style: const TextStyle(color: GV.muted, fontSize: 15)),
      const SizedBox(height: 8),
      SegmentedButton<String>(
        showSelectedIcon: false,
        segments: [
          ButtonSegment(value: 'alarm', icon: const Icon(Icons.alarm), label: Text(context.t('alert.sound.alarm'))),
          ButtonSegment(value: 'notify', icon: const Icon(Icons.notifications_active_outlined), label: Text(context.t('alert.sound.notify'))),
          ButtonSegment(value: 'silent', icon: const Icon(Icons.notifications_off_outlined), label: Text(context.t('alert.sound.silent'))),
        ],
        selected: {o.sound},
        onSelectionChanged: (v) {
          o.sound = v.first;
          onChanged();
        },
      ),
      if (!compact)
        Padding(
          padding: const EdgeInsets.only(top: 6),
          child: Text(context.t('alert.soundHelp.${o.sound}'), style: const TextStyle(color: GV.muted, fontSize: 13.5)),
        ),
      SwitchListTile(
        contentPadding: EdgeInsets.zero,
        secondary: const Icon(Icons.vibration, color: GV.gold),
        title: Text(context.t('alert.vibrate')),
        value: o.vibrate,
        onChanged: (v) {
          o.vibrate = v;
          onChanged();
        },
      ),
      ListTile(
        contentPadding: EdgeInsets.zero,
        leading: const Icon(Icons.snooze, color: GV.gold),
        title: Text(context.t('alert.snooze')),
        trailing: DropdownButton<int>(
          value: Reminder.snoozeChoices.contains(o.snooze) ? o.snooze : 10,
          dropdownColor: GV.surface2,
          underline: const SizedBox(),
          items: [
            for (final m in Reminder.snoozeChoices)
              DropdownMenuItem(
                value: m,
                child: Text(m == 0 ? context.t('alert.snoozeOff') : context.t('alert.mins', {'n': m}),
                    style: const TextStyle(color: GV.gold, fontSize: 16)),
              ),
          ],
          onChanged: (v) {
            o.snooze = v ?? 10;
            onChanged();
          },
        ),
      ),
    ]);
  }

  static Future<int?> _customBefore(BuildContext context) async {
    final n = TextEditingController(text: '2');
    var unit = 1440;
    return showDialog<int>(
      context: context,
      builder: (c) => StatefulBuilder(
        builder: (c, set) => AlertDialog(
          title: Text(context.t('alert.custom')),
          content: Row(children: [
            SizedBox(
              width: 80,
              child: TextField(
                controller: n,
                keyboardType: TextInputType.number,
                style: const TextStyle(fontSize: 20),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: DropdownButton<int>(
                value: unit,
                isExpanded: true,
                dropdownColor: GV.surface2,
                items: [
                  DropdownMenuItem(value: 1, child: Text(context.t('alert.unit.min'))),
                  DropdownMenuItem(value: 60, child: Text(context.t('alert.unit.hour'))),
                  DropdownMenuItem(value: 1440, child: Text(context.t('alert.unit.day'))),
                  DropdownMenuItem(value: 10080, child: Text(context.t('alert.unit.week'))),
                  DropdownMenuItem(value: 43200, child: Text(context.t('alert.unit.month'))),
                ],
                onChanged: (v) => set(() => unit = v ?? 1440),
              ),
            ),
          ]),
          actions: [
            TextButton(onPressed: () => Navigator.pop(c), child: Text(context.t('common.cancel'))),
            FilledButton(
              onPressed: () {
                final v = int.tryParse(n.text.trim());
                Navigator.pop(c, v == null || v <= 0 ? null : v * unit);
              },
              child: Text(context.t('common.ok')),
            ),
          ],
        ),
      ),
    );
  }
}
