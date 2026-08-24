import 'package:colony_domain/colony_domain.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/app_providers.dart';

class PlanRow {
  const PlanRow({
    required this.item,
    required this.title,
    required this.isDone,
    required this.origin,
    this.linkedTask,
  });

  final DayPlanItem item;
  final String title;
  final bool isDone;
  final String origin;
  final ColonyTask? linkedTask;
}

class PlanSelectedDay extends Notifier<String> {
  @override
  String build() => dayPlanLocalDateKey(ref.watch(clockProvider)());

  void select(String localDate) => state = localDate;
}

final planSelectedDayProvider =
    NotifierProvider<PlanSelectedDay, String>(PlanSelectedDay.new);

final dayPlanProvider = StreamProvider.autoDispose<DayPlanWithItems?>((ref) async* {
  final profile = await ref.watch(profileProvider.future);
  if (profile == null) {
    yield null;
    return;
  }
  final day = ref.watch(planSelectedDayProvider);
  yield* ref.watch(repositoriesProvider).dayPlan.watchForDate(profile.id, day);
});

final planLinkedTasksProvider =
    StreamProvider.autoDispose<Map<String, ColonyTask>>((ref) async* {
  final plan = ref.watch(dayPlanProvider).asData?.value;
  final ids = [
    for (final item in plan?.items ?? const <DayPlanItem>[])
      if (item.taskId != null) item.taskId!,
  ];
  if (ids.isEmpty) {
    yield const {};
    return;
  }
  yield* ref.watch(repositoriesProvider).tasks.watchByIds(ids).map(
        (tasks) => {for (final task in tasks) task.id.value: task},
      );
});

final planDayRowsProvider = Provider.autoDispose<AsyncValue<List<PlanRow>>>((ref) {
  final planAsync = ref.watch(dayPlanProvider);
  final tasksAsync = ref.watch(planLinkedTasksProvider);
  return planAsync.when(
    loading: () => const AsyncLoading(),
    error: AsyncError.new,
    data: (plan) {
      final items = plan?.items ?? const <DayPlanItem>[];
      return tasksAsync.when(
        loading: () => items.isEmpty
            ? const AsyncData(<PlanRow>[])
            : const AsyncLoading(),
        error: AsyncError.new,
        data: (tasks) => AsyncData([
          for (final item in items)
            PlanRow(
              item: item,
              title: item.title,
              isDone: DayPlanPolicies.isVisuallyDone(
                item,
                linkedTask: item.taskId == null
                    ? null
                    : tasks[item.taskId!.value],
              ),
              origin: DayPlanPolicies.originChip(
                linkedTask: item.taskId == null
                    ? null
                    : tasks[item.taskId!.value],
              ),
              linkedTask:
                  item.taskId == null ? null : tasks[item.taskId!.value],
            ),
        ]),
      );
    },
  );
});

final planDayProgressProvider = Provider.autoDispose<(int, int)>((ref) {
  final rows = ref.watch(planDayRowsProvider).asData?.value ?? const [];
  if (rows.isEmpty) return (0, 0);
  final done = rows.where((row) => row.isDone).length;
  return (done, rows.length);
});

bool _isPullableStatus(TaskStatus status) =>
    status == TaskStatus.inbox ||
    status == TaskStatus.next ||
    status == TaskStatus.scheduled ||
    status == TaskStatus.doing;

List<ColonyTask> _pullableTasks(Ref ref) {
  final active = ref.watch(activeTasksProvider).asData?.value ?? const [];
  final inbox = ref.watch(inboxTasksProvider).asData?.value ?? const [];
  final linkedIds = {
    for (final item
        in ref.watch(dayPlanProvider).asData?.value?.items ??
            const <DayPlanItem>[])
      if (item.taskId != null) item.taskId!.value,
  };
  final merged = <String, ColonyTask>{
    for (final task in [...inbox, ...active])
      if (_isPullableStatus(task.status) && !linkedIds.contains(task.id.value))
        task.id.value: task,
  };
  return merged.values.toList()
    ..sort((a, b) {
      final inboxFirst = (a.status == TaskStatus.inbox ? 0 : 1)
          .compareTo(b.status == TaskStatus.inbox ? 0 : 1);
      if (inboxFirst != 0) return inboxFirst;
      return a.title.toLowerCase().compareTo(b.title.toLowerCase());
    });
}

final planPullableTasksProvider = Provider.autoDispose<List<ColonyTask>>((ref) {
  return _pullableTasks(ref);
});

