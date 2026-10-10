import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../data/models.dart';
import '../../data/providers.dart';
import '../../widgets/common.dart';

/// People kept but hidden from the main lists.
class ArchivedScreen extends ConsumerWidget {
  const ArchivedScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final people = ref.watch(archivedPeopleProvider).value ?? const [];
    return Scaffold(
      appBar: AppBar(title: const Text('Archived')),
      body: people.isEmpty
          ? const Center(
              child: EmptyState(
                title: 'Nothing archived',
                message: 'Archive someone from their profile to hide them here without deleting anything.',
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: people.length,
              itemBuilder: (_, i) {
                final p = people[i];
                return ListTile(
                  leading: PersonAvatar(person: p, size: 42),
                  title: Text(p.shortName),
                  subtitle: Text(p.relationLabel),
                  onTap: () => context.push('/person/${p.id}'),
                  trailing: TextButton(
                    onPressed: () async {
                      await ref.read(repoProvider).setArchived(p.id, false);
                      if (context.mounted) showToast(context, '${p.shortName} is back in People');
                    },
                    child: const Text('Restore'),
                  ),
                );
              },
            ),
    );
  }
}
