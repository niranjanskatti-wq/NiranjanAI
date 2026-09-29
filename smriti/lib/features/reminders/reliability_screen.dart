import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../core/theme/tokens.dart';
import '../../widgets/common.dart';
import 'notification_service.dart';

/// Steps per phone brand to stop the system from killing reminders.
const brandGuides = <String, List<String>>{
  'Xiaomi / Redmi / POCO': [
    'Settings › Apps › Manage apps › Smriti › Autostart: turn ON.',
    'Same page › Battery saver: choose "No restrictions".',
    'Same page › Other permissions: allow "Show on lock screen" and "Display pop-up windows while running in the background".',
    'Open Recent apps, press and hold Smriti (or swipe it down) and tap the lock icon.',
  ],
  'Samsung': [
    'Settings › Apps › Smriti › Battery: choose "Unrestricted".',
    'Settings › Battery › Background usage limits › Never sleeping apps: add Smriti.',
    'Settings › Apps › Smriti › Notifications: make sure "Midnight alarm" channels are allowed.',
  ],
  'Vivo / iQOO': [
    'Settings › Battery › Background power consumption management › Smriti: choose "Allow".',
    'Settings › Apps & permissions › Permission management › Autostart: turn Smriti ON.',
    'Open Recent apps, swipe Smriti down to lock it.',
  ],
  'Oppo / Realme': [
    'Settings › Apps › App management › Smriti › Battery usage: turn ON "Allow background activity" and "Allow auto launch".',
    'Settings › Battery › More settings › Optimise battery use › Smriti: "Don\'t optimise".',
    'Open Recent apps, tap the menu on Smriti\'s card and choose "Lock".',
  ],
  'OnePlus': [
    'Settings › Apps › Smriti › Battery usage: turn ON "Allow background activity".',
    'Settings › Battery › Battery optimisation › Smriti: "Don\'t optimise".',
    'Lock Smriti in Recent apps.',
  ],
  'Motorola / Nokia / Pixel': [
    'Settings › Apps › Smriti › App battery usage: choose "Unrestricted".',
  ],
  'Honor / Huawei': [
    'Settings › Battery › App launch › Smriti: switch to "Manage manually" and turn ON Auto-launch, Secondary launch and Run in background.',
    'Lock Smriti in Recent apps.',
  ],
};

String? guideKeyFor(String manufacturer) {
  final m = manufacturer.toLowerCase();
  if (m.contains('xiaomi') || m.contains('redmi') || m.contains('poco')) return 'Xiaomi / Redmi / POCO';
  if (m.contains('samsung')) return 'Samsung';
  if (m.contains('vivo') || m.contains('iqoo')) return 'Vivo / iQOO';
  if (m.contains('oppo') || m.contains('realme')) return 'Oppo / Realme';
  if (m.contains('oneplus')) return 'OnePlus';
  if (m.contains('honor') || m.contains('huawei')) return 'Honor / Huawei';
  if (m.contains('motorola') || m.contains('nokia') || m.contains('google') || m.contains('hmd')) {
    return 'Motorola / Nokia / Pixel';
  }
  return null;
}

class ReliabilityScreen extends StatefulWidget {
  const ReliabilityScreen({super.key});

  @override
  State<ReliabilityScreen> createState() => _ReliabilityScreenState();
}

class _ReliabilityScreenState extends State<ReliabilityScreen> with WidgetsBindingObserver {
  bool? _notif, _exact, _battery;
  String _brand = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _refresh();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState s) {
    if (s == AppLifecycleState.resumed) _refresh();
  }

  Future<void> _refresh() async {
    final notif = await NotificationService.notificationsEnabled();
    final exact = await NotificationService.exactAllowed();
    bool battery;
    try {
      battery = await Permission.ignoreBatteryOptimizations.isGranted;
    } catch (_) {
      battery = true;
    }
    final brand = await NotificationService.manufacturer();
    if (mounted) {
      setState(() {
        _notif = notif;
        _exact = exact;
        _battery = battery;
        _brand = brand;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final key = guideKeyFor(_brand);
    Widget step(String title, String sub, bool? ok, String action, VoidCallback onTap) => Card(
          child: ListTile(
            leading: Icon(
              ok == null ? Icons.help_outline : (ok ? Icons.check_circle : Icons.error_outline),
              color: ok == null ? c.muted : (ok ? c.call : c.alert),
            ),
            title: Text(title),
            subtitle: Text(sub),
            trailing: ok == true ? null : TextButton(onPressed: onTap, child: Text(action)),
          ),
        );
    return Scaffold(
      appBar: AppBar(title: const Text('Make alarms reliable')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 40),
        children: [
          Text(
            'Phones save battery by closing apps in the background, which can silence reminders. '
            'These steps keep Smriti\'s alarms on time, even after a restart.',
            style: context.text.bodyMedium,
          ),
          const SizedBox(height: 16),
          step('Notifications', 'Allow Smriti to show reminders', _notif, 'Allow', () async {
            await NotificationService.requestNotifications();
            _refresh();
          }),
          step('Exact alarms', 'Ring at the exact minute you chose', _exact, 'Allow', () async {
            await NotificationService.requestExact();
            _refresh();
          }),
          step('Midnight alarm on lock screen', 'Allow full-screen alerts (needed on Android 14 and newer)', null, 'Open',
              () async {
            await NotificationService.requestFullScreen();
            _refresh();
          }),
          step('Battery', 'Let Smriti run in the background', _battery, 'Allow', () async {
            await Permission.ignoreBatteryOptimizations.request();
            _refresh();
          }),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: () async {
              await NotificationService.testAlarm();
              if (context.mounted) showToast(context, 'Test alarm in 1 minute. Lock your phone to see it.');
            },
            icon: const Icon(Icons.alarm_on_outlined),
            label: const Text('Test the midnight alarm in 1 minute'),
          ),
          const SizedBox(height: 20),
          SectionLabel(key == null ? 'Your phone brand' : 'Your phone: $key'),
          for (final e in brandGuides.entries)
            Card(
              child: Theme(
                data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                child: ExpansionTile(
                  initiallyExpanded: e.key == key,
                  title: Text(e.key, style: context.text.titleMedium),
                  childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                  children: [
                    for (var i = 0; i < e.value.length; i++)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text('${i + 1}.  ', style: context.text.titleSmall),
                          Expanded(child: Text(e.value[i], style: context.text.bodyMedium)),
                        ]),
                      ),
                    TextButton(onPressed: openAppSettings, child: const Text("Open Smriti's app settings")),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
