import 'package:colony_domain/colony_domain.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/app_providers.dart';

final knowledgeAreasProvider = StreamProvider<List<KnowledgeArea>>((ref) async* {
  final profile = await ref.watch(profileProvider.future);
  if (profile == null) {
    yield [];
    return;
  }
  yield* ref.watch(repositoriesProvider).flashcards.watchAreas(profile.id);
});

final flashcardDecksProvider = StreamProvider<List<FlashcardDeck>>((ref) async* {
  final profile = await ref.watch(profileProvider.future);
  if (profile == null) {
    yield [];
    return;
  }
  yield* ref.watch(repositoriesProvider).flashcards.watchDecks(profile.id);
});

final flashcardsProvider = StreamProvider<List<Flashcard>>((ref) async* {
  final profile = await ref.watch(profileProvider.future);
  if (profile == null) {
    yield [];
    return;
  }
  yield* ref.watch(repositoriesProvider).flashcards.watchCards(profile.id);
});

final flashcardSrsProvider =
    StreamProvider<Map<EntityId, FlashcardSrsState>>((ref) async* {
  final profile = await ref.watch(profileProvider.future);
  if (profile == null) {
    yield {};
    return;
  }
  yield* ref.watch(repositoriesProvider).flashcards.watchSrs(profile.id).map(
        (list) => {for (final srs in list) srs.cardId: srs},
      );
});

final flashcardLogsProvider = StreamProvider<List<FlashcardReviewLog>>((ref) async* {
  final profile = await ref.watch(profileProvider.future);
  if (profile == null) {
    yield [];
    return;
  }
  yield* ref.watch(repositoriesProvider).flashcards.watchLogs(profile.id);
});

final knowledgeForestProvider = Provider<List<KnowledgeAreaNode>>((ref) {
  return ref.watch(knowledgeAreasProvider).maybeWhen(
        data: KnowledgeAreaPolicy.buildForest,
        orElse: () => const [],
      );
});

final flashcardSearchQueryProvider =
    NotifierProvider<FlashcardSearchQuery, String>(FlashcardSearchQuery.new);

class FlashcardSearchQuery extends Notifier<String> {
  @override
  String build() => '';

  void set(String query) => state = query;
}

final flashcardQueueCountsProvider = Provider<FlashcardQueueCounts>((ref) {
  final cards = ref.watch(flashcardsProvider).asData?.value ?? const [];
  final srs = ref.watch(flashcardSrsProvider).asData?.value ?? const {};
  final now = ref.watch(clockProvider)();
  return StudyQueuePolicy.counts(cards: cards, srsByCard: srs, now: now);
});

final flashcardHeatProvider = Provider<Map<EntityId, KnowledgeAreaHeat>>((ref) {
  final cards = ref.watch(flashcardsProvider).asData?.value ?? const [];
  final srs = ref.watch(flashcardSrsProvider).asData?.value ?? const {};
  final logs = ref.watch(flashcardLogsProvider).asData?.value ?? const [];
  final now = ref.watch(clockProvider)();
  return StudyQueuePolicy.heatByArea(
    cards: cards,
    srsByCard: srs,
    logs: logs,
    now: now,
  );
});

final flashcardForecastProvider = Provider<List<int>>((ref) {
  final srs = ref.watch(flashcardSrsProvider).asData?.value ?? const {};
  return StudyQueuePolicy.forecastDue(
    states: srs.values,
    now: ref.watch(clockProvider)(),
  );
});

final flashcardDeckProvider =
    Provider.family<FlashcardDeck?, String>((ref, deckId) {
  final decks = ref.watch(flashcardDecksProvider).asData?.value ?? const [];
  return decks.where((d) => d.id.value == deckId).firstOrNull;
});

final knowledgeAreaProvider =
    Provider.family<KnowledgeArea?, String>((ref, areaId) {
  final areas = ref.watch(knowledgeAreasProvider).asData?.value ?? const [];
  return areas.where((a) => a.id.value == areaId).firstOrNull;
});

final researchFlashcardDecksProvider =
    StreamProvider.family<List<FlashcardDeck>, String>((ref, nodeId) {
  return ref
      .watch(repositoriesProvider)
      .flashcards
      .watchDecksForResearch(EntityId(nodeId));
});
