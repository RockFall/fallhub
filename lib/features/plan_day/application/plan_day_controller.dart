import 'package:colony_domain/colony_domain.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/app_providers.dart';
import '../../../core/providers/feature_controllers.dart';
import 'plan_day_providers.dart';

class PlanDayController extends AsyncNotifier<void> {
  @override
  Future<void> build() async {}

  void _pushUndo(UndoAction action) {
    ref.read(undoControllerProvider.notifier).push(action);
  }

  EntityId _newUndoId() => EntityId(ref.read(idGeneratorProvider).newId());

  DateTime _now() => ref.read(clockProvider)();

  Future<DayPlanWithItems> _planFor(String localDate) async {
    final profile = await ref.read(profileProvider.future);
    if (profile == null) throw StateError('Perfil não configurado');
    return ref.read(repositoriesProvider).dayPlan.getOrCreateForDate(
          profile.id,
          localDate,
        );
  }

  Future<void> addAdHoc(String title) async {
    await _addAdHocOn(title, ref.read(planSelectedDayProvider));
  }

  Future<void> addAdHocToToday(String title) async {
    await _addAdHocOn(title, dayPlanLocalDateKey(ref.read(clockProvider)()));
  }

  Future<void> _addAdHocOn(String title, String localDate) async {
    if (!DayPlanPolicies.isValidItemTitle(title)) return;
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final plan = await _planFor(localDate);
      final item = await ref.read(repositoriesProvider).dayPlan.addAdHoc(
            dayPlanId: plan.plan.id,
            title: title,
          );
      _pushUndo(
        UndoAction(
          id: _newUndoId(),
          type: UndoActionType.dayPlanItemAdded,
          createdAt: _now(),
          description: item.title,
          dayPlanItemId: item.id,
        ),
      );
    });
  }

  Future<void> addFromSuggestion(ColonyTask task, {String? localDate}) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final plan = await _planFor(
        localDate ?? ref.read(planSelectedDayProvider),
      );
      try {
        final item = await ref.read(repositoriesProvider).dayPlan.pullTask(
              dayPlanId: plan.plan.id,
              task: task,
            );
        _pushUndo(
          UndoAction(
            id: _newUndoId(),
            type: UndoActionType.dayPlanItemAdded,
            createdAt: _now(),
            description: item.title,
            dayPlanItemId: item.id,
          ),
        );
      } on DuplicateLinkedTaskException {
        // Already on the plan — treat as success for the 1-tap path.
      }
    });
  }

  Future<DayPlanCompletionRejection> toggle(PlanRow row) async {
    var rejection = DayPlanCompletionRejection.none;
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final repos = ref.read(repositoriesProvider);
      final beforeItem = row.item;
      final beforeTask = row.linkedTask;
      final result = await repos.dayPlan.toggleComplete(row.item.id);
      rejection = result.rejection;
      if (result.isRejected) return;
      _pushUndo(
        UndoAction(
          id: _newUndoId(),
          type: UndoActionType.dayPlanItemToggled,
          createdAt: _now(),
          description: beforeItem.title,
          dayPlanItemBefore: beforeItem,
          dayPlanItemId: beforeItem.id,
          taskId: beforeTask?.id,
          taskBefore: beforeTask,
        ),
      );
    });
    return rejection;
  }

  Future<void> removeFromToday(DayPlanItem item) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await ref.read(repositoriesProvider).dayPlan.removeItem(item.id);
      _pushUndo(
        UndoAction(
          id: _newUndoId(),
          type: UndoActionType.dayPlanItemRemoved,
          createdAt: _now(),
          description: item.title,
          dayPlanItemBefore: item,
        ),
      );
    });
  }

  Future<void> rename(DayPlanItem item, String title) async {
    if (!DayPlanPolicies.isValidItemTitle(title)) return;
    await ref.read(repositoriesProvider).dayPlan.updateTitle(
          dayPlanItemId: item.id,
          title: title,
        );
  }

  Future<void> reorder(List<EntityId> orderedIds) async {
    final plan = ref.read(dayPlanProvider).asData?.value;
    if (plan == null) return;
    await ref.read(repositoriesProvider).dayPlan.reorder(
          dayPlanId: plan.plan.id,
          orderedItemIds: orderedIds,
        );
  }

  Future<void> carryOverAll(List<DayPlanItem> yesterdayItems) async {
    if (yesterdayItems.isEmpty) return;
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final profile = await ref.read(profileProvider.future);
      if (profile == null) return;
      final day = ref.read(planSelectedDayProvider);
      final repos = ref.read(repositoriesProvider);
      final target = await repos.dayPlan.getOrCreateForDate(profile.id, day);
      await repos.dayPlan.carryOverItems(
        sourceItems: yesterdayItems,
        targetDayPlanId: target.plan.id,
      );
    });
  }

  Future<void> carryOverOne(DayPlanItem source) async {
    await carryOverAll([source]);
  }

  Future<void> toggleTaskOnToday(ColonyTask task) async {
    final profile = await ref.read(profileProvider.future);
    if (profile == null) return;
    final today = dayPlanLocalDateKey(ref.read(clockProvider)());
    final repos = ref.read(repositoriesProvider);
    final plan = await repos.dayPlan.getOrCreateForDate(profile.id, today);
    final existing = await repos.dayPlan.findLinkedItem(
      dayPlanId: plan.plan.id,
      taskId: task.id,
    );
    if (existing != null) {
      await removeFromToday(existing);
      return;
    }
    await addFromSuggestion(task, localDate: today);
  }
}

final planDayControllerProvider =
    AsyncNotifierProvider<PlanDayController, void>(PlanDayController.new);
