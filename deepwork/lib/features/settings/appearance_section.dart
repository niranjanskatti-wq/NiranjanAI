import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/settings.dart';
import '../../core/theme/tokens.dart';
import '../../data/providers.dart';
import '../../ui/widgets.dart';
import '../tasks/tasks_screen.dart' show pickColor;
import 'controls.dart';

class AppearanceSection extends ConsumerWidget {
  const AppearanceSection({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(settingsProvider);
    final p = context.pal;
    final ctl = settingsCtl(ref);
    final accent = s.s('appearance.accent').toUpperCase();
    final layout = s.homeLayout;

    Widget themeTile(String v, String label, IconData icon) {
      final active = s.s('appearance.theme') == v;
      return Expanded(
        child: Pressable(
          onTap: () => ctl.set('appearance.theme', v),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 160),
            padding: const EdgeInsets.symmetric(vertical: 16),
            decoration: BoxDecoration(
              color: active ? p.accentSoft : Colors.transparent,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: active ? p.accent.withValues(alpha: 0.6) : p.border),
            ),
            child: Column(children: [
              Icon(icon, color: active ? p.accent : p.muted),
              const SizedBox(height: 6),
              Text(label, style: TextStyle(fontWeight: FontWeight.w500, color: active ? p.accent : p.fg)),
            ]),
          ),
        ),
      );
    }

    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      SettingsSection(title: 'Theme', action: ResetButton(label: 'Appearance', onReset: () => ctl.replace(ctl.current.resetSection('appearance'))), children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 14),
          child: Row(children: [
            themeTile('dark', 'Dark', Icons.dark_mode_outlined),
            const SizedBox(width: 8),
            themeTile('light', 'Light', Icons.light_mode_outlined),
            const SizedBox(width: 8),
            themeTile('system', 'System', Icons.brightness_auto_outlined),
          ]),
        ),
        SettingsRow(
          label: 'Accent color',
          below: Wrap(spacing: 10, runSpacing: 10, crossAxisAlignment: WrapCrossAlignment.center, children: [
            for (final c in accentPresets)
              Pressable(
                onTap: () => ctl.set('appearance.accent', c),
                child: Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: colorFromHex(c),
                    shape: BoxShape.circle,
                    boxShadow: accent == c.toUpperCase() ? [BoxShadow(color: p.card, spreadRadius: 2), BoxShadow(color: colorFromHex(c), spreadRadius: 4)] : null,
                  ),
                  child: accent == c.toUpperCase() ? Icon(Icons.check_rounded, size: 18, color: onColor(colorFromHex(c))) : null,
                ),
              ),
            Pressable(
              onTap: () async {
                final c = await pickColor(context, s.s('appearance.accent'));
                if (c != null) await ctl.set('appearance.accent', c);
              },
              child: Container(
                height: 34,
                padding: const EdgeInsets.only(left: 4, right: 12),
                decoration: BoxDecoration(borderRadius: BorderRadius.circular(99), border: Border.all(color: p.border)),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Container(width: 26, height: 26, decoration: BoxDecoration(color: colorFromHex(accent), shape: BoxShape.circle)),
                  const SizedBox(width: 8),
                  const Text('Custom', style: TextStyle(fontWeight: FontWeight.w500, fontSize: 13)),
                ]),
              ),
            ),
          ]),
        ),
      ]),
      SettingsSection(title: 'Text & layout', children: [
        SettingsRow(
          label: 'Font',
          trailing: Segmented<String>(small: true, value: s.s('appearance.font'), onChanged: (v) => ctl.set('appearance.font', v), options: const [('inter', 'Inter'), ('geist', 'Geist'), ('serif', 'Serif')]),
        ),
        SettingsRow(
          label: 'Text size',
          trailing: Segmented<String>(small: true, value: s.s('appearance.textSize'), onChanged: (v) => ctl.set('appearance.textSize', v), options: const [('small', 'Small'), ('medium', 'Medium'), ('large', 'Large')]),
        ),
        SettingsRow(
          label: 'Density',
          trailing: Segmented<String>(small: true, value: s.s('appearance.density'), onChanged: (v) => ctl.set('appearance.density', v), options: const [('comfortable', 'Comfortable'), ('compact', 'Compact')]),
        ),
        SettingsRow(
          label: 'Animations',
          description: s.s('appearance.animations') == 'full' ? "Follows your phone's reduce-motion setting." : null,
          trailing: Segmented<String>(small: true, value: s.s('appearance.animations'), onChanged: (v) => ctl.set('appearance.animations', v), options: const [('full', 'Full'), ('reduced', 'Reduced'), ('off', 'Off')]),
        ),
      ]),
      SettingsSection(
        title: 'Home layout',
        description: "Drag to reorder Today's sections. Sections for modules that are off stay hidden.",
        children: [
          ReorderableListView(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            buildDefaultDragHandles: false,
            onReorderItem: (from, to) => ctl.edit((m) {
              final list = (m['appearance']['homeLayout'] as List).toList();
              final item = list.removeAt(from);
              list.insert(to, item);
              m['appearance']['homeLayout'] = list;
            }),
            children: [
              for (var i = 0; i < layout.length; i++)
                Builder(
                  key: ValueKey(layout[i]['id']),
                  builder: (context) {
                    final id = layout[i]['id'] as String;
                    final (label, module) = homeSections[id]!;
                    final off = module != null && !s.on(module);
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(children: [
                        ReorderableDragStartListener(index: i, child: Padding(padding: const EdgeInsets.all(6), child: Icon(Icons.drag_indicator_rounded, size: 20, color: p.muted))),
                        Expanded(child: Text(off ? '$label (module off)' : label, style: TextStyle(color: off ? p.muted : p.fg))),
                        Switch(
                          value: layout[i]['visible'] == true,
                          onChanged: (v) => ctl.edit((m) {
                            final list = (m['appearance']['homeLayout'] as List);
                            (list.firstWhere((e) => e['id'] == id) as Map)['visible'] = v;
                          }),
                        ),
                      ]),
                    );
                  },
                ),
            ],
          ),
        ],
      ),
    ]);
  }
}
