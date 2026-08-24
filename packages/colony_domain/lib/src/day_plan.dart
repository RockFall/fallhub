import 'package:equatable/equatable.dart';

import 'day_plan_policy.dart';
import 'enums.dart';
import 'id_generator.dart';
import 'task.dart';

/// `YYYY-MM-DD` for the device-local calendar date (same convention as
/// `scheduleCalendarDay`), not a UTC instant.
String dayPlanLocalDateKey(DateTime instant) {
  final local = instant.toLocal();
  return '${local.year.toString().padLeft(4, '0')}-'
      '${local.month.toString().padLeft(2, '0')}-'
      '${local.day.toString().padLeft(2, '0')}';
}

/// Shifts a `YYYY-MM-DD` key by [days] using calendar arithmetic (DST-safe).
String dayPlanShiftDate(String localDate, int days) {
  if (!DayPlanPolicies.isValidLocalDateKey(localDate)) {
    throw ArgumentError.value(localDate, 'localDate', 'esperado YYYY-MM-DD');
  }
  final parts = localDate.split('-');
  final shifted = DateTime(
    int.parse(parts[0]),
    int.parse(parts[1]),
    int.parse(parts[2]) + days,
  );
  return dayPlanLocalDateKey(shifted);
}

class DayPlan extends Equatable {
  const DayPlan({
    required this.id,
    required this.profileId,
    required this.localDate,
    required this.createdAt,
    required this.updatedAt,
    this.version = 1,
  });

  final EntityId id;
  final EntityId profileId;

  /// `YYYY-MM-DD`, device-local calendar date. Immutable after creation.
  final String localDate;
  final DateTime createdAt;
  final DateTime updatedAt;
  final int version;

  factory DayPlan.forDate({
    required EntityId id,
    required EntityId profileId,
    required String localDate,
    required DateTime createdAt,
  }) {
    if (!DayPlanPolicies.isValidLocalDateKey(localDate)) {
      throw ArgumentError.value(localDate, 'localDate', 'esperado YYYY-MM-DD');
    }
    return DayPlan(
      id: id,
      profileId: profileId,
      localDate: localDate,
      createdAt: createdAt,
      updatedAt: createdAt,
    );
  }

  DayPlan touched(DateTime at) => DayPlan(
        id: id,
        profileId: profileId,
        localDate: localDate,
        createdAt: createdAt,
        updatedAt: at,
        version: version + 1,
      );

  @override
  List<Object?> get props =>
      [id, profileId, localDate, createdAt, updatedAt, version];
}

class DayPlanItem extends Equatable {
  const DayPlanItem({
    required this.id,
    required this.dayPlanId,
    required this.title,
    required this.orderIndex,
    required this.createdAt,
    required this.updatedAt,
    this.taskId,
    this.sourceType = SourceType.manual,
    this.carriedFromItemId,
    this.completedAt,
    this.version = 1,
  });

  final EntityId id;
  final EntityId dayPlanId;

  /// Null ⇒ ad-hoc item, no backing [ColonyTask].
  final EntityId? taskId;

  /// Title snapshot. Always present, even when [taskId] is set.
  final String title;
  final int orderIndex;
  final SourceType sourceType;
  final EntityId? carriedFromItemId;
  final DateTime? completedAt;
  final DateTime createdAt;
  final DateTime updatedAt;
  final int version;

  bool get isDone => completedAt != null;
  bool get isLinked => taskId != null;

  factory DayPlanItem.adHoc({
    required EntityId id,
    required EntityId dayPlanId,
    required String title,
    required int orderIndex,
    required DateTime createdAt,
  }) {
    final trimmed = DayPlanPolicies.snapshotTitle(title);
    if (!DayPlanPolicies.isValidItemTitle(trimmed)) {
      throw ArgumentError('title vazio');
    }
    return DayPlanItem(
      id: id,
      dayPlanId: dayPlanId,
      title: trimmed,
      orderIndex: orderIndex,
      createdAt: createdAt,
      updatedAt: createdAt,
    );
  }

  factory DayPlanItem.fromTaskPull({
    required EntityId id,
    required EntityId dayPlanId,
    required ColonyTask task,
    required int orderIndex,
    required DateTime createdAt,
  }) {
    return DayPlanItem(
      id: id,
      dayPlanId: dayPlanId,
      taskId: task.id,
      title: DayPlanPolicies.snapshotTitle(task.title),
      orderIndex: orderIndex,
      createdAt: createdAt,
      updatedAt: createdAt,
    );
  }

  factory DayPlanItem.carriedOver({
    required EntityId id,
    required EntityId dayPlanId,
    required DayPlanItem source,
    required int orderIndex,
    required DateTime createdAt,
    String? refreshedTitle,
  }) {
    return DayPlanItem(
      id: id,
      dayPlanId: dayPlanId,
      taskId: source.taskId,
      title: refreshedTitle == null
          ? source.title
          : DayPlanPolicies.snapshotTitle(refreshedTitle),
      orderIndex: orderIndex,
      sourceType: SourceType.derived,
      carriedFromItemId: source.id,
      createdAt: createdAt,
      updatedAt: createdAt,
    );
  }

  DayPlanItem copyWith({
    String? title,
    int? orderIndex,
    DateTime? completedAt,
    DateTime? updatedAt,
    int? version,
    bool clearCompletedAt = false,
  }) {
    return DayPlanItem(
      id: id,
      dayPlanId: dayPlanId,
      taskId: taskId,
      title: title ?? this.title,
      orderIndex: orderIndex ?? this.orderIndex,
      sourceType: sourceType,
      carriedFromItemId: carriedFromItemId,
      completedAt: clearCompletedAt ? null : (completedAt ?? this.completedAt),
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      version: version ?? this.version,
    );
  }

  @override
  List<Object?> get props => [
        id,
        dayPlanId,
        taskId,
        title,
        orderIndex,
        sourceType,
        carriedFromItemId,
        completedAt,
        createdAt,
        updatedAt,
        version,
      ];
}

/// View-shape returned by repository/watch APIs. Not a persisted row.
class DayPlanWithItems extends Equatable {
  const DayPlanWithItems({required this.plan, required this.items});

  final DayPlan plan;

  /// Sorted ascending by [DayPlanItem.orderIndex].
  final List<DayPlanItem> items;

  @override
  List<Object?> get props => [plan, items];
}
