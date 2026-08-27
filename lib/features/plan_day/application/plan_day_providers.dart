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
  const DayTaskLists({
    required this.openDated,
    required this.openUndated,
    required this.done,
  });

  final List<ColonyTask> openDated;
  final List<ColonyTask> openUndated;
  final List<ColonyTask> done;

  List<ColonyTask> get open => [...openDated, ...openUndated];

  int get total => open.length + done.length;

  (int, int) get datedProgress {
    final datedDone = [
      for (final task in done)
        if (task.scheduledStart != null) task,
    ].length;
    return (datedDone, openDated.length + datedDone);
  }
}

class PlanDaySection {
  const PlanDaySection({required this.title, required this.groups});

  final String title;
  final List<TaskBacklogSection> groups;
}

DayTaskLists _listsForDay(
  String day,
  List<ColonyTask> active,
  List<ColonyTask> done,
) {
  final openDated = <ColonyTask>[];
  final openUndated = <ColonyTask>[];
  for (final task in active) {
    if (!TaskCapabilityPolicy.isOpenOnDay(task, day)) continue;
    if (TaskCapabilityPolicy.hasForDate(task)) {
      openDated.add(task);
    } else {
      openUndated.add(task);
    }
  }
  openDated.sort(TaskCapabilityPolicy.compareBacklog);
  openUndated.sort(TaskCapabilityPolicy.compareBacklog);
  final completed = [
    for (final task in done)
      if (TaskCapabilityPolicy.isDoneOnDay(task, day)) task,
  ];
  return DayTaskLists(
    openDated: openDated,
    openUndated: openUndated,
    done: completed,
  );
}

List<TaskBacklogSection> _groupsFor({
  required List<ColonyTask> tasks,
  required bool grouped,
  required List<Project> projects,
}) {
  if (tasks.isEmpty) return const [];
  if (!grouped) {
    return [TaskBacklogSection(title: '', tasks: tasks)];
  }
  return [
    for (final group in TaskCapabilityPolicy.groupByProject(
      tasks: tasks,
      projects: projects,
      ungroupedTitle: AppStrings.tasksNoProject,
    ))
      TaskBacklogSection(title: group.title, tasks: group.tasks),
  ];
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
    Provider<AsyncValue<List<PlanDaySection>>>((ref) {
  final grouped = ref.watch(planDayGroupByProjectProvider);
  final listsAsync = ref.watch(planDayTasksProvider);
  final projects = grouped
      ? (ref.watch(projectsProvider).asData?.value ?? const [])
      : const <Project>[];
  return listsAsync.when(
    loading: () => const AsyncLoading(),
    error: AsyncError.new,
    data: (lists) => AsyncData([
      if (lists.openDated.isNotEmpty)
        PlanDaySection(
          title: AppStrings.planDaySectionDated,
          groups: _groupsFor(
            tasks: lists.openDated,
            grouped: grouped,
            projects: projects,
          ),
        ),
      if (lists.openUndated.isNotEmpty)
        PlanDaySection(
          title: AppStrings.planDaySectionUndated,
          groups: _groupsFor(
            tasks: lists.openUndated,
            grouped: grouped,
            projects: projects,
          ),
        ),
    ]),
  );
});

final planDayProgressProvider = Provider<(int, int)>((ref) {
  final lists = ref.watch(planDayTasksProvider).asData?.value;
  if (lists == null) return (0, 0);
  return lists.datedProgress;
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
