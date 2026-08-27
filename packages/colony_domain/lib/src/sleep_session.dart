import 'package:equatable/equatable.dart';

import 'enums.dart';
import 'id_generator.dart';

/// How a sleep session was produced (ADR-035).
enum SleepSessionSource {
  /// On-device sensor fusion (phone stillness + screen + charge).
  detected,

  /// Imported from Health Connect (e.g. Samsung Health / watch).
  healthConnect,

  /// User-entered correction or manual log.
  manual,
}

/// Local sleep interval with provenance. Not a clinical sleep study.
class SleepSession extends Equatable {
  const SleepSession({
    required this.id,
    required this.profileId,
    required this.startedAt,
    this.endedAt,
    required this.source,
    required this.confidence,
    this.externalId,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
  });

  final EntityId id;
  final EntityId profileId;
  final DateTime startedAt;
  final DateTime? endedAt;
  final SleepSessionSource source;
  final ConfidenceLevel confidence;
  final String? externalId;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;

  bool get isOpen => endedAt == null;

  Duration? get duration {
    final end = endedAt;
    if (end == null) return null;
    return end.difference(startedAt);
  }

  factory SleepSession.create({
    required EntityId id,
    required EntityId profileId,
    required DateTime startedAt,
    DateTime? endedAt,
    required SleepSessionSource source,
    ConfidenceLevel confidence = ConfidenceLevel.medium,
    String? externalId,
    String? notes,
    required DateTime createdAt,
  }) {
    final start = startedAt.toUtc();
    final end = endedAt?.toUtc();
    if (end != null && !end.isAfter(start)) {
      throw ArgumentError('SleepSession endedAt must be after startedAt');
    }
    final ext = externalId?.trim();
    final n = notes?.trim();
    return SleepSession(
      id: id,
      profileId: profileId,
      startedAt: start,
      endedAt: end,
      source: source,
      confidence: confidence,
      externalId: (ext == null || ext.isEmpty) ? null : ext,
      notes: (n == null || n.isEmpty) ? null : n,
      createdAt: createdAt,
      updatedAt: createdAt,
    );
  }

  SleepSession copyWith({
    DateTime? startedAt,
    DateTime? endedAt,
    bool clearEndedAt = false,
    SleepSessionSource? source,
    ConfidenceLevel? confidence,
    String? externalId,
    bool clearExternalId = false,
    String? notes,
    bool clearNotes = false,
    DateTime? updatedAt,
  }) {
    final nextEnd = clearEndedAt ? null : (endedAt ?? this.endedAt);
    final nextStart = (startedAt ?? this.startedAt).toUtc();
    if (nextEnd != null && !nextEnd.toUtc().isAfter(nextStart)) {
      throw ArgumentError('SleepSession endedAt must be after startedAt');
    }
    return SleepSession(
      id: id,
      profileId: profileId,
      startedAt: nextStart,
      endedAt: nextEnd?.toUtc(),
      source: source ?? this.source,
      confidence: confidence ?? this.confidence,
      externalId: clearExternalId
          ? null
          : (externalId != null
              ? (externalId.trim().isEmpty ? null : externalId.trim())
              : this.externalId),
      notes: clearNotes
          ? null
          : (notes != null
              ? (notes.trim().isEmpty ? null : notes.trim())
              : this.notes),
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        profileId,
        startedAt,
        endedAt,
        source,
        confidence,
        externalId,
        notes,
        createdAt,
        updatedAt,
      ];
}
