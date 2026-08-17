import 'package:equatable/equatable.dart';

import 'id_generator.dart';
import 'knowledge_area.dart';

enum FlashcardKind {
  basic,
  reverse,
  cloze,
  freeRecall,
  exercise,
  repertoire,
}

enum FlashcardSrsStatus {
  newCard,
  learning,
  review,
  relearning,
}

enum FlashcardRating {
  again,
  hard,
  good,
  easy,
}

class FlashcardDeck extends Equatable {
  const FlashcardDeck({
    required this.id,
    required this.profileId,
    required this.title,
    required this.newLimitPerDay,
    required this.reviewLimitPerDay,
    required this.createdAt,
    required this.updatedAt,
    this.areaId,
    this.researchNodeId,
    this.description,
    this.archivedAt,
    this.version = 1,
  });

  final EntityId id;
  final EntityId profileId;
  final EntityId? areaId;
  final EntityId? researchNodeId;
  final String title;
  final String? description;
  final int newLimitPerDay;
  final int reviewLimitPerDay;
  final DateTime? archivedAt;
  final DateTime createdAt;
  final DateTime updatedAt;
  final int version;

  bool get isArchived => archivedAt != null;

  factory FlashcardDeck.create({
    required EntityId id,
    required EntityId profileId,
    required String title,
    required DateTime createdAt,
    EntityId? areaId,
    EntityId? researchNodeId,
    String? description,
    int newLimitPerDay = 20,
    int reviewLimitPerDay = 200,
  }) {
    return FlashcardDeck(
      id: id,
      profileId: profileId,
      areaId: areaId,
      researchNodeId: researchNodeId,
      title: title.trim(),
      description: emptyToNull(description),
      newLimitPerDay: newLimitPerDay.clamp(0, 999),
      reviewLimitPerDay: reviewLimitPerDay.clamp(0, 9999),
      createdAt: createdAt,
      updatedAt: createdAt,
    );
  }

  FlashcardDeck copyWith({
    EntityId? areaId,
    EntityId? researchNodeId,
    String? title,
    String? description,
    int? newLimitPerDay,
    int? reviewLimitPerDay,
    DateTime? archivedAt,
    DateTime? updatedAt,
    int? version,
    bool clearArea = false,
    bool clearResearch = false,
    bool clearDescription = false,
    bool clearArchived = false,
  }) {
    return FlashcardDeck(
      id: id,
      profileId: profileId,
      areaId: clearArea ? null : (areaId ?? this.areaId),
      researchNodeId:
          clearResearch ? null : (researchNodeId ?? this.researchNodeId),
      title: title?.trim() ?? this.title,
      description:
          clearDescription ? null : (description ?? this.description),
      newLimitPerDay: newLimitPerDay ?? this.newLimitPerDay,
      reviewLimitPerDay: reviewLimitPerDay ?? this.reviewLimitPerDay,
      archivedAt: clearArchived ? null : (archivedAt ?? this.archivedAt),
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      version: version ?? this.version,
    );
  }

  @override
  List<Object?> get props => [
        id,
        profileId,
        areaId,
        researchNodeId,
        title,
        description,
        newLimitPerDay,
        reviewLimitPerDay,
        archivedAt,
        createdAt,
        updatedAt,
        version,
      ];
}

class Flashcard extends Equatable {
  const Flashcard({
    required this.id,
    required this.profileId,
    required this.deckId,
    required this.kind,
    required this.front,
    required this.back,
    required this.suspended,
    required this.createdAt,
    required this.updatedAt,
    this.areaId,
    this.extra,
    this.tags = const [],
    this.clozeIndex,
    this.reverseOfId,
    this.version = 1,
  });

  final EntityId id;
  final EntityId profileId;
  final EntityId deckId;
  final EntityId? areaId;
  final FlashcardKind kind;
  final String front;
  final String back;
  final String? extra;
  final List<String> tags;
  final int? clozeIndex;
  final EntityId? reverseOfId;
  final bool suspended;
  final DateTime createdAt;
  final DateTime updatedAt;
  final int version;

  factory Flashcard.create({
    required EntityId id,
    required EntityId profileId,
    required EntityId deckId,
    required String front,
    required String back,
    required DateTime createdAt,
    FlashcardKind kind = FlashcardKind.basic,
    EntityId? areaId,
    String? extra,
    List<String> tags = const [],
    int? clozeIndex,
    EntityId? reverseOfId,
    bool suspended = false,
  }) {
    return Flashcard(
      id: id,
      profileId: profileId,
      deckId: deckId,
      areaId: areaId,
      kind: kind,
      front: front.trim(),
      back: back.trim(),
      extra: emptyToNull(extra),
      tags: normalizeFlashcardTags(tags),
      clozeIndex: clozeIndex,
      reverseOfId: reverseOfId,
      suspended: suspended,
      createdAt: createdAt,
      updatedAt: createdAt,
    );
  }

  Flashcard copyWith({
    EntityId? deckId,
    EntityId? areaId,
    FlashcardKind? kind,
    String? front,
    String? back,
    String? extra,
    List<String>? tags,
    int? clozeIndex,
    bool? suspended,
    DateTime? updatedAt,
    int? version,
    bool clearArea = false,
    bool clearExtra = false,
  }) {
    return Flashcard(
      id: id,
      profileId: profileId,
      deckId: deckId ?? this.deckId,
      areaId: clearArea ? null : (areaId ?? this.areaId),
      kind: kind ?? this.kind,
      front: front?.trim() ?? this.front,
      back: back?.trim() ?? this.back,
      extra: clearExtra ? null : (extra ?? this.extra),
      tags: tags == null ? this.tags : normalizeFlashcardTags(tags),
      clozeIndex: clozeIndex ?? this.clozeIndex,
      reverseOfId: reverseOfId,
      suspended: suspended ?? this.suspended,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      version: version ?? this.version,
    );
  }

