import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/tokens.dart';
import '../../data/providers.dart';
import '../../services/lock.dart';
import '../../ui/widgets.dart';
import 'controls.dart';

class PrivacySection extends ConsumerStatefulWidget {
  const PrivacySection({super.key});
  @override
  ConsumerState<PrivacySection> createState() => _PrivacySectionState();
}

class _PrivacySectionState extends ConsumerState<PrivacySection> {
  bool bioAvailable = false;

  @override
  void initState() {
    super.initState();
    LockService.biometricsAvailable().then((v) {
      if (mounted) setState(() => bioAvailable = v);
    });
  }

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(settingsProvider);
    final p = context.pal;
    final ctl = settingsCtl(ref);
    final enabled = s.b('lock.enabled') && s['lock.pinHash'] != null;

    Future<void> setPin() async {
      final pin = await showPinSetup(context);
      if (pin == null) return;
      final salt = LockService.newSalt();
      final hash = await LockService.hashPin(pin, salt);
      await ctl.edit((m) {
        m['lock']['enabled'] = true;
        m['lock']['pinHash'] = hash;
        m['lock']['pinSalt'] = salt;
        m['lock']['pinLength'] = pin.length;
      });
      if (context.mounted) toast(context, 'App lock is on');
    }

    Future<bool> verify(String title) async {
      final pin = await showPinVerify(context, title);
      if (pin == null) return false;
      final ok = await LockService.verifyPin(pin, s['lock.pinSalt'] as String?, s['lock.pinHash'] as String?);
      if (!ok && context.mounted) toast(context, "That PIN isn't right.", error: true);
      return ok;
    }

    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      SettingsSection(title: 'App lock', children: [
        SwitchRow(
          label: 'Require PIN to open',
          description: '4–6 digits, stored only as a salted hash on this phone.',
          value: enabled,
          onChanged: (v) async {
            if (v) {
              await setPin();
            } else if (await verify('Turn off app lock')) {
              await ctl.edit((m) {
                m['lock']['enabled'] = false;
                m['lock']['pinHash'] = null;
                m['lock']['pinSalt'] = null;
                m['lock']['biometric'] = false;
              });
              if (context.mounted) toast(context, 'App lock is off');
            }
          },
        ),
        if (enabled) ...[
          SettingsRow(label: 'Change PIN', trailing: Btn('Change', small: true, onPressed: () async {
            if (await verify('Change PIN')) await setPin();
          })),
          SwitchRow(
            label: 'Unlock with fingerprint or face',
            description: bioAvailable ? 'Your PIN still works.' : 'No fingerprint or face unlock is set up on this phone.',
            value: s.b('lock.biometric'),
            onChanged: !bioAvailable
                ? null
                : (v) async {
                    if (v && !await LockService.authenticate('Confirm to turn on fingerprint unlock')) return;
                    await ctl.set('lock.biometric', v);
                  },
          ),
          SettingsRow(
            label: 'Auto-lock',
            description: 'After inactivity, or when you leave the app for that long.',
            trailing: DropdownButton<int>(
              value: s.i('lock.autoLockMinutes'),
              underline: const SizedBox(),
              items: const [
                DropdownMenuItem(value: 0, child: Text('Immediately')),
                DropdownMenuItem(value: 1, child: Text('1 minute')),
                DropdownMenuItem(value: 5, child: Text('5 minutes')),
                DropdownMenuItem(value: 15, child: Text('15 minutes')),
                DropdownMenuItem(value: 30, child: Text('30 minutes')),
                DropdownMenuItem(value: 60, child: Text('1 hour')),
              ],
              onChanged: (v) => v == null ? null : ctl.set('lock.autoLockMinutes', v),
            ),
          ),
        ],
      ]),
      SettingsSection(title: 'Your data', children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 14),
          child: Text(
            'Everything you create in Deepwork is stored on this phone. There are no accounts, no analytics and no servers.\n\n'
            'The only network activity is the optional weekly backup, which sends one JSON file directly from this phone to a folder in your own Google Drive. The app can only see files it created.\n\n'
            'Backups never include your PIN or Google sign-in.',
            style: TextStyle(color: p.muted, fontSize: 13.5, height: 1.45),
          ),
        ),
      ]),
    ]);
  }
}

Future<String?> showPinSetup(BuildContext context) {
  var len = 4;
  final first = TextEditingController();
  final second = TextEditingController();
  var step = 1;
  return showAppSheet<String>(context, title: 'Choose a PIN', description: 'You will enter it each time the app locks.', builder: (ctx) => StatefulBuilder(builder: (ctx, setState) {
        final p = ctx.pal;
        final ctrl = step == 1 ? first : second;
        final mismatch = step == 2 && second.text.length == len && second.text != first.text;
        return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          if (step == 1) ...[
            Segmented<int>(value: len, onChanged: (v) => setState(() {
              len = v;
              if (first.text.length > v) first.text = first.text.substring(0, v);
            }), options: const [(4, '4 digits'), (5, '5 digits'), (6, '6 digits')]),
            const SizedBox(height: 14),
          ],
          Text(step == 1 ? 'Enter a new PIN' : 'Enter it again', style: TextStyle(color: p.muted)),
          const SizedBox(height: 8),
          TextField(
            key: ValueKey(step),
            controller: ctrl,
            autofocus: true,
            obscureText: true,
            keyboardType: TextInputType.number,
            maxLength: len,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 26, letterSpacing: 14, fontFeatures: tabular),
            decoration: const InputDecoration(counterText: ''),
            onChanged: (_) => setState(() {}),
          ),
          if (mismatch) Padding(padding: const EdgeInsets.only(top: 8), child: Text("PINs don't match.", style: TextStyle(color: p.warning))),
          const SizedBox(height: 16),
          Row(children: [
            Btn(step == 2 ? 'Back' : 'Cancel', kind: BtnKind.ghost, onPressed: () => step == 2 ? setState(() => step = 1) : Navigator.pop(ctx)),
            const Spacer(),
            step == 1
                ? Btn('Next', kind: BtnKind.primary, onPressed: first.text.length == len ? () => setState(() => step = 2) : null)
                : Btn('Turn on', kind: BtnKind.primary, onPressed: second.text == first.text ? () => Navigator.pop(ctx, first.text) : null),
          ]),
        ]);
      }));
}

Future<String?> showPinVerify(BuildContext context, String title) {
  final c = TextEditingController();
  return showAppSheet<String>(context, title: title, description: 'Enter your current PIN.', builder: (ctx) => Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        TextField(
          controller: c,
          autofocus: true,
          obscureText: true,
          keyboardType: TextInputType.number,
          maxLength: 6,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 26, letterSpacing: 14, fontFeatures: tabular),
          decoration: const InputDecoration(counterText: ''),
          onSubmitted: (v) => Navigator.pop(ctx, v),
        ),
        const SizedBox(height: 14),
        Row(children: [
          Btn('Cancel', kind: BtnKind.ghost, onPressed: () => Navigator.pop(ctx)),
          const Spacer(),
          Btn('Continue', kind: BtnKind.primary, onPressed: () => Navigator.pop(ctx, c.text)),
        ]),
      ]));
}
