import 'package:colony_domain/colony_domain.dart';
import 'package:test/test.dart';

void main() {
  group('weekStartDateFor', () {
    test('Monday start returns Monday for mid-week date', () {
      // Wednesday 2026-08-05
      final date = DateTime.utc(2026, 8, 5);
      final start = weekStartDateFor(date, weekStartsOnMonday: true);
      expect(start, DateTime.utc(2026, 8, 3));
    });

    test('Monday start returns same day when date is Monday', () {
      final date = DateTime.utc(2026, 8, 3);
      final start = weekStartDateFor(date, weekStartsOnMonday: true);
      expect(start, DateTime.utc(2026, 8, 3));
    });

    test('Monday start rolls Sunday back to previous Monday', () {
      final date = DateTime.utc(2026, 8, 9); // Sunday
      final start = weekStartDateFor(date, weekStartsOnMonday: true);
      expect(start, DateTime.utc(2026, 8, 3));
    });

    test('Sunday start returns Sunday for mid-week date', () {
      final date = DateTime.utc(2026, 8, 5); // Wednesday
      final start = weekStartDateFor(date, weekStartsOnMonday: false);
      expect(start, DateTime.utc(2026, 8, 2)); // previous Sunday
    });

    test('Sunday start returns same day when date is Sunday', () {
      final date = DateTime.utc(2026, 8, 9);
      final start = weekStartDateFor(date, weekStartsOnMonday: false);
      expect(start, DateTime.utc(2026, 8, 9));
    });
  });

  group('WeeklyReview', () {
    test('equality uses all fields', () {
      final a = WeeklyReview(
        id: EntityId('w1'),
        profileId: EntityId('p1'),
        weekStartDate: DateTime.utc(2026, 8, 3),
        createdAt: DateTime.utc(2026, 8, 6, 12),
        facts: 'Semana produtiva',
      );
      final b = WeeklyReview(
        id: EntityId('w1'),
        profileId: EntityId('p1'),
        weekStartDate: DateTime.utc(2026, 8, 3),
        createdAt: DateTime.utc(2026, 8, 6, 12),
        facts: 'Semana produtiva',
      );
      expect(a, equals(b));
    });
  });
}
