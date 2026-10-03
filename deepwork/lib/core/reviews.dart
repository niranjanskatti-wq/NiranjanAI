import '../data/database.dart';
import 'settings.dart';
import 'util/format.dart';

bool isEveningReviewDue(AppSettings s, List<Review> reviews, [DateTime? now]) {
  if (!s.on('eveningReview')) return false;
  final n = now ?? DateTime.now();
  if (n.hour * 60 + n.minute < timeToMinutes(s.s('eveningReview.time'))) return false;
  final today = dateKey(n);
  return !reviews.any((r) => r.type == 'daily' && r.date == today);
}

/// Start of the current weekly-review period: the most recent review day at review time.
DateTime weeklyPeriodStart(AppSettings s, [DateTime? now]) {
  final n = now ?? DateTime.now();
  final d = startOfDay(n);
  final day = addDays(d, -((weekday0(d) - s.i('weeklyReview.day') + 7) % 7));
  final at = atTime(day, s.s('weeklyReview.time'));
  return at.isAfter(n) ? addDays(at, -7) : at;
}

bool isWeeklyReviewDue(AppSettings s, List<Review> reviews, [DateTime? now]) {
  if (!s.on('weeklyReview')) return false;
  final n = now ?? DateTime.now();
  final start = weeklyPeriodStart(s, n);
  // Only show it within 3 days of the review day.
  if (n.difference(start).inHours > 72) return false;
  final cutoff = start.millisecondsSinceEpoch - 12 * 3600000;
  return !reviews.any((r) => r.type == 'weekly' && r.createdAt >= cutoff);
}
