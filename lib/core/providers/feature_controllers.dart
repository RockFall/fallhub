import 'package:colony_domain/colony_domain.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app_providers.dart';
import '../../features/decisions/application/decision_providers.dart';

class UndoController extends Notifier<UndoAction?> {
  @override
  UndoAction? build() => null;

  void push(UndoAction action) => state = action;

  void clear() => state = null;
}

final undoControllerProvider =
    NotifierProvider<UndoController, UndoAction?>(UndoController.new);

class CaptureController extends AsyncNotifier<void> {
  @override
  Future<void> build() async {}

  Future<ColonyTask?> capture(String title) async {
    if (title.trim().isEmpty) return null;
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final repos = ref.read(repositoriesProvider);
      final profile = await repos.profiles.getActive();
      if (profile == null) throw StateError('Perfil não configurado');
      final task = await repos.tasks.capture(
        profileId: profile.id,
        title: title.trim(),
      );
      ref.read(undoControllerProvider.notifier).push(
            UndoAction(
              id: EntityId(ref.read(idGeneratorProvider).newId()),
              type: UndoActionType.taskCreated,
              createdAt: ref.read(clockProvider)(),
              description: 'Captura: ${task.title}',
              taskId: task.id,
            ),
          );
    });
    if (state.hasError) return null;
    final profile = await ref.read(repositoriesProvider).profiles.getActive();
    if (profile == null) return null;
    final inbox = await ref.read(repositoriesProvider).tasks.watchInbox(profile.id).first;
    return inbox.isNotEmpty ? inbox.first : null;
  }

  Future<void> undoLast() async {
    final action = ref.read(undoControllerProvider);
    if (action == null) return;
    final repos = ref.read(repositoriesProvider);
    switch (action.type) {
      case UndoActionType.taskCreated:
        if (action.taskId != null) {
          final task = await repos.tasks.getById(action.taskId!);
          if (task != null) await repos.tasks.deleteSoft(task);
        }
      case UndoActionType.taskArchived:
      case UndoActionType.taskUpdated:
        if (action.taskBefore != null) {
          await repos.tasks.save(action.taskBefore!);
        }
    }
    ref.read(undoControllerProvider.notifier).clear();
  }
}

final captureControllerProvider =
    AsyncNotifierProvider<CaptureController, void>(CaptureController.new);

class OnboardingController extends AsyncNotifier<void> {
  @override
  Future<void> build() async {}

  Future<void> complete({
    required String colonyName,
    required String displayName,
    required List<String> sectors,
  }) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final repos = ref.read(repositoriesProvider);
      var profile = await repos.profiles.getActive();
      if (profile == null) {
        profile = await repos.profiles.create(
          colonyName: colonyName.trim(),
          displayName: displayName.trim(),
          timezone: DateTime.now().timeZoneName,
          locale: 'pt_BR',
          baseCurrency: 'BRL',
        );
        await repos.events.record(
          aggregateType: AggregateType.profile,
          aggregateId: profile.id,
          eventType: EventType.profileCreated,
          payload: {
            'colony_name': profile.colonyName,
            'display_name': profile.displayName,
          },
        );
      }

      final prefs = AppPreferences.defaults().copyWith(
        sectorsEnabled: sectors,
        onboardingCompleted: true,
      );
      await repos.preferences.save(prefs);
      await repos.needs.seedDefaults(profile.id);
    });
    ref.invalidate(profileProvider);
    ref.invalidate(preferencesProvider);
    if (state.hasError) return;
    await ref.read(profileProvider.future);
    await ref.read(preferencesProvider.future);
  }
}

final onboardingControllerProvider =
    AsyncNotifierProvider<OnboardingController, void>(OnboardingController.new);

class TaskActionsController extends AsyncNotifier<void> {
  @override
  Future<void> build() async {}

  Future<void> updateStatus(ColonyTask task, TaskStatus status) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      ref.read(undoControllerProvider.notifier).push(
            UndoAction(
              id: EntityId(ref.read(idGeneratorProvider).newId()),
              type: UndoActionType.taskUpdated,
              createdAt: ref.read(clockProvider)(),
              description: task.title,
              taskBefore: task,
              taskId: task.id,
            ),
          );
      await ref.read(repositoriesProvider).tasks.updateStatus(task, status);
    });
  }

  Future<void> archive(ColonyTask task) async {
    await updateStatus(task, TaskStatus.archived);
  }
}

final taskActionsControllerProvider =
    AsyncNotifierProvider<TaskActionsController, void>(TaskActionsController.new);

class ExportController extends AsyncNotifier<String?> {
  @override
  Future<String?> build() async => null;

  Future<String> exportJson() async {
    state = const AsyncLoading();
    late String json;
    state = await AsyncValue.guard(() async {
      json = await ref.read(repositoriesProvider).export.exportJson();
      await ref.read(repositoriesProvider).events.record(
            aggregateType: AggregateType.profile,
            aggregateId: EntityId('export'),
            eventType: EventType.exportCompleted,
            payload: {'format': 'json'},
          );
      return json;
    });
    if (state.hasError) throw state.error!;
    state = AsyncData(json);
    return json;
  }
}

final exportControllerProvider =
    AsyncNotifierProvider<ExportController, String?>(ExportController.new);

class RestoreController extends AsyncNotifier<void> {
  @override
  Future<void> build() async {}

  ExportSnapshot parseExport(String jsonString) {
    return ExportSnapshot.fromJsonString(jsonString);
  }

  Future<void> restore(ExportSnapshot snapshot) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await ref.read(repositoriesProvider).restore.restore(snapshot);
    });
    if (state.hasError) throw state.error!;
    ref.invalidate(profileProvider);
    ref.invalidate(preferencesProvider);
    ref.invalidate(decisionsProvider);
  }
}

final restoreControllerProvider =
    AsyncNotifierProvider<RestoreController, void>(RestoreController.new);
