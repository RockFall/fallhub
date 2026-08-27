import 'package:colony_domain/colony_domain.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/app_providers.dart';
import '../../../core/providers/feature_controllers.dart';
import '../../tasks/application/task_controller.dart';

class PlanDayController extends AsyncNotifier<void> {
  @override
  Future<void> build() async {}

  Future<ColonyTask?> createNamed(String title) {
    return ref.read(taskBacklogControllerProvider.notifier).createNamed(title);
  }

  Future<void> toggleDone(ColonyTask task) {
    return ref.read(taskBacklogControllerProvider.notifier).toggleDone(task);
  }

  Future<void> toggleMarkedForToday(ColonyTask task) async {
    final today = dayPlanLocalDateKey(ref.read(clockProvider)());
    final marked = TaskCapabilityPolicy.isScheduledOn(task, today);
    final now = ref.read(clockProvider)();
    final next = marked
        ? task.copyWith(
            clearScheduledStart: true,
            updatedAt: now,
          )
        : task.copyWith(
            scheduledStart: TaskCapabilityPolicy.localMidnightUtc(now),
            updatedAt: now,
          );
    await ref.read(taskActionsControllerProvider.notifier).save(task, next);
  }
}

final planDayControllerProvider =
    AsyncNotifierProvider<PlanDayController, void>(PlanDayController.new);
