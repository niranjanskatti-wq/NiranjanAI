import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/tokens.dart';
import '../../core/util/format.dart';
import '../../data/database.dart';
import '../../data/enums.dart';
import '../../data/providers.dart';
import '../../widgets/pickers.dart';

/// First launch: the owner's name and (optionally) their own dates.
class WelcomeScreen extends ConsumerStatefulWidget {
  const WelcomeScreen({super.key});

  @override
  ConsumerState<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends ConsumerState<WelcomeScreen> {
  final _name = TextEditingController();
  DateParts? _birthday, _anniversary;
  bool _saving = false;

  Future<void> _start() async {
    final name = _name.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enter your name')));
      return;
    }
    setState(() => _saving = true);
    final repo = ref.read(repoProvider);
    final id = await repo.insertPerson(PeopleCompanion.insert(
      name: name,
      relationship: Value(Relationship.self.name),
      isMe: const Value(true),
      birthYear: Value(_birthday?.year),
    ));
    if (_birthday != null) {
      await repo.saveEvent(
        data: EventsCompanion.insert(
          kind: EventKind.person.name,
          type: EventType.birthday.name,
          day: _birthday!.day,
          month: _birthday!.month,
        ),
        personIds: [id],
      );
    }
    if (_anniversary != null) {
      await repo.saveEvent(
        data: EventsCompanion.insert(
          kind: EventKind.person.name,
          type: EventType.weddingAnniversary.name,
          day: _anniversary!.day,
          month: _anniversary!.month,
          year: Value(_anniversary!.year),
        ),
        personIds: [id],
      );
    }
    await ref.read(databaseProvider).setSetting('onboarded', 'true');
    HapticFeedback.lightImpact();
    if (mounted) context.go('/home');
  }

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    Widget dateTile(String label, DateParts? value, ValueChanged<DateParts?> set) => Card(
          child: ListTile(
            leading: Icon(label.contains('Birthday') ? Icons.cake_outlined : Icons.favorite_outline, color: c.goldText),
            title: Text(label),
            subtitle: Text(value == null
                ? 'Optional'
                : fmtEventDate(day: value.day, month: value.month, year: value.year)),
            trailing: value == null
                ? const Icon(Icons.add_rounded)
                : IconButton(tooltip: 'Clear', onPressed: () => set(null), icon: const Icon(Icons.close_rounded)),
            onTap: () async {
              final d = await pickDate(context, initial: value, title: label);
              if (d != null) set(d);
            },
          ),
        );

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(24, 48, 24, 24),
          children: [
            Text('✦', style: TextStyle(fontFamily: serif, fontSize: 48, color: c.goldText, height: 1)),
            const SizedBox(height: 12),
            Text('Smriti', style: context.text.displayLarge?.copyWith(fontSize: 56)),
            const SizedBox(height: 8),
            Text(
              'Never miss a day that matters. Birthdays, anniversaries and important dates, '
              'counted down and kept safe on this phone.',
              style: context.text.bodyLarge?.copyWith(color: c.muted),
            ),
            const SizedBox(height: 32),
            TextField(
              controller: _name,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(labelText: 'Your name', hintText: 'Used when you send wishes'),
            ),
            const SizedBox(height: 16),
            dateTile('Your Birthday', _birthday, (v) => setState(() => _birthday = v)),
            const SizedBox(height: 8),
            dateTile('Your wedding anniversary', _anniversary, (v) => setState(() => _anniversary = v)),
            const SizedBox(height: 28),
            FilledButton(onPressed: _saving ? null : _start, child: const Text('Get started')),
            const SizedBox(height: 16),
            Text(
              'Nothing leaves your phone. No account, no ads.',
              textAlign: TextAlign.center,
              style: context.text.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}
