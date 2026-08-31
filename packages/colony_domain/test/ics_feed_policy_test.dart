import 'package:colony_domain/colony_domain.dart';
import 'package:test/test.dart';

void main() {
  group('IcsFeedPolicy', () {
    test('rewrites webcal and accepts Google iCal URLs', () {
      final uri = IcsFeedPolicy.normalize(
        'webcal://calendar.google.com/calendar/ical/me%40gmail.com/private-abc/basic.ics',
      );
      expect(uri, isNotNull);
      expect(uri!.scheme, 'https');
      expect(IcsFeedPolicy.looksLikeCalendarFeed(uri), isTrue);
    });

    test('rejects empty and non-http', () {
      expect(IcsFeedPolicy.normalize(''), isNull);
      expect(IcsFeedPolicy.normalize('ftp://x.ics'), isNull);
    });
  });

  group('IcsRrule', () {
    test('expands weekly BYDAY inside the window', () {
      final seed = IcsEventPreview(
        uid: 'standup',
        summary: 'Standup',
        startAt: DateTime.utc(2026, 8, 31, 12), // Monday
        endAt: DateTime.utc(2026, 8, 31, 12, 30),
      );
      final out = IcsRrule.expand(
        seed: seed,
        rrule: 'FREQ=WEEKLY;BYDAY=MO,WE',
        windowStart: DateTime.utc(2026, 8, 31),
        windowEnd: DateTime.utc(2026, 9, 8),
      );
      expect(out.map((e) => e.startAt.day), [31, 2, 7]);
      expect(out.first.uid, startsWith('standup#'));
    });

    test('COUNT stops expansion', () {
      final seed = IcsEventPreview(
        uid: 'd',
        summary: 'Daily',
        startAt: DateTime.utc(2026, 1, 1, 9),
        endAt: DateTime.utc(2026, 1, 1, 10),
      );
      final out = IcsRrule.expand(
        seed: seed,
        rrule: 'FREQ=DAILY;COUNT=3',
        windowStart: DateTime.utc(2026, 1, 1),
        windowEnd: DateTime.utc(2026, 2, 1),
      );
      expect(out, hasLength(3));
    });

    test('COUNT series that ended before the window is empty', () {
      final seed = IcsEventPreview(
        uid: 'old',
        summary: 'Old series',
        startAt: DateTime.utc(2026, 1, 1, 9),
        endAt: DateTime.utc(2026, 1, 1, 10),
      );
      final out = IcsRrule.expand(
        seed: seed,
        rrule: 'FREQ=DAILY;COUNT=2',
        windowStart: DateTime.utc(2026, 8, 1),
        windowEnd: DateTime.utc(2026, 8, 31),
      );
      expect(out, isEmpty);
    });
  });
}
