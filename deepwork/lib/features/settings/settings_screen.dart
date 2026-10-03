import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/settings.dart';
import '../../core/theme/tokens.dart';
import '../../data/providers.dart';
import '../../services/native.dart';
import '../../ui/widgets.dart';
import 'about_section.dart';
import 'appearance_section.dart';
import 'backup_section.dart';
import 'blocking_section.dart';
import 'controls.dart';
import 'customize_section.dart';
import 'data_section.dart';
import 'notifications_section.dart';
import 'privacy_section.dart';

class SettingsSectionInfo {
  const SettingsSectionInfo(this.id, this.label, this.description, this.icon, this.builder);
  final String id, label, description;
  final IconData icon;
  final Widget Function() builder;
}

List<SettingsSectionInfo> settingsSections() => [
      SettingsSectionInfo('features', 'Features', 'Turn modules on or off', Icons.toggle_on_outlined, () => const FeaturesSection()),
      if (NativeBridge.available) SettingsSectionInfo('blocking', 'App blocking', 'Pause distracting apps while you focus', Icons.block_rounded, () => const BlockingSection()),
      SettingsSectionInfo('customize', 'Customization', 'Fine-tune each module', Icons.tune_rounded, () => const CustomizeSection()),
      SettingsSectionInfo('appearance', 'Appearance', 'Theme, accent, font, layout', Icons.palette_outlined, () => const AppearanceSection()),
      SettingsSectionInfo('notifications', 'Notifications', 'Reminders and quiet hours', Icons.notifications_none_rounded, () => const NotificationsSection()),
      SettingsSectionInfo('privacy', 'Privacy & Lock', 'PIN, fingerprint, auto-lock', Icons.shield_outlined, () => const PrivacySection()),
      SettingsSectionInfo('backup', 'Backup', 'Weekly Google Drive backup', Icons.cloud_outlined, () => const BackupSection()),
      SettingsSectionInfo('data', 'Data', 'Export, import, demo, delete', Icons.storage_rounded, () => const DataSection()),
      SettingsSectionInfo('about', 'About', 'Version and storage', Icons.info_outline_rounded, () => const AboutSection()),
    ];

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key, this.section});
  final String? section;

  @override
  Widget build(BuildContext context) {
    final sections = settingsSections();
    final current = sections.where((s) => s.id == section).firstOrNull;
    final wide = MediaQuery.sizeOf(context).width >= 900;
    final p = context.pal;

    if (wide) {
      final active = current ?? sections.first;
      return Scaffold(
        body: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1100),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
                child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  SizedBox(
                    width: 230,
                    child: ListView(children: [
                      const PageHeader(title: 'Settings'),
                      for (final s in sections)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 2),
                          child: Material(
                            color: s.id == active.id ? p.card : Colors.transparent,
                            borderRadius: BorderRadius.circular(12),
                            child: ListTile(
                              dense: true,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: s.id == active.id ? p.border : Colors.transparent)),
                              leading: Icon(s.icon, size: 19, color: s.id == active.id ? p.accent : p.muted),
                              title: Text(s.label, style: TextStyle(fontWeight: FontWeight.w500, color: s.id == active.id ? p.fg : p.muted)),
                              onTap: () => context.go('/settings/${s.id}'),
                            ),
                          ),
                        ),
                    ]),
                  ),
                  const SizedBox(width: 28),
                  Expanded(
                    child: ListView(padding: const EdgeInsets.only(bottom: 40), children: [
                      const SizedBox(height: 8),
                      Text(active.label, style: Theme.of(context).textTheme.titleLarge),
                      const SizedBox(height: 18),
                      KeyedSubtree(key: ValueKey(active.id), child: active.builder()),
                    ]),
                  ),
                ]),
              ),
            ),
          ),
        ),
      );
    }

    if (current == null) {
      return Scaffold(
        body: PageBody(children: [
          const PageHeader(title: 'Settings'),
          AppCard(
            padding: EdgeInsets.zero,
            child: Column(children: [
              for (var i = 0; i < sections.length; i++) ...[
                ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  leading: Container(width: 38, height: 38, decoration: BoxDecoration(color: p.card2, borderRadius: BorderRadius.circular(11)), child: Icon(sections[i].icon, size: 19, color: p.muted)),
                  title: Text(sections[i].label, style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 15)),
                  subtitle: Text(sections[i].description, style: TextStyle(color: p.muted, fontSize: 13)),
                  trailing: Icon(Icons.chevron_right_rounded, color: p.muted),
                  onTap: () => context.push('/settings/${sections[i].id}'),
                ),
                if (i < sections.length - 1) Divider(indent: 70, color: p.border.withValues(alpha: 0.7)),
              ],
            ]),
          ),
        ]),
      );
    }

    return Scaffold(
      appBar: backBar(context, title: current.label, fallback: '/settings'),
      body: PageBody(children: [current.builder()]),
    );
  }
}

class FeaturesSection extends ConsumerWidget {
  const FeaturesSection({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(settingsProvider);
    final p = context.pal;
    final ctl = settingsCtl(ref);
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Padding(
        padding: const EdgeInsets.only(bottom: 16, left: 4),
        child: Text('Every module is optional. Turned-off modules disappear from navigation, Today, notifications and insights.', style: TextStyle(color: p.muted, fontSize: 13.5)),
      ),
      SettingsSection(
        title: 'Modules',
        action: ResetButton(label: 'Modules', onReset: () => ctl.replace(ctl.current.resetModules())),
        children: [
          for (final m in modules.where((m) => m.key != 'appBlocking' || NativeBridge.available))
            SwitchRow(
              label: m.label,
              description: m.key == 'backup' && !s.b('backup.connected') ? 'Connect Google Drive to turn this on.' : m.locked ? 'Always on.' : m.description,
              value: s.on(m.key),
              onChanged: m.locked
                  ? null
                  : (v) {
                      if (m.key == 'backup' && v && !s.b('backup.connected')) {
                        context.push('/settings/backup');
                        return;
                      }
                      ctl.set('modules.${m.key}', v);
                    },
            ),
        ],
      ),
    ]);
  }
}
