import 'package:colony_domain/colony_domain.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/app_providers.dart';

final projectsProvider = StreamProvider<List<Project>>((ref) async* {
  final profile = await ref.watch(profileProvider.future);
  if (profile == null) {
    yield [];
    return;
  }
  yield* ref.watch(repositoriesProvider).projects.watchAll(profile.id);
});

final projectProvider = StreamProvider.family<Project?, String>((ref, projectId) async* {
  final repos = ref.watch(repositoriesProvider);
  yield await repos.projects.getById(EntityId(projectId));
  final profile = await ref.watch(profileProvider.future);
  if (profile == null) {
    yield null;
    return;
  }
  await for (final projects in repos.projects.watchAll(profile.id)) {
    yield projects.where((p) => p.id.value == projectId).firstOrNull;
  }
});

final questLinkedProjectsProvider =
    StreamProvider.family<List<Project>, String>((ref, questId) {
  return ref.watch(repositoriesProvider).projects.watchLinkedToQuest(EntityId(questId));
});

final projectLinkedQuestsProvider =
    StreamProvider.family<List<Quest>, String>((ref, projectId) {
  return ref.watch(repositoriesProvider).projects.watchLinkedQuests(EntityId(projectId));
});

final projectListProvider = Provider<ProjectListData>((ref) {
  final projectsAsync = ref.watch(projectsProvider);
  return projectsAsync.when(
    data: (projects) => ProjectListData(
      active: projects.where((p) => p.status == ProjectStatus.active).toList(),
      completed: projects.where((p) => p.status == ProjectStatus.completed).toList(),
      archived: projects.where((p) => p.status == ProjectStatus.archived).toList(),
    ),
    loading: () => const ProjectListData(),
    error: (_, __) => const ProjectListData(),
  );
});

class ProjectListData {
  const ProjectListData({
    this.active = const [],
    this.completed = const [],
    this.archived = const [],
  });

  final List<Project> active;
  final List<Project> completed;
  final List<Project> archived;

  bool get isEmpty => active.isEmpty && completed.isEmpty && archived.isEmpty;
}
