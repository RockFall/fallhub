import 'package:colony_domain/colony_domain.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/app_providers.dart';
import 'flashcard_providers.dart';

class FlashcardController extends AsyncNotifier<void> {
  @override
  Future<void> build() async {}

  Future<T?> _run<T>(Future<T> Function() body) async {
    state = const AsyncLoading();
    try {
      final result = await body();
      state = const AsyncData(null);
      return result;
    } catch (error, stackTrace) {
      state = AsyncError(error, stackTrace);
      rethrow;
    }
  }

  Future<KnowledgeArea?> createArea({
    required String title,
    EntityId? parentId,
    String? description,
  }) {
    return _run(() async {
      final profile = await ref.read(profileProvider.future);
      if (profile == null) throw StateError('Perfil não configurado');
      return ref.read(repositoriesProvider).flashcards.createArea(
            profileId: profile.id,
            title: title,
            parentId: parentId,
            description: description,
          );
    });
  }

  Future<void> updateArea(KnowledgeArea area) {
    return _run(() {
      return ref.read(repositoriesProvider).flashcards.updateArea(area);
    });
  }

  Future<List<KnowledgeArea>?> seedCatalog(Iterable<String> keys) {
    return _run(() async {
      final profile = await ref.read(profileProvider.future);
      if (profile == null) throw StateError('Perfil não configurado');
      return ref.read(repositoriesProvider).flashcards.seedCatalog(
            profileId: profile.id,
            keys: keys,
          );
    });
  }

  Future<void> addPlacement({
    required EntityId areaId,
    required EntityId parentAreaId,
  }) {
    return _run(() {
      return ref.read(repositoriesProvider).flashcards.addPlacement(
            areaId: areaId,
            parentAreaId: parentAreaId,
          );
    });
  }

  Future<void> removePlacement({
    required EntityId areaId,
    required EntityId parentAreaId,
  }) {
    return _run(() {
      return ref.read(repositoriesProvider).flashcards.removePlacement(
            areaId: areaId,
            parentAreaId: parentAreaId,
          );
    });
  }

  Future<void> linkResearch({
    required EntityId researchNodeId,
    required EntityId areaId,
    ResearchKnowledgeLinkKind kind = ResearchKnowledgeLinkKind.related,
  }) {
    return _run(() {
      return ref.read(repositoriesProvider).flashcards.linkResearch(
            researchNodeId: researchNodeId,
            areaId: areaId,
            kind: kind,
          );
    });
  }

  Future<void> unlinkResearch({
    required EntityId researchNodeId,
    required EntityId areaId,
  }) {
    return _run(() {
      return ref.read(repositoriesProvider).flashcards.unlinkResearch(
            researchNodeId: researchNodeId,
            areaId: areaId,
          );
    });
  }

  Future<FlashcardTag?> createTag({
    required String title,
    EntityId? parentId,
  }) {
    return _run(() async {
      final profile = await ref.read(profileProvider.future);
      if (profile == null) throw StateError('Perfil não configurado');
      return ref.read(repositoriesProvider).flashcards.createTag(
            profileId: profile.id,
            title: title,
            parentId: parentId,
          );
    });
  }

  Future<void> updateTag(FlashcardTag tag) {
    return _run(() {
      return ref.read(repositoriesProvider).flashcards.updateTag(tag);
    });
  }

  Future<void> applyCardTagLabels({
    required Flashcard card,
    required List<String> labels,
  }) {
    return _run(() {
      return ref.read(repositoriesProvider).flashcards.applyCardTagLabels(
            card: card,
            labels: labels,
          );
    });
  }

  Future<FlashcardDeck?> createDeck({
    required String title,
    EntityId? areaId,
    EntityId? researchNodeId,
    String? description,
    int newLimitPerDay = 20,
    int reviewLimitPerDay = 200,
  }) {
    return _run(() async {
      final profile = await ref.read(profileProvider.future);
      if (profile == null) throw StateError('Perfil não configurado');
      return ref.read(repositoriesProvider).flashcards.createDeck(
            profileId: profile.id,
            title: title,
            areaId: areaId,
            researchNodeId: researchNodeId,
            description: description,
            newLimitPerDay: newLimitPerDay,
            reviewLimitPerDay: reviewLimitPerDay,
          );
    });
  }

  Future<void> updateDeck(FlashcardDeck deck) {
    return _run(() {
      return ref.read(repositoriesProvider).flashcards.updateDeck(deck);
    });
  }

