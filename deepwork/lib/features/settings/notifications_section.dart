import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/tokens.dart';
import '../../core/util/format.dart';
import '../../data/providers.dart';
import '../../services/notifications.dart';
import '../../ui/widgets.dart';
import 'controls.dart';

class NotificationsSection extends ConsumerStatefulWidget {
  const NotificationsSection({super.key});
  @override
  ConsumerState<NotificationsSection> createState() => _NotificationsSectionState();
}

class _NotificationsSectionState extends ConsumerState<NotificationsSection> with WidgetsBindingObserver {
  bool? granted;
  bool? exact;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _check();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _check();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  Future<void> _check() async {
    final g = await Notifications.permissionGranted();
    final e = await Notifications.exactAllowed();
    if (mounted) {
      setState(() {
        granted = g;
        exact = e;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(settingsProvider);
    final p = context.pal;
    final ctl = settingsCtl(ref);
    final master = s.on('notifications');
    String? need(String m, String label) => s.on(m) ? null : 'Requires $label.';

    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      SettingsSection(title: 'Permission', children: [
        SettingsRow(
          label: granted == null ? 'Checking…' : granted! ? 'Notifications allowed' : 'Not allowed yet',
          description: granted == true ? 'Reminders and timer alerts fire even when Deepwork is closed.' : 'Allow notifications so reminders and timer alerts can reach you.',
          trailing: granted == false
              ? Btn('Allow', kind: BtnKind.primary, small: true, onPressed: () async {
                  await Notifications.requestPermission();
                  await _check();
                })
              : granted == true
                  ? Btn('Test', small: true, onPressed: () async {
                      final ok = await Notifications.show(s, NotifyKind.sessionComplete, 'Deepwork', 'Notifications are working.', force: true);
                      if (!ok && context.mounted) toast(context, 'Could not show a notification.', error: true);
                    })
                  : null,
        ),
        SettingsRow(
          label: 'Exact timer alerts',
          description: exact == true ? 'Session and break alerts fire right on time.' : 'Without this, Android may delay timer alerts by a few minutes.',
          trailing: exact == false ? Btn('Allow', small: true, onPressed: () async {
            await Notifications.requestExact();
            await _check();
          }) : Icon(Icons.check_circle_rounded, color: p.success, size: 20),
        ),
      ]),
      SettingsSection(
        title: 'Reminders',
        action: ResetButton(label: 'Notifications', onReset: () => ctl.replace(ctl.current.resetSection('notifications'))),
        children: [
          SwitchRow(label: 'All notifications', description: 'Master switch.', value: master, onChanged: (v) => ctl.set('modules.notifications', v)),
          Opacity(
            opacity: master ? 1 : 0.45,
            child: IgnorePointer(
              ignoring: !master,
              child: Column(children: [
                SettingsRow(
                  label: 'Morning planning',
                  description: need('priorities', 'Top priorities') ?? 'A nudge to pick today’s priorities.',
                  trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                    TimeButton(value: s.s('notifications.morning.time'), onChanged: (v) => ctl.set('notifications.morning.time', v)),
                    Switch(value: s.b('notifications.morning.enabled'), onChanged: (v) => ctl.set('notifications.morning.enabled', v)),
                  ]),
                ),
                Divider(color: p.border.withValues(alpha: 0.7)),
                SettingsRow(
                  label: 'Evening review',
                  description: need('eveningReview', 'Evening review') ?? 'Uses the evening review time.',
                  trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                    TimeButton(value: s.s('eveningReview.time'), onChanged: (v) => ctl.set('eveningReview.time', v)),
                    Switch(value: s.b('notifications.evening.enabled'), onChanged: (v) => ctl.set('notifications.evening.enabled', v)),
                  ]),
                ),
                Divider(color: p.border.withValues(alpha: 0.7)),
                SettingsRow(
                  label: 'Weekly review',
                  description: need('weeklyReview', 'Weekly review') ?? '${dayNames[s.i('weeklyReview.day')]}s',
                  trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                    TimeButton(value: s.s('weeklyReview.time'), onChanged: (v) => ctl.set('weeklyReview.time', v)),
                    Switch(value: s.b('notifications.weekly.enabled'), onChanged: (v) => ctl.set('notifications.weekly.enabled', v)),
                  ]),
                ),
                Divider(color: p.border.withValues(alpha: 0.7)),
                SwitchRow(label: 'Break over', description: need('breaks', 'Break reminders'), value: s.b('notifications.breakOver'), onChanged: (v) => ctl.set('notifications.breakOver', v)),
                Divider(color: p.border.withValues(alpha: 0.7)),
                SwitchRow(label: 'Session complete', value: s.b('notifications.sessionComplete'), onChanged: (v) => ctl.set('notifications.sessionComplete', v)),
              ]),
            ),
          ),
        ],
      ),
      SettingsSection(title: 'Quiet hours', children: [
        SwitchRow(label: 'Quiet hours', description: 'No notifications during this window.', value: s.b('notifications.quietHours.enabled'), onChanged: (v) => ctl.set('notifications.quietHours.enabled', v)),
        if (s.b('notifications.quietHours.enabled')) ...[
          SettingsRow(label: 'From', trailing: TimeButton(value: s.s('notifications.quietHours.start'), onChanged: (v) => ctl.set('notifications.quietHours.start', v))),
          SettingsRow(label: 'Until', trailing: TimeButton(value: s.s('notifications.quietHours.end'), onChanged: (v) => ctl.set('notifications.quietHours.end', v))),
        ],
      ]),
    ]);
  }
}
