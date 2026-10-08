import 'package:flutter/material.dart';

import '../../core/app_services.dart';
import '../../core/format.dart';
import '../../core/strings.dart';
import '../../core/theme.dart';
import '../../data/models.dart';
import '../../services/notifications.dart';
import '../widgets/alarm_options.dart';
import '../widgets/common.dart';

/// Every alert and alarm, each with its own on/off switch.
class AlertSettingsScreen extends StatelessWidget {
  const AlertSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final repo = AppServices.I.repo;
    return Scaffold(
      appBar: AppBar(title: Text(context.t('alerts.title'))),
      body: DataBuilder<Prefs>(
        load: repo.prefs,
        builder: (context, p) {
          final on = p.notifications;
          Widget sw(String key, bool value, String title, {String? sub, IconData? icon, bool enabled = true}) =>
              SwitchListTile(
                secondary: icon == null ? null : Icon(icon, color: GV.gold, size: 26),
                title: Text(title),
                subtitle: sub == null ? null : Text(sub),
                value: value,
                onChanged: enabled ? (v) => repo.setPref(key, v) : null,
              );
          Widget days(String key, int value, String title, {bool enabled = true, int min = 0}) => ListTile(
                enabled: enabled,
                title: Text(title),
                trailing: _Stepper(value: value, min: min, enabled: enabled, onChanged: (v) => repo.setPref(key, v)),
              );
          return ListView(padding: const EdgeInsets.fromLTRB(16, 0, 16, 40), children: [
            SectionTitle(context.t('alerts.general')),
            _group([
              sw('notif_enabled', on, context.t('alerts.master'), sub: context.t('alerts.masterSub'), icon: Icons.notifications_active_outlined),
              ListTile(
                enabled: on,
                leading: const Icon(Icons.schedule, color: GV.gold, size: 26),
                title: Text(context.t('alerts.time')),
                subtitle: Text(context.t('alerts.timeSub')),
                trailing: Text(Fmt.hhmm(p.alertTime), style: const TextStyle(color: GV.gold, fontSize: 17, fontWeight: FontWeight.w700)),
                onTap: () async {
                  final parts = p.alertTime.split(':');
                  final t = await showTimePicker(
                      context: context, initialTime: TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1])));
                  if (t != null) {
                    await repo.setPref('alert_time', '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}');
                  }
                },
              ),
              ExpansionTile(
                leading: const Icon(Icons.alarm, color: GV.gold, size: 26),
                title: Text(context.t('alert.defaults')),
                subtitle: Text(context.t('alert.defaultsSub')),
                childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                children: [
                  Builder(builder: (context) {
                    final o = AlarmOptions.fromPrefs(p);
                    return AlarmOptionsEditor(
                      options: o,
                      onChanged: () async {
                        await repo.setSetting('default_alerts', o.sortedAlerts.join(','));
                        await repo.setSetting('default_sound', o.sound);
                        await repo.setSetting('default_snooze', '${o.snooze}');
                        await repo.setPref('default_vibrate', o.vibrate);
                      },
                    );
                  }),
                ],
              ),
              ListTile(
                enabled: on,
                leading: const Icon(Icons.verified_outlined, color: GV.gold, size: 26),
                title: Text(context.t('alerts.exact')),
                subtitle: Text(context.t('alerts.exactSub')),
                onTap: () async {
                  await Notifier.requestPermission();
                  await Notifier.requestExactAlarms();
                },
              ),
              ListTile(
                enabled: on,
                leading: const Icon(Icons.alarm_on, color: GV.gold, size: 26),
                title: Text(context.t('alerts.test')),
                subtitle: Text(context.t('alerts.testSub')),
                onTap: () async {
                  final msg = context.t('alerts.testSet');
                  final title = context.t('alerts.testTitle');
                  final body = context.t('alerts.testBody');
                  await Notifier.requestPermission();
                  await Notifier.requestExactAlarms();
                  await Notifier.schedule(99999, DateTime.now().add(const Duration(minutes: 1)), title, body, style: AlertStyle(sound: p.defaultSound, vibrate: p.defaultVibrate, snooze: p.defaultSnooze));
                  if (context.mounted) toast(context, msg);
                },
              ),
            ]),
            SectionTitle(context.t('alerts.lockers')),
            _group([
              sw('rent_alerts', p.rentAlerts, context.t('alerts.rent'), icon: Icons.receipt_long_outlined, enabled: on),
              days('rent_lead_days', p.rentLeadDays, context.t('rem.rentLead'), enabled: on && p.rentAlerts),
              sw('planned_alerts', p.plannedAlerts, context.t('alerts.planned'), icon: Icons.event_available_outlined, enabled: on),
              days('planned_lead_days', p.plannedLeadDays, context.t('alerts.plannedLead'), enabled: on && p.plannedAlerts),
              sw('return_by_default', p.returnByDefault, context.t('ret.askDefault'), sub: context.t('ret.askDefaultSub'), icon: Icons.alarm_add),
              days('return_by_days', p.returnByDays, context.t('ret.defaultDays'), min: 1),
              sw('not_returned_alerts', p.notReturnedAlerts, context.t('alerts.notReturned'), icon: Icons.assignment_return_outlined, enabled: on),
              days('not_returned_days', p.notReturnedDays, context.t('rem.notReturnedDays'), enabled: on && p.notReturnedAlerts, min: 1),
            ]),
            SectionTitle(context.t('hol.title')),
            _group([
              sw('holiday_alerts', p.holidayAlerts, context.t('alerts.holiday'), sub: context.t('alerts.holidaySub'), icon: Icons.beach_access_outlined, enabled: on),
              days('holiday_lead_days', p.holidayLeadDays, context.t('alerts.holidayLead'), enabled: on && p.holidayAlerts),
              sw('holiday_weekend_alerts', p.holidayWeekendAlerts, context.t('alerts.holidayWeekends'), enabled: on && p.holidayAlerts),
              sw('closed_sundays', p.sundaysClosed, context.t('hol.ruleSundays'), icon: Icons.calendar_view_week),
              sw('closed_sat_2_4', p.saturdays24Closed, context.t('hol.ruleSaturdays'), icon: Icons.calendar_view_week),
              sw('holidays_on_visit_cal', p.holidaysOnVisitCal, context.t('hol.onVisitCal'), icon: Icons.event_note),
            ]),
            SectionTitle(context.t('alerts.other')),
            _group([
              sw('backup_notifications', p.backupNotifications, context.t('alerts.backup'), icon: Icons.cloud_done_outlined, enabled: on),
            ]),
          ]);
        },
      ),
    );
  }

  Widget _group(List<Widget> children) => GoldCard(padding: const EdgeInsets.symmetric(vertical: 4), child: Column(children: children));
}

/// Big −/+ buttons for day counts (easy for elders).
class _Stepper extends StatelessWidget {
  const _Stepper({required this.value, required this.onChanged, this.min = 0, this.enabled = true});
  final int value;
  final int min;
  final bool enabled;
  final ValueChanged<int> onChanged;
  @override
  Widget build(BuildContext context) => Row(mainAxisSize: MainAxisSize.min, children: [
        IconButton(
          icon: const Icon(Icons.remove_circle_outline),
          color: GV.gold,
          onPressed: enabled && value > min ? () => onChanged(value - 1) : null,
        ),
        SizedBox(
          width: 52,
          child: Text(context.t('common.nDays', {'n': value}),
              textAlign: TextAlign.center, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
        ),
        IconButton(
          icon: const Icon(Icons.add_circle_outline),
          color: GV.gold,
          onPressed: enabled && value < 365 ? () => onChanged(value + 1) : null,
        ),
      ]);
}
