import 'package:deepwork/core/reviews.dart';
import 'package:deepwork/core/settings.dart';
import 'package:deepwork/data/database.dart';
import 'package:flutter_test/flutter_test.dart';

Review review(String type, String date, DateTime created) =>
    Review(id: '$type$date', type: type, date: date, answers: '[]', nextPriorities: '[]', stats: '{}', createdAt: created.millisecondsSinceEpoch, isDemo: false);

void main() {
  final s = AppSettings.defaults();
  test('evening review is due after its time until saved', () {
    expect(isEveningReviewDue(s, const [], DateTime(2026, 10, 7, 19)), isFalse);
    expect(isEveningReviewDue(s, const [], DateTime(2026, 10, 7, 20, 30)), isTrue);
    expect(isEveningReviewDue(s, [review('daily', '2026-10-07', DateTime(2026, 10, 7, 20, 40))], DateTime(2026, 10, 7, 21)), isFalse);
    expect(isEveningReviewDue(s.set('modules.eveningReview', false), const [], DateTime(2026, 10, 7, 21)), isFalse);
  });

  test('weekly review is due on the review day after its time, for up to 3 days', () {
    // Default: Sunday 17:00.
    expect(isWeeklyReviewDue(s, const [], DateTime(2026, 10, 4, 16)), isFalse); // Sunday before 5 pm → last period too old
    expect(isWeeklyReviewDue(s, const [], DateTime(2026, 10, 4, 18)), isTrue);
    expect(isWeeklyReviewDue(s, const [], DateTime(2026, 10, 6, 12)), isTrue);
    expect(isWeeklyReviewDue(s, const [], DateTime(2026, 10, 8, 12)), isFalse);
    expect(isWeeklyReviewDue(s, [review('weekly', '2026-10-04', DateTime(2026, 10, 4, 18))], DateTime(2026, 10, 5, 9)), isFalse);
  });
}
