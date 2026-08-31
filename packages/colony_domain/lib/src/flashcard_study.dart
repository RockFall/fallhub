import 'package:equatable/equatable.dart';

import 'flashcard.dart';
import 'flashcard_pace.dart';
import 'flashcard_srs.dart';
import 'id_generator.dart';
import 'knowledge_area.dart';
import 'knowledge_area_placement.dart';

class StudyCard extends Equatable {
  const StudyCard({
    required this.card,
    required this.srs,
    required this.prompt,
    required this.answer,
    this.extra,
    this.sessionMode = FlashcardStudySessionMode.scheduled,
  });

  final Flashcard card;
  final FlashcardSrsState srs;
  final String prompt;
  final String answer;
  final String? extra;
  final FlashcardStudySessionMode sessionMode;

  @override
  List<Object?> get props => [card, srs, prompt, answer, extra, sessionMode];
}

class FlashcardQueueCounts extends Equatable {
  const FlashcardQueueCounts({
    required this.newCount,
    required this.learningCount,
    required this.reviewCount,
  });

  final int newCount;
  final int learningCount;
  final int reviewCount;

  int get dueTotal => newCount + learningCount + reviewCount;

  @override
  List<Object?> get props => [newCount, learningCount, reviewCount];
}

class KnowledgeAreaHeat extends Equatable {
  const KnowledgeAreaHeat({
    required this.areaId,
    required this.cardCount,
    required this.dueCount,
    required this.retention,
  });

  final EntityId areaId;
  final int cardCount;
  final int dueCount;

  /// 0–1 from last 20 reviews in the area; null if no reviews.
  final double? retention;

  @override
  List<Object?> get props => [areaId, cardCount, dueCount, retention];
}

abstract final class FlashcardSchedulePolicy {
  static bool isInDueQueue(Flashcard card) =>
      !card.suspended && card.scheduleMode == FlashcardScheduleMode.scheduled;
}

class FlashcardTodayDigest extends Equatable {
  const FlashcardTodayDigest({
    required this.dueNowTotal,
    required this.dueNowByBucket,
    required this.sessionByBucket,
    required this.dueLaterToday,
    required this.unscheduledCount,
    required this.completedToday,
    required this.cappedForSession,
    required this.limitDeferred,
    required this.estimatedMinutes,
  });

  final int dueNowTotal;
  final FlashcardQueueCounts dueNowByBucket;

  /// Buckets the upcoming session will actually serve (after deck limits).
  final FlashcardQueueCounts sessionByBucket;
  final int dueLaterToday;
  final int unscheduledCount;
  final int completedToday;
  final int cappedForSession;
  final int limitDeferred;
  final int estimatedMinutes;

  @override
  List<Object?> get props => [
        dueNowTotal,
        dueNowByBucket,
        sessionByBucket,
        dueLaterToday,
        unscheduledCount,
        completedToday,
        cappedForSession,
        limitDeferred,
        estimatedMinutes,
      ];
}

/// Canonical shelf for a card: own area, else the deck's area.
abstract final class FlashcardAreaPolicy {
  static EntityId? effectiveAreaId(
    Flashcard card, {
    FlashcardDeck? deck,
    Map<EntityId, FlashcardDeck> decksById = const {},
  }) {
    if (card.areaId != null) return card.areaId;
    return deck?.areaId ?? decksById[card.deckId]?.areaId;
  }

  static String? pathLabelForCard({
    required Flashcard card,
    required List<KnowledgeArea> areas,
    FlashcardDeck? deck,
    Map<EntityId, FlashcardDeck> decksById = const {},
  }) {
    final areaId = effectiveAreaId(card, deck: deck, decksById: decksById);
    if (areaId == null) return null;
    final label = KnowledgeAreaPolicy.pathLabel(areaId: areaId, areas: areas);
    return label.trim().isEmpty ? null : label;
  }

  static bool isVisibleInArea({
    required Flashcard card,
    required EntityId rootId,
    required List<KnowledgeArea> areas,
    List<KnowledgeAreaPlacement> placements = const [],
    FlashcardDeck? deck,
    Map<EntityId, FlashcardDeck> decksById = const {},
  }) {
    final areaId = effectiveAreaId(card, deck: deck, decksById: decksById);
    if (areaId == null) return false;
    return KnowledgeAreaPolicy.descendantIds(
      rootId: rootId,
      areas: areas,
      placements: placements,
    ).contains(areaId);
  }

