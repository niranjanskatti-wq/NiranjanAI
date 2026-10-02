import 'package:android_intent_plus/android_intent.dart';
import 'package:android_intent_plus/flag.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/util/occurrence.dart';
import '../../data/database.dart';
import '../../data/models.dart';
import '../../data/providers.dart';

/// What is being wished: an event occurrence, a festival, or just a person.
class WishTarget {
  WishTarget({
    this.entry,
    required this.date,
    required this.recipients,
    this.about,
    this.festivalId,
    this.festivalName,
    this.belated = false,
    this.years,
    this.milestone = false,
  });

  final EventEntry? entry;
  final Day date;

  /// People who can receive the call or message (already resolves "Send wishes to").
  final List<Person> recipients;

  /// Whose occasion it is, when different from the recipient.
  final Person? about;
  final String? festivalId, festivalName;
  final bool belated, milestone;
  final int? years;

  String get occasionKey => date.toString();

  /// Headline for sheets: "Wish Appa", "Wish Ravi & Priya".
  String get title => entry != null ? entry!.title : (about?.shortName ?? recipients.firstOrNull?.shortName ?? '');
}

/// Builds the target for the next (or a past) occurrence of [e].
Future<WishTarget> targetFor(WidgetRef ref, EventEntry e, Day date, {bool belated = false}) async {
  final repo = ref.read(repoProvider);
  final sendTo = e.event.sendWishesToId == null ? null : await repo.getPerson(e.event.sendWishesToId!);
  final people = e.people.where((p) => !p.isMe).toList();
  final u = Upcoming(e, date, 0);
  return WishTarget(
    entry: e,
    date: date,
    recipients: sendTo != null ? [sendTo] : people,
    about: sendTo != null ? people.firstOrNull : null,
    belated: belated,
    years: u.years,
    milestone: u.milestone,
  );
}

/// The "Mark as wished?" chip waiting for the user after a call or share.
class PendingWish {
  const PendingWish({required this.label, this.eventId, this.festivalId, required this.date, this.personId});

  final String label;
  final int? eventId, personId;
  final String? festivalId;
  final String date;
}

class PendingWishNotifier extends Notifier<PendingWish?> {
  @override
  PendingWish? build() => null;

  void set(PendingWish? p) => state = p;
}

final pendingWishProvider = NotifierProvider<PendingWishNotifier, PendingWish?>(PendingWishNotifier.new);

enum WhatsappApp { whatsapp, business }

extension on WhatsappApp {
  String get package => this == WhatsappApp.whatsapp ? 'com.whatsapp' : 'com.whatsapp.w4b';
}

/// Talks to the phone: dialler, WhatsApp, SMS, clipboard, share menu.
class WishService {
  /// In Wish Mode ([wishMode]) every send counts as wished straight away and
  /// no "Mark as wished?" chip is shown.
  WishService(this.ref, {this.wishMode = false});

  final WidgetRef ref;
  final bool wishMode;

  static String _digits(String n) => n.replaceAll(RegExp(r'\D'), '');

  Future<void> _log(WishTarget t, Person? to, String method, {String? message, String? templateId}) async {
    await ref.read(repoProvider).logWish(
          personId: to?.id ?? t.about?.id,
          eventId: t.entry?.event.id,
          festivalId: t.festivalId,
          occasionDate: t.occasionKey,
          method: method,
          message: message,
          templateId: templateId,
          confirmed: wishMode,
        );
    if (wishMode) return;
    ref.read(pendingWishProvider.notifier).set(PendingWish(
          label: t.entry?.title ?? to?.shortName ?? '',
          eventId: t.entry?.event.id,
          festivalId: t.festivalId,
          date: t.occasionKey,
          personId: to?.id,
        ));
  }

  /// Calls directly when allowed; otherwise opens the dialler with the number.
  Future<void> call(WishTarget t, Person to) async {
    final number = to.callNumber;
    if (number == null) return;
    HapticFeedback.mediumImpact();
    final granted = await Permission.phone.request().isGranted;
    await AndroidIntent(
      action: granted ? 'android.intent.action.CALL' : 'android.intent.action.DIAL',
      data: 'tel:$number',
      flags: const [Flag.FLAG_ACTIVITY_NEW_TASK],
    ).launch();
    await _log(t, to, 'call');
  }

  /// Installed WhatsApp apps, in preference order.
  static Future<List<WhatsappApp>> installedWhatsapp() async {
    final out = <WhatsappApp>[];
    for (final app in WhatsappApp.values) {
      final ok = await AndroidIntent(
        action: 'action_view',
        data: 'https://api.whatsapp.com/send?phone=910000000000',
        package: app.package,
      ).canResolveActivity();
      if (ok ?? false) out.add(app);
    }
    return out;
  }

  /// Opens the person's WhatsApp chat with [text] typed in, ready to send.
  Future<void> whatsapp(WishTarget t, Person to, String text, WhatsappApp app, {String? templateId}) async {
    final number = to.effectiveWhatsapp;
    if (number == null) return;
    HapticFeedback.lightImpact();
    await AndroidIntent(
      action: 'action_view',
      data: Uri(
        scheme: 'https',
        host: 'api.whatsapp.com',
        path: '/send',
        queryParameters: {'phone': _digits(number), 'text': text},
      ).toString(),
      package: app.package,
      flags: const [Flag.FLAG_ACTIVITY_NEW_TASK],
    ).launch();
    await _log(t, to, 'whatsapp', message: text, templateId: templateId);
  }

  /// Opens the messaging app to the person's number with [text] filled in.
  Future<void> sms(WishTarget t, Person to, String text, {String? templateId}) async {
    final number = to.callNumber ?? to.whatsappNumber;
    if (number == null) return;
    HapticFeedback.lightImpact();
    await AndroidIntent(
      action: 'android.intent.action.SENDTO',
      data: 'smsto:$number',
      arguments: {'sms_body': text},
      flags: const [Flag.FLAG_ACTIVITY_NEW_TASK],
    ).launch();
    await _log(t, to, 'sms', message: text, templateId: templateId);
  }

  Future<void> copy(WishTarget t, Person? to, String text, {String? templateId}) async {
    await Clipboard.setData(ClipboardData(text: text));
    HapticFeedback.lightImpact();
    await _log(t, to, 'copy', message: text, templateId: templateId);
  }

  /// Sends [text] into a specific app's own chooser (e.g. pick a WhatsApp group).
  Future<bool> sendToApp(WishTarget t, Person? to, String text, String package, String method) async {
    final intent = AndroidIntent(
      action: 'android.intent.action.SEND',
      type: 'text/plain',
      arguments: {'android.intent.extra.TEXT': text},
      package: package,
      flags: const [Flag.FLAG_ACTIVITY_NEW_TASK],
    );
    if (!(await intent.canResolveActivity() ?? false)) return false;
    await intent.launch();
    await _log(t, to, method, message: text);
    return true;
  }

  Future<void> email(WishTarget t, Person? to, String text, String subject) async {
    await AndroidIntent(
      action: 'android.intent.action.SENDTO',
      data: Uri(scheme: 'mailto', queryParameters: {'subject': subject, 'body': text}).toString(),
      flags: const [Flag.FLAG_ACTIVITY_NEW_TASK],
    ).launch();
    await _log(t, to, 'email', message: text);
  }

  Future<void> systemShare(WishTarget t, Person? to, String text) async {
    await SharePlus.instance.share(ShareParams(text: text));
    await _log(t, to, 'share', message: text);
  }

  /// Records that a greeting card image was shared.
  Future<void> cardShared(WishTarget t, Person? to, String text) => _log(t, to, 'card', message: text);
}
