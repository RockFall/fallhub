import 'package:equatable/equatable.dart';

import 'id_generator.dart';

/// Interaction kinds from spec §24.2 (lite subset).
enum InteractionKind {
  meeting,
  call,
  message,
  gathering,
  help,
  conflict,
  decision,
  promise,
  gift,
  introduction,
  other,
}

/// Logged interaction with a [Person] (ADR-026 follow-up / §24.2 lite).
class PersonInteraction extends Equatable {
  const PersonInteraction({
    required this.id,
    required this.profileId,
    required this.personId,
    required this.kind,
    required this.occurredAt,
    this.note,
    required this.createdAt,
  });

  final EntityId id;
  final EntityId profileId;
  final EntityId personId;
  final InteractionKind kind;
  final DateTime occurredAt;
  final String? note;
  final DateTime createdAt;

  factory PersonInteraction.create({
    required EntityId id,
    required EntityId profileId,
    required EntityId personId,
    required InteractionKind kind,
    required DateTime occurredAt,
    String? note,
    required DateTime createdAt,
  }) {
    final trimmed = note?.trim();
    return PersonInteraction(
      id: id,
      profileId: profileId,
      personId: personId,
      kind: kind,
      occurredAt: occurredAt.toUtc(),
      note: (trimmed == null || trimmed.isEmpty) ? null : trimmed,
      createdAt: createdAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        profileId,
        personId,
        kind,
        occurredAt,
        note,
        createdAt,
      ];
}
