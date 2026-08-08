import 'package:colony_domain/colony_domain.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/localization/app_strings.dart';
import '../../../core/providers/app_providers.dart';

final workPrioritiesProvider = StreamProvider<List<WorkPriority>>((ref) async* {
  final profile = await ref.watch(profileProvider.future);
  if (profile == null) {
    yield [];
    return;
  }
  yield* ref.watch(repositoriesProvider).workPriorities.watchAll(profile.id);
});

final billsProvider = StreamProvider<List<Bill>>((ref) async* {
  final profile = await ref.watch(profileProvider.future);
  if (profile == null) {
    yield [];
    return;
  }
  yield* ref.watch(repositoriesProvider).bills.watchAll(profile.id);
});

final scheduleDayProvider =
    StreamProvider.family<List<ScheduleBlock>, DateTime>((ref, day) async* {
  final profile = await ref.watch(profileProvider.future);
  if (profile == null) {
    yield [];
    return;
  }
  yield* ref.watch(repositoriesProvider).schedule.watchForDay(profile.id, day);
});

final scheduledTasksDayProvider =
    StreamProvider.family<List<ColonyTask>, DateTime>((ref, day) async* {
  final profile = await ref.watch(profileProvider.future);
  if (profile == null) {
    yield [];
    return;
  }
  yield* ref.watch(repositoriesProvider).tasks.watchScheduledForDay(profile.id, day);
});

final scheduleSelectedDayProvider = NotifierProvider<ScheduleSelectedDay, DateTime>(
  ScheduleSelectedDay.new,
);

class ScheduleSelectedDay extends Notifier<DateTime> {
  @override
  DateTime build() => scheduleCalendarDay(DateTime.now());

  void select(DateTime day) {
    state = scheduleCalendarDay(day);
  }
}

enum ScheduleViewMode {
  day,
  threeDay,
}

class ScheduleViewModeNotifier extends Notifier<ScheduleViewMode> {
  @override
  ScheduleViewMode build() => ScheduleViewMode.day;

  void select(ScheduleViewMode mode) {
    state = mode;
  }
}

final scheduleViewModeProvider =
    NotifierProvider<ScheduleViewModeNotifier, ScheduleViewMode>(
  ScheduleViewModeNotifier.new,
);

final scheduleThreeDayRangeProvider = Provider<List<DateTime>>((ref) {
  final anchor = ref.watch(scheduleSelectedDayProvider);
  return scheduleThreeDayRange(anchor);
});

List<ScheduleTimelineItem> buildScheduleTimelineItems({
  required List<ScheduleBlock> blocks,
  required List<ColonyTask> tasks,
}) {
  final items = <ScheduleTimelineItem>[
    for (final block in blocks)
      ScheduleTimelineItem.fromBlock(
        block,
        AppStrings.scheduleBlockModeLabel(block.mode),
      ),
    for (final task in tasks)
      if (task.scheduledStart != null)
        ScheduleTimelineItem.fromTask(task),
  ];
  items.sort((a, b) => a.startAt.compareTo(b.startAt));
  return items;
}

final scheduleTimelineItemsProvider =
    Provider.family<AsyncValue<List<ScheduleTimelineItem>>, DateTime>((ref, day) {
  final blocks = ref.watch(scheduleDayProvider(day));
  final tasks = ref.watch(scheduledTasksDayProvider(day));

  if (blocks.isLoading || tasks.isLoading) {
    return const AsyncLoading();
  }
  if (blocks.hasError) {
    return AsyncError(blocks.error!, blocks.stackTrace!);
  }
  if (tasks.hasError) {
    return AsyncError(tasks.error!, tasks.stackTrace!);
  }

  return AsyncData(
    buildScheduleTimelineItems(
      blocks: blocks.requireValue,
      tasks: tasks.requireValue,
    ),
  );
});

final scheduleConflictsProvider =
    Provider.family<AsyncValue<List<ScheduleConflict>>, DateTime>((ref, day) {
  final items = ref.watch(scheduleTimelineItemsProvider(day));
  return items.whenData(detectScheduleConflicts);
});
