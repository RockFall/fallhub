import 'package:colony_domain/colony_domain.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/app_providers.dart';
import 'research_providers.dart';

class ResearchController extends AsyncNotifier<void> {
  @override
  Future<void> build() async {}

  Future<ResearchNode?> create({
    required String title,
    required ResearchNodeType type,
    String? description,
  }) async {
    state = const AsyncLoading();
    ResearchNode? created;
    state = await AsyncValue.guard(() async {
      final profile = await ref.read(repositoriesProvider).profiles.getActive();
      if (profile == null) throw StateError('Perfil não configurado');
      created = await ref.read(repositoriesProvider).research.create(
            profileId: profile.id,
            title: title,
            type: type,
            description: description,
          );
    });
    if (state.hasError) return null;
    ref.invalidate(researchNodesProvider);
    return created;
  }

  Future<void> updateFields(ResearchNode node) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await ref.read(repositoriesProvider).research.save(node);
    });
    ref.invalidate(researchNodesProvider);
    ref.invalidate(researchNodeProvider(node.id.value));
  }

  Future<void> setInResearch(ResearchNode node) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await ref.read(repositoriesProvider).research.updateStatus(
            node,
            ResearchNodeStatus.inResearch,
          );
    });
    ref.invalidate(researchNodesProvider);
    ref.invalidate(researchNodeProvider(node.id.value));
  }

  Future<void> setDemonstrated(ResearchNode node, {String? note}) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await ref.read(repositoriesProvider).research.updateStatus(
            node,
            ResearchNodeStatus.demonstrated,
            demonstratedNote: note,
          );
    });
    ref.invalidate(researchNodesProvider);
    ref.invalidate(researchNodeProvider(node.id.value));
  }

  Future<LearningSession?> logSession({
    required EntityId nodeId,
    required DateTime startedAt,
    required int durationMinutes,
    required LearningSessionMode mode,
    String? notes,
  }) async {
    state = const AsyncLoading();
    LearningSession? session;
    state = await AsyncValue.guard(() async {
      final profile = await ref.read(repositoriesProvider).profiles.getActive();
      if (profile == null) throw StateError('Perfil não configurado');
      session = await ref.read(repositoriesProvider).research.logSession(
            profileId: profile.id,
            nodeId: nodeId,
            startedAt: startedAt,
            durationMinutes: durationMinutes,
            mode: mode,
            notes: notes,
          );
    });
    if (state.hasError) return null;
    ref.invalidate(researchSessionsProvider(nodeId.value));
    return session;
  }

  Future<ResearchEvidence?> addEvidence({
    required EntityId nodeId,
    required ResearchEvidenceType type,
    required String title,
    required String body,
    EntityId? sessionId,
  }) async {
    state = const AsyncLoading();
    ResearchEvidence? evidence;
    state = await AsyncValue.guard(() async {
      final profile = await ref.read(repositoriesProvider).profiles.getActive();
      if (profile == null) throw StateError('Perfil não configurado');
      evidence = await ref.read(repositoriesProvider).research.addEvidence(
            profileId: profile.id,
            nodeId: nodeId,
            type: type,
            title: title,
            body: body,
            sessionId: sessionId,
          );
    });
    if (state.hasError) return null;
    ref.invalidate(researchEvidenceProvider(nodeId.value));
    return evidence;
  }

  Future<void> deleteEvidence({
    required EntityId nodeId,
    required EntityId evidenceId,
  }) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await ref
          .read(repositoriesProvider)
          .research
          .deleteEvidence(evidenceId);
    });
    ref.invalidate(researchEvidenceProvider(nodeId.value));
  }

  Future<void> archive(ResearchNode node) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await ref.read(repositoriesProvider).research.updateStatus(
            node,
            ResearchNodeStatus.archived,
          );
    });
    ref.invalidate(researchNodesProvider);
    ref.invalidate(researchNodeProvider(node.id.value));
  }

  Future<void> linkPrerequisite({
    required EntityId nodeId,
    required EntityId prerequisiteNodeId,
  }) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await ref.read(repositoriesProvider).research.linkPrerequisite(
            nodeId: nodeId,
            prerequisiteNodeId: prerequisiteNodeId,
          );
    });
    ref.invalidate(researchPrerequisitesProvider(nodeId.value));
    ref.invalidate(researchPrerequisiteLinksProvider);
  }

  Future<void> unlinkPrerequisite({
    required EntityId nodeId,
    required EntityId prerequisiteNodeId,
  }) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await ref.read(repositoriesProvider).research.unlinkPrerequisite(
            nodeId: nodeId,
            prerequisiteNodeId: prerequisiteNodeId,
          );
    });
    ref.invalidate(researchPrerequisitesProvider(nodeId.value));
    ref.invalidate(researchPrerequisiteLinksProvider);
  }

  Future<void> setLinkedQuests(
    ResearchNode node,
    List<EntityId> questIds,
  ) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final repos = ref.read(repositoriesProvider);
      final current = await repos.research.watchLinkedQuests(node.id).first;
      final currentIds = current.map((q) => q.id).toSet();
      final desired = questIds.toSet();

      for (final quest in current) {
        if (!desired.contains(quest.id)) {
          await repos.research.unlinkQuest(
            questId: quest.id,
            researchNodeId: node.id,
          );
        }
      }
      for (final questId in desired) {
        if (!currentIds.contains(questId)) {
          await repos.research.linkQuest(
            questId: questId,
            researchNodeId: node.id,
          );
        }
      }
    });
    ref.invalidate(researchLinkedQuestsProvider(node.id.value));
    for (final questId in questIds) {
      ref.invalidate(questLinkedResearchProvider(questId.value));
    }
  }

  Future<void> unlinkQuest({
    required ResearchNode node,
    required EntityId questId,
  }) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await ref.read(repositoriesProvider).research.unlinkQuest(
            questId: questId,
            researchNodeId: node.id,
          );
    });
    ref.invalidate(researchLinkedQuestsProvider(node.id.value));
    ref.invalidate(questLinkedResearchProvider(questId.value));
  }
}

final researchControllerProvider =
    AsyncNotifierProvider<ResearchController, void>(ResearchController.new);