  /// Cards whose effective area sits in [rootId] (including aliases / subareas).
  static List<Flashcard> cardsInArea({
    required List<Flashcard> cards,
    required EntityId rootId,
    required List<KnowledgeArea> areas,
    List<KnowledgeAreaPlacement> placements = const [],
    List<FlashcardDeck> decks = const [],
  }) {
    final decksById = {for (final deck in decks) deck.id: deck};
    return [
      for (final card in cards)
        if (isVisibleInArea(
          card: card,
          rootId: rootId,
          areas: areas,
          placements: placements,
          decksById: decksById,
        ))
          card,
    ];
  }

  static bool canSpecialize({
    required EntityId? deckAreaId,
    required EntityId cardAreaId,
    required List<KnowledgeArea> areas,
    List<KnowledgeAreaPlacement> placements = const [],
  }) {
    if (deckAreaId == null) return true;
    if (cardAreaId == deckAreaId) return true;
    return KnowledgeAreaPolicy.descendantIds(
      rootId: deckAreaId,
      areas: areas,
      placements: placements,
    ).contains(cardAreaId);
  }

  static List<KnowledgeArea> specializationCandidates({
    required EntityId? deckAreaId,
    required List<KnowledgeArea> areas,
    List<KnowledgeAreaPlacement> placements = const [],
  }) {
    if (deckAreaId == null) return List<KnowledgeArea>.from(areas);
    final ids = KnowledgeAreaPolicy.descendantIds(
      rootId: deckAreaId,
      areas: areas,
      placements: placements,
    );
    return [for (final area in areas) if (ids.contains(area.id)) area];
  }
}

abstract final class FlashcardDailyUsagePolicy {
  static Map<EntityId, int> newIntroducedByDeck({
    required List<Flashcard> cards,
    required Map<EntityId, FlashcardSrsState> srsByCard,
    required List<FlashcardReviewLog> logs,
    required DateTime now,
  }) {
    final byId = {for (final card in cards) card.id: card};
    final firstSrs = <EntityId, FlashcardReviewLog>{};
    for (final log in logs) {
      if (log.reviewKind != FlashcardReviewKind.srs) continue;
      if (!StudyQueuePolicy.isSameLocalDay(log.reviewedAt, now)) continue;
      final existing = firstSrs[log.cardId];
      if (existing == null || log.reviewedAt.isBefore(existing.reviewedAt)) {
        firstSrs[log.cardId] = log;
      }
    }
    final out = <EntityId, int>{};
    for (final entry in firstSrs.entries) {
      final card = byId[entry.key];
      if (card == null) continue;
      final srs = srsByCard[card.id];
      if (srs == null) continue;
      if (srs.repetitions <= 1 &&
          (srs.status == FlashcardSrsStatus.learning ||
              srs.status == FlashcardSrsStatus.review)) {
        out[card.deckId] = (out[card.deckId] ?? 0) + 1;
      }
    }
    return out;
  }

  static Map<EntityId, int> reviewRepsByDeck({
    required List<Flashcard> cards,
    required List<FlashcardReviewLog> logs,
    required DateTime now,
  }) {
    final byId = {for (final card in cards) card.id: card};
    final out = <EntityId, int>{};
    for (final log in logs) {
      if (log.reviewKind != FlashcardReviewKind.srs) continue;
      if (!StudyQueuePolicy.isSameLocalDay(log.reviewedAt, now)) continue;
      if (log.intervalDaysBefore < 1) continue;
      final card = byId[log.cardId];
      if (card == null) continue;
      out[card.deckId] = (out[card.deckId] ?? 0) + 1;
    }
    return out;
  }
}

