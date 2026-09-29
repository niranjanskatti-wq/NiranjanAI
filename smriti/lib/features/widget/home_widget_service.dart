import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:home_widget/home_widget.dart';

import '../../core/util/occurrence.dart';
import '../../data/database.dart';
import '../../data/models.dart';
import '../../data/repository.dart';
import '../festivals/festival_model.dart';
import '../reminders/notification_service.dart';

/// Feeds the home-screen widget. The widget works out "today / in 3 days"
/// itself from the dates, so it stays right even when Smriti isn't opened.
class HomeWidgetService {
  static const androidName = 'com.niranjan.smriti.SmritiWidget';

  /// The next few dates, oldest first, as the widget reads them.
  static List<Map<String, String>> items(List<EventEntry> entries, Day today, {int count = 15}) => [
        for (final u in computeUpcoming(entries, today).where((u) => u.daysLeft <= 366).take(count))
          {
            't': u.entry.title,
            'l': [u.entry.typeLabel, ?u.yearsPhrase].join(' · '),
            'd': u.date.toString(),
          },
      ];

  static Future<void> publish(List<EventEntry> entries, Day today) async {
    if (!NotificationService.supported) return;
    try {
      await HomeWidget.saveWidgetData<String>('items', jsonEncode(items(entries, today)));
      await HomeWidget.updateWidget(qualifiedAndroidName: androidName);
    } catch (e) {
      debugPrint('Widget update failed: $e');
    }
  }

  /// For the background refresh, where there are no providers.
  static Future<void> refreshFrom(AppDatabase db) async {
    if (!NotificationService.supported) return;
    final entries = await Repository(db).watchEntries().first;
    final festivals = (await FestivalRepo.loadAll(db)).where((f) => f.enabled).toList();
    await publish([
      ...entries,
      for (var i = 0; i < festivals.length; i++) FestivalEntry(festivals[i], -(i + 1)),
    ], Day.today());
  }
}
