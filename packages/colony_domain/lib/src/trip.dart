import 'package:equatable/equatable.dart';

import 'id_generator.dart';

enum TripStatus {
  planned,
  active,
  completed,
  cancelled;

  bool get isHiddenFromActiveList => this == cancelled;
}

/// Personal trip / travel plan (ADR-027). Local record only; not a booking agency.
class Trip extends Equatable {
  const Trip({
    required this.id,
    required this.profileId,
    required this.title,
    this.destinations = const [],
    this.startAt,
    this.endAt,
    this.purpose,
    this.notes,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
  });

  final EntityId id;
  final EntityId profileId;
  final String title;
  final List<String> destinations;
  final DateTime? startAt;
  final DateTime? endAt;
  final String? purpose;
  final String? notes;
  final TripStatus status;
  final DateTime createdAt;
  final DateTime updatedAt;

  factory Trip.create({
    required EntityId id,
    required EntityId profileId,
    required String title,
    List<String> destinations = const [],
    DateTime? startAt,
    DateTime? endAt,
    String? purpose,
    String? notes,
    TripStatus status = TripStatus.planned,
    required DateTime createdAt,
  }) {
    final trimmedTitle = title.trim();
    if (trimmedTitle.isEmpty) {
      throw ArgumentError('Trip title cannot be empty');
    }
    if (startAt != null && endAt != null && endAt.isBefore(startAt)) {
      throw ArgumentError('Trip endAt cannot be before startAt');
    }
    final trimmedPurpose = purpose?.trim();
    final trimmedNotes = notes?.trim();
    return Trip(
      id: id,
      profileId: profileId,
      title: trimmedTitle,
      destinations: destinations
          .map((d) => d.trim())
          .where((d) => d.isNotEmpty)
          .toList(),
      startAt: startAt,
      endAt: endAt,
      purpose: (trimmedPurpose == null || trimmedPurpose.isEmpty)
          ? null
          : trimmedPurpose,
      notes: (trimmedNotes == null || trimmedNotes.isEmpty)
          ? null
          : trimmedNotes,
      status: status,
      createdAt: createdAt,
      updatedAt: createdAt,
    );
  }

  Trip copyWith({
    String? title,
    List<String>? destinations,
    DateTime? startAt,
    bool clearStartAt = false,
    DateTime? endAt,
    bool clearEndAt = false,
    String? purpose,
    bool clearPurpose = false,
    String? notes,
    bool clearNotes = false,
    TripStatus? status,
    DateTime? updatedAt,
  }) {
    final nextTitle = title?.trim() ?? this.title;
    if (nextTitle.isEmpty) {
      throw ArgumentError('Trip title cannot be empty');
    }
    final nextStart = clearStartAt ? null : (startAt ?? this.startAt);
    final nextEnd = clearEndAt ? null : (endAt ?? this.endAt);
    if (nextStart != null && nextEnd != null && nextEnd.isBefore(nextStart)) {
      throw ArgumentError('Trip endAt cannot be before startAt');
    }
    final nextPurpose = clearPurpose
        ? null
        : (purpose != null
            ? (purpose.trim().isEmpty ? null : purpose.trim())
            : this.purpose);
    final nextNotes = clearNotes
        ? null
        : (notes != null
            ? (notes.trim().isEmpty ? null : notes.trim())
            : this.notes);
    return Trip(
      id: id,
      profileId: profileId,
      title: nextTitle,
      destinations: destinations ?? this.destinations,
      startAt: nextStart,
      endAt: nextEnd,
      purpose: nextPurpose,
      notes: nextNotes,
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
        destinations,
        startAt,
        endAt,
        purpose,
        notes,
        status,
        createdAt,
        updatedAt,
      ];
}
