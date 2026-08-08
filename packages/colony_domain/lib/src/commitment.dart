import 'package:equatable/equatable.dart';

import 'id_generator.dart';

enum CommitmentStatus {
  open,
  kept,
  broken,
  cancelled;

  bool get isHiddenFromActiveList =>
      this == kept || this == broken || this == cancelled;
}

/// Personal promise / commitment (ADR-030 / §24.4). Local record only; no scoring.
class Commitment extends Equatable {
  const Commitment({
    required this.id,
    required this.profileId,
    required this.description,
    required this.madeByLabel,
    this.madeToPersonId,
    this.madeToOrganizationId,
    this.madeToLabel,
    this.dueAt,
    required this.status,
    this.notes,
    this.linkedQuestId,
    required this.createdAt,
    required this.updatedAt,
  });

  final EntityId id;
  final EntityId profileId;
  final String description;
  final String madeByLabel;
  final EntityId? madeToPersonId;
  final EntityId? madeToOrganizationId;
  final String? madeToLabel;
  final DateTime? dueAt;
  final CommitmentStatus status;
  final String? notes;
  final EntityId? linkedQuestId;
  final DateTime createdAt;
  final DateTime updatedAt;

  factory Commitment.create({
    required EntityId id,
    required EntityId profileId,
    required String description,
    String madeByLabel = 'eu',
    EntityId? madeToPersonId,
    EntityId? madeToOrganizationId,
    String? madeToLabel,
    DateTime? dueAt,
    CommitmentStatus status = CommitmentStatus.open,
    String? notes,
    EntityId? linkedQuestId,
    required DateTime createdAt,
  }) {
    final trimmedDescription = description.trim();
    if (trimmedDescription.isEmpty) {
      throw ArgumentError('Commitment description cannot be empty');
    }
    final trimmedMadeBy = madeByLabel.trim();
    if (trimmedMadeBy.isEmpty) {
      throw ArgumentError('Commitment madeByLabel cannot be empty');
    }
    final trimmedMadeTo = madeToLabel?.trim();
    final normalizedMadeTo =
        (trimmedMadeTo == null || trimmedMadeTo.isEmpty) ? null : trimmedMadeTo;
    if (madeToPersonId == null &&
        madeToOrganizationId == null &&
        normalizedMadeTo == null) {
      throw ArgumentError(
        'Commitment requires madeToPersonId, madeToOrganizationId, or madeToLabel',
      );
    }
    final trimmedNotes = notes?.trim();
    return Commitment(
      id: id,
      profileId: profileId,
      description: trimmedDescription,
      madeByLabel: trimmedMadeBy,
      madeToPersonId: madeToPersonId,
      madeToOrganizationId: madeToOrganizationId,
      madeToLabel: normalizedMadeTo,
      dueAt: dueAt,
      status: status,
      notes: (trimmedNotes == null || trimmedNotes.isEmpty)
          ? null
          : trimmedNotes,
      linkedQuestId: linkedQuestId,
      createdAt: createdAt,
      updatedAt: createdAt,
    );
  }

  Commitment withStatus(CommitmentStatus status, DateTime updatedAt) {
    return copyWith(status: status, updatedAt: updatedAt);
  }

  Commitment copyWith({
    String? description,
    String? madeByLabel,
    EntityId? madeToPersonId,
    bool clearMadeToPersonId = false,
    EntityId? madeToOrganizationId,
    bool clearMadeToOrganizationId = false,
    String? madeToLabel,
    bool clearMadeToLabel = false,
    DateTime? dueAt,
    bool clearDueAt = false,
    CommitmentStatus? status,
    String? notes,
    bool clearNotes = false,
    EntityId? linkedQuestId,
    bool clearLinkedQuestId = false,
    DateTime? updatedAt,
  }) {
    final nextDescription = description?.trim() ?? this.description;
    if (nextDescription.isEmpty) {
      throw ArgumentError('Commitment description cannot be empty');
    }
    final nextMadeBy = madeByLabel?.trim() ?? this.madeByLabel;
    if (nextMadeBy.isEmpty) {
      throw ArgumentError('Commitment madeByLabel cannot be empty');
    }
    final nextPerson = clearMadeToPersonId
        ? null
        : (madeToPersonId ?? this.madeToPersonId);
    final nextOrg = clearMadeToOrganizationId
        ? null
        : (madeToOrganizationId ?? this.madeToOrganizationId);
    final nextMadeToLabel = clearMadeToLabel
        ? null
        : (madeToLabel != null
            ? (madeToLabel.trim().isEmpty ? null : madeToLabel.trim())
            : this.madeToLabel);
    if (nextPerson == null && nextOrg == null && nextMadeToLabel == null) {
      throw ArgumentError(
        'Commitment requires madeToPersonId, madeToOrganizationId, or madeToLabel',
      );
    }
    final nextNotes = clearNotes
        ? null
        : (notes != null
            ? (notes.trim().isEmpty ? null : notes.trim())
            : this.notes);
    return Commitment(
      id: id,
      profileId: profileId,
      description: nextDescription,
      madeByLabel: nextMadeBy,
      madeToPersonId: nextPerson,
      madeToOrganizationId: nextOrg,
      madeToLabel: nextMadeToLabel,
      dueAt: clearDueAt ? null : (dueAt ?? this.dueAt),
      status: status ?? this.status,
      notes: nextNotes,
      linkedQuestId: clearLinkedQuestId
          ? null
          : (linkedQuestId ?? this.linkedQuestId),
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        profileId,
        description,
        madeByLabel,
        madeToPersonId,
        madeToOrganizationId,
        madeToLabel,
        dueAt,
        status,
        notes,
        linkedQuestId,
        createdAt,
        updatedAt,
      ];
}
