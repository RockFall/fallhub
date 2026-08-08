import 'package:equatable/equatable.dart';

import 'id_generator.dart';

/// Local person record for relations (ADR-026). Not a CRM contact sync.
class Person extends Equatable {
  const Person({
    required this.id,
    required this.profileId,
    required this.displayName,
    this.preferredName,
    this.relationshipTypes = const [],
    this.notes,
    this.birthday,
    this.lastInteractionAt,
    this.nextFollowUpAt,
    this.archivedAt,
    required this.createdAt,
    required this.updatedAt,
  });

  final EntityId id;
  final EntityId profileId;
  final String displayName;
  final String? preferredName;
  final List<String> relationshipTypes;
  final String? notes;
  final DateTime? birthday;
  final DateTime? lastInteractionAt;
  final DateTime? nextFollowUpAt;
  final DateTime? archivedAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  bool get isArchived => archivedAt != null;

  factory Person.create({
    required EntityId id,
    required EntityId profileId,
    required String displayName,
    String? preferredName,
    List<String> relationshipTypes = const [],
    String? notes,
    DateTime? birthday,
    DateTime? lastInteractionAt,
    DateTime? nextFollowUpAt,
    required DateTime createdAt,
  }) {
    final trimmed = displayName.trim();
    if (trimmed.isEmpty) {
      throw ArgumentError('Person displayName cannot be empty');
    }
    final preferred = preferredName?.trim();
    final trimmedNotes = notes?.trim();
    return Person(
      id: id,
      profileId: profileId,
      displayName: trimmed,
      preferredName:
          (preferred == null || preferred.isEmpty) ? null : preferred,
      relationshipTypes: relationshipTypes
          .map((t) => t.trim())
          .where((t) => t.isNotEmpty)
          .toList(),
      notes: (trimmedNotes == null || trimmedNotes.isEmpty)
          ? null
          : trimmedNotes,
      birthday: birthday,
      lastInteractionAt: lastInteractionAt,
      nextFollowUpAt: nextFollowUpAt,
      createdAt: createdAt,
      updatedAt: createdAt,
    );
  }

  Person copyWith({
    String? displayName,
    String? preferredName,
    bool clearPreferredName = false,
    List<String>? relationshipTypes,
    String? notes,
    bool clearNotes = false,
    DateTime? birthday,
    bool clearBirthday = false,
    DateTime? lastInteractionAt,
    bool clearLastInteractionAt = false,
    DateTime? nextFollowUpAt,
    bool clearNextFollowUpAt = false,
    DateTime? archivedAt,
    bool clearArchivedAt = false,
    DateTime? updatedAt,
  }) {
    final nextName = displayName?.trim() ?? this.displayName;
    if (nextName.isEmpty) {
      throw ArgumentError('Person displayName cannot be empty');
    }
    final nextPreferred = clearPreferredName
        ? null
        : (preferredName != null
            ? (preferredName.trim().isEmpty ? null : preferredName.trim())
            : this.preferredName);
    final nextNotes = clearNotes
        ? null
        : (notes != null
            ? (notes.trim().isEmpty ? null : notes.trim())
            : this.notes);
    return Person(
      id: id,
      profileId: profileId,
      displayName: nextName,
      preferredName: nextPreferred,
      relationshipTypes: relationshipTypes ?? this.relationshipTypes,
      notes: nextNotes,
      birthday: clearBirthday ? null : (birthday ?? this.birthday),
      lastInteractionAt: clearLastInteractionAt
          ? null
          : (lastInteractionAt ?? this.lastInteractionAt),
      nextFollowUpAt: clearNextFollowUpAt
          ? null
          : (nextFollowUpAt ?? this.nextFollowUpAt),
      archivedAt: clearArchivedAt ? null : (archivedAt ?? this.archivedAt),
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        profileId,
        displayName,
        preferredName,
        relationshipTypes,
        notes,
        birthday,
        lastInteractionAt,
        nextFollowUpAt,
        archivedAt,
        createdAt,
        updatedAt,
      ];
}
