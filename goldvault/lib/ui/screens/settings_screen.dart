import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../app.dart';
import '../../core/app_services.dart';
import '../../core/format.dart';
import '../../core/security.dart';
import '../../core/strings.dart';
import '../../core/theme.dart';
import '../widgets/common.dart';
import 'alert_settings_screen.dart';
import 'cloud_screen.dart';
import 'out_now_screen.dart';
import 'dashboard_screen.dart';
import 'reminders_screen.dart';
import 'where_is_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final ctrl = GoldVaultApp.ctrl;
    return Scaffold(
      appBar: AppBar(title: Text(context.t('set.title'))),
      body: DataBuilder<Map<String, String?>>(
        load: () => AppServices.I.repo.allSettings(),
        builder: (context, s) => ListView(padding: const EdgeInsets.fromLTRB(16, 0, 16, 40), children: [
          SectionTitle(context.t('set.language')),
          SegmentedButton<String>(
            showSelectedIcon: false,
            segments: const [
              ButtonSegment(value: 'en', label: Text('English', style: TextStyle(fontSize: 17))),
              ButtonSegment(value: 'kn', label: Text('ಕನ್ನಡ', style: TextStyle(fontSize: 17))),
            ],
            selected: {ctrl.locale.languageCode},
            onSelectionChanged: (v) => ctrl.setLanguage(v.first),
          ),
          SectionTitle(context.t('set.general')),
          _group([
            _tile(Icons.travel_explore, context.t('where.title'), null,
                () => Navigator.push(context, MaterialPageRoute(builder: (_) => const WhereIsScreen()))),
            _tile(Icons.timer_outlined, context.t('ret.screen'), context.t('ret.screenSub'),
                () => Navigator.push(context, MaterialPageRoute(builder: (_) => const OutNowScreen()))),
            _tile(Icons.alarm, context.t('rem.title'), context.t('rem.titleSub'),
                () => Navigator.push(context, MaterialPageRoute(builder: (_) => const RemindersScreen()))),
            _tile(Icons.notifications_active_outlined, context.t('alerts.title'), context.t('alerts.sub'),
                () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AlertSettingsScreen()))),
          ]),
          SectionTitle(context.t('set.display')),
          _group([
            _switch(s, 'show_values', false, Icons.currency_rupee, context.t('set.showValues'), context.t('set.showValuesSub')),
            if (s['show_values'] == '1')
              _tile(Icons.trending_up, context.t('rates.title'), _ratesLine(context, s), () => showRatesDialog(context)),
            _switch(s, 'dash_breakdown', true, Icons.pie_chart_outline, context.t('set.dashBreakdown'), null),
            _switch(s, 'dash_reminders', true, Icons.notifications_outlined, context.t('set.dashReminders'), null),
            _switch(s, 'dash_recent', true, Icons.swap_horiz, context.t('set.dashRecent'), null),
            _switch(s, 'show_out_time', true, Icons.timer_outlined, context.t('set.showOutTime'), context.t('set.showOutTimeSub')),
            _switch(s, 'holidays_on_visit_cal', true, Icons.beach_access_outlined, context.t('hol.onVisitCal'), null),
          ]),
          SectionTitle(context.t('set.cloud')),
          _group([
            _tile(Icons.cloud_sync_outlined, context.t('cloud.title'), context.t('cloud.subtitle'),
                () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CloudScreen()))),
          ]),
          SectionTitle(context.t('set.security')),
          _group([
            _tile(Icons.pin_outlined, context.t('set.changePin'), null, () => _changePin(context)),
            const _BiometricTile(),
            SwitchListTile(
              secondary: const Icon(Icons.screenshot_monitor, color: GV.gold),
              title: Text(context.t('set.blockAll')),
              subtitle: Text(context.t('set.blockAllSub')),
              value: s['screenshot_all'] != '0',
              onChanged: (v) async {
                await AppServices.I.repo.setSetting('screenshot_all', v ? '1' : '0');
                await ScreenGuard.setAlways(v);
                AppServices.I.repo.revision.value++;
              },
            ),
            ListTile(
              leading: const Icon(Icons.timer_outlined, size: 28),
              title: Text(context.t('set.autoLockAfter')),
              trailing: DropdownButton<int>(
                value: [30, 60, 120, 300].contains(int.tryParse(s['auto_lock_seconds'] ?? '')) ? int.parse(s['auto_lock_seconds']!) : 60,
                dropdownColor: GV.surface2,
                underline: const SizedBox(),
                items: [
                  for (final sec in const [30, 60, 120, 300])
                    DropdownMenuItem(
                      value: sec,
                      child: Text(sec < 60 ? context.t('set.seconds', {'n': sec}) : context.t('set.minutes', {'n': sec ~/ 60}),
                          style: const TextStyle(color: GV.gold, fontSize: 16)),
                    ),
                ],
                onChanged: (v) async {
                  if (v == null) return;
                  GoldVaultApp.appLock.timeout = Duration(seconds: v);
                  await AppServices.I.repo.setPref('auto_lock_seconds', v);
                },
              ),
            ),
            _tile(Icons.lock_outline, context.t('set.lockNow'), null, () => GoldVaultApp.appLock.lock()),
          ]),
          SectionTitle(context.t('set.about')),
          GoldCard(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('GoldVault', style: TextStyle(fontFamily: GV.display, fontSize: 22, color: GV.gold)),
              const SizedBox(height: 6),
              Text(context.t('set.aboutBody'), style: const TextStyle(color: GV.muted, height: 1.4)),
            ]),
          ),
        ]),
      ),
    );
  }

  String _ratesLine(BuildContext context, Map<String, String?> s) {
    final g = double.tryParse(s['rate_gold24'] ?? '') ?? 0;
    final sv = double.tryParse(s['rate_silver'] ?? '') ?? 0;
    if (g == 0 && sv == 0) return context.t('rates.notSet');
    return '${context.t('rates.gold24')} ${Fmt.rupees(g)} · ${context.t('rates.silver')} ${Fmt.rupees(sv)}';
  }

  Widget _switch(Map<String, String?> s, String key, bool def, IconData icon, String title, String? sub) => SwitchListTile(
        secondary: Icon(icon, color: GV.gold),
        title: Text(title),
        subtitle: sub == null ? null : Text(sub),
        value: s[key] == null ? def : s[key] == '1',
        onChanged: (v) => AppServices.I.repo.setPref(key, v),
      );

  Widget _group(List<Widget> children) => GoldCard(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Column(children: children),
      );

  Widget _tile(IconData icon, String title, String? sub, VoidCallback onTap) => ListTile(
        leading: Icon(icon, size: 28),
        title: Text(title),
        subtitle: sub == null ? null : Text(sub),
        trailing: const Icon(Icons.chevron_right, color: GV.gold),
        onTap: onTap,
      );

  Future<void> _changePin(BuildContext context) async {
    final cur = TextEditingController();
    final n1 = TextEditingController();
    final n2 = TextEditingController();
    InputDecoration dec(String l) => InputDecoration(labelText: l, counterText: '');
    Widget pin(TextEditingController c, String l) => TextField(
          controller: c,
          obscureText: true,
          maxLength: 4,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          style: const TextStyle(fontSize: 22, letterSpacing: 8),
          decoration: dec(l),
        );
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: Text(context.t('set.changePin')),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          pin(cur, context.t('set.currentPin')),
          const SizedBox(height: 12),
          pin(n1, context.t('set.newPin')),
          const SizedBox(height: 12),
          pin(n2, context.t('set.confirmPin')),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c, false), child: Text(context.t('common.cancel'))),
          FilledButton(onPressed: () => Navigator.pop(c, true), child: Text(context.t('common.save'))),
        ],
      ),
    );
    if (ok != true || !context.mounted) return;
    final secure = AppServices.I.secure;
    if (!await secure.checkPin(cur.text)) {
      if (context.mounted) toast(context, context.t('lock.wrong'));
      return;
    }
    if (n1.text.length != 4 || n1.text != n2.text) {
      if (context.mounted) toast(context, context.t('lock.mismatch'));
      return;
    }
    await secure.setPin(n1.text);
    if (context.mounted) toast(context, context.t('set.pinChanged'));
  }
}

class _BiometricTile extends StatefulWidget {
  const _BiometricTile();
  @override
  State<_BiometricTile> createState() => _BiometricTileState();
}

class _BiometricTileState extends State<_BiometricTile> {
  bool? _on;
  bool _available = false;

  @override
  void initState() {
    super.initState();
    () async {
      _available = await GoldVaultApp.appLock.biometricAvailable();
      _on = await AppServices.I.secure.biometricEnabled();
      if (mounted) setState(() {});
    }();
  }

  @override
  Widget build(BuildContext context) {
    return SwitchListTile(
      secondary: const Icon(Icons.fingerprint, color: GV.gold, size: 28),
      title: Text(context.t('set.biometric')),
      subtitle: Text(_available ? context.t('set.biometricSub') : context.t('set.biometricNA')),
      value: _on ?? false,
      onChanged: !_available
          ? null
          : (v) async {
              if (v && !await GoldVaultApp.appLock.confirmBiometrics(context.t('lock.bioReason'))) return;
              await AppServices.I.secure.setBiometricEnabled(v);
              setState(() => _on = v);
            },
    );
  }
}
