/// Calendar-day helpers for schedule features.
///
/// Schedule UI uses local calendar dates (year/month/day). Stored instants are
/// UTC; day bounds are local midnight through next midnight converted to UTC.
DateTime scheduleCalendarDay(DateTime instant) {
  final local = instant.toLocal();
  return DateTime(local.year, local.month, local.day);
}

/// UTC instants for the half-open interval `[dayStart, dayEnd)` of a calendar day.
({DateTime start, DateTime end}) scheduleDayUtcBounds(DateTime day) {
  final localStart = DateTime(day.year, day.month, day.day);
  return (
    start: localStart.toUtc(),
    end: localStart.add(const Duration(days: 1)).toUtc(),
  );
}

/// Builds UTC instants for block times on a calendar [day] using local hours.
({DateTime startAt, DateTime endAt}) scheduleBlockUtcTimes({
  required DateTime day,
  required int startHour,
  required int startMinute,
  required int endHour,
  required int endMinute,
}) {
  final startAt = DateTime(day.year, day.month, day.day, startHour, startMinute)
      .toUtc();
  final endAt =
      DateTime(day.year, day.month, day.day, endHour, endMinute).toUtc();
  return (startAt: startAt, endAt: endAt);
}

class ScheduleBlockTimeRangeException implements Exception {
  const ScheduleBlockTimeRangeException();

  @override
  String toString() => 'Schedule block end must be after start';
}

void assertScheduleBlockTimeRange(DateTime startAt, DateTime endAt) {
  if (!endAt.isAfter(startAt)) {
    throw const ScheduleBlockTimeRangeException();
  }
}

/// Three consecutive calendar days starting at [anchor] (normalized to local midnight).
List<DateTime> scheduleThreeDayRange(DateTime anchor) {
  final start = scheduleCalendarDay(anchor);
  return [
    start,
    start.add(const Duration(days: 1)),
    start.add(const Duration(days: 2)),
  ];
}

/// Parses `YYYY-MM-DD` query params for schedule deep links.
DateTime? parseScheduleDateParam(String value) {
  final match = RegExp(r'^(\d{4})-(\d{2})-(\d{2})$').firstMatch(value.trim());
  if (match == null) return null;
  final y = int.parse(match.group(1)!);
  final m = int.parse(match.group(2)!);
  final d = int.parse(match.group(3)!);
  return scheduleCalendarDay(DateTime(y, m, d));
}