final planTaskSuggestionsProvider =
    Provider.autoDispose.family<List<ColonyTask>, String>((ref, query) {
  final list = ref.watch(planPullableTasksProvider);
  final q = query.trim().toLowerCase();
  if (q.isEmpty) return list.take(5).toList();
  return list
      .where((task) => task.title.toLowerCase().contains(q))
      .take(3)
      .toList();
});

final planCarryOverProvider =
    FutureProvider.autoDispose<List<DayPlanItem>>((ref) async {
  final profile = await ref.watch(profileProvider.future);
  if (profile == null) return [];
  final day = ref.watch(planSelectedDayProvider);
  final today = dayPlanLocalDateKey(ref.watch(clockProvider)());
  if (day != today) return [];
  final yesterday = dayPlanShiftDate(day, -1);
  final source = await ref
      .watch(repositoriesProvider)
      .dayPlan
      .getForDate(profile.id, yesterday);
  if (source == null || source.items.isEmpty) return [];
  final todayPlan = ref.watch(dayPlanProvider).asData?.value;
  final alreadyCarried = {
    for (final item in todayPlan?.items ?? const <DayPlanItem>[])
      if (item.carriedFromItemId != null) item.carriedFromItemId!.value,
  };
  final alreadyLinked = {
    for (final item in todayPlan?.items ?? const <DayPlanItem>[])
      if (item.taskId != null) item.taskId!.value,
  };
  final linkedIds = [
    for (final item in source.items)
      if (item.taskId != null) item.taskId!,
  ];
  final tasks = linkedIds.isEmpty
      ? <String, ColonyTask>{}
      : {
          for (final task in await ref
              .watch(repositoriesProvider)
              .tasks
              .watchByIds(linkedIds)
              .first)
            task.id.value: task,
        };
  return [
    for (final item in source.items)
      if (!DayPlanPolicies.isVisuallyDone(
            item,
            linkedTask: item.taskId == null ? null : tasks[item.taskId!.value],
          ) &&
          !alreadyCarried.contains(item.id.value) &&
          (item.taskId == null || !alreadyLinked.contains(item.taskId!.value)))
        item,
  ];
});

final todayPlanProvider = StreamProvider<DayPlanWithItems?>((ref) async* {
  final profile = await ref.watch(profileProvider.future);
  if (profile == null) {
    yield null;
    return;
  }
  yield* ref.watch(repositoriesProvider).dayPlan.watchForDate(
        profile.id,
        dayPlanLocalDateKey(ref.watch(clockProvider)()),
      );
});

final todayLinkedTasksProvider =
    StreamProvider<Map<String, ColonyTask>>((ref) async* {
  final plan = ref.watch(todayPlanProvider).asData?.value;
  final ids = [
    for (final item in plan?.items ?? const <DayPlanItem>[])
      if (item.taskId != null) item.taskId!,
  ];
  if (ids.isEmpty) {
    yield const {};
    return;
  }
  yield* ref.watch(repositoriesProvider).tasks.watchByIds(ids).map(
        (tasks) => {for (final task in tasks) task.id.value: task},
      );
});

List<PlanRow> planRowsFor(
  DayPlanWithItems? plan,
  Map<String, ColonyTask> tasks,
) {
  return [
    for (final item in plan?.items ?? const <DayPlanItem>[])
      PlanRow(
        item: item,
        title: item.title,
        isDone: DayPlanPolicies.isVisuallyDone(
          item,
          linkedTask: item.taskId == null ? null : tasks[item.taskId!.value],
        ),
        origin: DayPlanPolicies.originChip(
          linkedTask: item.taskId == null ? null : tasks[item.taskId!.value],
        ),
        linkedTask: item.taskId == null ? null : tasks[item.taskId!.value],
      ),
  ];
}

final todayPlanRowsProvider = Provider<AsyncValue<List<PlanRow>>>((ref) {
  final planAsync = ref.watch(todayPlanProvider);
  final tasksAsync = ref.watch(todayLinkedTasksProvider);
  return planAsync.when(
    loading: () => const AsyncLoading(),
    error: AsyncError.new,
    data: (plan) => tasksAsync.when(
      loading: () => plan == null || plan.items.isEmpty
          ? const AsyncData(<PlanRow>[])
          : const AsyncLoading(),
      error: AsyncError.new,
      data: (tasks) => AsyncData(planRowsFor(plan, tasks)),
    ),
  );
});

final todayPlanTaskIdsProvider = Provider<Set<String>>((ref) {
  final plan = ref.watch(todayPlanProvider).asData?.value;
  return {
    for (final item in plan?.items ?? const <DayPlanItem>[])
      if (item.taskId != null) item.taskId!.value,
  };
});
