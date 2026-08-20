import 'package:equatable/equatable.dart';

import 'flashcard.dart';
import 'id_generator.dart';

class FlashcardTagCycleException implements Exception {
  @override
  String toString() => 'Uma tag não pode ser ancestral de si mesma.';
}

class FlashcardTag extends Equatable {
  const FlashcardTag({
    required this.id,
    required this.profileId,
    required this.title,
    required this.createdAt,
    this.parentId,
    this.sortOrder = 0,
  });

  final EntityId id;
  final EntityId profileId;
  final EntityId? parentId;
  final String title;
  final int sortOrder;
  final DateTime createdAt;

  factory FlashcardTag.create({
    required EntityId id,
    required EntityId profileId,
    required String title,
    required DateTime createdAt,
    EntityId? parentId,
    int sortOrder = 0,
  }) {
    return FlashcardTag(
      id: id,
      profileId: profileId,
      parentId: parentId,
      title: title.trim(),
      sortOrder: sortOrder,
      createdAt: createdAt,
    );
  }

  FlashcardTag copyWith({
    EntityId? parentId,
    String? title,
    int? sortOrder,
    bool clearParent = false,
  }) {
    return FlashcardTag(
      id: id,
      profileId: profileId,
      parentId: clearParent ? null : (parentId ?? this.parentId),
      title: title?.trim() ?? this.title,
      sortOrder: sortOrder ?? this.sortOrder,
      createdAt: createdAt,
    );
  }

  @override
  List<Object?> get props =>
      [id, profileId, parentId, title, sortOrder, createdAt];
}

class FlashcardTagLink extends Equatable {
  const FlashcardTagLink({
    required this.cardId,
    required this.tagId,
    required this.linkedAt,
  });

  final EntityId cardId;
  final EntityId tagId;
  final DateTime linkedAt;

  @override
  List<Object?> get props => [cardId, tagId, linkedAt];
}

class FlashcardTagNode extends Equatable {
  const FlashcardTagNode({
    required this.tag,
    this.children = const [],
  });

  final FlashcardTag tag;
  final List<FlashcardTagNode> children;

  int get descendantCount =>
      children.fold(0, (sum, child) => sum + 1 + child.descendantCount);

  @override
  List<Object?> get props => [tag, children];
}

abstract final class FlashcardTagPolicy {
  static List<String> parsePath(Object? raw) {
    if (raw == null) return const [];
    if (raw is List) {
      return [
        for (final item in raw)
          if (item != null && item.toString().trim().isNotEmpty)
            item.toString().trim(),
      ];
    }
    final text = raw.toString().trim();
    if (text.isEmpty) return const [];
    return [
      for (final part in text.split(RegExp(r'\s*(?:>|/|·|,)\s*')))
        if (part.trim().isNotEmpty) part.trim(),
    ];
  }

  static String normalizeTitle(String title) =>
      title.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');

  static List<FlashcardTagNode> buildForest(List<FlashcardTag> tags) {
    final byParent = <EntityId?, List<FlashcardTag>>{};
    for (final tag in tags) {
      byParent.putIfAbsent(tag.parentId, () => []).add(tag);
    }
    for (final list in byParent.values) {
      list.sort((a, b) {
        final order = a.sortOrder.compareTo(b.sortOrder);
        if (order != 0) return order;
        return a.title.toLowerCase().compareTo(b.title.toLowerCase());
      });
    }

    List<FlashcardTagNode> walk(EntityId? parentId) {
      return [
        for (final tag in byParent[parentId] ?? const <FlashcardTag>[])
          FlashcardTagNode(tag: tag, children: walk(tag.id)),
      ];
    }

    return walk(null);
  }

  static List<FlashcardTag> childrenOf({
    required EntityId? parentId,
    required List<FlashcardTag> tags,
  }) {
    return [
      for (final tag in tags)
        if (tag.parentId == parentId) tag,
    ]..sort((a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()));
  }

  static FlashcardTag? childNamed({
    required EntityId? parentId,
    required String title,
    required List<FlashcardTag> tags,
  }) {
    final needle = normalizeTitle(title);
    for (final child in childrenOf(parentId: parentId, tags: tags)) {
      if (normalizeTitle(child.title) == needle) return child;
    }
    return null;
  }

  static List<FlashcardTag> ancestorsOf({
    required EntityId tagId,
    required Map<EntityId, FlashcardTag> byId,
  }) {
    final out = <FlashcardTag>[];
    var cursor = byId[tagId];
    final seen = <EntityId>{};
    while (cursor != null && seen.add(cursor.id)) {
      out.add(cursor);
      final parentId = cursor.parentId;
      cursor = parentId == null ? null : byId[parentId];
    }
    return out;
  }

  static String pathLabel({
    required EntityId tagId,
    required List<FlashcardTag> tags,
  }) {
    final byId = {for (final tag in tags) tag.id: tag};
    return ancestorsOf(tagId: tagId, byId: byId)
        .reversed
        .map((tag) => tag.title)
        .join(' · ');
  }

  static Set<EntityId> descendantIds({
    required EntityId rootId,
    required List<FlashcardTag> tags,
  }) {
    final children = <EntityId, List<EntityId>>{};
    for (final tag in tags) {
      final parent = tag.parentId;
      if (parent != null) {
        children.putIfAbsent(parent, () => []).add(tag.id);
      }
    }
    final out = <EntityId>{rootId};
    final stack = <EntityId>[rootId];
    while (stack.isNotEmpty) {
      final id = stack.removeLast();
      for (final child in children[id] ?? const <EntityId>[]) {
        if (out.add(child)) stack.add(child);
      }
    }
    return out;
  }

  static void assertAcyclic({
    required EntityId tagId,
    required EntityId? parentId,
    required Map<EntityId, EntityId?> parentById,
  }) {
    var cursor = parentId;
    final seen = <EntityId>{tagId};
    while (cursor != null) {
      if (!seen.add(cursor)) {
        throw FlashcardTagCycleException();
      }
      cursor = parentById[cursor];
    }
  }

  static List<Flashcard> cardsWithTag({
    required List<Flashcard> cards,
    required List<FlashcardTagLink> links,
    required List<FlashcardTag> tags,
    required EntityId rootId,
  }) {
    final allowed = descendantIds(rootId: rootId, tags: tags);
    final cardIds = {
      for (final link in links)
        if (allowed.contains(link.tagId)) link.cardId,
    };
    return [for (final card in cards) if (cardIds.contains(card.id)) card];
  }

  static List<EntityId> tagIdsForCard({
    required EntityId cardId,
    required List<FlashcardTagLink> links,
  }) {
    return [
      for (final link in links)
        if (link.cardId == cardId) link.tagId,
    ];
  }
}
