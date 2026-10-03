import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/tokens.dart';
import '../../data/providers.dart';
import '../../services/native.dart';
import '../../ui/widgets.dart';
import 'controls.dart';

/// Android: choose which apps are paused during focus sessions.
class BlockingSection extends ConsumerStatefulWidget {
  const BlockingSection({super.key});
  @override
  ConsumerState<BlockingSection> createState() => _BlockingSectionState();
}

class _BlockingSectionState extends ConsumerState<BlockingSection> with WidgetsBindingObserver {
  bool? serviceOn;
  List<InstalledApp>? apps;
  String query = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _check();
    NativeBridge.installedApps().then((v) {
      if (mounted) setState(() => apps = v);
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Re-check when returning from Android's accessibility settings.
    if (state == AppLifecycleState.resumed) _check();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  void _check() => NativeBridge.blockerEnabled().then((v) {
        if (mounted) setState(() => serviceOn = v);
      });

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(settingsProvider);
    final p = context.pal;
    final ctl = settingsCtl(ref);
    final mode = s.s('blocking.mode');
    final selected = s.strings('blocking.packages').toSet();
    final q = query.trim().toLowerCase();
    final list = (apps ?? const <InstalledApp>[]).where((a) => q.isEmpty || a.label.toLowerCase().contains(q)).toList()
      ..sort((a, b) => selected.contains(a.packageName) != selected.contains(b.packageName) ? (selected.contains(a.packageName) ? -1 : 1) : a.label.toLowerCase().compareTo(b.label.toLowerCase()));

    void toggle(InstalledApp a) => ctl.edit((m) {
          final pk = (m['blocking']['packages'] as List).cast<String>().toSet();
          pk.contains(a.packageName) ? pk.remove(a.packageName) : pk.add(a.packageName);
          m['blocking']['packages'] = pk.toList();
          (m['blocking']['labels'] as Map)[a.packageName] = a.label;
        });

    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Padding(
        padding: const EdgeInsets.only(left: 4, bottom: 16),
        child: Text(
          'While a focus session is running, opening a paused app shows a “Stay with it” screen instead. Pausing or ending the session lifts the block. Your phone app, keyboard and home screen are never blocked.',
          style: TextStyle(color: p.muted, fontSize: 13.5, height: 1.4),
        ),
      ),
      if (serviceOn == false) ...[
        AppCard(
          borderColor: p.warning.withValues(alpha: 0.45),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Icon(Icons.shield_outlined, color: p.warning, size: 20),
              const SizedBox(width: 8),
              const Expanded(child: Text('Turn on the blocking permission', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15))),
            ]),
            const SizedBox(height: 8),
            Text(
              'Android needs you to allow Deepwork under Accessibility. It only sees which app is opened during a session, never what is on screen. Tap below, choose “Deepwork focus blocking” (it may be under “Installed apps” or “Downloaded apps”) and switch it on.',
              style: TextStyle(color: p.muted, fontSize: 13, height: 1.4),
            ),
            const SizedBox(height: 8),
            Text(
              'If Android says the setting is restricted: open App info for Deepwork, tap ⋮ (top right) → “Allow restricted settings”, then try again.',
              style: TextStyle(color: p.muted, fontSize: 13, height: 1.4),
            ),
            const SizedBox(height: 14),
            Wrap(spacing: 8, runSpacing: 8, children: [
              Btn('Open Accessibility settings', kind: BtnKind.primary, onPressed: NativeBridge.openBlockerSettings),
              Btn('App info', onPressed: NativeBridge.openAppSettings),
            ]),
          ]),
        ),
        const Gap(),
      ],
      SettingsSection(title: 'Blocking', action: ResetButton(label: 'App blocking', onReset: () => ctl.replace(ctl.current.resetSection('blocking'))), children: [
        SwitchRow(label: 'Block apps during focus sessions', value: s.on('appBlocking'), onChanged: (v) => ctl.set('modules.appBlocking', v)),
        SettingsRow(
          label: 'Permission',
          description: serviceOn == null ? 'Checking…' : serviceOn! ? 'Allowed' : 'Not allowed yet',
          trailing: serviceOn == true ? Icon(Icons.check_circle_rounded, color: p.success) : null,
        ),
        SettingsRow(
          label: 'Mode',
          description: mode == 'block' ? 'Only the apps you pick are paused.' : 'Every app is paused except the ones you pick.',
          below: Segmented<String>(value: mode, onChanged: (v) => ctl.set('blocking.mode', v), options: const [('block', 'Block chosen apps'), ('allow', 'Allow only chosen apps')]),
        ),
        SwitchRow(
          label: 'Log attempts as distractions',
          description: 'Trying to open a paused app is added to the session as a “Blocked app” distraction.',
          value: s.b('blocking.logAttempts'),
          onChanged: (v) => ctl.set('blocking.logAttempts', v),
        ),
      ]),
      SettingsSection(title: mode == 'block' ? 'Apps to pause (${selected.length})' : 'Apps to allow (${selected.length})', children: [
        Padding(
          padding: const EdgeInsets.only(top: 12, bottom: 4),
          child: TextField(decoration: const InputDecoration(hintText: 'Search apps', prefixIcon: Icon(Icons.search_rounded, size: 20)), onChanged: (v) => setState(() => query = v)),
        ),
        if (apps == null)
          const Padding(padding: EdgeInsets.all(24), child: Center(child: CircularProgressIndicator()))
        else if (apps!.isEmpty)
          Padding(padding: const EdgeInsets.all(16), child: Text('No apps found.', style: TextStyle(color: p.muted)))
        else
          for (final a in list)
            InkWell(
              onTap: () => toggle(a),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Row(children: [
                  a.icon != null ? ClipRRect(borderRadius: BorderRadius.circular(9), child: Image.memory(a.icon!, width: 36, height: 36, gaplessPlayback: true)) : Container(width: 36, height: 36, decoration: BoxDecoration(color: p.card2, borderRadius: BorderRadius.circular(9))),
                  const SizedBox(width: 12),
                  Expanded(child: Text(a.label, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w500))),
                  Switch(value: selected.contains(a.packageName), onChanged: (_) => toggle(a)),
                ]),
              ),
            ),
      ]),
    ]);
  }
}
