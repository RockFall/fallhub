import 'package:equatable/equatable.dart';

import 'flashcard.dart';
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
    required this.dueLaterToday,
    required this.unscheduledCount,
    required this.completedToday,
    required this.cappedForSession,
    required this.limitDeferred,
    required this.estimatedMinutes,
  });

  final int dueNowTotal;
  final FlashcardQueueCounts dueNowByBucket;
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
        dueLaterToday,
        unscheduledCount,
        completedToday,
        cappedForSession,
        limitDeferred,
        estimatedMinutes,
      ];
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

    var capped = 0;
    final byDeck = <EntityId, List<Flashcard>>{};
    for (final card in scheduled) {
      byDeck.putIfAbsent(card.deckId, () => []).add(card);
    }
    for (final entry in byDeck.entries) {
      final deck = deckById[entry.key];
      capped += StudyQueuePolicy.buildQueue(
        cards: entry.value,
        srsByCard: srsByCard,
        now: now,
        newRemaining: (deck?.newLimitPerDay ?? 20) - (newUsed[entry.key] ?? 0),
        reviewRemaining:
            (deck?.reviewLimitPerDay ?? 200) - (reviewUsed[entry.key] ?? 0),
        interleaveByArea: false,
      ).length;
    }

    return FlashcardTodayDigest(
      dueNowTotal: buckets.dueTotal,
      dueNowByBucket: buckets,
      dueLaterToday: later,
      unscheduledCount: unscheduled,
      completedToday: completed,
      cappedForSession: capped,
      limitDeferred: (buckets.dueTotal - capped).clamp(0, buckets.dueTotal),
      estimatedMinutes: capped < 1 ? 0 : (capped * 0.5).ceil().clamp(1, 180),
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
  }) {
    final learning = <StudyCard>[];
    final reviews = <StudyCard>[];
    final news = <StudyCard>[];

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
          reviews.add(item);
        case FlashcardSrsStatus.newCard:
          news.add(item);
      }
    }

    learning.sort((a, b) => a.srs.dueAt.compareTo(b.srs.dueAt));
    reviews.sort((a, b) => a.srs.dueAt.compareTo(b.srs.dueAt));
    news.sort((a, b) => a.card.createdAt.compareTo(b.card.createdAt));

    final limitedReviews = reviews.take(reviewRemaining.clamp(0, reviews.length));
    final limitedNews = news.take(newRemaining.clamp(0, news.length));
    final combined = [...learning, ...limitedReviews, ...limitedNews];
    if (!interleaveByArea) return combined;
    return _interleave(combined);
  }

  static List<StudyCard> _interleave(List<StudyCard> cards) {
    final buckets = <String, List<StudyCard>>{};
    for (final card in cards) {
      final key = card.card.areaId?.value ?? card.card.deckId.value;
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
      if (out.length >= limit) break;
    }
    return out;
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
  }) {
    final logsByCard = <EntityId, List<FlashcardReviewLog>>{};
    for (final log in logs) {
      if (log.reviewKind != FlashcardReviewKind.srs) continue;
      logsByCard.putIfAbsent(log.cardId, () => []).add(log);
    }

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
        final areaId = card.areaId;
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
          cards.where((card) {
            final areaId = card.areaId;
            if (areaId == null) return false;
            return KnowledgeAreaPolicy.descendantIds(
              rootId: area.id,
              areas: areas,
              placements: placements,
            ).contains(areaId);
          }),
        ),
    };
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
