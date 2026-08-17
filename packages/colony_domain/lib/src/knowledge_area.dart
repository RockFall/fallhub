import 'package:equatable/equatable.dart';

import 'id_generator.dart';
import 'knowledge_area_placement.dart';

class KnowledgeArea extends Equatable {
  const KnowledgeArea({
    required this.id,
    required this.profileId,
    required this.title,
    required this.slug,
    required this.sortOrder,
    required this.createdAt,
    required this.updatedAt,
    this.parentId,
    this.description,
    this.iconKey,
    this.catalogKey,
  });

  final EntityId id;
  final EntityId profileId;
  final EntityId? parentId;
  final String title;
  final String slug;
  final String? description;
  final String? iconKey;
  final String? catalogKey;
  final int sortOrder;
  final DateTime createdAt;
  final DateTime updatedAt;

  factory KnowledgeArea.create({
    required EntityId id,
    required EntityId profileId,
    required String title,
    required DateTime createdAt,
    EntityId? parentId,
    String? description,
    String? iconKey,
    String? catalogKey,
    int sortOrder = 0,
    String? slug,
  }) {
    final trimmed = title.trim();
    return KnowledgeArea(
      id: id,
      profileId: profileId,
      parentId: parentId,
      title: trimmed,
      slug: slug ?? slugifyKnowledgeTitle(trimmed),
      description: emptyToNull(description),
      iconKey: emptyToNull(iconKey),
      catalogKey: emptyToNull(catalogKey),
      sortOrder: sortOrder,
      createdAt: createdAt,
      updatedAt: createdAt,
    );
  }

  KnowledgeArea copyWith({
    EntityId? parentId,
    String? title,
    String? slug,
    String? description,
    String? iconKey,
    int? sortOrder,
    DateTime? updatedAt,
    bool clearParent = false,
    bool clearDescription = false,
  }) {
    return KnowledgeArea(
      id: id,
      profileId: profileId,
      parentId: clearParent ? null : (parentId ?? this.parentId),
      title: title?.trim() ?? this.title,
      slug: slug ?? this.slug,
      description:
          clearDescription ? null : (description ?? this.description),
      iconKey: iconKey ?? this.iconKey,
      catalogKey: catalogKey,
      sortOrder: sortOrder ?? this.sortOrder,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        profileId,
        parentId,
        title,
        slug,
        description,
        iconKey,
        catalogKey,
        sortOrder,
        createdAt,
        updatedAt,
      ];
}

class KnowledgeAreaNode extends Equatable {
  const KnowledgeAreaNode({
    required this.area,
    this.children = const [],
  });

  final KnowledgeArea area;
  final List<KnowledgeAreaNode> children;

  int get descendantCount =>
      children.fold(0, (sum, child) => sum + 1 + child.descendantCount);

  @override
  List<Object?> get props => [area, children];
}

class KnowledgeAreaCycleException implements Exception {
  KnowledgeAreaCycleException(this.message);
  final String message;

  @override
  String toString() => message;
}

abstract final class KnowledgeAreaPolicy {
  static void assertAcyclic({
    required EntityId areaId,
    required EntityId? parentId,
    required Map<EntityId, EntityId?> parentById,
  }) {
    if (parentId == null) return;
    if (parentId == areaId) {
      throw KnowledgeAreaCycleException('Área não pode ser pai de si mesma.');
    }
    var cursor = parentId;
    final seen = <EntityId>{areaId, parentId};
    while (true) {
      final next = parentById[cursor];
      if (next == null) return;
      if (!seen.add(next)) {
        throw KnowledgeAreaCycleException('Ciclo no mapa de conhecimento.');
      }
      cursor = next;
    }
  }

  static List<KnowledgeAreaNode> buildForest(List<KnowledgeArea> areas) {
    final byParent = <EntityId?, List<KnowledgeArea>>{};
    for (final area in areas) {
      byParent.putIfAbsent(area.parentId, () => []).add(area);
    }
    for (final list in byParent.values) {
      list.sort((a, b) {
        final order = a.sortOrder.compareTo(b.sortOrder);
        if (order != 0) return order;
        return a.title.toLowerCase().compareTo(b.title.toLowerCase());
      });
    }

    List<KnowledgeAreaNode> walk(EntityId? parentId) {
      return [
        for (final area in byParent[parentId] ?? const <KnowledgeArea>[])
          KnowledgeAreaNode(area: area, children: walk(area.id)),
      ];
    }

    return walk(null);
  }

  static List<KnowledgeArea> ancestorsOf({
    required EntityId areaId,
    required Map<EntityId, KnowledgeArea> byId,
  }) {
    final out = <KnowledgeArea>[];
    var cursor = byId[areaId];
    final seen = <EntityId>{};
    while (cursor != null && seen.add(cursor.id)) {
      out.add(cursor);
      final parentId = cursor.parentId;
      cursor = parentId == null ? null : byId[parentId];
    }
    return out;
  }

  static String pathLabel({
    required EntityId areaId,
    required List<KnowledgeArea> areas,
  }) {
    final byId = {for (final area in areas) area.id: area};
    return ancestorsOf(areaId: areaId, byId: byId)
        .reversed
        .map((area) => area.title)
        .join(' · ');
  }

