import 'package:colony_domain/colony_domain.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/app_providers.dart';

class FlashcardController extends AsyncNotifier<void> {
  @override
  Future<void> build() async {}

  Future<T?> _run<T>(Future<T> Function() body) async {
    state = const AsyncLoading();
    T? result;
    state = await AsyncValue.guard(() async {
      result = await body();
    });
    return result;
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
          );
    });
  }

  Future<void> updateCard(Flashcard card) {
    return _run(() {
      return ref.read(repositoriesProvider).flashcards.updateCard(card);
    });
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

  Future<void> undoReview(FlashcardReviewOutcome outcome) {
    return _run(() {
      return ref.read(repositoriesProvider).flashcards.undoReview(
            outcome: outcome,
          );
    });
  }
}

final flashcardControllerProvider =
    AsyncNotifierProvider<FlashcardController, void>(FlashcardController.new);
