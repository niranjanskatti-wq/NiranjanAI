import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/theme/tokens.dart';
import '../../data/database.dart';
import '../../data/providers.dart';
import '../../widgets/common.dart';

IconData methodIcon(String m) => switch (m) {
      'call' => Icons.call_rounded,
      'whatsapp' => Icons.chat_rounded,
      'sms' => Icons.sms_outlined,
      'copy' => Icons.copy_rounded,
      'email' => Icons.mail_outline,
      'telegram' => Icons.send_outlined,
      'card' => Icons.image_outlined,
      'manual' => Icons.check_rounded,
      _ => Icons.ios_share,
    };

String methodLabel(String m) => switch (m) {
      'call' => 'Called',
      'whatsapp' => 'WhatsApp',
      'sms' => 'Text message',
      'copy' => 'Copied',
      'email' => 'Email',
      'telegram' => 'Telegram',
      'card' => 'Greeting card',
      'manual' => 'Marked as wished',
      _ => 'Shared',
    };

final _when = DateFormat('d MMM yyyy, h:mm a');

/// Calls and messages to or about a person, newest first.
class WishHistoryCard extends ConsumerWidget {
  const WishHistoryCard({super.key, required this.person, required this.eventIds});

  final Person person;
  final Set<int> eventIds;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.c;
    final logs = (ref.watch(wishLogsProvider).value ?? const <WishLog>[])
        .where((l) => l.personId == person.id || (l.eventId != null && eventIds.contains(l.eventId)))
        .toList();
    return InfoCard(
      title: 'Wish history',
      children: [
        if (logs.isEmpty)
          Text('Calls and wishes you send from Smriti appear here, so you never repeat a message.',
              style: context.text.bodyMedium),
        for (final l in logs.take(20))
          Dismissible(
            key: ValueKey(l.id),
            direction: DismissDirection.endToStart,
            background: Container(
              alignment: Alignment.centerRight,
              padding: const EdgeInsets.only(right: 12),
              color: c.alert.withValues(alpha: 0.15),
              child: Icon(Icons.delete_outline, color: c.alert),
            ),
            onDismissed: (_) => ref.read(repoProvider).deleteWishLog(l.id),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Icon(methodIcon(l.method), size: 18, color: c.muted),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Row(children: [
                      Text(methodLabel(l.method), style: context.text.titleSmall),
                      if (l.confirmed) ...[
                        const SizedBox(width: 6),
                        Icon(Icons.check_circle, size: 14, color: c.call),
                      ],
                      const Spacer(),
                      Text(_when.format(l.createdAt), style: context.text.bodySmall),
                    ]),
                    if (l.message != null)
                      Text(l.message!, style: context.text.bodySmall, maxLines: 2, overflow: TextOverflow.ellipsis),
                  ]),
                ),
              ]),
            ),
          ),
      ],
    );
  }
}
