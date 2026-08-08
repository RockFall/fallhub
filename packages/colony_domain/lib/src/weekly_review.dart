import 'package:equatable/equatable.dart';

import 'id_generator.dart';

/// Returns UTC midnight of the week start containing [date].
///
/// When [weekStartsOnMonday] is true, weeks start on Monday; otherwise Sunday.
DateTime weekStartDateFor(
  DateTime date, {
  required bool weekStartsOnMonday,
}) {
  final day = DateTime.utc(date.year, date.month, date.day);
  if (weekStartsOnMonday) {
    final daysFromMonday = day.weekday - DateTime.monday;
    return day.subtract(Duration(days: daysFromMonday));
  }
  final daysFromSunday = day.weekday % DateTime.daysPerWeek;
  return day.subtract(Duration(days: daysFromSunday));
}

class WeeklyReview extends Equatable {
  const WeeklyReview({
    required this.id,
    required this.profileId,
    required this.weekStartDate,
    required this.createdAt,
    this.facts,
    this.wins,
    this.problems,
    this.projects,
    this.learning,
    this.nextWeek,
  });

  final EntityId id;
  final EntityId profileId;
  final DateTime weekStartDate;
  final DateTime createdAt;
  final String? facts;
  final String? wins;
  final String? problems;
  final String? projects;
  final String? learning;
  final String? nextWeek;

  @override
  List<Object?> get props => [
        id,
        profileId,
        weekStartDate,
        createdAt,
        facts,
        wins,
        problems,
        projects,
        learning,
        nextWeek,
      ];
}
