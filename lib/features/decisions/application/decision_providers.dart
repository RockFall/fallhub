import 'package:colony_domain/colony_domain.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/app_providers.dart';

final decisionsProvider = StreamProvider<List<DecisionRecord>>((ref) async* {
  final profile = await ref.watch(profileProvider.future);
  if (profile == null) {
    yield [];
    return;
  }
  yield* ref.watch(repositoriesProvider).decisions.watchAll(profile.id);
});

final decisionProvider =
    StreamProvider.family<DecisionRecord?, String>((ref, decisionId) async* {
  final repos = ref.watch(repositoriesProvider);
  yield await repos.decisions.getById(EntityId(decisionId));
  final profile = await ref.watch(profileProvider.future);
  if (profile == null) {
    yield null;
    return;
  }
  await for (final decisions in repos.decisions.watchAll(profile.id)) {
    yield decisions.where((d) => d.id.value == decisionId).firstOrNull;
  }
});

final questLinkedDecisionsProvider =
    StreamProvider.family<List<DecisionRecord>, String>((ref, questId) {
  return ref.watch(repositoriesProvider).decisions.watchByQuest(EntityId(questId));
});