  @override
  List<Object?> get props => [
        id,
        profileId,
        deckId,
        areaId,
        kind,
        front,
        back,
        extra,
        tags,
        clozeIndex,
        reverseOfId,
        suspended,
        createdAt,
        updatedAt,
        version,
      ];
}

class FlashcardSrsState extends Equatable {
  const FlashcardSrsState({
    required this.cardId,
    required this.status,
    required this.easeFactor,
    required this.intervalDays,
    required this.repetitions,
    required this.lapses,
    required this.learningStepIndex,
    required this.leech,
    required this.dueAt,
    this.lastReviewedAt,
  });

  final EntityId cardId;
  final FlashcardSrsStatus status;
  final double easeFactor;
  final double intervalDays;
  final int repetitions;
  final int lapses;
  final int learningStepIndex;
  final bool leech;
  final DateTime dueAt;
  final DateTime? lastReviewedAt;

  factory FlashcardSrsState.fresh({
    required EntityId cardId,
    required DateTime createdAt,
  }) {
    return FlashcardSrsState(
      cardId: cardId,
      status: FlashcardSrsStatus.newCard,
      easeFactor: 2.5,
      intervalDays: 0,
      repetitions: 0,
      lapses: 0,
      learningStepIndex: 0,
      leech: false,
      dueAt: createdAt,
    );
  }

  FlashcardSrsState copyWith({
    FlashcardSrsStatus? status,
    double? easeFactor,
    double? intervalDays,
    int? repetitions,
    int? lapses,
    int? learningStepIndex,
    bool? leech,
    DateTime? dueAt,
    DateTime? lastReviewedAt,
  }) {
    return FlashcardSrsState(
      cardId: cardId,
      status: status ?? this.status,
      easeFactor: easeFactor ?? this.easeFactor,
      intervalDays: intervalDays ?? this.intervalDays,
      repetitions: repetitions ?? this.repetitions,
      lapses: lapses ?? this.lapses,
      learningStepIndex: learningStepIndex ?? this.learningStepIndex,
      leech: leech ?? this.leech,
      dueAt: dueAt ?? this.dueAt,
      lastReviewedAt: lastReviewedAt ?? this.lastReviewedAt,
    );
  }

  @override
  List<Object?> get props => [
        cardId,
        status,
        easeFactor,
        intervalDays,
        repetitions,
        lapses,
        learningStepIndex,
        leech,
        dueAt,
        lastReviewedAt,
      ];
}

class FlashcardReviewLog extends Equatable {
  const FlashcardReviewLog({
    required this.id,
    required this.cardId,
    required this.reviewedAt,
    required this.rating,
    required this.intervalDaysBefore,
    required this.intervalDaysAfter,
    required this.easeBefore,
    required this.easeAfter,
    this.durationMs,
  });

  final EntityId id;
  final EntityId cardId;
  final DateTime reviewedAt;
  final FlashcardRating rating;
  final double intervalDaysBefore;
  final double intervalDaysAfter;
  final double easeBefore;
  final double easeAfter;
  final int? durationMs;

  @override
  List<Object?> get props => [
        id,
        cardId,
        reviewedAt,
        rating,
        intervalDaysBefore,
        intervalDaysAfter,
        easeBefore,
        easeAfter,
        durationMs,
      ];
}

class FlashcardReviewOutcome extends Equatable {
  const FlashcardReviewOutcome({
    required this.previous,
    required this.next,
    required this.log,
    required this.becameLeech,
  });

  final FlashcardSrsState previous;
  final FlashcardSrsState next;
  final FlashcardReviewLog log;
  final bool becameLeech;

  @override
  List<Object?> get props => [previous, next, log, becameLeech];
}

class FlashcardValidationException implements Exception {
  FlashcardValidationException(this.message);
  final String message;

  @override
  String toString() => message;
}

abstract final class FlashcardPolicy {
  static void validateCard(Flashcard card) {
    if (card.front.isEmpty) {
      throw FlashcardValidationException('A frente do cartão é obrigatória.');
    }
    if (card.kind != FlashcardKind.freeRecall && card.back.isEmpty) {
      throw FlashcardValidationException('O verso do cartão é obrigatório.');
    }
    if (card.kind == FlashcardKind.cloze &&
        ClozeRenderer.indicesIn(card.front).isEmpty) {
      throw FlashcardValidationException(
        'Cartão cloze precisa de {{c1::texto}} na frente.',
      );
    }
  }
}

abstract final class ClozeRenderer {
  static final _pattern = RegExp(r'\{\{c(\d+)::(.+?)\}\}');

  static Set<int> indicesIn(String source) {
    return {
      for (final match in _pattern.allMatches(source))
        int.parse(match.group(1)!),
    };
  }

  static String prompt(String source, int clozeIndex) {
    return source.replaceAllMapped(_pattern, (match) {
      final index = int.parse(match.group(1)!);
      final text = match.group(2)!;
      if (index == clozeIndex) return '[…]';
      return text;
    });
  }

  static String answer(String source) {
    return source.replaceAllMapped(_pattern, (match) => match.group(2)!);
  }
}

List<String> normalizeFlashcardTags(Iterable<String> tags) {
  final seen = <String>{};
  final out = <String>[];
  for (final raw in tags) {
    final tag = raw.trim().toLowerCase();
    if (tag.isEmpty || !seen.add(tag)) continue;
    out.add(tag);
  }
  return out;
}
