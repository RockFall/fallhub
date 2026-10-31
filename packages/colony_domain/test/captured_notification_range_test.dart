import 'package:colony_domain/colony_domain.dart';
import 'package:test/test.dart';

void main() {
  group('capturedNotificationDayRangeBounds', () {
    test('covers one local day from midnight to the next', () {
      final day = DateTime(2026, 10, 30);
      final bounds = capturedNotificationDayRangeBounds(
        fromDay: day,
        toDay: day,
      );
      expect(bounds.start, DateTime(2026, 10, 30).toUtc());
      expect(bounds.end, DateTime(2026, 10, 31).toUtc());
    });

    test(
      'includes every local day from the earlier bound through the later',
      () {
        final bounds = capturedNotificationDayRangeBounds(
          fromDay: DateTime(2026, 10, 31),
          toDay: DateTime(2026, 10, 30),
        );
        expect(bounds.start, DateTime(2026, 10, 30).toUtc());
        expect(bounds.end, DateTime(2026, 11, 1).toUtc());
      },
    );
  });
}
