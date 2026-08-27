import 'package:colony_domain/colony_domain.dart';
import 'package:test/test.dart';

void main() {
  final now = DateTime(2026, 8, 9, 12);

  SleepSession closed({
    required DateTime start,
    required DateTime end,
    String id = 's',
  }) {
    return SleepSession.create(
      id: EntityId(id),
      profileId: const EntityId('p'),
      startedAt: start,
      endedAt: end,
      source: SleepSessionSource.detected,
      createdAt: now.toUtc(),
    );
  }

  test('attributes overnight sleep to wake day', () {
    final sessions = [
      closed(
        id: 'night',
        start: DateTime(2026, 8, 8, 23, 10),
        end: DateTime(2026, 8, 9, 6, 40),
      ),
    ];
    final days = groupSleepSessionsByWakeDay(sessions, now: now);
    expect(days, hasLength(1));
    expect(days.single.day, DateTime(2026, 8, 9));
    expect(days.single.total.inMinutes, 7 * 60 + 30);
  });

  test('groups multiple nights newest first', () {
    final sessions = [
      closed(
        id: 'a',
        start: DateTime(2026, 8, 7, 23),
        end: DateTime(2026, 8, 8, 7),
      ),
      closed(
        id: 'b',
        start: DateTime(2026, 8, 8, 23),
        end: DateTime(2026, 8, 9, 7),
      ),
    ];
    final days = groupSleepSessionsByWakeDay(sessions, now: now);
    expect(days.map((d) => d.day), [
      DateTime(2026, 8, 9),
      DateTime(2026, 8, 8),
    ]);
  });
}
