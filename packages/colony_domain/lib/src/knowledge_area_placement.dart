import 'package:equatable/equatable.dart';

import 'id_generator.dart';

class KnowledgeAreaPlacement extends Equatable {
  const KnowledgeAreaPlacement({
    required this.areaId,
    required this.parentAreaId,
    required this.linkedAt,
    this.catalogKey,
  });

  final EntityId areaId;
  final EntityId parentAreaId;
  final DateTime linkedAt;
  final String? catalogKey;

  @override
  List<Object?> get props => [areaId, parentAreaId, linkedAt, catalogKey];
}

enum ResearchKnowledgeLinkKind {
  primary,
  related,
  practice,
}

class ResearchKnowledgeLink extends Equatable {
  const ResearchKnowledgeLink({
    required this.researchNodeId,
    required this.areaId,
    required this.kind,
    required this.linkedAt,
  });

  final EntityId researchNodeId;
  final EntityId areaId;
  final ResearchKnowledgeLinkKind kind;
  final DateTime linkedAt;

  @override
  List<Object?> get props => [researchNodeId, areaId, kind, linkedAt];
}
