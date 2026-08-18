import 'package:colony_domain/colony_domain.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/providers/app_providers.dart';

final knowledgeAreasProvider = StreamProvider<List<KnowledgeArea>>((ref) {
  final profile = ref.watch(profileProvider).asData?.value;
  if (profile == null) return const Stream.empty();
  return ref.watch(repositoriesProvider).flashcards.watchAreas(profile.id);
});

final knowledgePlacementsProvider =
    StreamProvider<List<KnowledgeAreaPlacement>>((ref) {
  final profile = ref.watch(profileProvider).asData?.value;
  if (profile == null) return const Stream.empty();
  return ref.watch(repositoriesProvider).flashcards.watchPlacements(profile.id);
});

final researchKnowledgeLinksProvider =
    StreamProvider<List<ResearchKnowledgeLink>>((ref) {
  final profile = ref.watch(profileProvider).asData?.value;
  if (profile == null) return const Stream.empty();
  return ref
      .watch(repositoriesProvider)
      .flashcards
      .watchResearchLinks(profile.id);
});

final flashcardDecksProvider = StreamProvider<List<FlashcardDeck>>((ref) {
  final profile = ref.watch(profileProvider).asData?.value;
  if (profile == null) return const Stream.empty();
  return ref.watch(repositoriesProvider).flashcards.watchDecks(profile.id);
});

final flashcardsProvider = StreamProvider<List<Flashcard>>((ref) {
  final profile = ref.watch(profileProvider).asData?.value;
  if (profile == null) return const Stream.empty();
  return ref.watch(repositoriesProvider).flashcards.watchCards(profile.id);
});

final flashcardSrsProvider =
    StreamProvider<Map<EntityId, FlashcardSrsState>>((ref) {
  final profile = ref.watch(profileProvider).asData?.value;
  if (profile == null) return const Stream.empty();
  return ref.watch(repositoriesProvider).flashcards.watchSrs(profile.id).map(
        (list) => {for (final srs in list) srs.cardId: srs},
      );
});

final flashcardLogsProvider = StreamProvider<List<FlashcardReviewLog>>((ref) {
  final profile = ref.watch(profileProvider).asData?.value;
  if (profile == null) return const Stream.empty();
  return ref.watch(repositoriesProvider).flashcards.watchLogs(profile.id);
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

final flashcardJsonPromptProvider = Provider<String>((ref) {
  return FlashcardJsonPromptBuilder.build(
    areas: ref.watch(knowledgeAreasProvider).asData?.value ?? const [],
    placements: ref.watch(knowledgePlacementsProvider).asData?.value ?? const [],
    decks: ref.watch(flashcardDecksProvider).asData?.value ?? const [],
  );
});

final flashcardTodayDigestProvider = Provider<FlashcardTodayDigest>((ref) {
  final cards = ref.watch(flashcardsProvider).asData?.value ?? const [];
  final srs = ref.watch(flashcardSrsProvider).asData?.value ?? const {};
  final decks = ref.watch(flashcardDecksProvider).asData?.value ?? const [];
  final logs = ref.watch(flashcardLogsProvider).asData?.value ?? const [];
  final now = ref.watch(clockProvider)();
  return FlashcardTodayDigestPolicy.build(
    cards: cards,
    srsByCard: srs,
    decks: decks,
    logs: logs,
    now: now,
  );
});

final flashcardQueueCountsProvider = Provider<FlashcardQueueCounts>((ref) {
  return ref.watch(flashcardTodayDigestProvider).dueNowByBucket;
});

final flashcardHeatProvider = Provider<Map<EntityId, KnowledgeAreaHeat>>((ref) {
  final cards = ref.watch(flashcardsProvider).asData?.value ?? const [];
  final srs = ref.watch(flashcardSrsProvider).asData?.value ?? const {};
  final logs = ref.watch(flashcardLogsProvider).asData?.value ?? const [];
  final areas = ref.watch(knowledgeAreasProvider).asData?.value ?? const [];
  final placements =
      ref.watch(knowledgePlacementsProvider).asData?.value ?? const [];
  final now = ref.watch(clockProvider)();
  return StudyQueuePolicy.heatByArea(
    cards: cards,
    srsByCard: srs,
    logs: logs,
    now: now,
    areas: areas,
    placements: placements,
    decks: ref.watch(flashcardDecksProvider).asData?.value ?? const [],
  );
});

final flashcardForecastProvider = Provider<List<int>>((ref) {
  final srs = ref.watch(flashcardSrsProvider).asData?.value ?? const {};
  return StudyQueuePolicy.forecastDue(
    states: srs.values,
    now: ref.watch(clockProvider)(),
  );
});

final flashcardPaceMetricsProvider = Provider<FlashcardPaceMetrics>((ref) {
  return FlashcardPacePolicy.metrics(
    cards: ref.watch(flashcardsProvider).asData?.value ?? const [],
    srsByCard: ref.watch(flashcardSrsProvider).asData?.value ?? const {},
    logs: ref.watch(flashcardLogsProvider).asData?.value ?? const [],
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

final researchKnowledgeShelvesProvider =
    StreamProvider.family<List<ResearchKnowledgeLink>, String>((ref, nodeId) {
  return ref
      .watch(repositoriesProvider)
      .flashcards
      .watchResearchLinksForNode(EntityId(nodeId));
});

const _disclaimerPrefsKey = 'flashcards.disclaimerDismissed';

class FlashcardDisclaimerDismissed extends AsyncNotifier<bool> {
  @override
  Future<bool> build() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(_disclaimerPrefsKey) ?? false;
    } catch (_) {
      return false;
    }
  }

  Future<void> dismiss() async {
    state = const AsyncData(true);
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_disclaimerPrefsKey, true);
    } catch (_) {}
  }
}

final flashcardDisclaimerDismissedProvider =
    AsyncNotifierProvider<FlashcardDisclaimerDismissed, bool>(
  FlashcardDisclaimerDismissed.new,
);

FlashcardDeck? mostRecentFlashcardDeck(List<FlashcardDeck> decks) {
  final visible = decks.where((d) => !d.isArchived).toList()
    ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
  return visible.firstOrNull;
}
