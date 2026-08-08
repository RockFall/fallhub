import 'package:equatable/equatable.dart';

import 'id_generator.dart';

enum ZoneConnectivity {
  online,
  offline,
  limited,
  unknown,
}

/// Contextual zone (ADR-031 / §25.2). Local record; no GPS/geofencing.
class ContextZone extends Equatable {
  const ContextZone({
    required this.id,
    required this.profileId,
    required this.name,
    this.locationLabel,
    this.capabilities = const [],
    this.unavailableWorkTypes = const [],
    required this.connectivity,
    this.notes,
    this.archivedAt,
    required this.createdAt,
    required this.updatedAt,
  });

  final EntityId id;
  final EntityId profileId;
  final String name;
  final String? locationLabel;
  final List<String> capabilities;
  final List<String> unavailableWorkTypes;
  final ZoneConnectivity connectivity;
  final String? notes;
  final DateTime? archivedAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  bool get isArchived => archivedAt != null;

  factory ContextZone.create({
    required EntityId id,
    required EntityId profileId,
    required String name,
    String? locationLabel,
    List<String> capabilities = const [],
    List<String> unavailableWorkTypes = const [],
    ZoneConnectivity connectivity = ZoneConnectivity.unknown,
    String? notes,
    required DateTime createdAt,
  }) {
    final trimmedName = name.trim();
    if (trimmedName.isEmpty) {
      throw ArgumentError('ContextZone name cannot be empty');
    }
    final trimmedLocation = locationLabel?.trim();
    final trimmedNotes = notes?.trim();
    return ContextZone(
      id: id,
      profileId: profileId,
      name: trimmedName,
      locationLabel: (trimmedLocation == null || trimmedLocation.isEmpty)
          ? null
          : trimmedLocation,
      capabilities: capabilities
          .map((c) => c.trim())
          .where((c) => c.isNotEmpty)
          .toList(),
      unavailableWorkTypes: unavailableWorkTypes
          .map((c) => c.trim())
          .where((c) => c.isNotEmpty)
          .toList(),
      connectivity: connectivity,
      notes: (trimmedNotes == null || trimmedNotes.isEmpty)
          ? null
          : trimmedNotes,
      createdAt: createdAt,
      updatedAt: createdAt,
    );
  }

  ContextZone copyWith({
    String? name,
    String? locationLabel,
    bool clearLocationLabel = false,
    List<String>? capabilities,
    List<String>? unavailableWorkTypes,
    ZoneConnectivity? connectivity,
    String? notes,
    bool clearNotes = false,
    DateTime? archivedAt,
    bool clearArchivedAt = false,
    DateTime? updatedAt,
  }) {
    final nextName = name?.trim() ?? this.name;
    if (nextName.isEmpty) {
      throw ArgumentError('ContextZone name cannot be empty');
    }
    final nextLocation = clearLocationLabel
        ? null
        : (locationLabel != null
            ? (locationLabel.trim().isEmpty ? null : locationLabel.trim())
            : this.locationLabel);
    final nextNotes = clearNotes
        ? null
        : (notes != null
            ? (notes.trim().isEmpty ? null : notes.trim())
            : this.notes);
    return ContextZone(
      id: id,
      profileId: profileId,
      name: nextName,
      locationLabel: nextLocation,
      capabilities: capabilities ?? this.capabilities,
      unavailableWorkTypes: unavailableWorkTypes ?? this.unavailableWorkTypes,
      connectivity: connectivity ?? this.connectivity,
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
        locationLabel,
        capabilities,
        unavailableWorkTypes,
        connectivity,
        notes,
        archivedAt,
        createdAt,
        updatedAt,
      ];
}
