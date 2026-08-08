import 'package:colony_domain/colony_domain.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/app_providers.dart';
import 'project_providers.dart';

class ProjectController extends AsyncNotifier<void> {
  @override
  Future<void> build() async {}

  Future<Project?> create({
    required String title,
    String? purpose,
  }) async {
    state = const AsyncLoading();
    Project? created;
    state = await AsyncValue.guard(() async {
      final profile = await ref.read(repositoriesProvider).profiles.getActive();
      if (profile == null) throw StateError('Perfil não configurado');
      created = await ref.read(repositoriesProvider).projects.create(
            profileId: profile.id,
            title: title,
            purpose: purpose,
          );
    });
    if (state.hasError) return null;
    ref.invalidate(projectsProvider);
    return created;
  }

  Future<void> updateFields(Project project) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await ref.read(repositoriesProvider).projects.save(project);
    });
    ref.invalidate(projectsProvider);
    ref.invalidate(projectProvider(project.id.value));
  }

  Future<void> complete(Project project) async {
    if (project.status != ProjectStatus.active) return;
    await updateFields(
      project.copyWith(
        status: ProjectStatus.completed,
        updatedAt: DateTime.now().toUtc(),
      ),
    );
  }

  Future<void> archive(Project project) async {
    if (project.status != ProjectStatus.completed) return;
    await updateFields(
      project.copyWith(
        status: ProjectStatus.archived,
        updatedAt: DateTime.now().toUtc(),
      ),
    );
  }

  Future<void> linkQuest({
    required EntityId questId,
    required EntityId projectId,
  }) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await ref.read(repositoriesProvider).projects.linkQuest(
            questId: questId,
            projectId: projectId,
          );
    });
    ref.invalidate(questLinkedProjectsProvider(questId.value));
    ref.invalidate(projectLinkedQuestsProvider(projectId.value));
  }

  Future<void> unlinkQuest({
    required EntityId questId,
    required EntityId projectId,
  }) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await ref.read(repositoriesProvider).projects.unlinkQuest(
            questId: questId,
            projectId: projectId,
          );
    });
    ref.invalidate(questLinkedProjectsProvider(questId.value));
    ref.invalidate(projectLinkedQuestsProvider(projectId.value));
  }
}

final projectControllerProvider =
    AsyncNotifierProvider<ProjectController, void>(ProjectController.new);
