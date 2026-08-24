import 'package:colony_domain/colony_domain.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/localization/app_strings.dart';
import '../../../core/providers/app_providers.dart';
import '../../projects/application/project_providers.dart';

enum TaskBacklogFilter { open, deadline, noDate, done }

class TaskBacklogView extends Notifier<({TaskBacklogFilter filter, bool groupByProject})> {
  @override
  ({TaskBacklogFilter filter, bool groupByProject}) build() =>
      (filter: TaskBacklogFilter.open, groupByProject: false);

  void setFilter(TaskBacklogFilter filter) =>
      state = (filter: filter, groupByProject: state.groupByProject);

  void toggleGroupByProject() =>
      state = (filter: state.filter, groupByProject: !state.groupByProject);
}

final taskBacklogViewProvider = NotifierProvider<
    TaskBacklogView, ({TaskBacklogFilter filter, bool groupByProject})>(
  TaskBacklogView.new,
);

final doneTasksProvider = StreamProvider<List<ColonyTask>>((ref) async* {
  final profile = await ref.watch(profileProvider.future);
  if (profile == null) {
    yield const [];
    return;
  }
  yield* ref.watch(repositoriesProvider).tasks.watchDone(profile.id);
});

final taskByIdProvider =
    StreamProvider.autoDispose.family<ColonyTask?, String>((ref, taskId) {
  return ref.watch(repositoriesProvider).tasks.watchById(EntityId(taskId));
});

final taskChildrenProvider =
    StreamProvider.autoDispose.family<List<ColonyTask>, String>((ref, taskId) {
  return ref.watch(repositoriesProvider).tasks.watchChildren(EntityId(taskId));
});

final taskChildProgressProvider =
    Provider.autoDispose.family<(int, int), String>((ref, taskId) {
  final children =
      ref.watch(taskChildrenProvider(taskId)).asData?.value ?? const [];
  return TaskCapabilityPolicy.subtaskProgress(children);
});

class TaskBacklogSection {
  const TaskBacklogSection({required this.title, required this.tasks});

  final String title;
  final List<ColonyTask> tasks;
}

final taskBacklogProvider = Provider<AsyncValue<List<ColonyTask>>>((ref) {
  final view = ref.watch(taskBacklogViewProvider);
  final now = ref.watch(clockProvider)();
  final source = view.filter == TaskBacklogFilter.done
      ? ref.watch(doneTasksProvider)
      : ref.watch(activeTasksProvider);
  return source.when(
    loading: () => const AsyncLoading(),
    error: AsyncError.new,
    data: (tasks) {
      var list = TaskCapabilityPolicy.topLevelOpen(tasks);
      if (view.filter == TaskBacklogFilter.done) {
        list = TaskCapabilityPolicy.topLevelDone(tasks);
      } else if (view.filter == TaskBacklogFilter.deadline) {
        list = [
          for (final task in list)
            if (task.dueAt != null) task,
        ];
      } else if (view.filter == TaskBacklogFilter.noDate) {
        list = [
          for (final task in list)
            if (task.dueAt == null && task.scheduledStart == null) task,
        ];
      }
      if (view.filter != TaskBacklogFilter.done) {
        list.sort((a, b) {
          final overdueA = TaskCapabilityPolicy.isOverdue(a, now) ? 0 : 1;
          final overdueB = TaskCapabilityPolicy.isOverdue(b, now) ? 0 : 1;
          final byOverdue = overdueA.compareTo(overdueB);
          if (byOverdue != 0) return byOverdue;
          return TaskCapabilityPolicy.compareBacklog(a, b);
        });
      }
      return AsyncData(list);
    },
  );
});

final taskBacklogSectionsProvider = Provider<AsyncValue<List<TaskBacklogSection>>>((ref) {
  final view = ref.watch(taskBacklogViewProvider);
  final tasksAsync = ref.watch(taskBacklogProvider);
  if (!view.groupByProject) {
    return tasksAsync.when(
      loading: () => const AsyncLoading(),
      error: AsyncError.new,
      data: (tasks) => AsyncData([
        if (tasks.isNotEmpty) TaskBacklogSection(title: '', tasks: tasks),
      ]),
    );
  }
  final projects = ref.watch(projectsProvider).asData?.value ?? const [];
  return tasksAsync.when(
    loading: () => const AsyncLoading(),
    error: AsyncError.new,
    data: (tasks) {
      final groups = TaskCapabilityPolicy.groupByProject(
        tasks: tasks,
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
