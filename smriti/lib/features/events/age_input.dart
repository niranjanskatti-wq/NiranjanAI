import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/util/occurrence.dart';
import '../../data/database.dart';
import '../../data/enums.dart';
import '../../data/models.dart';
import '../../data/repository.dart';

/// Asks "How old is Appa turning?" (or years married) for a date whose year
/// isn't saved. Returns the number, or null if cancelled.
Future<int?> askYears(BuildContext context,
    {required bool birthday, required String name, required Day on, int? initial}) async {
  final ctrl = TextEditingController(text: initial?.toString() ?? '');
  final value = await showDialog<int>(
    context: context,
    builder: (ctx) {
      void done() {
        final n = int.tryParse(ctrl.text.trim());
        if (n != null && n > 0 && n < 130) Navigator.pop(ctx, n);
      }

      return AlertDialog(
        title: Text(birthday ? 'How old is $name turning?' : 'How many years married?'),
        content: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          TextField(
            controller: ctrl,
            autofocus: true,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(3)],
            decoration: InputDecoration(
              labelText: birthday ? 'Age on ${on.day}/${on.month}/${on.year}' : 'Years on ${on.day}/${on.month}/${on.year}',
              hintText: birthday ? 'e.g. 60' : 'e.g. 25',
            ),
            onSubmitted: (_) => done(),
          ),
          const SizedBox(height: 8),
          Text(
            birthday
                ? 'Smriti works out the birth year, so every wish can say "Happy 60th birthday".'
                : 'Smriti works out the wedding year, so every wish can say "Happy 25th anniversary".',
            style: Theme.of(ctx).textTheme.bodySmall,
          ),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(onPressed: done, child: const Text('Save')),
        ],
      );
    },
  );
  ctrl.dispose();
  return value;
}

/// The year that makes [years] come out on [on].
int yearFor(int years, Day on) => on.year - years;

/// Saves the year behind [years] for [entry] (and the person's birth year for a birthday).
Future<void> saveYears(Repository repo, EventEntry entry, int years, Day on) async {
  final year = yearFor(years, on);
  await repo.updateEvent(entry.event.id, EventsCompanion(year: Value(year)));
  final p = entry.primary;
  if (entry.type == EventType.birthday && entry.people.length == 1 && p != null) {
    await repo.setBirthYear(p.id, year);
  }
}
