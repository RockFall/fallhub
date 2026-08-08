import 'package:equatable/equatable.dart';

import 'id_generator.dart';

enum HealthConditionType {
  symptom,
  diagnosisReported,
  injury,
  recovery,
  context,
}

enum HealthConditionStatus {
  active,
  monitoring,
  resolved,
  archived;

  bool get isTerminal => this == resolved || this == archived;
}

/// Local user-reported health condition (ADR-023). Not a clinical diagnosis.
class HealthCondition extends Equatable {
  const HealthCondition({
    required this.id,
    required this.profileId,
    required this.title,
    required this.type,
    required this.status,
    this.onsetAt,
    this.resolvedAt,
    this.severityUserReported,
    this.bodyRegions = const [],
    this.clinicianConfirmed = false,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
  });

  final EntityId id;
  final EntityId profileId;
  final String title;
  final HealthConditionType type;
  final HealthConditionStatus status;
  final DateTime? onsetAt;
  final DateTime? resolvedAt;
  final int? severityUserReported;
  final List<String> bodyRegions;
  final bool clinicianConfirmed;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;

  factory HealthCondition.create({
    required EntityId id,
    required EntityId profileId,
    required String title,
    required HealthConditionType type,
    HealthConditionStatus status = HealthConditionStatus.active,
    DateTime? onsetAt,
    int? severityUserReported,
    List<String> bodyRegions = const [],
    bool clinicianConfirmed = false,
    String? notes,
    required DateTime createdAt,
  }) {
    final trimmedNotes = notes?.trim();
    return HealthCondition(
      id: id,
      profileId: profileId,
      title: title.trim(),
      type: type,
      status: status,
      onsetAt: onsetAt,
      severityUserReported: severityUserReported,
      bodyRegions: bodyRegions
          .map((r) => r.trim())
          .where((r) => r.isNotEmpty)
          .toList(),
      clinicianConfirmed: clinicianConfirmed,
      notes: (trimmedNotes == null || trimmedNotes.isEmpty)
          ? null
          : trimmedNotes,
      createdAt: createdAt,
      updatedAt: createdAt,
    );
  }

  HealthCondition copyWith({
    String? title,
    HealthConditionType? type,
    HealthConditionStatus? status,
    DateTime? onsetAt,
    bool clearOnsetAt = false,
    DateTime? resolvedAt,
    bool clearResolvedAt = false,
    int? severityUserReported,
    bool clearSeverity = false,
    List<String>? bodyRegions,
    bool? clinicianConfirmed,
    String? notes,
    bool clearNotes = false,
    DateTime? updatedAt,
  }) {
    final nextNotes = clearNotes
        ? null
        : (notes != null ? (notes.trim().isEmpty ? null : notes.trim()) : this.notes);
    return HealthCondition(
      id: id,
      profileId: profileId,
      title: title?.trim() ?? this.title,
      type: type ?? this.type,
      status: status ?? this.status,
      onsetAt: clearOnsetAt ? null : (onsetAt ?? this.onsetAt),
      resolvedAt: clearResolvedAt ? null : (resolvedAt ?? this.resolvedAt),
      severityUserReported: clearSeverity
          ? null
          : (severityUserReported ?? this.severityUserReported),
      bodyRegions: bodyRegions ?? this.bodyRegions,
      clinicianConfirmed: clinicianConfirmed ?? this.clinicianConfirmed,
      notes: nextNotes,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        profileId,
        title,
        type,
        status,
        onsetAt,
        resolvedAt,
        severityUserReported,
        bodyRegions,
        clinicianConfirmed,
        notes,
        createdAt,
        updatedAt,
      ];
}