abstract final class FlashcardTodayDigestPolicy {
  static FlashcardTodayDigest build({
    required List<Flashcard> cards,
    required Map<EntityId, FlashcardSrsState> srsByCard,
    required List<FlashcardDeck> decks,
    required List<FlashcardReviewLog> logs,
    required DateTime now,
  }) {
    final scheduled = cards.where(FlashcardSchedulePolicy.isInDueQueue).toList();
    final buckets = StudyQueuePolicy.counts(
      cards: scheduled,
      srsByCard: srsByCard,
      now: now,
    );
    final later = StudyQueuePolicy.countDueLaterToday(
      cards: scheduled,
      srsByCard: srsByCard,
      now: now,
    );
    final unscheduled = cards
        .where(
          (c) =>
              !c.suspended &&
              c.scheduleMode == FlashcardScheduleMode.unscheduled,
        )
        .length;
    final completed = {
      for (final log in logs)
        if (log.reviewKind == FlashcardReviewKind.srs &&
            StudyQueuePolicy.isSameLocalDay(log.reviewedAt, now))
          log.cardId,
    }.length;

    final deckById = {for (final deck in decks) deck.id: deck};
    final newUsed = FlashcardDailyUsagePolicy.newIntroducedByDeck(
      cards: cards,
      srsByCard: srsByCard,
      logs: logs,
      now: now,
    );
    final reviewUsed = FlashcardDailyUsagePolicy.reviewRepsByDeck(
      cards: cards,
      logs: logs,
      now: now,
    );

    var sessionNew = 0;
    var sessionLearning = 0;
    var sessionReview = 0;
    final byDeck = <EntityId, List<Flashcard>>{};
    for (final card in scheduled) {
      byDeck.putIfAbsent(card.deckId, () => []).add(card);
    }
    for (final entry in byDeck.entries) {
      final deck = deckById[entry.key];
      final queue = StudyQueuePolicy.buildQueue(
        cards: entry.value,
        srsByCard: srsByCard,
        now: now,
        newRemaining: (deck?.newLimitPerDay ?? 20) - (newUsed[entry.key] ?? 0),
        reviewRemaining:
            (deck?.reviewLimitPerDay ?? 200) - (reviewUsed[entry.key] ?? 0),
        interleaveByArea: false,
        decks: decks,
      );
      for (final item in queue) {
        switch (item.srs.status) {
          case FlashcardSrsStatus.newCard:
            sessionNew++;
          case FlashcardSrsStatus.learning:
          case FlashcardSrsStatus.relearning:
            sessionLearning++;
          case FlashcardSrsStatus.review:
            sessionReview++;
        }
      }
    }
    final capped = sessionNew + sessionLearning + sessionReview;

    return FlashcardTodayDigest(
      dueNowTotal: buckets.dueTotal,
      dueNowByBucket: buckets,
      sessionByBucket: FlashcardQueueCounts(
        newCount: sessionNew,
        learningCount: sessionLearning,
        reviewCount: sessionReview,
      ),
      dueLaterToday: later,
      unscheduledCount: unscheduled,
      completedToday: completed,
      cappedForSession: capped,
      limitDeferred: (buckets.dueTotal - capped).clamp(0, buckets.dueTotal),
      estimatedMinutes: FlashcardPacePolicy.estimatedSessionMinutes(
        cardCount: capped,
        logs: logs,
      ),
    );
  }
}

abstract final class StudyQueuePolicy {
  static StudyCard present(
    Flashcard card,
    FlashcardSrsState srs, {
    FlashcardStudySessionMode sessionMode = FlashcardStudySessionMode.scheduled,
  }) {
    if (card.kind == FlashcardKind.cloze) {
      final index = card.clozeIndex ??
          (ClozeRenderer.indicesIn(card.front).isEmpty
              ? 1
              : ClozeRenderer.indicesIn(card.front).first);
      return StudyCard(
        card: card,
        srs: srs,
        prompt: ClozeRenderer.prompt(card.front, index),
        answer: ClozeRenderer.answer(card.front),
        extra: card.extra ?? (card.back.isEmpty ? null : card.back),
        sessionMode: sessionMode,
      );
    }
    return StudyCard(
      card: card,
      srs: srs,
      prompt: card.front,
      answer: card.back,
      extra: card.extra,
      sessionMode: sessionMode,
    );
  }

