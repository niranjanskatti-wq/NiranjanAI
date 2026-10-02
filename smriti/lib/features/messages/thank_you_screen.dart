import 'package:android_intent_plus/android_intent.dart';
import 'package:android_intent_plus/flag.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/tokens.dart';
import '../../data/providers.dart';
import '../../widgets/common.dart';
import 'message_engine.dart';
import 'message_store.dart';

/// On your own birthday: ready thank-you replies to send quickly.
class ThankYouScreen extends ConsumerStatefulWidget {
  const ThankYouScreen({super.key});

  @override
  ConsumerState<ThankYouScreen> createState() => _ThankYouScreenState();
}

class _ThankYouScreenState extends ConsumerState<ThankYouScreen> {
  Lang _lang = Lang.en;
  int _selected = 0;

  @override
  void initState() {
    super.initState();
    ref.read(databaseProvider).getSetting('messageLang').then((v) {
      if (mounted) setState(() => _lang = Lang.parse(v));
    });
  }

  Future<void> _send(String text, String how) async {
    HapticFeedback.lightImpact();
    switch (how) {
      case 'whatsapp':
        for (final pkg in ['com.whatsapp', 'com.whatsapp.w4b']) {
          final i = AndroidIntent(
            action: 'android.intent.action.SEND',
            type: 'text/plain',
            arguments: {'android.intent.extra.TEXT': text},
            package: pkg,
            flags: const [Flag.FLAG_ACTIVITY_NEW_TASK],
          );
          if (await i.canResolveActivity() ?? false) {
            await i.launch();
            return;
          }
        }
        if (mounted) showToast(context, 'WhatsApp is not installed');
      case 'sms':
        await AndroidIntent(
          action: 'android.intent.action.SENDTO',
          data: 'smsto:',
          arguments: {'sms_body': text},
          flags: const [Flag.FLAG_ACTIVITY_NEW_TASK],
        ).launch();
      default:
        await Clipboard.setData(ClipboardData(text: text));
        if (mounted) showToast(context, 'Copied');
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final lib = ref.watch(libraryProvider).value;
    final me = ref.watch(meProvider).value;
    final users = ref.watch(userMessagesProvider).value ?? const [];
    final ctx = MessageContext(myName: me?.name.split(' ').first);
    final list = [
      ...users.map(userTemplate),
      ...?lib?.all,
    ].where((t) => t.occasion == Occasion.thankYou && t.lang == _lang && ctx.canFill(t)).toList();
    final chosen = list.isEmpty ? null : ctx.fill(list[_selected.clamp(0, list.length - 1)].text);

    return Scaffold(
      appBar: AppBar(title: const Text('Thank you replies')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 160),
        children: [
          Text('Happy birthday! 🎉 Pick a reply, then send it to everyone who wished you.',
              style: context.text.bodyMedium),
          const SizedBox(height: 12),
          SegmentedButton<Lang>(
            showSelectedIcon: false,
            segments: [for (final l in Lang.values) ButtonSegment(value: l, label: Text(l.label))],
            selected: {_lang},
            onSelectionChanged: (s) => setState(() {
              _lang = s.first;
              _selected = 0;
            }),
          ),
          const SizedBox(height: 12),
          RadioGroup<int>(
            groupValue: _selected,
            onChanged: (v) => setState(() => _selected = v ?? 0),
            child: Column(children: [
              for (var i = 0; i < list.length; i++)
                Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: RadioListTile<int>(value: i, title: Text(ctx.fill(list[i].text), style: context.text.bodyLarge)),
                ),
            ]),
          ),
        ],
      ),
      bottomSheet: chosen == null
          ? null
          : Container(
              color: c.surface,
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
              child: SafeArea(
                child: Row(children: [
                  Expanded(
                    child: FilledButton.icon(
                      style: FilledButton.styleFrom(backgroundColor: const Color(0xFF25A35A), foregroundColor: Colors.white),
                      onPressed: () => _send(chosen, 'whatsapp'),
                      icon: const Icon(Icons.chat_rounded),
                      label: const Text('WhatsApp'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _send(chosen, 'sms'),
                      icon: const Icon(Icons.sms_outlined),
                      label: const Text('SMS'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _send(chosen, 'copy'),
                      icon: const Icon(Icons.copy_rounded),
                      label: const Text('Copy'),
                    ),
                  ),
                ]),
              ),
            ),
    );
  }
}
