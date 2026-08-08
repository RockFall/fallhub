import 'package:equatable/equatable.dart';

import 'id_generator.dart';

enum ProjectStatus {
  active,
  completed,
  archived;

  bool get isTerminal => this == completed || this == archived;
}

class Project extends Equatable {
  const Project({
    required this.id,
    required this.profileId,
    required this.title,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    this.purpose,
    this.version = 1,
  });

  final EntityId id;
  final EntityId profileId;
  final String title;
  final String? purpose;
  final ProjectStatus status;
  final DateTime createdAt;
  final DateTime updatedAt;
  final int version;

  factory Project.create({
    required EntityId id,
    required EntityId profileId,
    required String title,
    required DateTime createdAt,
    String? purpose,
    ProjectStatus status = ProjectStatus.active,
  }) {
    return Project(
      id: id,
      profileId: profileId,
      title: title.trim(),
      purpose: purpose?.trim(),
      status: status,
      createdAt: createdAt,
      updatedAt: createdAt,
    );
  }

  Project copyWith({
    String? title,
    String? purpose,
    ProjectStatus? status,
    DateTime? updatedAt,
    int? version,
    bool clearPurpose = false,
  }) {
    return Project(
      id: id,
      profileId: profileId,
      title: title ?? this.title,
      purpose: clearPurpose ? null : (purpose ?? this.purpose),
      status: status ?? this.status,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      version: version ?? this.version,
    );
  }

  @override
  List<Object?> get props =>
      [id, profileId, title, purpose, status, createdAt, updatedAt, version];
}

class QuestProjectLink extends Equatable {
  const QuestProjectLink({
    required this.questId,
    required this.projectId,
    required this.linkedAt,
  });

  final EntityId questId;
  final EntityId projectId;
  final DateTime linkedAt;

  @override
  List<Object?> get props => [questId, projectId, linkedAt];
}

class ProjectLifecyclePolicy {
  const ProjectLifecyclePolicy._();

  static bool canTransition(ProjectStatus from, ProjectStatus to) {
    if (from == to) return true;
    return _allowed[from]?.contains(to) ?? false;
  }

  static const _allowed = <ProjectStatus, Set<ProjectStatus>>{
    ProjectStatus.active: {ProjectStatus.completed},
    ProjectStatus.completed: {ProjectStatus.archived},
    ProjectStatus.archived: {},
  };
}
