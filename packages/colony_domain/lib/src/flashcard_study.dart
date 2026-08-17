import 'package:equatable/equatable.dart';

import 'flashcard.dart';
import 'id_generator.dart';

class StudyCard extends Equatable {
  const StudyCard({
    required this.card,
    required this.srs,
    required this.prompt,
    required this.answer,
    this.extra,
  });

  final Flashcard card;
  final FlashcardSrsState srs;
  final String prompt;
  final String answer;
  final String? extra;

  @override
  List<Object?> get props => [card, srs, prompt, answer, extra];
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

abstract final class StudyQueuePolicy {
  static StudyCard present(Flashcard card, FlashcardSrsState srs) {
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
      );
    }
    return StudyCard(
      card: card,
      srs: srs,
      prompt: card.front,
      answer: card.back,
      extra: card.extra,
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
      if (card.suspended) continue;
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
      if (card.suspended) continue;
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
  }) {
    final cardsByArea = <EntityId, List<Flashcard>>{};
    for (final card in cards) {
      final areaId = card.areaId;
      if (areaId == null) continue;
      cardsByArea.putIfAbsent(areaId, () => []).add(card);
    }
    final logsByCard = <EntityId, List<FlashcardReviewLog>>{};
    for (final log in logs) {
      logsByCard.putIfAbsent(log.cardId, () => []).add(log);
    }

    return {
      for (final entry in cardsByArea.entries)
        entry.key: KnowledgeAreaHeat(
          areaId: entry.key,
          cardCount: entry.value.length,
          dueCount: counts(
            cards: entry.value,
            srsByCard: srsByCard,
            now: now,
          ).dueTotal,
          retention: retention([
            for (final card in entry.value)
              ...?logsByCard[card.id],
          ]),
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
      if (state.status == FlashcardSrsStatus.newCard) continue;
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
