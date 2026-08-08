import 'package:equatable/equatable.dart';

import 'id_generator.dart';

enum ResearchNodeType {
  skill,
  knowledge,
  capability,
  practice,
}

enum ResearchNodeStatus {
  available,
  inResearch,
  demonstrated,
  archived;

  bool get isTerminal => this == demonstrated || this == archived;

  bool get isActiveFocus => this == inResearch;
}

class QuestResearchLink extends Equatable {
  const QuestResearchLink({
    required this.questId,
    required this.researchNodeId,
    required this.linkedAt,
  });

  final EntityId questId;
  final EntityId researchNodeId;
  final DateTime linkedAt;

  @override
  List<Object?> get props => [questId, researchNodeId, linkedAt];
}

class ResearchNode extends Equatable {
  const ResearchNode({
    required this.id,
    required this.profileId,
    required this.title,
    required this.type,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    this.description,
    this.demonstratedNote,
    this.version = 1,
  });

  final EntityId id;
  final EntityId profileId;
  final String title;
  final String? description;
  final ResearchNodeType type;
  final ResearchNodeStatus status;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? demonstratedNote;
  final int version;

  factory ResearchNode.create({
    required EntityId id,
    required EntityId profileId,
    required String title,
    required ResearchNodeType type,
    required DateTime createdAt,
    String? description,
    ResearchNodeStatus status = ResearchNodeStatus.available,
  }) {
    return ResearchNode(
      id: id,
      profileId: profileId,
      title: title.trim(),
      description: description?.trim(),
      type: type,
      status: status,
      createdAt: createdAt,
      updatedAt: createdAt,
    );
  }

  ResearchNode copyWith({
    String? title,
    String? description,
    ResearchNodeType? type,
    ResearchNodeStatus? status,
    DateTime? updatedAt,
    String? demonstratedNote,
    int? version,
    bool clearDescription = false,
    bool clearDemonstratedNote = false,
  }) {
    return ResearchNode(
      id: id,
      profileId: profileId,
      title: title ?? this.title,
      description: clearDescription ? null : (description ?? this.description),
      type: type ?? this.type,
      status: status ?? this.status,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      demonstratedNote: clearDemonstratedNote
          ? null
          : (demonstratedNote ?? this.demonstratedNote),
      version: version ?? this.version,
    );
  }

  @override
  List<Object?> get props => [
        id,
        profileId,
        title,
        description,
        type,
        status,
        createdAt,
        updatedAt,
        demonstratedNote,
        version,
      ];
}

class ResearchLifecyclePolicy {
  const ResearchLifecyclePolicy._();

  static bool canTransition(ResearchNodeStatus from, ResearchNodeStatus to) {
    if (from == to) return true;
    return _allowed[from]?.contains(to) ?? false;
  }

  static const _allowed = <ResearchNodeStatus, Set<ResearchNodeStatus>>{
    ResearchNodeStatus.available: {
      ResearchNodeStatus.inResearch,
      ResearchNodeStatus.archived,
    },
    ResearchNodeStatus.inResearch: {ResearchNodeStatus.demonstrated},
    ResearchNodeStatus.demonstrated: {ResearchNodeStatus.archived},
    ResearchNodeStatus.archived: {},
  };
}
