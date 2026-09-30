import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:home_widget/home_widget.dart';

import '../../core/util/occurrence.dart';
import '../../data/database.dart';
import '../../data/models.dart';
import '../../data/repository.dart';
import '../festivals/festival_model.dart';
import '../reminders/notification_service.dart';

/// Feeds the home-screen widgets. The widgets work out "today / in 3 days"
/// themselves from the dates, so they stay right even when Smriti isn't opened.
class HomeWidgetService {
  static const androidName = 'com.niranjan.smriti.SmritiWidget';

  /// Every widget style, with its name in the picker.
  static const styles = {
    'com.niranjan.smriti.SmritiWidget': ('Next up', 'The next date with its countdown, and three more'),
    'com.niranjan.smriti.SmritiCountdownWidget': ('Countdown', 'Small: a big countdown to the next date'),
    'com.niranjan.smriti.SmritiListWidget': ('Coming up', 'Tall: the next six dates in a list'),
    'com.niranjan.smriti.SmritiTodayWidget': ('Today', 'Glows until you wish everyone celebrating today'),
  };

  /// Key used for "wished" on a date: the event id, or the festival key.
  static String keyOf(EventEntry e) => e is FestivalEntry ? e.festival.key : '${e.event.id}';

  /// The next few dates, oldest first, as the widgets read them.
  static List<Map<String, String>> items(List<EventEntry> entries, Day today, {int count = 15}) => [
        for (final u in computeUpcoming(entries, today).where((u) => u.daysLeft <= 366).take(count))
          {
            't': u.entry.title,
            'l': [u.entry.typeLabel, ?u.yearsPhrase].join(' · '),
            'd': u.date.toString(),
            'k': keyOf(u.entry),
          },
      ];

  /// [done]: "key|yyyy-mm-dd" of dates already marked as wished; the Today
  /// widget stops glowing once all of today's are in it.
  static Future<void> publish(List<EventEntry> entries, Day today, {Set<String> done = const {}}) async {
    if (!NotificationService.supported) return;
    try {
      final from = today.addDays(-2).toString();
      await HomeWidget.saveWidgetData<String>('items', jsonEncode(items(entries, today)));
      await HomeWidget.saveWidgetData<String>(
          'done', jsonEncode([for (final k in done) if (k.split('|').last.compareTo(from) >= 0) k]));
      for (final name in styles.keys) {
        await HomeWidget.updateWidget(qualifiedAndroidName: name);
      }
    } catch (e) {
      debugPrint('Widget update failed: $e');
    }
  }

  /// For the background refresh, where there are no providers.
  static Future<void> refreshFrom(AppDatabase db) async {
    if (!NotificationService.supported) return;
    final showFestivals = await db.getSetting('showFestivals') != 'false';
    final showImportant = await db.getSetting('showImportant') != 'false';
    final entries = await Repository(db).watchEntries().first;
    final festivals = showFestivals ? (await FestivalRepo.loadAll(db)).where((f) => f.enabled).toList() : const <Festival>[];
    final done = {
      for (final l in await db.select(db.wishLogs).get())
        if (l.confirmed && l.occasionDate != null) '${l.eventId ?? l.festivalId}|${l.occasionDate}',
    };
    await publish(done: done, [
      ...entries.where((e) => visibleKind(e, festivals: showFestivals, important: showImportant)),
      for (var i = 0; i < festivals.length; i++) FestivalEntry(festivals[i], -(i + 1)),
    ], Day.today());
  }

  /// Handles taps on the Today widget: smriti://done?k=…&d=… marks a date as
  /// wished, smriti://open?k=… opens it. Returns 'done', a route, or null.
  static Future<String?> handleTap(Uri? uri, Repository repo) async {
    if (uri == null || uri.scheme != 'smriti') return null;
    final k = uri.queryParameters['k'];
    if (k == null) return null;
    final eventId = int.tryParse(k);
    if (uri.host == 'done') {
      final d = uri.queryParameters['d'];
      if (d == null) return null;
      if (eventId != null) {
        final entry = await repo.watchEntry(eventId).first;
        await repo.markWished(eventId: eventId, occasionDate: d, personId: entry?.primary?.id);
      } else {
        await repo.markWished(festivalId: k, occasionDate: d);
      }
      return 'done';
    }
    return eventId != null ? '/event/$eventId' : '/festival?key=${Uri.encodeQueryComponent(k)}';
  }
}
