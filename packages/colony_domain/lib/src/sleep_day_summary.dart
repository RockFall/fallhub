import 'package:equatable/equatable.dart';

import 'sleep_session.dart';

/// One calendar day's sleep total (ADR-035).
///
/// Overnight sessions are attributed to the **wake day** (local date of
/// [SleepSession.endedAt]), matching common health apps. Open sessions use
/// today's local date (or start date if [now] is before start).
class SleepDaySummary extends Equatable {
  const SleepDaySummary({
    required this.day,
    required this.sessions,
    required this.total,
  });

  /// Local calendar day at midnight (date only).
  final DateTime day;
  final List<SleepSession> sessions;
  final Duration total;

  int get sessionCount => sessions.length;

  bool get hasOpenSession => sessions.any((s) => s.isOpen);

  @override
  List<Object?> get props => [day, sessions, total];
}

/// Groups closed/open sleep sessions into wake-day buckets, newest first.
List<SleepDaySummary> groupSleepSessionsByWakeDay(
  List<SleepSession> sessions, {
  DateTime? now,
}) {
  final clock = (now ?? DateTime.now()).toLocal();
  final buckets = <DateTime, List<SleepSession>>{};

  for (final session in sessions) {
    final day = _wakeDay(session, clock);
    buckets.putIfAbsent(day, () => []).add(session);
  }

  final days = buckets.keys.toList()
    ..sort((a, b) => b.compareTo(a));

  return [
    for (final day in days)
      SleepDaySummary(
        day: day,
        sessions: (buckets[day]!
              ..sort((a, b) => b.startedAt.compareTo(a.startedAt))),
        total: buckets[day]!.fold<Duration>(
          Duration.zero,
          (sum, s) {
            if (s.endedAt != null) {
              return sum + s.endedAt!.difference(s.startedAt);
            }
            final end = clock.isAfter(s.startedAt.toLocal())
                ? clock
                : s.startedAt.toLocal();
            return sum + end.difference(s.startedAt.toLocal());
          },
        ),
      ),
  ];
}

DateTime _wakeDay(SleepSession session, DateTime nowLocal) {
  final endLocal = session.endedAt?.toLocal();
  if (endLocal != null) {
    return DateTime(endLocal.year, endLocal.month, endLocal.day);
  }
  final startLocal = session.startedAt.toLocal();
  if (nowLocal.isBefore(startLocal)) {
    return DateTime(startLocal.year, startLocal.month, startLocal.day);
  }
  return DateTime(nowLocal.year, nowLocal.month, nowLocal.day);
}
