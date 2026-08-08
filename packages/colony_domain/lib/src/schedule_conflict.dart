import 'package:equatable/equatable.dart';

import 'schedule_block.dart';
import 'task.dart';

/// Kind of item rendered on the day schedule timeline.
enum ScheduleTimelineItemKind { block, task }

/// A timed entry on the schedule day view (block or task with times).
class ScheduleTimelineItem extends Equatable {
  const ScheduleTimelineItem({
    required this.id,
    required this.startAt,
    required this.endAt,
    required this.kind,
    required this.label,
    this.block,
    this.task,
  });

  final String id;
  final DateTime startAt;
  final DateTime endAt;
  final ScheduleTimelineItemKind kind;
  final String label;
  final ScheduleBlock? block;
  final ColonyTask? task;

  factory ScheduleTimelineItem.fromBlock(ScheduleBlock block, String label) {
    return ScheduleTimelineItem(
      id: block.id.value,
      startAt: block.startAt,
      endAt: block.endAt,
      kind: ScheduleTimelineItemKind.block,
      label: label,
      block: block,
    );
  }

  factory ScheduleTimelineItem.fromTask(ColonyTask task, {Duration? displayDuration}) {
    final start = task.scheduledStart!;
    final duration = task.estimatedMinutes != null
        ? Duration(minutes: task.estimatedMinutes!)
        : (displayDuration ?? const Duration(minutes: 30));
    return ScheduleTimelineItem(
      id: task.id.value,
      startAt: start,
      endAt: start.add(duration),
      kind: ScheduleTimelineItemKind.task,
      label: task.title,
      task: task,
    );
  }

  /// Tasks without [ColonyTask.estimatedMinutes] appear on the timeline but
  /// are excluded from overlap detection (spec: sparse task durations).
  bool get isConflictEligible =>
      kind == ScheduleTimelineItemKind.block ||
      (task?.estimatedMinutes != null);

  @override
  List<Object?> get props => [id, startAt, endAt, kind, label, block, task];
}

/// Overlap between two half-open intervals `[startAt, endAt)`.
class ScheduleConflict extends Equatable {
  const ScheduleConflict({
    required this.itemA,
    required this.itemB,
    required this.overlapStart,
    required this.overlapEnd,
  });

  final ScheduleTimelineItem itemA;
  final ScheduleTimelineItem itemB;
  final DateTime overlapStart;
  final DateTime overlapEnd;

  Duration get overlapDuration => overlapEnd.difference(overlapStart);

  @override
  List<Object?> get props => [itemA, itemB, overlapStart, overlapEnd];
}

/// Returns true when `[startA, endA)` and `[startB, endB)` overlap (half-open).
bool scheduleIntervalsOverlap(
  DateTime startA,
  DateTime endA,
  DateTime startB,
  DateTime endB,
) {
  return startA.isBefore(endB) && startB.isBefore(endA);
}

/// Overlap start for two half-open intervals, or null when they do not overlap.
DateTime? scheduleOverlapStart(
  DateTime startA,
  DateTime endA,
  DateTime startB,
  DateTime endB,
) {
  if (!scheduleIntervalsOverlap(startA, endA, startB, endB)) return null;
  return startA.isAfter(startB) ? startA : startB;
}

/// Overlap end for two half-open intervals, or null when they do not overlap.
DateTime? scheduleOverlapEnd(
  DateTime startA,
  DateTime endA,
  DateTime startB,
  DateTime endB,
) {
  if (!scheduleIntervalsOverlap(startA, endA, startB, endB)) return null;
  return endA.isBefore(endB) ? endA : endB;
}

/// Detects pairwise overlaps among [items] using half-open interval semantics.
List<ScheduleConflict> detectScheduleConflicts(List<ScheduleTimelineItem> items) {
  final eligible = items.where((item) => item.isConflictEligible).toList();
  final conflicts = <ScheduleConflict>[];

  for (var i = 0; i < eligible.length; i++) {
    for (var j = i + 1; j < eligible.length; j++) {
      final a = eligible[i];
      final b = eligible[j];
      final overlapStart = scheduleOverlapStart(
        a.startAt,
        a.endAt,
        b.startAt,
        b.endAt,
      );
      final overlapEnd = scheduleOverlapEnd(
        a.startAt,
        a.endAt,
        b.startAt,
        b.endAt,
      );
      if (overlapStart == null || overlapEnd == null) continue;
      conflicts.add(
        ScheduleConflict(
          itemA: a,
          itemB: b,
          overlapStart: overlapStart,
          overlapEnd: overlapEnd,
        ),
      );
    }
  }

  return conflicts;
}

/// Item ids participating in at least one conflict.
Set<String> scheduleConflictItemIds(List<ScheduleConflict> conflicts) {
  return {
    for (final conflict in conflicts) ...[conflict.itemA.id, conflict.itemB.id],
  };
}