  static Set<EntityId> descendantIds({
    required EntityId rootId,
    required List<KnowledgeArea> areas,
    List<KnowledgeAreaPlacement> placements = const [],
  }) {
    final children = <EntityId, List<EntityId>>{};
    for (final area in areas) {
      final parent = area.parentId;
      if (parent != null) {
        children.putIfAbsent(parent, () => []).add(area.id);
      }
    }
    for (final placement in placements) {
      children.putIfAbsent(placement.parentAreaId, () => []).add(placement.areaId);
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

  static List<KnowledgeArea> childrenOf({
    required EntityId parentId,
    required List<KnowledgeArea> areas,
    List<KnowledgeAreaPlacement> placements = const [],
  }) {
    final byId = {for (final area in areas) area.id: area};
    final ids = <EntityId>{
      for (final area in areas)
        if (area.parentId == parentId) area.id,
      for (final placement in placements)
        if (placement.parentAreaId == parentId) placement.areaId,
    };
    return [
      for (final id in ids)
        if (byId[id] != null) byId[id]!,
    ];
  }

  static bool isAliasUnder({
    required EntityId areaId,
    required EntityId parentId,
    required List<KnowledgeArea> areas,
    required List<KnowledgeAreaPlacement> placements,
  }) {
    final area = {for (final item in areas) item.id: item}[areaId];
    if (area?.parentId == parentId) return false;
    return placements.any(
      (p) => p.areaId == areaId && p.parentAreaId == parentId,
    );
  }

  static List<String> pathsTo({
    required EntityId areaId,
    required List<KnowledgeArea> areas,
    List<KnowledgeAreaPlacement> placements = const [],
  }) {
    final byId = {for (final area in areas) area.id: area};
    if (byId[areaId] == null) return const [];
    final parents = <EntityId?>{
      byId[areaId]!.parentId,
      for (final placement in placements)
        if (placement.areaId == areaId) placement.parentAreaId,
    };
    final labels = <String>[];
    for (final parentId in parents) {
      final chain = <String>[byId[areaId]!.title];
      var cursor = parentId == null ? null : byId[parentId];
      final seen = <EntityId>{areaId};
      while (cursor != null && seen.add(cursor.id)) {
        chain.add(cursor.title);
        final next = cursor.parentId;
        cursor = next == null ? null : byId[next];
      }
      labels.add(chain.reversed.join(' · '));
    }
    return labels.toSet().toList()..sort();
  }

  static List<KnowledgeArea> extraParentsOf({
    required EntityId areaId,
    required List<KnowledgeArea> areas,
    required List<KnowledgeAreaPlacement> placements,
  }) {
    final byId = {for (final area in areas) area.id: area};
    final area = byId[areaId];
    final extraIds = <EntityId>{
      for (final placement in placements)
        if (placement.areaId == areaId) placement.parentAreaId,
    };
    extraIds.remove(area?.parentId);
    extraIds.remove(areaId);
    return [
      for (final id in extraIds)
        if (byId[id] != null) byId[id]!,
    ]..sort(
        (a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()),
      );
  }

  static bool hasSecondaryPlacement({
    required EntityId areaId,
    required List<KnowledgeAreaPlacement> placements,
  }) {
    return placements.any((p) => p.areaId == areaId);
  }

  static bool matchesQuery({
    required KnowledgeArea area,
    required String query,
    required List<KnowledgeArea> areas,
    List<KnowledgeAreaPlacement> placements = const [],
  }) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return true;
    if (area.title.toLowerCase().contains(q)) return true;
    if ((area.description ?? '').toLowerCase().contains(q)) return true;
    return pathsTo(
      areaId: area.id,
      areas: areas,
      placements: placements,
    ).any((path) => path.toLowerCase().contains(q));
  }

  static void assertPlacementAcyclic({
    required EntityId areaId,
    required EntityId parentAreaId,
    required List<KnowledgeArea> areas,
    required List<KnowledgeAreaPlacement> placements,
  }) {
    if (areaId == parentAreaId) {
      throw KnowledgeAreaCycleException('Área não pode ser pai de si mesma.');
    }
    final next = [
      ...placements,
      KnowledgeAreaPlacement(
        areaId: areaId,
        parentAreaId: parentAreaId,
        linkedAt: DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
      ),
    ];
    if (descendantIds(
      rootId: areaId,
      areas: areas,
      placements: next,
    ).contains(parentAreaId)) {
      throw KnowledgeAreaCycleException('Ciclo no mapa de conhecimento.');
    }
  }
}

String slugifyKnowledgeTitle(String title) {
  final lower = title.trim().toLowerCase();
  final buffer = StringBuffer();
  var dash = false;
  for (final code in lower.runes) {
    final ch = String.fromCharCode(code);
    final ok = RegExp(r'[a-z0-9]').hasMatch(ch);
    if (ok) {
      buffer.write(ch);
      dash = false;
    } else if (!dash && buffer.isNotEmpty) {
      buffer.write('-');
      dash = true;
    }
  }
  final slug = buffer.toString().replaceAll(RegExp(r'-+$'), '');
  return slug.isEmpty ? 'area' : slug;
}

String? emptyToNull(String? value) {
  final trimmed = value?.trim();
  if (trimmed == null || trimmed.isEmpty) return null;
  return trimmed;
}
