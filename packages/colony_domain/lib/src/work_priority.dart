import 'package:equatable/equatable.dart';

import 'id_generator.dart';
import 'work_enums.dart';

class WorkPriority extends Equatable {
  const WorkPriority({
    required this.profileId,
    required this.workType,
    required this.level,
    required this.updatedAt,
  });

  final EntityId profileId;
  final WorkType workType;
  final PriorityLevel level;
  final DateTime updatedAt;

  WorkPriority copyWith({
    PriorityLevel? level,
    DateTime? updatedAt,
  }) {
    return WorkPriority(
      profileId: profileId,
      workType: workType,
      level: level ?? this.level,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [profileId, workType, level, updatedAt];
}

/// Cycles priority on tap: blocked → immediate → high → normal → low → auto → blocked.
abstract final class PriorityCyclePolicy {
  static const cycle = [
    PriorityLevel.blocked,
    PriorityLevel.immediate,
    PriorityLevel.high,
    PriorityLevel.normal,
    PriorityLevel.low,
    PriorityLevel.automatic,
  ];

  static PriorityLevel next(PriorityLevel current) {
    final index = cycle.indexOf(current);
    if (index < 0) return PriorityLevel.blocked;
    return cycle[(index + 1) % cycle.length];
  }
}
