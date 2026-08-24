import 'package:equatable/equatable.dart';

import 'enums.dart';
import 'id_generator.dart';

class ColonyTask extends Equatable {
  const ColonyTask({
    required this.id,
    required this.profileId,
    required this.title,
    required this.status,
    required this.sourceType,
    required this.createdAt,
    required this.updatedAt,
    this.description,
    this.dueAt,
    this.scheduledStart,
    this.estimatedMinutes,
    this.actualMinutes,
    this.energyRequirement = EnergyRequirement.unknown,
    this.blockedReason,
    this.completedAt,
    this.deletedAt,
    this.version = 1,
    this.questId,
  });

  final EntityId id;
  final EntityId profileId;
  final String title;
  final String? description;
  final TaskStatus status;
  final SourceType sourceType;
  final DateTime? dueAt;
  final DateTime? scheduledStart;
  final int? estimatedMinutes;
  final int? actualMinutes;
  final EnergyRequirement energyRequirement;
  final String? blockedReason;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? completedAt;
  final DateTime? deletedAt;
  final int version;
  final EntityId? questId;

  factory ColonyTask.capture({
    required EntityId id,
    required EntityId profileId,
    required String title,
    required DateTime createdAt,
  }) {
    return ColonyTask(
      id: id,
      profileId: profileId,
      title: title,
      status: TaskStatus.inbox,
      sourceType: SourceType.manual,
      createdAt: createdAt,
      updatedAt: createdAt,
    );
  }

  ColonyTask copyWith({
    String? title,
    String? description,
    TaskStatus? status,
    SourceType? sourceType,
    DateTime? dueAt,
    DateTime? scheduledStart,
    int? estimatedMinutes,
    int? actualMinutes,
    EnergyRequirement? energyRequirement,
    String? blockedReason,
    DateTime? updatedAt,
    DateTime? completedAt,
    DateTime? deletedAt,
    int? version,
    EntityId? questId,
    bool clearBlockedReason = false,
    bool clearCompletedAt = false,
    bool clearQuestId = false,
  }) {
    return ColonyTask(
      id: id,
      profileId: profileId,
      title: title ?? this.title,
      description: description ?? this.description,
      status: status ?? this.status,
      sourceType: sourceType ?? this.sourceType,
      dueAt: dueAt ?? this.dueAt,
      scheduledStart: scheduledStart ?? this.scheduledStart,
      estimatedMinutes: estimatedMinutes ?? this.estimatedMinutes,
      actualMinutes: actualMinutes ?? this.actualMinutes,
      energyRequirement: energyRequirement ?? this.energyRequirement,
      blockedReason:
          clearBlockedReason ? null : (blockedReason ?? this.blockedReason),
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      completedAt:
          clearCompletedAt ? null : (completedAt ?? this.completedAt),
      deletedAt: deletedAt ?? this.deletedAt,
      version: version ?? this.version,
      questId: clearQuestId ? null : (questId ?? this.questId),
    );
  }

  ColonyTask withStatus(TaskStatus newStatus, DateTime at) {
    final completing = newStatus == TaskStatus.done;
    final blocking = newStatus == TaskStatus.blocked;
    return copyWith(
      status: newStatus,
      updatedAt: at,
      completedAt: completing ? at : null,
      clearCompletedAt: !completing,
      clearBlockedReason: !blocking,
    );
  }

  @override
  List<Object?> get props => [
        id,
        profileId,
        title,
        description,
        status,
        sourceType,
        dueAt,
        scheduledStart,
        estimatedMinutes,
        actualMinutes,
        energyRequirement,
        blockedReason,
        createdAt,
        updatedAt,
        completedAt,
        deletedAt,
        version,
        questId,
      ];
}

class TaskTransitionPolicy {
  const TaskTransitionPolicy._();

  static bool canTransition(TaskStatus from, TaskStatus to) {
    if (from == to) return true;
    return _allowed[from]?.contains(to) ?? false;
  }

  static const _allowed = <TaskStatus, Set<TaskStatus>>{
    TaskStatus.inbox: {
      TaskStatus.next,
      TaskStatus.scheduled,
      TaskStatus.archived,
      TaskStatus.cancelled,
      TaskStatus.done,
    },
    TaskStatus.next: {
      TaskStatus.doing,
      TaskStatus.scheduled,
      TaskStatus.blocked,
      TaskStatus.waiting,
      TaskStatus.cancelled,
      TaskStatus.archived,
      TaskStatus.done,
    },
    TaskStatus.scheduled: {
      TaskStatus.doing,
      TaskStatus.next,
      TaskStatus.cancelled,
      TaskStatus.archived,
      TaskStatus.done,
    },
    TaskStatus.doing: {
      TaskStatus.done,
      TaskStatus.blocked,
      TaskStatus.waiting,
      TaskStatus.next,
    },
    TaskStatus.blocked: {
      TaskStatus.next,
      TaskStatus.cancelled,
    },
    TaskStatus.waiting: {
      TaskStatus.next,
      TaskStatus.cancelled,
      TaskStatus.done,
    },
    TaskStatus.done: {
      TaskStatus.next,
      TaskStatus.archived,
    },
    TaskStatus.archived: {
      TaskStatus.next,
    },
    TaskStatus.cancelled: {
      TaskStatus.archived,
      TaskStatus.inbox,
    },
  };
}
