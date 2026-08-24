import 'package:colony_domain/colony_domain.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/localization/app_strings.dart';
import '../../../core/providers/app_providers.dart';
import '../../projects/application/project_providers.dart';
import '../../tasks/application/task_providers.dart';

class PlanSelectedDay extends Notifier<String> {
  @override
  String build() => dayPlanLocalDateKey(ref.watch(clockProvider)());

  void select(String localDate) => state = localDate;
}

final planSelectedDayProvider =
    NotifierProvider<PlanSelectedDay, String>(PlanSelectedDay.new);

class PlanDayView extends Notifier<bool> {
  @override
  bool build() => false;

  void toggleGroupByProject() => state = !state;
}

final planDayGroupByProjectProvider =
    NotifierProvider<PlanDayView, bool>(PlanDayView.new);

class DayTaskLists {
  const DayTaskLists({required this.open, required this.done});

  final List<ColonyTask> open;
  final List<ColonyTask> done;

  int get total => open.length + done.length;
}

DayTaskLists _listsForDay(
  String day,
  List<ColonyTask> active,
  List<ColonyTask> done,
) {
  final open = [
    for (final task in active)
      if (TaskCapabilityPolicy.isOpenOnDay(task, day)) task,
  ]..sort(TaskCapabilityPolicy.compareBacklog);
  final completed = [
    for (final task in done)
      if (TaskCapabilityPolicy.isDoneOnDay(task, day)) task,
  ];
  return DayTaskLists(open: open, done: completed);
}

final planDayTasksProvider = Provider<AsyncValue<DayTaskLists>>((ref) {
  final day = ref.watch(planSelectedDayProvider);
  final activeAsync = ref.watch(activeTasksProvider);
  final doneAsync = ref.watch(doneTasksProvider);
  return activeAsync.when(
    loading: () => const AsyncLoading(),
    error: AsyncError.new,
    data: (active) => doneAsync.when(
      loading: () => AsyncData(_listsForDay(day, active, const [])),
      error: AsyncError.new,
      data: (done) => AsyncData(_listsForDay(day, active, done)),
    ),
  );
});

final planDaySectionsProvider =
    Provider<AsyncValue<List<TaskBacklogSection>>>((ref) {
  final grouped = ref.watch(planDayGroupByProjectProvider);
  final listsAsync = ref.watch(planDayTasksProvider);
  if (!grouped) {
    return listsAsync.when(
      loading: () => const AsyncLoading(),
      error: AsyncError.new,
      data: (lists) => AsyncData([
        if (lists.open.isNotEmpty)
          TaskBacklogSection(title: '', tasks: lists.open),
      ]),
    );
  }
  final projects = ref.watch(projectsProvider).asData?.value ?? const [];
  return listsAsync.when(
    loading: () => const AsyncLoading(),
    error: AsyncError.new,
    data: (lists) {
      final groups = TaskCapabilityPolicy.groupByProject(
        tasks: lists.open,
        projects: projects,
        ungroupedTitle: AppStrings.tasksNoProject,
      );
      return AsyncData([
        for (final group in groups)
          TaskBacklogSection(title: group.title, tasks: group.tasks),
      ]);
    },
  );
});

final planDayProgressProvider = Provider<(int, int)>((ref) {
  final lists = ref.watch(planDayTasksProvider).asData?.value;
  if (lists == null || lists.total == 0) return (0, 0);
  return (lists.done.length, lists.total);
});

final todayPlanTasksProvider = Provider<AsyncValue<DayTaskLists>>((ref) {
  final today = dayPlanLocalDateKey(ref.watch(clockProvider)());
  final activeAsync = ref.watch(activeTasksProvider);
  final doneAsync = ref.watch(doneTasksProvider);
  return activeAsync.when(
    loading: () => const AsyncLoading(),
    error: AsyncError.new,
    data: (active) => doneAsync.when(
      loading: () => AsyncData(_listsForDay(today, active, const [])),
      error: AsyncError.new,
      data: (done) => AsyncData(_listsForDay(today, active, done)),
    ),
  );
});

final todayPlanTaskIdsProvider = Provider<Set<String>>((ref) {
  final today = dayPlanLocalDateKey(ref.watch(clockProvider)());
  final active = ref.watch(activeTasksProvider).asData?.value ?? const [];
  return {
    for (final task in active)
      if (TaskCapabilityPolicy.isScheduledOn(task, today)) task.id.value,
  };
});
