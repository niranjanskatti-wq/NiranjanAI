import 'package:flutter/material.dart';

import '../../core/theme/tokens.dart';
import '../../data/backup_format.dart' show schemaVersion;
import '../../ui/brand.dart';
import '../../ui/widgets.dart';

const appVersion = String.fromEnvironment('APP_VERSION', defaultValue: '1.0.0');

class AboutSection extends StatelessWidget {
  const AboutSection({super.key});
  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      AppCard(
        child: Row(children: [
          const DeepworkMark(size: 48),
          const SizedBox(width: 14),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('Deepwork', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
              Text('Version $appVersion · data schema v$schemaVersion', style: TextStyle(color: p.muted, fontSize: 13)),
            ]),
          ),
        ]),
      ),
      const Gap(),
      SettingsSection(title: 'This phone', children: const [
        SettingsRow(label: 'Storage', description: 'Everything is stored on this phone and works offline. Only the optional Drive backup uses the internet.'),
      ]),
      SettingsSection(title: 'Principles', children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 14),
          child: Text(
            'Deepwork measures what you actually finish, not just time spent. It is a personal tool: no accounts, no tracking, no cloud database and no AI. All insights are simple rules calculated on this phone.',
            style: TextStyle(color: p.muted, fontSize: 13.5, height: 1.45),
          ),
        ),
      ]),
    ]);
  }
}
