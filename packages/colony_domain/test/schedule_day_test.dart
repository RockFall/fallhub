import 'package:colony_domain/colony_domain.dart';
import 'package:test/test.dart';

void main() {
  group('scheduleCalendarDay', () {
    test('uses local calendar components', () {
      final instant = DateTime.utc(2026, 8, 7, 2);
      final day = scheduleCalendarDay(instant);
      expect(day.year, instant.toLocal().year);
      expect(day.month, instant.toLocal().month);
      expect(day.day, instant.toLocal().day);
      expect(day.hour, 0);
      expect(day.minute, 0);
    });
  });

  group('scheduleDayUtcBounds', () {
    test('covers local midnight through next midnight as UTC instants', () {
      final day = DateTime(2026, 8, 6);
      final bounds = scheduleDayUtcBounds(day);
      expect(bounds.start, DateTime(2026, 8, 6).toUtc());
      expect(bounds.end, DateTime(2026, 8, 7).toUtc());
      expect(bounds.end.difference(bounds.start), const Duration(days: 1));
    });
  });

  group('scheduleBlockUtcTimes', () {
    test('converts local hours on calendar day to UTC', () {
      final day = DateTime(2026, 8, 6);
      final times = scheduleBlockUtcTimes(
        day: day,
        startHour: 9,
        startMinute: 30,
        endHour: 10,
        endMinute: 15,
      );
      expect(times.startAt, DateTime(2026, 8, 6, 9, 30).toUtc());
      expect(times.endAt, DateTime(2026, 8, 6, 10, 15).toUtc());
    });
  });

  group('assertScheduleBlockTimeRange', () {
    test('accepts end after start', () {
      expect(
        () => assertScheduleBlockTimeRange(
          DateTime.utc(2026, 8, 6, 9),
          DateTime.utc(2026, 8, 6, 10),
        ),
        returnsNormally,
      );
    });

    test('rejects end equal to start', () {
      expect(
        () => assertScheduleBlockTimeRange(
          DateTime.utc(2026, 8, 6, 9),
          DateTime.utc(2026, 8, 6, 9),
        ),
        throwsA(isA<ScheduleBlockTimeRangeException>()),
      );
    });

    test('rejects end before start', () {
      expect(
        () => assertScheduleBlockTimeRange(
          DateTime.utc(2026, 8, 6, 10),
          DateTime.utc(2026, 8, 6, 9),
        ),
        throwsA(isA<ScheduleBlockTimeRangeException>()),
      );
    });
  });

  group('parseScheduleDateParam', () {
    test('parses YYYY-MM-DD', () {
      final day = parseScheduleDateParam('2026-08-06');
      expect(day, DateTime(2026, 8, 6));
    });

    test('returns null for invalid input', () {
      expect(parseScheduleDateParam('2026/08/06'), isNull);
      expect(parseScheduleDateParam('invalid'), isNull);
    });
  });

  group('scheduleThreeDayRange', () {
    test('returns three consecutive days from anchor', () {
      final anchor = DateTime(2026, 8, 6);
      final range = scheduleThreeDayRange(anchor);
      expect(range, hasLength(3));
      expect(range[0], DateTime(2026, 8, 6));
      expect(range[1], DateTime(2026, 8, 7));
      expect(range[2], DateTime(2026, 8, 8));
    });

    test('normalizes anchor to calendar day', () {
      final anchor = DateTime(2026, 8, 6, 15, 30);
      final range = scheduleThreeDayRange(anchor);
      expect(range.first.hour, 0);
      expect(range.first.minute, 0);
    });

    test('crosses month boundary', () {
      final range = scheduleThreeDayRange(DateTime(2026, 1, 30));
      expect(range[0], DateTime(2026, 1, 30));
      expect(range[1], DateTime(2026, 1, 31));
      expect(range[2], DateTime(2026, 2, 1));
    });

    test('crosses year boundary', () {
      final range = scheduleThreeDayRange(DateTime(2025, 12, 31));
      expect(range[0], DateTime(2025, 12, 31));
      expect(range[1], DateTime(2026, 1, 1));
      expect(range[2], DateTime(2026, 1, 2));
    });
  });

  group('ScheduleBlock.create', () {
    test('rejects invalid time range', () {
      expect(
        () => ScheduleBlock.create(
          id: const EntityId('block-1'),
          profileId: const EntityId('profile-1'),
          startAt: DateTime.utc(2026, 8, 6, 10),
          endAt: DateTime.utc(2026, 8, 6, 9),
          mode: ScheduleBlockMode.focus,
          createdAt: DateTime.utc(2026, 8, 6),
        ),
        throwsA(isA<ScheduleBlockTimeRangeException>()),
      );
    });
  });
}
