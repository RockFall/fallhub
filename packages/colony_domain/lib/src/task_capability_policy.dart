import 'day_plan.dart';
import 'enums.dart';
import 'id_generator.dart';
import 'project.dart';
import 'task.dart';

class TaskBacklogGroup {
  const TaskBacklogGroup({
    required this.projectId,
    required this.title,
    required this.tasks,
  });

  final EntityId? projectId;
  final String title;
  final List<ColonyTask> tasks;
}

class TaskCapabilityPolicy {
  const TaskCapabilityPolicy._();

  static bool isTopLevel(ColonyTask task) => task.parentTaskId == null;

  static bool canHaveChildren(ColonyTask task) => task.parentTaskId == null;

  static bool canBeChildOf({
    required ColonyTask child,
    required ColonyTask parent,
  }) {
    if (child.id == parent.id) return false;
    if (parent.parentTaskId != null) return false;
    return true;
  }

  static List<ColonyTask> childrenOf(
    Iterable<ColonyTask> all,
    EntityId parentId,
  ) {
    return [
      for (final task in all)
        if (task.parentTaskId == parentId && task.deletedAt == null) task,
    ];
  }

  static (int done, int total) subtaskProgress(Iterable<ColonyTask> children) {
    final visible = [
      for (final task in children)
        if (task.deletedAt == null && task.status != TaskStatus.archived) task,
    ];
    final done = visible.where((task) => task.status == TaskStatus.done).length;
    return (done, visible.length);
  }

  static bool isOverdue(ColonyTask task, DateTime now) {
    if (task.status.isTerminal) return false;
    final due = task.dueAt;
    if (due == null) return false;
    return _localDateOnly(due).isBefore(_localDateOnly(now));
  }

  static bool isDueOn(ColonyTask task, DateTime day) {
    final due = task.dueAt;
    if (due == null) return false;
    return _localDateOnly(due) == _localDateOnly(day);
  }

  static bool isForDate(ColonyTask task, DateTime day) {
    final start = task.scheduledStart;
    if (start == null) return false;
    return _localDateOnly(start) == _localDateOnly(day);
  }

  static bool hasForDate(ColonyTask task) => task.scheduledStart != null;

  static bool isScheduledOn(ColonyTask task, String localDate) {
    final start = task.scheduledStart;
    if (start == null) return false;
    return dayPlanLocalDateKey(start) == localDate;
  }

  /// Inbox stays capture-only; Hoje lists next/scheduled/doing/blocked/waiting.
  static bool isWorkableOnDay(ColonyTask task) {
    return task.isTopLevel &&
        task.deletedAt == null &&
        task.status.isActive &&
        task.status != TaskStatus.inbox;
  }

  /// Open top-level work tasks with no day mark (always listed) or marked for [localDate].
  static bool isOpenOnDay(ColonyTask task, String localDate) {
    if (!isWorkableOnDay(task)) return false;
    return !hasForDate(task) || isScheduledOn(task, localDate);
  }

  /// Done tasks marked for [localDate], or undated ones completed on that day.
  static bool isDoneOnDay(ColonyTask task, String localDate) {
    if (!task.isTopLevel ||
        task.deletedAt != null ||
        task.status != TaskStatus.done) {
      return false;
    }
    if (isScheduledOn(task, localDate)) return true;
    if (task.scheduledStart != null) return false;
    final completed = task.completedAt;
    return completed != null && dayPlanLocalDateKey(completed) == localDate;
  }

  static DateTime localMidnightUtc(DateTime now) {
    final local = now.toLocal();
    return DateTime(local.year, local.month, local.day).toUtc();
  }

  static DateTime localDateOnly(DateTime value) => _localDateOnly(value);

  static DateTime _localDateOnly(DateTime value) {
    final local = value.toLocal();
    return DateTime(local.year, local.month, local.day);
  }

  static int compareBacklog(ColonyTask a, ColonyTask b) {
    final byPriority = _rank(a.priority).compareTo(_rank(b.priority));
    if (byPriority != 0) return byPriority;
    final dueA = a.dueAt;
    final dueB = b.dueAt;
    if (dueA != null && dueB != null) {
      final byDue = dueA.compareTo(dueB);
      if (byDue != 0) return byDue;
    } else if (dueA != null) {
      return -1;
    } else if (dueB != null) {
      return 1;
    }
    return a.title.toLowerCase().compareTo(b.title.toLowerCase());
  }

  static int _rank(TaskPriority priority) => switch (priority) {
        TaskPriority.now => 0,
        TaskPriority.soon => 1,
        TaskPriority.none => 2,
        TaskPriority.later => 3,
      };

  static List<ColonyTask> topLevelOpen(Iterable<ColonyTask> tasks) {
    return [
      for (final task in tasks)
        if (task.isTopLevel &&
            task.deletedAt == null &&
            task.status.isActive)
          task,
    ]..sort(compareBacklog);
  }

  static List<ColonyTask> topLevelDone(Iterable<ColonyTask> tasks) {
    return [
      for (final task in tasks)
        if (task.isTopLevel &&
            task.deletedAt == null &&
            task.status == TaskStatus.done)
          task,
    ]..sort((a, b) {
        final ca = a.completedAt;
        final cb = b.completedAt;
        if (ca != null && cb != null) return cb.compareTo(ca);
        return b.updatedAt.compareTo(a.updatedAt);
      });
  }

  static List<TaskBacklogGroup> groupByProject({
    required List<ColonyTask> tasks,
    required List<Project> projects,
    required String ungroupedTitle,
  }) {
    final byId = {for (final project in projects) project.id.value: project};
    final buckets = <String?, List<ColonyTask>>{};
    for (final task in tasks) {
      buckets.putIfAbsent(task.projectId?.value, () => []).add(task);
    }
    final named = <TaskBacklogGroup>[];
    for (final project in projects) {
      final items = buckets.remove(project.id.value);
      if (items == null || items.isEmpty) continue;
      items.sort(compareBacklog);
      named.add(
        TaskBacklogGroup(
          projectId: project.id,
          title: project.title,
          tasks: items,
        ),
      );
    }
    named.sort((a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()));
    final leftoverKeys = buckets.keys.where((key) => key != null).toList();
    for (final key in leftoverKeys) {
      final items = buckets.remove(key)!;
      items.sort(compareBacklog);
      named.add(
        TaskBacklogGroup(
          projectId: EntityId(key!),
          title: byId[key]?.title ?? ungroupedTitle,
          tasks: items,
        ),
      );
    }
    final ungrouped = buckets.remove(null);
    if (ungrouped != null && ungrouped.isNotEmpty) {
      ungrouped.sort(compareBacklog);
      named.add(
        TaskBacklogGroup(
          projectId: null,
          title: ungroupedTitle,
          tasks: ungrouped,
        ),
      );
    }
    return named;
  }
}
