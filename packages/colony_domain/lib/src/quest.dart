import 'package:equatable/equatable.dart';

import 'id_generator.dart';

enum QuestStatus {
  draft,
  active,
  paused,
  completed,
  abandoned;

  bool get isTerminal => this == completed || this == abandoned;

  bool get isActiveBoard => this == active || this == paused;

  bool get isDraftBoard => this == draft;

  bool get isHistoryBoard => this == completed || this == abandoned;
}

class Quest extends Equatable {
  const Quest({
    required this.id,
    required this.profileId,
    required this.title,
    required this.purpose,
    required this.successCriteria,
    required this.risks,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    this.deadline,
    this.exitReason,
    this.pauseReason,
    this.completedAt,
    this.acceptedAt,
    this.acceptanceDeadline,
    this.acceptanceAssumptions = const [],
    this.version = 1,
  });

  final EntityId id;
  final EntityId profileId;
  final String title;
  final String purpose;
  final List<String> successCriteria;
  final List<String> risks;
  final DateTime? deadline;
  final QuestStatus status;
  final String? exitReason;
  final String? pauseReason;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? completedAt;
  final DateTime? acceptedAt;
  final DateTime? acceptanceDeadline;
  final List<String> acceptanceAssumptions;
  final int version;

  factory Quest.create({
    required EntityId id,
    required EntityId profileId,
    required String title,
    required String purpose,
    required DateTime createdAt,
    QuestStatus status = QuestStatus.draft,
    List<String> successCriteria = const [],
    List<String> risks = const [],
    DateTime? deadline,
  }) {
    return Quest(
      id: id,
      profileId: profileId,
      title: title.trim(),
      purpose: purpose.trim(),
      successCriteria: successCriteria,
      risks: risks,
      deadline: deadline,
      status: status,
      createdAt: createdAt,
      updatedAt: createdAt,
    );
  }

  Quest copyWith({
    String? title,
    String? purpose,
    List<String>? successCriteria,
    List<String>? risks,
    DateTime? deadline,
    QuestStatus? status,
    String? exitReason,
    String? pauseReason,
    DateTime? updatedAt,
    DateTime? completedAt,
    DateTime? acceptedAt,
    DateTime? acceptanceDeadline,
    List<String>? acceptanceAssumptions,
    int? version,
    bool clearDeadline = false,
    bool clearExitReason = false,
    bool clearPauseReason = false,
    bool clearCompletedAt = false,
    bool clearAcceptedAt = false,
    bool clearAcceptanceDeadline = false,
  }) {
    return Quest(
      id: id,
      profileId: profileId,
      title: title ?? this.title,
      purpose: purpose ?? this.purpose,
      successCriteria: successCriteria ?? this.successCriteria,
      risks: risks ?? this.risks,
      deadline: clearDeadline ? null : (deadline ?? this.deadline),
      status: status ?? this.status,
      exitReason: clearExitReason ? null : (exitReason ?? this.exitReason),
      pauseReason: clearPauseReason ? null : (pauseReason ?? this.pauseReason),
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      completedAt: clearCompletedAt ? null : (completedAt ?? this.completedAt),
      acceptedAt: clearAcceptedAt ? null : (acceptedAt ?? this.acceptedAt),
      acceptanceDeadline: clearAcceptanceDeadline
          ? null
          : (acceptanceDeadline ?? this.acceptanceDeadline),
      acceptanceAssumptions:
          acceptanceAssumptions ?? this.acceptanceAssumptions,
      version: version ?? this.version,
    );
  }

  @override
  List<Object?> get props => [
        id,
        profileId,
        title,
        purpose,
        successCriteria,
        risks,
        deadline,
        status,
        exitReason,
        pauseReason,
        createdAt,
        updatedAt,
        completedAt,
        acceptedAt,
        acceptanceDeadline,
        acceptanceAssumptions,
        version,
      ];
}

class QuestLifecyclePolicy {
  const QuestLifecyclePolicy._();

  static bool canTransition(QuestStatus from, QuestStatus to) {
    if (from == to) return true;
    return _allowed[from]?.contains(to) ?? false;
  }

  static const _allowed = <QuestStatus, Set<QuestStatus>>{
    QuestStatus.draft: {QuestStatus.active},
    QuestStatus.active: {
      QuestStatus.paused,
      QuestStatus.completed,
      QuestStatus.abandoned,
    },
    QuestStatus.paused: {
      QuestStatus.active,
      QuestStatus.completed,
      QuestStatus.abandoned,
    },
    QuestStatus.completed: {},
    QuestStatus.abandoned: {},
  };
}
