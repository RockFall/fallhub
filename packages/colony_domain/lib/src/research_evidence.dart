import 'package:equatable/equatable.dart';

import 'id_generator.dart';

enum ResearchEvidenceType {
  note,
  practiceLog,
  summary,
}

class ResearchEvidence extends Equatable {
  const ResearchEvidence({
    required this.id,
    required this.profileId,
    required this.nodeId,
    required this.type,
    required this.title,
    required this.body,
    required this.createdAt,
    this.sessionId,
  });

  final EntityId id;
  final EntityId profileId;
  final EntityId nodeId;
  final EntityId? sessionId;
  final ResearchEvidenceType type;
  final String title;
  final String body;
  final DateTime createdAt;

  factory ResearchEvidence.create({
    required EntityId id,
    required EntityId profileId,
    required EntityId nodeId,
    required ResearchEvidenceType type,
    required String title,
    required String body,
    required DateTime createdAt,
    EntityId? sessionId,
  }) {
    return ResearchEvidence(
      id: id,
      profileId: profileId,
      nodeId: nodeId,
      sessionId: sessionId,
      type: type,
      title: title.trim(),
      body: body.trim(),
      createdAt: createdAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        profileId,
        nodeId,
        sessionId,
        type,
        title,
        body,
        createdAt,
      ];
}
