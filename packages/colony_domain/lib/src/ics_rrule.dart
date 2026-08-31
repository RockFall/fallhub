import 'integration.dart';

/// Expands a VEVENT RRULE into concrete instances inside a time window.
///
/// Covers the FREQ/INTERVAL/COUNT/UNTIL/BYDAY/BYMONTHDAY subset that Google
/// Agenda puts in `basic.ics`. Not a full RFC 5545 engine.
abstract final class IcsRrule {
  static const maxOccurrences = 800;

  static List<IcsEventPreview> expand({
    required IcsEventPreview seed,
    required String rrule,
    List<DateTime> exdates = const [],
    DateTime? windowStart,
    DateTime? windowEnd,
    int maxOccurrences = IcsRrule.maxOccurrences,
  }) {
    final parsed = _ParsedRrule.tryParse(rrule);
    if (parsed == null) return [seed];

    final duration = seed.endAt.difference(seed.startAt);
    if (!duration.isNegative && duration == Duration.zero) {
      return [seed];
    }

    final seedUtc = seed.startAt.toUtc();
    final startBound = windowStart ?? seedUtc.subtract(const Duration(days: 1));
    final endBound = _minDate(
      windowEnd ?? seedUtc.add(const Duration(days: 400)),
      parsed.until,
    );

    final exSet = {for (final e in exdates) e.toUtc().millisecondsSinceEpoch};

    final out = <IcsEventPreview>[];
    // Walk from DTSTART so COUNT/INTERVAL stay faithful; skip emitting
    // outside the window instead of restarting the series at windowStart.
    var cursor = DateTime.utc(seedUtc.year, seedUtc.month, seedUtc.day);
    final last = DateTime.utc(
      endBound.toUtc().year,
      endBound.toUtc().month,
      endBound.toUtc().day,
    );

    var emittedFromSeed = 0;
    var inWindow = 0;
    var iterations = 0;
    const maxIterations = 20000;
    while (!cursor.isAfter(last) &&
        inWindow < maxOccurrences &&
        iterations < maxIterations) {
      iterations++;
      final candidate = DateTime.utc(
        cursor.year,
        cursor.month,
        cursor.day,
        seedUtc.hour,
        seedUtc.minute,
        seedUtc.second,
      );
      if (!candidate.isBefore(seedUtc) &&
          parsed.matches(candidate, seedUtc) &&
          !exSet.contains(candidate.millisecondsSinceEpoch)) {
        if (parsed.count != null && emittedFromSeed >= parsed.count!) {
          break;
        }
        emittedFromSeed++;
        final inRange =
            !candidate.isBefore(startBound.toUtc()) &&
            candidate.isBefore(
              endBound.toUtc().add(const Duration(seconds: 1)),
            );
        if (inRange) {
          final uid = seed.uid;
          out.add(
            IcsEventPreview(
              uid: uid == null || uid.isEmpty
                  ? null
                  : '$uid#${candidate.toIso8601String()}',
              summary: seed.summary,
              startAt: candidate,
              endAt: candidate.add(duration),
            ),
          );
          inWindow++;
        }
      }
      cursor = cursor.add(const Duration(days: 1));
    }

    return out;
  }

  static DateTime _minDate(DateTime a, DateTime? b) {
    if (b == null) return a;
    return a.isBefore(b) ? a : b;
  }
}

class _ParsedRrule {
  _ParsedRrule({
    required this.freq,
    required this.interval,
    this.count,
    this.until,
    required this.byDays,
    required this.byMonthDays,
  });

  final _Freq freq;
  final int interval;
  final int? count;
  final DateTime? until;
  final Set<int> byDays;
  final Set<int> byMonthDays;

