import 'package:colony_domain/colony_domain.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/app_providers.dart';
import '../../projects/application/project_providers.dart';
import '../../research/application/research_providers.dart';
import 'quest_providers.dart';

class QuestController extends AsyncNotifier<void> {
  @override
  Future<void> build() async {}

  Future<Quest?> create({
    required String title,
    required String purpose,
    List<String> successCriteria = const [],
    List<String> risks = const [],
    DateTime? deadline,
  }) async {
    state = const AsyncLoading();
    Quest? created;
    state = await AsyncValue.guard(() async {
      final profile = await ref.read(repositoriesProvider).profiles.getActive();
      if (profile == null) throw StateError('Perfil não configurado');
      created = await ref.read(repositoriesProvider).quests.create(
            profileId: profile.id,
            title: title,
            purpose: purpose,
            successCriteria: successCriteria,
            risks: risks,
            deadline: deadline,
          );
    });
    if (state.hasError) return null;
    ref.invalidate(questsProvider);
    return created;
  }

  Future<void> acceptAndActivate(
    Quest quest, {
    required List<String> acceptanceAssumptions,
    DateTime? acceptanceDeadline,
  }) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await ref.read(repositoriesProvider).quests.acceptAndActivate(
            quest,
            acceptanceAssumptions: acceptanceAssumptions,
            acceptanceDeadline: acceptanceDeadline,
          );
    });
    ref.invalidate(questsProvider);
    ref.invalidate(questProvider(quest.id.value));
  }

  Future<void> updateFields(Quest quest) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await ref.read(repositoriesProvider).quests.save(quest);
    });
    ref.invalidate(questsProvider);
    ref.invalidate(questProvider(quest.id.value));
  }

  Future<void> activate(Quest quest) async {
    await _transition(quest, QuestStatus.active);
  }

  Future<void> pause(Quest quest, {String? reason}) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await ref.read(repositoriesProvider).quests.updateStatus(
            quest,
            QuestStatus.paused,
            pauseReason: reason,
          );
    });
    ref.invalidate(questsProvider);
    ref.invalidate(questProvider(quest.id.value));
  }

  Future<void> complete(Quest quest) async {
    await _transition(quest, QuestStatus.completed);
  }

  Future<void> abandon(Quest quest, {String? reason}) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await ref.read(repositoriesProvider).quests.updateStatus(
            quest,
            QuestStatus.abandoned,
            exitReason: reason,
          );
    });
    ref.invalidate(questsProvider);
    ref.invalidate(questProvider(quest.id.value));
  }

  Future<void> linkTask(Quest quest, ColonyTask task) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final repos = ref.read(repositoriesProvider);
      final linked = await repos.tasks.listByQuest(quest.id);
      for (final existing in linked) {
        if (existing.id != task.id) {
          await repos.tasks.linkToQuest(existing, null);
        }
      }
      await repos.tasks.linkToQuest(task, quest.id);
    });
    ref.invalidate(questLinkedTasksProvider(quest.id.value));
    ref.invalidate(activeTasksProvider);
  }

  Future<void> linkProject(Quest quest, EntityId projectId) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await ref.read(repositoriesProvider).projects.linkQuest(
            questId: quest.id,
            projectId: projectId,
          );
    });
    ref.invalidate(questLinkedProjectsProvider(quest.id.value));
  }

  Future<void> unlinkProject(Quest quest, EntityId projectId) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await ref.read(repositoriesProvider).projects.unlinkQuest(
            questId: quest.id,
            projectId: projectId,
          );
    });
    ref.invalidate(questLinkedProjectsProvider(quest.id.value));
  }

  Future<void> setLinkedProjects(Quest quest, List<EntityId> projectIds) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final repos = ref.read(repositoriesProvider);
      final current = await repos.projects.watchLinkedToQuest(quest.id).first;
      final currentIds = current.map((p) => p.id).toSet();
      final desired = projectIds.toSet();

      for (final project in current) {
        if (!desired.contains(project.id)) {
          await repos.projects.unlinkQuest(
            questId: quest.id,
            projectId: project.id,
          );
        }
      }
      for (final projectId in desired) {
        if (!currentIds.contains(projectId)) {
          await repos.projects.linkQuest(
            questId: quest.id,
            projectId: projectId,
          );
        }
      }
    });
    ref.invalidate(questLinkedProjectsProvider(quest.id.value));
  }

  Future<void> linkResearch(Quest quest, EntityId researchNodeId) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await ref.read(repositoriesProvider).research.linkQuest(
            questId: quest.id,
            researchNodeId: researchNodeId,
          );
    });
    ref.invalidate(questLinkedResearchProvider(quest.id.value));
    ref.invalidate(researchLinkedQuestsProvider(researchNodeId.value));
  }

  Future<void> unlinkResearch(Quest quest, EntityId researchNodeId) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await ref.read(repositoriesProvider).research.unlinkQuest(
            questId: quest.id,
            researchNodeId: researchNodeId,
          );
    });
    ref.invalidate(questLinkedResearchProvider(quest.id.value));
    ref.invalidate(researchLinkedQuestsProvider(researchNodeId.value));
  }

  Future<void> setLinkedResearch(Quest quest, List<EntityId> researchNodeIds) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final repos = ref.read(repositoriesProvider);
      final current = await repos.research.watchLinkedToQuest(quest.id).first;
      final currentIds = current.map((n) => n.id).toSet();
      final desired = researchNodeIds.toSet();

      for (final node in current) {
        if (!desired.contains(node.id)) {
          await repos.research.unlinkQuest(
            questId: quest.id,
            researchNodeId: node.id,
          );
        }
      }
      for (final nodeId in desired) {
        if (!currentIds.contains(nodeId)) {
          await repos.research.linkQuest(
            questId: quest.id,
            researchNodeId: nodeId,
          );
        }
      }
    });
    ref.invalidate(questLinkedResearchProvider(quest.id.value));
    for (final nodeId in researchNodeIds) {
      ref.invalidate(researchLinkedQuestsProvider(nodeId.value));
    }
  }

  Future<void> setPrerequisites(Quest quest, List<EntityId> prerequisiteIds) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final repos = ref.read(repositoriesProvider);
      final current = await repos.quests.listPrerequisites(quest.id);
      final currentIds = current.map((q) => q.id).toSet();
      final desired = prerequisiteIds.toSet();

      for (final prereq in current) {
        if (!desired.contains(prereq.id)) {
          await repos.quests.unlinkPrerequisite(
            questId: quest.id,
            prerequisiteQuestId: prereq.id,
          );
        }
      }
      for (final prereqId in desired) {
        if (!currentIds.contains(prereqId)) {
          await repos.quests.linkPrerequisite(
            questId: quest.id,
            prerequisiteQuestId: prereqId,
          );
        }
      }
    });
    ref.invalidate(questPrerequisitesProvider(quest.id.value));
    ref.invalidate(questPrerequisiteLinksProvider);
    ref.invalidate(questChainProvider(quest.id.value));
  }

  Future<void> unlinkPrerequisite(Quest quest, EntityId prerequisiteId) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await ref.read(repositoriesProvider).quests.unlinkPrerequisite(
            questId: quest.id,
            prerequisiteQuestId: prerequisiteId,
          );
    });
    ref.invalidate(questPrerequisitesProvider(quest.id.value));
    ref.invalidate(questPrerequisiteLinksProvider);
    ref.invalidate(questChainProvider(quest.id.value));
  }

  Future<ColonyTask?> quickCreateTask(Quest quest, String title) async {
    state = const AsyncLoading();
    ColonyTask? task;
    state = await AsyncValue.guard(() async {
      final repos = ref.read(repositoriesProvider);
      task = await repos.tasks.capture(
        profileId: quest.profileId,
        title: title,
      );
      final next = await repos.tasks.updateStatus(task!, TaskStatus.next);
      await linkTask(quest, next);
    });
    if (state.hasError) return null;
    return task;
  }

  Future<void> _transition(Quest quest, QuestStatus status) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await ref.read(repositoriesProvider).quests.updateStatus(quest, status);
    });
    ref.invalidate(questsProvider);
    ref.invalidate(questProvider(quest.id.value));
  }
}

final questControllerProvider =
    AsyncNotifierProvider<QuestController, void>(QuestController.new);
