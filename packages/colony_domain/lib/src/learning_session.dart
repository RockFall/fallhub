import 'package:equatable/equatable.dart';

import 'id_generator.dart';

enum LearningSessionMode {
  read,
  watch,
  practice,
  review,
}

class LearningSession extends Equatable {
  const LearningSession({
    required this.id,
    required this.profileId,
    required this.nodeId,
    required this.startedAt,
    required this.durationMinutes,
    required this.mode,
    this.notes,
  });

  final EntityId id;
  final EntityId profileId;
  final EntityId nodeId;
  final DateTime startedAt;
  final int durationMinutes;
  final LearningSessionMode mode;
  final String? notes;

  factory LearningSession.create({
    required EntityId id,
    required EntityId profileId,
    required EntityId nodeId,
    required DateTime startedAt,
    required int durationMinutes,
    required LearningSessionMode mode,
    String? notes,
  }) {
    return LearningSession(
      id: id,
      profileId: profileId,
      nodeId: nodeId,
      startedAt: startedAt,
      durationMinutes: durationMinutes,
      mode: mode,
      notes: notes?.trim().isEmpty ?? true ? null : notes?.trim(),
    );
  }

  @override
  List<Object?> get props => [
        id,
        profileId,
        nodeId,
        startedAt,
        durationMinutes,
        mode,
        notes,
      ];
}