  static FlashcardQueueCounts counts({
    required List<Flashcard> cards,
    required Map<EntityId, FlashcardSrsState> srsByCard,
    required DateTime now,
  }) {
    var newCount = 0;
    var learningCount = 0;
    var reviewCount = 0;
    for (final card in cards) {
      if (!FlashcardSchedulePolicy.isInDueQueue(card)) continue;
      final srs = srsByCard[card.id] ??
          FlashcardSrsState.fresh(cardId: card.id, createdAt: card.createdAt);
      if (srs.dueAt.isAfter(now)) continue;
      switch (srs.status) {
        case FlashcardSrsStatus.newCard:
          newCount++;
        case FlashcardSrsStatus.learning:
        case FlashcardSrsStatus.relearning:
          learningCount++;
        case FlashcardSrsStatus.review:
          reviewCount++;
      }
    }
    return FlashcardQueueCounts(
      newCount: newCount,
      learningCount: learningCount,
      reviewCount: reviewCount,
    );
  }

  static List<StudyCard> buildQueue({
    required List<Flashcard> cards,
    required Map<EntityId, FlashcardSrsState> srsByCard,
    required DateTime now,
    required int newRemaining,
    required int reviewRemaining,
    bool interleaveByArea = true,
    List<FlashcardDeck> decks = const [],
    bool learningOnly = false,
  }) {
    final learning = <StudyCard>[];
    final reviews = <StudyCard>[];
    final news = <StudyCard>[];
    final decksById = {for (final deck in decks) deck.id: deck};

    for (final card in cards) {
      if (!FlashcardSchedulePolicy.isInDueQueue(card)) continue;
      final srs = srsByCard[card.id] ??
          FlashcardSrsState.fresh(cardId: card.id, createdAt: card.createdAt);
      if (srs.dueAt.isAfter(now)) continue;
      final item = present(card, srs);
      switch (srs.status) {
        case FlashcardSrsStatus.learning:
        case FlashcardSrsStatus.relearning:
          learning.add(item);
        case FlashcardSrsStatus.review:
          if (!learningOnly) reviews.add(item);
        case FlashcardSrsStatus.newCard:
          if (!learningOnly) news.add(item);
      }
    }

    learning.sort(_byPriorityThen((a, b) => a.srs.dueAt.compareTo(b.srs.dueAt)));
    reviews.sort(_byPriorityThen((a, b) => a.srs.dueAt.compareTo(b.srs.dueAt)));
    news.sort(
      _byPriorityThen((a, b) => a.card.createdAt.compareTo(b.card.createdAt)),
    );

    final limitedReviews =
        reviews.take(reviewRemaining.clamp(0, reviews.length));
    final limitedNews = news.take(newRemaining.clamp(0, news.length));
    final combined = [...learning, ...limitedReviews, ...limitedNews];
    if (!interleaveByArea) return combined;
    return _interleave(combined, decksById: decksById);
  }

  static int Function(StudyCard, StudyCard) _byPriorityThen(
    int Function(StudyCard a, StudyCard b) next,
  ) {
    return (a, b) {
      final byPriority = a.card.priority.compareTo(b.card.priority);
      if (byPriority != 0) return byPriority;
      final byNext = next(a, b);
      if (byNext != 0) return byNext;
      return a.card.id.value.compareTo(b.card.id.value);
    };
  }

  static List<StudyCard> _interleave(
    List<StudyCard> cards, {
    Map<EntityId, FlashcardDeck> decksById = const {},
  }) {
    final buckets = <String, List<StudyCard>>{};
    for (final card in cards) {
      final key = FlashcardAreaPolicy.effectiveAreaId(
            card.card,
            decksById: decksById,
          )?.value ??
          card.card.deckId.value;
      buckets.putIfAbsent(key, () => []).add(card);
    }
    final keys = buckets.keys.toList()..sort();
    final out = <StudyCard>[];
    var added = true;
    while (added) {
      added = false;
      for (final key in keys) {
        final bucket = buckets[key]!;
        if (bucket.isEmpty) continue;
        out.add(bucket.removeAt(0));
        added = true;
      }
    }
    return out;
  }

