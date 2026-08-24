import 'package:equatable/equatable.dart';

import 'day_plan.dart';
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
    this.dayPlanItemBefore,
    this.dayPlanItemId,
  });

  final EntityId id;
  final UndoActionType type;
  final DateTime createdAt;
  final String description;
  final EntityId? taskId;
  final ColonyTask? taskBefore;
  final EntityId? dayPlanItemId;
  final DayPlanItem? dayPlanItemBefore;

  @override
  List<Object?> get props => [
        id,
        type,
        createdAt,
        description,
        taskId,
        taskBefore,
        dayPlanItemId,
        dayPlanItemBefore,
      ];
}
