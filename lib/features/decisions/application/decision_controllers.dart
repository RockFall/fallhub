import 'package:colony_domain/colony_domain.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/app_providers.dart';
import 'decision_providers.dart';

class DecisionController extends AsyncNotifier<void> {
  @override
  Future<void> build() async {}

  Future<DecisionRecord?> create({
    required String title,
    required String context,
    required String decision,
    List<String> alternatives = const [],
    List<String> criteria = const [],
    List<String> assumptions = const [],
    List<String> expectedOutcomes = const [],
    List<String> risks = const [],
    DecisionReversibility reversibility = DecisionReversibility.moderate,
    DateTime? reviewAt,
    EntityId? linkToQuestId,
  }) async {
    state = const AsyncLoading();
    DecisionRecord? created;
    state = await AsyncValue.guard(() async {
      final profile = await ref.read(repositoriesProvider).profiles.getActive();
      if (profile == null) throw StateError('Perfil não configurado');
      created = await ref.read(repositoriesProvider).decisions.create(
            profileId: profile.id,
            title: title,
            context: context,
            decision: decision,
            alternatives: alternatives,
            criteria: criteria,
            assumptions: assumptions,
            expectedOutcomes: expectedOutcomes,
            risks: risks,
            reversibility: reversibility,
            reviewAt: reviewAt,
          );
      if (linkToQuestId != null) {
        await ref.read(repositoriesProvider).decisions.linkQuest(
              questId: linkToQuestId,
              decisionId: created!.id,
            );
      }
    });
    if (state.hasError) return null;
    ref.invalidate(decisionsProvider);
    if (linkToQuestId != null) {
      ref.invalidate(questLinkedDecisionsProvider(linkToQuestId.value));
    }
    return created;
  }

  Future<void> updateFields(DecisionRecord record) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await ref.read(repositoriesProvider).decisions.save(record);
    });
    ref.invalidate(decisionsProvider);
    ref.invalidate(decisionProvider(record.id.value));
  }

  Future<void> linkQuest({
    required EntityId questId,
    required EntityId decisionId,
  }) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await ref.read(repositoriesProvider).decisions.linkQuest(
            questId: questId,
            decisionId: decisionId,
          );
    });
    ref.invalidate(questLinkedDecisionsProvider(questId.value));
  }

  Future<void> unlinkQuest({
    required EntityId questId,
    required EntityId decisionId,
  }) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await ref.read(repositoriesProvider).decisions.unlinkQuest(
            questId: questId,
            decisionId: decisionId,
          );
    });
    ref.invalidate(questLinkedDecisionsProvider(questId.value));
  }

  Future<void> setLinkedDecisions(
    EntityId questId,
    List<EntityId> decisionIds,
  ) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final repos = ref.read(repositoriesProvider);
      final current = await repos.decisions.watchByQuest(questId).first;
      final currentIds = current.map((d) => d.id).toSet();
      final desired = decisionIds.toSet();

      for (final id in currentIds.difference(desired)) {
        await repos.decisions.unlinkQuest(questId: questId, decisionId: id);
      }
      for (final id in desired.difference(currentIds)) {
        await repos.decisions.linkQuest(questId: questId, decisionId: id);
      }
    });
    ref.invalidate(questLinkedDecisionsProvider(questId.value));
  }

  Future<void> delete(EntityId id) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await ref.read(repositoriesProvider).decisions.delete(id);
    });
    ref.invalidate(decisionsProvider);
    ref.invalidate(decisionProvider(id.value));
  }
}

final decisionControllerProvider =
    AsyncNotifierProvider<DecisionController, void>(DecisionController.new);