  static int countDueLaterToday({
    required List<Flashcard> cards,
    required Map<EntityId, FlashcardSrsState> srsByCard,
    required DateTime now,
  }) {
    final end = startOfNextLocalDay(now);
    var count = 0;
    for (final card in cards) {
      if (!FlashcardSchedulePolicy.isInDueQueue(card)) continue;
      final srs = srsByCard[card.id] ??
          FlashcardSrsState.fresh(cardId: card.id, createdAt: card.createdAt);
      if (srs.dueAt.isAfter(now) && !srs.dueAt.isAfter(end)) count++;
    }
    return count;
  }

  static List<StudyCard> buildPracticeQueue({
    required List<Flashcard> cards,
    required Map<EntityId, FlashcardSrsState> srsByCard,
    int limit = 20,
  }) {
    final out = <StudyCard>[];
    for (final card in cards) {
      if (card.suspended) continue;
      final srs = srsByCard[card.id] ??
          FlashcardSrsState.fresh(cardId: card.id, createdAt: card.createdAt);
      out.add(
        present(card, srs, sessionMode: FlashcardStudySessionMode.practice),
      );
    }
    out.sort(
      _byPriorityThen((a, b) => a.card.createdAt.compareTo(b.card.createdAt)),
    );
    return out.take(limit.clamp(0, out.length)).toList();
  }

  static DateTime startOfNextLocalDay(DateTime now) {
    final local = now.toLocal();
    return DateTime(local.year, local.month, local.day + 1).toUtc();
  }

  static bool isSameLocalDay(DateTime a, DateTime b) {
    final la = a.toLocal();
    final lb = b.toLocal();
    return la.year == lb.year && la.month == lb.month && la.day == lb.day;
  }

  static double? retention(Iterable<FlashcardReviewLog> logs, {int window = 20}) {
    final recent = logs.toList()
      ..sort((a, b) => b.reviewedAt.compareTo(a.reviewedAt));
    final slice = recent.take(window).toList();
    if (slice.isEmpty) return null;
    final good = slice
        .where(
          (log) =>
              log.rating == FlashcardRating.good ||
              log.rating == FlashcardRating.easy,
        )
        .length;
    return good / slice.length;
  }

  static Map<EntityId, KnowledgeAreaHeat> heatByArea({
    required List<Flashcard> cards,
    required Map<EntityId, FlashcardSrsState> srsByCard,
    required List<FlashcardReviewLog> logs,
    required DateTime now,
    List<KnowledgeArea> areas = const [],
    List<KnowledgeAreaPlacement> placements = const [],
    List<FlashcardDeck> decks = const [],
  }) {
    final logsByCard = <EntityId, List<FlashcardReviewLog>>{};
    for (final log in logs) {
      if (log.reviewKind != FlashcardReviewKind.srs) continue;
      logsByCard.putIfAbsent(log.cardId, () => []).add(log);
    }
    final decksById = {for (final deck in decks) deck.id: deck};

    KnowledgeAreaHeat heatFor(
      EntityId areaId,
      Iterable<Flashcard> subset,
    ) {
      final list = subset.toList();
      return KnowledgeAreaHeat(
        areaId: areaId,
        cardCount: list.length,
        dueCount: counts(
          cards: list,
          srsByCard: srsByCard,
          now: now,
        ).dueTotal,
        retention: retention([
          for (final card in list) ...?logsByCard[card.id],
        ]),
      );
    }

    if (areas.isEmpty) {
      final cardsByArea = <EntityId, List<Flashcard>>{};
      for (final card in cards) {
        final areaId = FlashcardAreaPolicy.effectiveAreaId(
          card,
          decksById: decksById,
        );
        if (areaId == null) continue;
        cardsByArea.putIfAbsent(areaId, () => []).add(card);
      }
      return {
        for (final entry in cardsByArea.entries)
          entry.key: heatFor(entry.key, entry.value),
      };
    }

    return {
      for (final area in areas)
        area.id: heatFor(
          area.id,
          cards.where(
            (card) => FlashcardAreaPolicy.isVisibleInArea(
              card: card,
              rootId: area.id,
              areas: areas,
              placements: placements,
              decksById: decksById,
            ),
          ),
        ),
    };
  }

