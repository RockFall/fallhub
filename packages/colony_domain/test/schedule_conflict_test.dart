import 'package:colony_domain/colony_domain.dart';
import 'package:test/test.dart';

ScheduleTimelineItem _block(String id, int startHour, int endHour) {
  return ScheduleTimelineItem(
    id: id,
    startAt: DateTime.utc(2026, 8, 6, startHour),
    endAt: DateTime.utc(2026, 8, 6, endHour),
    kind: ScheduleTimelineItemKind.block,
    label: id,
  );
}

void main() {
  group('scheduleIntervalsOverlap', () {
    test('no overlap when intervals are separate', () {
      expect(
        scheduleIntervalsOverlap(
          DateTime.utc(2026, 8, 6, 9),
          DateTime.utc(2026, 8, 6, 10),
          DateTime.utc(2026, 8, 6, 11),
          DateTime.utc(2026, 8, 6, 12),
        ),
        isFalse,
      );
    });

    test('adjacent boundaries do not overlap (half-open)', () {
      expect(
        scheduleIntervalsOverlap(
          DateTime.utc(2026, 8, 6, 9),
          DateTime.utc(2026, 8, 6, 10),
          DateTime.utc(2026, 8, 6, 10),
          DateTime.utc(2026, 8, 6, 11),
        ),
        isFalse,
      );
    });

    test('partial overlap', () {
      expect(
        scheduleIntervalsOverlap(
          DateTime.utc(2026, 8, 6, 9),
          DateTime.utc(2026, 8, 6, 11),
          DateTime.utc(2026, 8, 6, 10),
          DateTime.utc(2026, 8, 6, 12),
        ),
        isTrue,
      );
    });

    test('nested interval overlaps', () {
      expect(
        scheduleIntervalsOverlap(
          DateTime.utc(2026, 8, 6, 9),
          DateTime.utc(2026, 8, 6, 12),
          DateTime.utc(2026, 8, 6, 10),
          DateTime.utc(2026, 8, 6, 11),
        ),
        isTrue,
      );
    });
  });

  group('scheduleOverlapStart/End', () {
    test('computes partial overlap bounds', () {
      expect(
        scheduleOverlapStart(
          DateTime.utc(2026, 8, 6, 9),
          DateTime.utc(2026, 8, 6, 11),
          DateTime.utc(2026, 8, 6, 10),
          DateTime.utc(2026, 8, 6, 12),
        ),
        DateTime.utc(2026, 8, 6, 10),
      );
      expect(
        scheduleOverlapEnd(
          DateTime.utc(2026, 8, 6, 9),
          DateTime.utc(2026, 8, 6, 11),
          DateTime.utc(2026, 8, 6, 10),
          DateTime.utc(2026, 8, 6, 12),
        ),
        DateTime.utc(2026, 8, 6, 11),
      );
    });

    test('returns null for adjacent intervals', () {
      expect(
        scheduleOverlapStart(
          DateTime.utc(2026, 8, 6, 9),
          DateTime.utc(2026, 8, 6, 10),
          DateTime.utc(2026, 8, 6, 10),
          DateTime.utc(2026, 8, 6, 11),
        ),
        isNull,
      );
    });
  });

  group('detectScheduleConflicts', () {
    test('empty input yields no conflicts', () {
      expect(detectScheduleConflicts([]), isEmpty);
    });

    test('single block yields no conflicts', () {
      expect(
        detectScheduleConflicts([_block('a', 9, 10)]),
        isEmpty,
      );
    });

    test('adjacent blocks do not conflict', () {
      expect(
        detectScheduleConflicts([
          _block('a', 9, 10),
          _block('b', 10, 11),
        ]),
        isEmpty,
      );
    });

    test('partial overlap produces one conflict', () {
      final conflicts = detectScheduleConflicts([
        _block('a', 9, 11),
        _block('b', 10, 12),
      ]);
      expect(conflicts, hasLength(1));
      expect(conflicts.first.overlapStart, DateTime.utc(2026, 8, 6, 10));
      expect(conflicts.first.overlapEnd, DateTime.utc(2026, 8, 6, 11));
      expect(conflicts.first.overlapDuration, const Duration(hours: 1));
    });

    test('nested overlap uses inner bounds', () {
      final conflicts = detectScheduleConflicts([
        _block('outer', 9, 12),
        _block('inner', 10, 11),
      ]);
      expect(conflicts, hasLength(1));
      expect(conflicts.first.overlapStart, DateTime.utc(2026, 8, 6, 10));
      expect(conflicts.first.overlapEnd, DateTime.utc(2026, 8, 6, 11));
    });

    test('three-way overlap yields three pairwise conflicts', () {
      final conflicts = detectScheduleConflicts([
        _block('a', 9, 12),
        _block('b', 10, 13),
        _block('c', 11, 14),
      ]);
      expect(conflicts, hasLength(3));
    });

    test('tasks without estimated minutes are excluded from detection', () {
      final task = ScheduleTimelineItem.fromTask(
        ColonyTask(
          id: const EntityId('task-1'),
          profileId: const EntityId('profile-1'),
          title: 'Sem duração',
          status: TaskStatus.scheduled,
          sourceType: SourceType.manual,
          scheduledStart: DateTime.utc(2026, 8, 6, 10),
          createdAt: DateTime.utc(2026, 8, 6),
          updatedAt: DateTime.utc(2026, 8, 6),
        ),
      );
      expect(task.isConflictEligible, isFalse);

      final conflicts = detectScheduleConflicts([
        _block('a', 9, 11),
        task,
      ]);
      expect(conflicts, isEmpty);
    });

    test('tasks with estimated minutes participate in conflicts', () {
      final task = ScheduleTimelineItem.fromTask(
        ColonyTask(
          id: const EntityId('task-1'),
          profileId: const EntityId('profile-1'),
          title: 'Com duração',
          status: TaskStatus.scheduled,
          sourceType: SourceType.manual,
          scheduledStart: DateTime.utc(2026, 8, 6, 10),
          estimatedMinutes: 60,
          createdAt: DateTime.utc(2026, 8, 6),
          updatedAt: DateTime.utc(2026, 8, 6),
        ),
      );
      expect(task.isConflictEligible, isTrue);

      final conflicts = detectScheduleConflicts([
        _block('a', 9, 11),
        task,
      ]);
      expect(conflicts, hasLength(1));
    });
  });

  group('scheduleConflictItemIds', () {
    test('collects ids from all conflicts', () {
      final conflicts = detectScheduleConflicts([
        _block('a', 9, 12),
        _block('b', 10, 13),
        _block('c', 11, 14),
      ]);
      expect(
        scheduleConflictItemIds(conflicts),
        {'a', 'b', 'c'},
      );
    });
  });
}
