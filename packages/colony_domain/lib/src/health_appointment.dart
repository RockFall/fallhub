import 'package:equatable/equatable.dart';

import 'id_generator.dart';

enum HealthAppointmentStatus {
  scheduled,
  done,
  cancelled;

  bool get isHiddenFromActiveList =>
      this == done || this == cancelled;
}

/// Local appointment reminder (ADR-023 addendum). Not medical advice; no diagnosis.
class HealthAppointment extends Equatable {
  const HealthAppointment({
    required this.id,
    required this.profileId,
    required this.title,
    required this.scheduledAt,
    this.locationLabel,
    this.clinicianLabel,
    this.notes,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
  });

  final EntityId id;
  final EntityId profileId;
  final String title;
  final DateTime scheduledAt;
  final String? locationLabel;
  final String? clinicianLabel;
  final String? notes;
  final HealthAppointmentStatus status;
  final DateTime createdAt;
  final DateTime updatedAt;

  factory HealthAppointment.create({
    required EntityId id,
    required EntityId profileId,
    required String title,
    required DateTime scheduledAt,
    String? locationLabel,
    String? clinicianLabel,
    String? notes,
    HealthAppointmentStatus status = HealthAppointmentStatus.scheduled,
    required DateTime createdAt,
  }) {
    final trimmed = title.trim();
    if (trimmed.isEmpty) {
      throw ArgumentError('HealthAppointment title cannot be empty');
    }
    final loc = locationLabel?.trim();
    final clinician = clinicianLabel?.trim();
    final n = notes?.trim();
    return HealthAppointment(
      id: id,
      profileId: profileId,
      title: trimmed,
      scheduledAt: scheduledAt.toUtc(),
      locationLabel: (loc == null || loc.isEmpty) ? null : loc,
      clinicianLabel: (clinician == null || clinician.isEmpty) ? null : clinician,
      notes: (n == null || n.isEmpty) ? null : n,
      status: status,
      createdAt: createdAt,
      updatedAt: createdAt,
    );
  }

  HealthAppointment copyWith({
    String? title,
    DateTime? scheduledAt,
    String? locationLabel,
    bool clearLocationLabel = false,
    String? clinicianLabel,
    bool clearClinicianLabel = false,
    String? notes,
    bool clearNotes = false,
    HealthAppointmentStatus? status,
    DateTime? updatedAt,
  }) {
    final nextTitle = title?.trim() ?? this.title;
    if (nextTitle.isEmpty) {
      throw ArgumentError('HealthAppointment title cannot be empty');
    }
    return HealthAppointment(
      id: id,
      profileId: profileId,
      title: nextTitle,
      scheduledAt: (scheduledAt ?? this.scheduledAt).toUtc(),
      locationLabel: clearLocationLabel
          ? null
          : (locationLabel != null
              ? (locationLabel.trim().isEmpty ? null : locationLabel.trim())
              : this.locationLabel),
      clinicianLabel: clearClinicianLabel
          ? null
          : (clinicianLabel != null
              ? (clinicianLabel.trim().isEmpty ? null : clinicianLabel.trim())
              : this.clinicianLabel),
      notes: clearNotes
          ? null
          : (notes != null
              ? (notes.trim().isEmpty ? null : notes.trim())
              : this.notes),
      status: status ?? this.status,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        profileId,
        title,
        scheduledAt,
        locationLabel,
        clinicianLabel,
        notes,
        status,
        createdAt,
        updatedAt,
      ];
}