  static List<Flashcard> cardsInArea({
    required List<Flashcard> cards,
    required EntityId rootId,
    required List<KnowledgeArea> areas,
    List<KnowledgeAreaPlacement> placements = const [],
    List<FlashcardDeck> decks = const [],
  }) {
    final decksById = {for (final deck in decks) deck.id: deck};
    return [
      for (final card in cards)
        if (FlashcardAreaPolicy.isVisibleInArea(
          card: card,
          rootId: rootId,
          areas: areas,
          placements: placements,
          decksById: decksById,
        ))
          card,
    ];
  }

  static List<Flashcard> cardsForResearch({
    required List<Flashcard> cards,
    required EntityId researchNodeId,
    required List<FlashcardDeck> decks,
    required List<ResearchKnowledgeLink> links,
    required List<KnowledgeArea> areas,
    List<KnowledgeAreaPlacement> placements = const [],
  }) {
    final linkedDecks = {
      for (final deck in decks)
        if (deck.researchNodeId == researchNodeId) deck.id,
    };
    final practiceAreas = {
      for (final link in links)
        if (link.researchNodeId == researchNodeId &&
            (link.kind == ResearchKnowledgeLinkKind.primary ||
                link.kind == ResearchKnowledgeLinkKind.practice))
          link.areaId,
    };
    final decksById = {for (final deck in decks) deck.id: deck};
    return [
      for (final card in cards)
        if (linkedDecks.contains(card.deckId) ||
            practiceAreas.any(
              (areaId) => FlashcardAreaPolicy.isVisibleInArea(
                card: card,
                rootId: areaId,
                areas: areas,
                placements: placements,
                decksById: decksById,
              ),
            ))
          card,
    ];
  }

  static String formatDueAt(DateTime dueAt, DateTime now) {
    if (!dueAt.isAfter(now)) return 'agora';
    return Sm2Scheduler.formatInterval(dueAt.difference(now));
  }

  static String? nextDuePhrase(FlashcardSrsState? srs, DateTime now) {
    if (srs == null) return null;
    if (srs.status == FlashcardSrsStatus.newCard && srs.lastReviewedAt == null) {
      return null;
    }
    return formatDueAt(srs.dueAt, now);
  }

  static List<String> forecastDayLabels(DateTime now, {int days = 7}) {
    const labels = ['dom', 'seg', 'ter', 'qua', 'qui', 'sex', 'sáb'];
    final start = now.toLocal();
    return [
      for (var i = 0; i < days; i++)
        labels[DateTime(start.year, start.month, start.day + i).weekday % 7],
    ];
  }

  static List<int> forecastDue({
    required Iterable<FlashcardSrsState> states,
    required DateTime now,
    int days = 7,
  }) {
    final out = List<int>.filled(days, 0);
    final start = DateTime(now.toLocal().year, now.toLocal().month, now.toLocal().day);
    for (final state in states) {
      if (state.status == FlashcardSrsStatus.newCard &&
          state.lastReviewedAt == null) {
        continue;
      }
      final due = state.dueAt.toLocal();
      final delta = DateTime(due.year, due.month, due.day).difference(start).inDays;
      if (delta >= 0 && delta < days) out[delta]++;
    }
    return out;
  }
}

abstract final class FlashcardSearch {
  static bool matches(Flashcard card, String query) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return true;
    if (card.front.toLowerCase().contains(q)) return true;
    if (card.back.toLowerCase().contains(q)) return true;
    if ((card.extra ?? '').toLowerCase().contains(q)) return true;
    return card.tags.any((tag) => tag.contains(q));
  }
}

/// Builds a Google search for the card's question (opens in the browser).
abstract final class FlashcardGoogleSearch {
  static String questionText(Flashcard card, {String? prompt}) {
    if (card.kind == FlashcardKind.cloze) {
      return ClozeRenderer.answer(card.front).trim();
    }
    final text = (prompt ?? card.front).trim();
    return text;
  }

  static Uri uriFor(Flashcard card, {String? prompt}) {
    return uriForQuestion(questionText(card, prompt: prompt));
  }

  static Uri uriForQuestion(String question) {
    return Uri.https('www.google.com', '/search', {
      'q': question.trim(),
    });
  }
}
