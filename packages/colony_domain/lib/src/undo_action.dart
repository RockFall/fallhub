import 'package:equatable/equatable.dart';

import 'enums.dart';
import 'id_generator.dart';
import 'task.dart';

class UndoAction extends Equatable {
  const UndoAction({
    required this.id,
    required this.type,
    required this.createdAt,
    required this.description,
    this.taskBefore,
    this.taskId,
  });

  final EntityId id;
  final UndoActionType type;
  final DateTime createdAt;
  final String description;
  final EntityId? taskId;
  final ColonyTask? taskBefore;

  @override
  List<Object?> get props =>
      [id, type, createdAt, description, taskId, taskBefore];
}
