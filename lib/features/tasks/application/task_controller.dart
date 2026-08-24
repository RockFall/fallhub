import 'package:colony_domain/colony_domain.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/app_providers.dart';
import '../../../core/providers/feature_controllers.dart';

class TaskBacklogController extends AsyncNotifier<void> {
  @override
  Future<void> build() async {}

  Future<ColonyTask?> createNamed(String title) async {
    final trimmed = title.trim();
    if (trimmed.isEmpty) return null;
    state = const AsyncLoading();
    ColonyTask? created;
    state = await AsyncValue.guard(() async {
      final profile = await ref.read(profileProvider.future);
      if (profile == null) throw StateError('Perfil não configurado');
      created = await ref.read(repositoriesProvider).tasks.createSimple(
            profileId: profile.id,
            title: trimmed,
          );
    });
    return created;
  }

  Future<ColonyTask?> addSubtask({
    required ColonyTask parent,
    required String title,
  }) async {
    final trimmed = title.trim();
    if (trimmed.isEmpty) return null;
    if (!TaskCapabilityPolicy.canHaveChildren(parent)) return null;
    state = const AsyncLoading();
    ColonyTask? created;
    state = await AsyncValue.guard(() async {
      created = await ref.read(repositoriesProvider).tasks.createSimple(
            profileId: parent.profileId,
            title: trimmed,
            parentTaskId: parent.id,
            projectId: parent.projectId,
          );
    });
    return created;
  }

  Future<void> toggleDone(ColonyTask task) async {
    final target =
        task.status == TaskStatus.done ? TaskStatus.next : TaskStatus.done;
    if (!TaskTransitionPolicy.canTransition(task.status, target)) return;
    await ref.read(taskActionsControllerProvider.notifier).updateStatus(
          task,
          target,
        );
  }
}

final taskBacklogControllerProvider =
    AsyncNotifierProvider<TaskBacklogController, void>(
  TaskBacklogController.new,
);
