import 'package:equatable/equatable.dart';

import 'day_plan.dart';
import 'enums.dart';
import 'id_generator.dart';
import 'task.dart';

enum DayPlanCompletionRejection {
  none,
  linkedTaskBlocksCompletion,
}

class DayPlanCompletionResult extends Equatable {
  const DayPlanCompletionResult({
    required this.item,
    required this.rejection,
    this.taskStatusToApply,
  });

  final DayPlanItem item;
  final DayPlanCompletionRejection rejection;

  /// Status the caller must apply to the linked [ColonyTask], if any.
  final TaskStatus? taskStatusToApply;

  bool get isRejected => rejection != DayPlanCompletionRejection.none;

  @override
  List<Object?> get props => [item, rejection, taskStatusToApply];
}

class DuplicateLinkedTaskException implements Exception {
  DuplicateLinkedTaskException(this.taskId);
  final EntityId taskId;

  @override
  String toString() => 'Tarefa já está no plano: ${taskId.value}';
}

abstract final class DayPlanPolicies {
  static final RegExp _dateKeyPattern = RegExp(r'^\d{4}-\d{2}-\d{2}$');

  static bool isValidLocalDateKey(String value) {
    if (!_dateKeyPattern.hasMatch(value)) return false;
    final parts = value.split('-');
    final y = int.parse(parts[0]);
    final m = int.parse(parts[1]);
    final d = int.parse(parts[2]);
    if (m < 1 || m > 12) return false;
    final daysInMonth = DateTime(y, m + 1, 0).day;
    return d >= 1 && d <= daysInMonth;
  }

  static String snapshotTitle(String rawTitle) => rawTitle.trim();

  static bool isValidItemTitle(String title) => title.trim().isNotEmpty;

  static bool canPullTask({
    required Iterable<EntityId> linkedTaskIds,
    required EntityId taskId,
  }) =>
      !linkedTaskIds.contains(taskId);

  /// Linked completion is gated by [TaskTransitionPolicy]. Blocked, cancelled
  /// and archived tasks cannot be marked done from the plan.
  static bool canCompleteLinkedItem(TaskStatus taskStatus) =>
      TaskTransitionPolicy.canTransition(taskStatus, TaskStatus.done);

  static DayPlanCompletionResult completeItem({
    required DayPlanItem item,
    required ColonyTask? linkedTask,
    required DateTime at,
  }) {
    if (item.isDone) {
      return DayPlanCompletionResult(
        item: item,
        rejection: DayPlanCompletionRejection.none,
      );
    }
    if (linkedTask != null && !canCompleteLinkedItem(linkedTask.status)) {
      return DayPlanCompletionResult(
        item: item,
        rejection: DayPlanCompletionRejection.linkedTaskBlocksCompletion,
      );
    }
    return DayPlanCompletionResult(
      item: item.copyWith(
        completedAt: at,
        updatedAt: at,
        version: item.version + 1,
      ),
      rejection: DayPlanCompletionRejection.none,
      taskStatusToApply: linkedTask == null ? null : TaskStatus.done,
    );
  }

  static DayPlanCompletionResult uncompleteItem({
    required DayPlanItem item,
    required ColonyTask? linkedTask,
    required DateTime at,
  }) {
    if (!item.isDone) {
      return DayPlanCompletionResult(
        item: item,
        rejection: DayPlanCompletionRejection.none,
      );
    }
    final revertTask =
        linkedTask != null && linkedTask.status == TaskStatus.done;
    return DayPlanCompletionResult(
      item: item.copyWith(
        clearCompletedAt: true,
        updatedAt: at,
        version: item.version + 1,
      ),
      rejection: DayPlanCompletionRejection.none,
      taskStatusToApply: revertTask ? TaskStatus.next : null,
    );
  }

  static List<DayPlanItem> renumber(List<DayPlanItem> orderedItems) {
    return [
      for (var i = 0; i < orderedItems.length; i++)
        orderedItems[i].orderIndex == i
            ? orderedItems[i]
            : orderedItems[i].copyWith(orderIndex: i),
    ];
  }

  /// Copies unfinished items into a new plan. Idempotent via [carriedFromItemId]
  /// and existing linked-task uniqueness. Does not mutate the source plan.
  static List<DayPlanItem> carryOverUnfinished({
    required List<DayPlanItem> sourceItems,
    required Map<String, ColonyTask> linkedTasksById,
    required List<DayPlanItem> targetExistingItems,
    required EntityId targetDayPlanId,
    required List<EntityId> newIds,
    required DateTime now,
  }) {
    final alreadyLinked = targetExistingItems
        .map((e) => e.taskId?.value)
        .whereType<String>()
        .toSet();
    final alreadyCarried = targetExistingItems
        .map((e) => e.carriedFromItemId?.value)
        .whereType<String>()
        .toSet();

    var nextOrder = targetExistingItems.length;
    var idIndex = 0;
    final result = <DayPlanItem>[];
    for (final source in sourceItems) {
      if (source.isDone) continue;
      if (alreadyCarried.contains(source.id.value)) continue;
      final task = source.taskId == null
          ? null
          : linkedTasksById[source.taskId!.value];
      if (task != null && task.status.isTerminal) continue;
      if (source.taskId != null &&
          alreadyLinked.contains(source.taskId!.value)) {
        continue;
      }
      if (idIndex >= newIds.length) {
        throw ArgumentError('newIds insuficiente para o carry-over');
      }
      result.add(
        DayPlanItem.carriedOver(
          id: newIds[idIndex++],
          dayPlanId: targetDayPlanId,
          source: source,
          orderIndex: nextOrder++,
          createdAt: now,
          refreshedTitle: task?.title,
        ),
      );
    }
    return result;
  }

  /// Display-time done: own [DayPlanItem.completedAt] or a linked task already
  /// marked done elsewhere.
  static bool isVisuallyDone(DayPlanItem item, {ColonyTask? linkedTask}) {
    if (item.isDone) return true;
    return linkedTask?.status == TaskStatus.done;
  }

  static String originChip({ColonyTask? linkedTask}) {
    if (linkedTask == null) return 'today';
    if (linkedTask.status == TaskStatus.inbox) return 'inbox';
    return 'next';
  }
}