  Future<List<Flashcard>?> createCard({
    required EntityId deckId,
    required String front,
    required String back,
    FlashcardKind kind = FlashcardKind.basic,
    EntityId? areaId,
    String? extra,
    List<String> tags = const [],
    bool bidirectional = false,
    FlashcardScheduleMode scheduleMode = FlashcardScheduleMode.scheduled,
    int? priority,
  }) {
    return _run(() async {
      final profile = await ref.read(profileProvider.future);
      if (profile == null) throw StateError('Perfil não configurado');
      return ref.read(repositoriesProvider).flashcards.createCard(
            profileId: profile.id,
            deckId: deckId,
            front: front,
            back: back,
            kind: kind,
            areaId: areaId,
            extra: extra,
            tags: tags,
            bidirectional: bidirectional,
            scheduleMode: scheduleMode,
            priority: priority,
          );
    });
  }

  Future<void> updateCard(Flashcard card, {List<String>? tagLabels}) {
    return _run(() async {
      await ref.read(repositoriesProvider).flashcards.updateCard(card);
      if (tagLabels != null) {
        await ref.read(repositoriesProvider).flashcards.applyCardTagLabels(
              card: card,
              labels: tagLabels,
            );
      }
    });
  }

  Future<void> setPriority(Flashcard card, int priority) {
    return updateCard(card.copyWith(priority: priority));
  }

  Future<void> setSuspended(Flashcard card, bool suspended) {
    return _run(() {
      return ref.read(repositoriesProvider).flashcards.setSuspended(
            card,
            suspended,
          );
    });
  }

  Future<void> bury(Flashcard card) {
    return _run(() {
      return ref.read(repositoriesProvider).flashcards.bury(card);
    });
  }

  Future<void> scheduleCard(Flashcard card) {
    return _run(() {
      return ref.read(repositoriesProvider).flashcards.scheduleCard(card);
    });
  }

  Future<void> unscheduleCard(Flashcard card) {
    return _run(() {
      return ref.read(repositoriesProvider).flashcards.unscheduleCard(card);
    });
  }

  Future<List<EntityId>?> deleteCard(Flashcard card) {
    return _run(() {
      return ref.read(repositoriesProvider).flashcards.deleteCard(card);
    });
  }

  Future<int?> deleteCards(List<Flashcard> cards) {
    return _run(() {
      return ref.read(repositoriesProvider).flashcards.deleteCards(cards);
    });
  }

  Future<FlashcardReviewOutcome?> review({
    required Flashcard card,
    required FlashcardRating rating,
    int? durationMs,
  }) {
    return _run(() {
      return ref.read(repositoriesProvider).flashcards.review(
            card: card,
            rating: rating,
            durationMs: durationMs,
          );
    });
  }

  Future<FlashcardReviewLog?> practice({
    required Flashcard card,
    required FlashcardRating rating,
    int? durationMs,
  }) {
    return _run(() {
      return ref.read(repositoriesProvider).flashcards.practice(
            card: card,
            rating: rating,
            durationMs: durationMs,
          );
    });
  }

  Future<void> undoReview(FlashcardReviewOutcome outcome) {
    return _run(() {
      return ref.read(repositoriesProvider).flashcards.undoReview(
            outcome: outcome,
          );
    });
  }

  Future<void> undoPractice(FlashcardReviewLog log) {
    return _run(() {
      return ref.read(repositoriesProvider).flashcards.undoPractice(log);
    });
  }

  FlashcardJsonImportPlan previewJson(String source) {
    return previewDocument(FlashcardJsonCodec.parse(source));
  }

  FlashcardJsonImportPlan previewDocument(FlashcardJsonDocument document) {
    return FlashcardJsonImportPolicy.plan(
      document: document,
      areas: ref.read(knowledgeAreasProvider).asData?.value ?? const [],
      placements: ref.read(knowledgePlacementsProvider).asData?.value ?? const [],
      decks: ref.read(flashcardDecksProvider).asData?.value ?? const [],
      cards: ref.read(flashcardsProvider).asData?.value ?? const [],
    );
  }

  Future<FlashcardJsonImportResult?> importJson(String source) {
    return importDocument(FlashcardJsonCodec.parse(source));
  }

  Future<FlashcardJsonImportResult?> importDocument(
    FlashcardJsonDocument document,
  ) {
    return _run(() async {
      final profile = await ref.read(profileProvider.future);
      if (profile == null) throw StateError('Perfil não configurado');
      return ref.read(repositoriesProvider).flashcards.importJson(
            profileId: profile.id,
            document: document,
          );
    });
  }
}

final flashcardControllerProvider =
    AsyncNotifierProvider<FlashcardController, void>(FlashcardController.new);
