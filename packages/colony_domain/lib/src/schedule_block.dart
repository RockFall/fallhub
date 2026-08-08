import 'package:equatable/equatable.dart';

import 'id_generator.dart';
import 'schedule_day.dart';
import 'work_enums.dart';

class ScheduleBlock extends Equatable {
  const ScheduleBlock({
    required this.id,
    required this.profileId,
    required this.startAt,
    required this.endAt,
    required this.mode,
    required this.createdAt,
    required this.updatedAt,
  });

  final EntityId id;
  final EntityId profileId;
  final DateTime startAt;
  final DateTime endAt;
  final ScheduleBlockMode mode;
  final DateTime createdAt;
  final DateTime updatedAt;

  factory ScheduleBlock.create({
    required EntityId id,
    required EntityId profileId,
    required DateTime startAt,
    required DateTime endAt,
    required ScheduleBlockMode mode,
    required DateTime createdAt,
  }) {
    assertScheduleBlockTimeRange(startAt, endAt);
    return ScheduleBlock(
      id: id,
      profileId: profileId,
      startAt: startAt,
      endAt: endAt,
      mode: mode,
      createdAt: createdAt,
      updatedAt: createdAt,
    );
  }

  ScheduleBlock copyWith({
    DateTime? startAt,
    DateTime? endAt,
    ScheduleBlockMode? mode,
    DateTime? updatedAt,
  }) {
    return ScheduleBlock(
      id: id,
      profileId: profileId,
      startAt: startAt ?? this.startAt,
      endAt: endAt ?? this.endAt,
      mode: mode ?? this.mode,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props =>
      [id, profileId, startAt, endAt, mode, createdAt, updatedAt];
}
