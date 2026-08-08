import 'package:colony_domain/colony_domain.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/app_providers.dart';
import 'work_providers.dart';

class WorkBootstrapController extends AsyncNotifier<void> {
  @override
  Future<void> build() async {}

  Future<void> ensureSeeded() async {
    if (state.isLoading) return;
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final profile = await ref.read(repositoriesProvider).profiles.getActive();
      if (profile == null) return;
      await ref.read(repositoriesProvider).workPriorities.seedDefaults(profile.id);
      ref.invalidate(workPrioritiesProvider);
    });
  }
}

final workBootstrapProvider =
    AsyncNotifierProvider<WorkBootstrapController, void>(WorkBootstrapController.new);

class WorkPriorityController extends AsyncNotifier<void> {
  @override
  Future<void> build() async {}

  Future<void> cycle(WorkPriority priority) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await ref.read(repositoriesProvider).workPriorities.cyclePriority(priority);
    });
  }
}

final workPriorityControllerProvider =
    AsyncNotifierProvider<WorkPriorityController, void>(WorkPriorityController.new);

class BillController extends AsyncNotifier<void> {
  @override
  Future<void> build() async {}

  Future<void> create({
    required String title,
    BillRepeatMode repeatMode = BillRepeatMode.fixed,
    String target = '1',
  }) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final profile = await ref.read(repositoriesProvider).profiles.getActive();
      if (profile == null) throw StateError('Perfil não configurado');
      await ref.read(repositoriesProvider).bills.create(
            profileId: profile.id,
            title: title,
            repeatMode: repeatMode,
            target: target,
          );
    });
  }
}

final billControllerProvider =
    AsyncNotifierProvider<BillController, void>(BillController.new);

class ScheduleController extends AsyncNotifier<void> {
  @override
  Future<void> build() async {}

  Future<void> addBlock({
    required DateTime day,
    required int startHour,
    required int startMinute,
    required int endHour,
    required int endMinute,
    ScheduleBlockMode mode = ScheduleBlockMode.focus,
  }) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final profile = await ref.read(repositoriesProvider).profiles.getActive();
      if (profile == null) throw StateError('Perfil não configurado');

      final times = scheduleBlockUtcTimes(
        day: day,
        startHour: startHour,
        startMinute: startMinute,
        endHour: endHour,
        endMinute: endMinute,
      );
      assertScheduleBlockTimeRange(times.startAt, times.endAt);

      await ref.read(repositoriesProvider).schedule.create(
            profileId: profile.id,
            startAt: times.startAt,
            endAt: times.endAt,
            mode: mode,
          );
    });
  }

  Future<void> updateBlock({
    required ScheduleBlock block,
    required DateTime day,
    required int startHour,
    required int startMinute,
    required int endHour,
    required int endMinute,
    ScheduleBlockMode? mode,
  }) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final times = scheduleBlockUtcTimes(
        day: day,
        startHour: startHour,
        startMinute: startMinute,
        endHour: endHour,
        endMinute: endMinute,
      );
      assertScheduleBlockTimeRange(times.startAt, times.endAt);
      final updated = block.copyWith(
        startAt: times.startAt,
        endAt: times.endAt,
        mode: mode ?? block.mode,
        updatedAt: DateTime.now().toUtc(),
      );
      await ref.read(repositoriesProvider).schedule.save(updated);
    });
  }

  Future<void> deleteBlock(EntityId id) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await ref.read(repositoriesProvider).schedule.delete(id);
    });
  }
}

final scheduleControllerProvider =
    AsyncNotifierProvider<ScheduleController, void>(ScheduleController.new);