  static _ParsedRrule? tryParse(String raw) {
    final text = raw.trim();
    if (text.isEmpty) return null;
    final parts = <String, String>{};
    for (final piece in text.split(';')) {
      final cut = piece.indexOf('=');
      if (cut <= 0) continue;
      parts[piece.substring(0, cut).trim().toUpperCase()] = piece
          .substring(cut + 1)
          .trim();
    }
    final freqName = parts['FREQ']?.toUpperCase();
    final freq = switch (freqName) {
      'DAILY' => _Freq.daily,
      'WEEKLY' => _Freq.weekly,
      'MONTHLY' => _Freq.monthly,
      'YEARLY' => _Freq.yearly,
      _ => null,
    };
    if (freq == null) return null;

    final interval = int.tryParse(parts['INTERVAL'] ?? '1') ?? 1;
    final count = int.tryParse(parts['COUNT'] ?? '');
    DateTime? until;
    final untilRaw = parts['UNTIL'];
    if (untilRaw != null && untilRaw.isNotEmpty) {
      until = _parseUntil(untilRaw);
    }

    final byDays = <int>{};
    final byDayRaw = parts['BYDAY'];
    if (byDayRaw != null) {
      for (final tok in byDayRaw.split(',')) {
        final wd = _weekday(tok.replaceAll(RegExp(r'[^A-Z]'), ''));
        if (wd != null) byDays.add(wd);
      }
    }

    final byMonthDays = <int>{};
    final byMonthDayRaw = parts['BYMONTHDAY'];
    if (byMonthDayRaw != null) {
      for (final tok in byMonthDayRaw.split(',')) {
        final n = int.tryParse(tok.trim());
        if (n != null && n >= 1 && n <= 31) byMonthDays.add(n);
      }
    }

    return _ParsedRrule(
      freq: freq,
      interval: interval < 1 ? 1 : interval,
      count: count != null && count > 0 ? count : null,
      until: until,
      byDays: byDays,
      byMonthDays: byMonthDays,
    );
  }

  bool matches(DateTime candidate, DateTime seed) {
    switch (freq) {
      case _Freq.daily:
        final days = candidate
            .difference(DateTime.utc(seed.year, seed.month, seed.day))
            .inDays;
        return days >= 0 && days % interval == 0;
      case _Freq.weekly:
        final seedWeekday = seed.weekday;
        final allowed = byDays.isEmpty ? {seedWeekday} : byDays;
        if (!allowed.contains(candidate.weekday)) return false;
        final seedMonday = seed.subtract(Duration(days: seed.weekday - 1));
        final candMonday = candidate.subtract(
          Duration(days: candidate.weekday - 1),
        );
        final weeks =
            DateTime.utc(candMonday.year, candMonday.month, candMonday.day)
                .difference(
                  DateTime.utc(
                    seedMonday.year,
                    seedMonday.month,
                    seedMonday.day,
                  ),
                )
                .inDays ~/
            7;
        return weeks >= 0 && weeks % interval == 0;
      case _Freq.monthly:
        final monthDelta =
            (candidate.year - seed.year) * 12 + (candidate.month - seed.month);
        if (monthDelta < 0 || monthDelta % interval != 0) return false;
        if (byMonthDays.isNotEmpty) return byMonthDays.contains(candidate.day);
        return candidate.day == seed.day;
      case _Freq.yearly:
        final yearDelta = candidate.year - seed.year;
        if (yearDelta < 0 || yearDelta % interval != 0) return false;
        return candidate.month == seed.month && candidate.day == seed.day;
    }
  }

  static DateTime? _parseUntil(String raw) {
    final cleaned = raw.trim().replaceAll(RegExp(r'[-:]'), '');
    if (RegExp(r'^\d{8}$').hasMatch(cleaned)) {
      return DateTime.utc(
        int.parse(cleaned.substring(0, 4)),
        int.parse(cleaned.substring(4, 6)),
        int.parse(cleaned.substring(6, 8)),
        23,
        59,
        59,
      );
    }
    final m = RegExp(
      r'^(\d{4})(\d{2})(\d{2})T(\d{2})(\d{2})(\d{2})Z?$',
    ).firstMatch(cleaned);
    if (m == null) return null;
    return DateTime.utc(
      int.parse(m.group(1)!),
      int.parse(m.group(2)!),
      int.parse(m.group(3)!),
      int.parse(m.group(4)!),
      int.parse(m.group(5)!),
      int.parse(m.group(6)!),
    );
  }

  static int? _weekday(String tok) => switch (tok) {
    'MO' => DateTime.monday,
    'TU' => DateTime.tuesday,
    'WE' => DateTime.wednesday,
    'TH' => DateTime.thursday,
    'FR' => DateTime.friday,
    'SA' => DateTime.saturday,
    'SU' => DateTime.sunday,
    _ => null,
  };
}

enum _Freq { daily, weekly, monthly, yearly }
