import 'package:equatable/equatable.dart';

import 'id_generator.dart';

enum OrganizationKind {
  company,
  university,
  family,
  friends,
  association,
  community,
  vendor,
  clinic,
  financial,
  other,
}

/// Local organization / faction record (ADR-028). Not a CRM.
class Organization extends Equatable {
  const Organization({
    required this.id,
    required this.profileId,
    required this.name,
    required this.kind,
    this.notes,
    this.archivedAt,
    required this.createdAt,
    required this.updatedAt,
  });

  final EntityId id;
  final EntityId profileId;
  final String name;
  final OrganizationKind kind;
  final String? notes;
  final DateTime? archivedAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  bool get isArchived => archivedAt != null;

  factory Organization.create({
    required EntityId id,
    required EntityId profileId,
    required String name,
    required OrganizationKind kind,
    String? notes,
    required DateTime createdAt,
  }) {
    final trimmed = name.trim();
    if (trimmed.isEmpty) {
      throw ArgumentError('Organization name cannot be empty');
    }
    final trimmedNotes = notes?.trim();
    return Organization(
      id: id,
      profileId: profileId,
      name: trimmed,
      kind: kind,
      notes: (trimmedNotes == null || trimmedNotes.isEmpty)
          ? null
          : trimmedNotes,
      createdAt: createdAt,
      updatedAt: createdAt,
    );
  }

  Organization copyWith({
    String? name,
    OrganizationKind? kind,
    String? notes,
    bool clearNotes = false,
    DateTime? archivedAt,
    bool clearArchivedAt = false,
    DateTime? updatedAt,
  }) {
    final nextName = name?.trim() ?? this.name;
    if (nextName.isEmpty) {
      throw ArgumentError('Organization name cannot be empty');
    }
    final nextNotes = clearNotes
        ? null
        : (notes != null
            ? (notes.trim().isEmpty ? null : notes.trim())
            : this.notes);
    return Organization(
      id: id,
      profileId: profileId,
      name: nextName,
      kind: kind ?? this.kind,
      notes: nextNotes,
      archivedAt: clearArchivedAt ? null : (archivedAt ?? this.archivedAt),
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        profileId,
        name,
        kind,
        notes,
        archivedAt,
        createdAt,
        updatedAt,
      ];
}
