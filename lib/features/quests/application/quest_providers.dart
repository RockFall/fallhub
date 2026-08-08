import 'package:colony_domain/colony_domain.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/app_providers.dart';

final questsProvider = StreamProvider<List<Quest>>((ref) async* {
  final profile = await ref.watch(profileProvider.future);
  if (profile == null) {
    yield [];
    return;
  }
  yield* ref.watch(repositoriesProvider).quests.watchAll(profile.id);
});

final questProvider = StreamProvider.family<Quest?, String>((ref, questId) async* {
  final repos = ref.watch(repositoriesProvider);
  yield await repos.quests.getById(EntityId(questId));
  final profile = await ref.watch(profileProvider.future);
  if (profile == null) {
    yield null;
    return;
  }
  await for (final quests in repos.quests.watchAll(profile.id)) {
    yield quests.where((q) => q.id.value == questId).firstOrNull;
  }
});

final questLinkedTasksProvider =
    StreamProvider.family<List<ColonyTask>, String>((ref, questId) {
  final repos = ref.watch(repositoriesProvider);
  return repos.tasks.watchByQuest(EntityId(questId));
});

final questPrerequisitesProvider =
    StreamProvider.family<List<Quest>, String>((ref, questId) {
  final repos = ref.watch(repositoriesProvider);
  return repos.quests.watchPrerequisites(EntityId(questId));
});

final questPrerequisiteLinksProvider =
    FutureProvider<List<QuestPrerequisiteLink>>((ref) async {
  ref.watch(questsProvider);
  final profile = await ref.watch(profileProvider.future);
  if (profile == null) return [];
  return ref.read(repositoriesProvider).quests.listPrerequisiteLinks(profile.id);
});

final questChainProvider = Provider.family<List<QuestChainNode>, String>((ref, questId) {
  final questsAsync = ref.watch(questsProvider);
  final linksAsync = ref.watch(questPrerequisiteLinksProvider);
  return questsAsync.when(
    data: (quests) => linksAsync.when(
      data: (links) => buildQuestChain(
        focusQuestId: EntityId(questId),
        quests: quests,
        links: links,
      ),
      loading: () => const [],
      error: (_, __) => const [],
    ),
    loading: () => const [],
    error: (_, __) => const [],
  );
});

final questWaitingOnPrerequisitesProvider =
    Provider.family<bool, String>((ref, questId) {
  final questAsync = ref.watch(questProvider(questId));
  final prereqsAsync = ref.watch(questPrerequisitesProvider(questId));
  final quest = questAsync.asData?.value;
  final prereqs = prereqsAsync.asData?.value ?? const <Quest>[];
  if (quest == null) return false;
  return QuestPrerequisitePolicy.isWaitingOnPrerequisites(
    quest: quest,
    prerequisites: prereqs,
  );
});

final questBoardProvider = Provider<QuestBoardData>((ref) {
  final questsAsync = ref.watch(questsProvider);
  return questsAsync.when(
    data: (quests) => QuestBoardData(
      active: quests.where((q) => q.status == QuestStatus.active).toList(),
      paused: quests.where((q) => q.status == QuestStatus.paused).toList(),
      drafts: quests.where((q) => q.status == QuestStatus.draft).toList(),
      history: quests.where((q) => q.status.isHistoryBoard).toList(),
    ),
    loading: () => const QuestBoardData(),
    error: (_, __) => const QuestBoardData(),
  );
});

class QuestBoardData {
  const QuestBoardData({
    this.active = const [],
    this.paused = const [],
    this.drafts = const [],
    this.history = const [],
  });

  final List<Quest> active;
  final List<Quest> paused;
  final List<Quest> drafts;
  final List<Quest> history;

  bool get isEmpty =>
      active.isEmpty && paused.isEmpty && drafts.isEmpty && history.isEmpty;
}
