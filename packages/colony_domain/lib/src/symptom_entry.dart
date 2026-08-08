import 'package:equatable/equatable.dart';

import 'health_safety_policy.dart';
import 'id_generator.dart';

/// Point-in-time symptom log (ADR-023). User-reported; not a diagnosis.
class SymptomEntry extends Equatable {
  const SymptomEntry({
    required this.id,
    required this.profileId,
    this.conditionId,
    required this.occurredAt,
    required this.intensity,
    this.note,
    this.bodyRegion,
    required this.createdAt,
  });

  final EntityId id;
  final EntityId profileId;
  final EntityId? conditionId;
  final DateTime occurredAt;
  final int intensity;
  final String? note;
  final String? bodyRegion;
  final DateTime createdAt;

  factory SymptomEntry.create({
    required EntityId id,
    required EntityId profileId,
    EntityId? conditionId,
    required DateTime occurredAt,
    required int intensity,
    String? note,
    String? bodyRegion,
    required DateTime createdAt,
  }) {
    HealthSafetyPolicy.validateSeverity(intensity);
    final trimmedNote = note?.trim();
    final trimmedRegion = bodyRegion?.trim();
    return SymptomEntry(
      id: id,
      profileId: profileId,
      conditionId: conditionId,
      occurredAt: occurredAt,
      intensity: intensity,
      note: (trimmedNote == null || trimmedNote.isEmpty) ? null : trimmedNote,
      bodyRegion:
          (trimmedRegion == null || trimmedRegion.isEmpty) ? null : trimmedRegion,
      createdAt: createdAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        profileId,
        conditionId,
        occurredAt,
        intensity,
        note,
        bodyRegion,
        createdAt,
      ];
}
