import 'ics_rrule.dart';
import 'integration.dart';

/// Minimal ICS VEVENT parser for offline import stub (ADR-032 / ADR-050).
abstract final class IcsCodec {
  /// Parses VEVENT blocks; returns preview rows. Throws [FormatException].
  ///
  /// Recurring events (RRULE) are expanded inside [windowStart]–[windowEnd]
  /// (defaults: a day before DTSTART through +400 days).
  static List<IcsEventPreview> parsePreview(
    String ics, {
    DateTime? windowStart,
    DateTime? windowEnd,
  }) {
    final unfolded = _unfold(ics);
    if (unfolded.trim().isEmpty) {
      throw const FormatException('ICS vazio');
    }
    final events = <IcsEventPreview>[];
    final lines = unfolded.split(RegExp(r'\r?\n'));
    _RawEvent? current;
    var sawEvent = false;
    for (final raw in lines) {
      final line = raw.trimRight();
      if (line.isEmpty) continue;
      final upper = line.toUpperCase();
      if (upper == 'BEGIN:VEVENT') {
        current = _RawEvent();
        sawEvent = true;
        continue;
      }
      if (upper == 'END:VEVENT') {
        if (current != null) {
          events.addAll(
            _expand(_toPreview(current), current, windowStart, windowEnd),
          );
        }
        current = null;
        continue;
      }
      if (current == null) continue;
      final colon = line.indexOf(':');
      if (colon <= 0) continue;
      final keyPart = line.substring(0, colon);
      final value = _unescape(line.substring(colon + 1).trim());
      final key = keyPart.split(';').first.toUpperCase();
      switch (key) {
        case 'SUMMARY':
          current.summary = value;
        case 'UID':
          current.uid = value;
        case 'RRULE':
          current.rrule = value;
        case 'DURATION':
          current.duration = value;
        case 'DTSTART':
          current.dtStartRaw = line.substring(colon + 1);
          current.dtStartKey = keyPart;
        case 'DTEND':
          current.dtEndRaw = line.substring(colon + 1);
          current.dtEndKey = keyPart;
        case 'EXDATE':
          current.exdates.addAll(
            _splitExdates(line.substring(colon + 1), keyPart),
          );
        default:
          break;
      }
    }
    if (!sawEvent) {
      throw const FormatException('Nenhum VEVENT encontrado');
    }
    return events;
  }

  static List<IcsEventPreview> _expand(
    IcsEventPreview seed,
    _RawEvent raw,
    DateTime? windowStart,
    DateTime? windowEnd,
  ) {
    final rrule = raw.rrule;
    if (rrule == null || rrule.trim().isEmpty) return [seed];
    return IcsRrule.expand(
      seed: seed,
      rrule: rrule,
      exdates: raw.exdates,
      windowStart: windowStart,
      windowEnd: windowEnd,
    );
  }

  static String _unfold(String source) {
    return source.replaceAll(RegExp(r'\r?\n[ \t]'), '');
  }

  static String _unescape(String value) {
    return value
        .replaceAll(r'\,', ',')
        .replaceAll(r'\;', ';')
        .replaceAll(r'\\', r'\')
        .replaceAll(r'\n', '\n');
  }

  static IcsEventPreview _toPreview(_RawEvent props) {
    final summary = (props.summary ?? 'Sem título').trim();
    final startRaw = props.dtStartRaw;
    if (startRaw == null || startRaw.isEmpty) {
      throw const FormatException('VEVENT sem DTSTART');
    }
    final startKey = props.dtStartKey ?? 'DTSTART';
    final startAt = _parseIcsDateTime(startRaw, startKey);
    DateTime endAt;
    final endRaw = props.dtEndRaw;
    if (endRaw != null && endRaw.isNotEmpty) {
      endAt = _parseIcsDateTime(endRaw, props.dtEndKey ?? 'DTEND');
    } else {
      final duration = _parseDuration(props.duration);
      endAt = startAt.add(duration ?? const Duration(hours: 1));
    }
    if (!endAt.isAfter(startAt)) {
      throw const FormatException('VEVENT com intervalo inválido');
    }
    final uid = props.uid?.trim();
    return IcsEventPreview(
      uid: (uid == null || uid.isEmpty) ? null : uid,
      summary: summary.isEmpty ? 'Sem título' : summary,
      startAt: startAt,
      endAt: endAt,
    );
  }

  static List<DateTime> _splitExdates(String value, String keyPart) {
    final out = <DateTime>[];
    for (final piece in value.split(',')) {
      final trimmed = piece.trim();
      if (trimmed.isEmpty) continue;
      try {
        out.add(_parseIcsDateTime(trimmed, keyPart));
      } on FormatException {
        continue;
      }
    }
    return out;
  }

  static DateTime _parseIcsDateTime(String value, String keyPart) {
    final v = value.trim();
    final isDateOnly =
        keyPart.toUpperCase().contains('VALUE=DATE') ||
        (RegExp(r'^\d{8}$').hasMatch(v));
    if (isDateOnly) {
      final y = int.parse(v.substring(0, 4));
      final m = int.parse(v.substring(4, 6));
      final d = int.parse(v.substring(6, 8));
      // All-day: local calendar date → UTC instant (same convention as schedule).
      return DateTime(y, m, d).toUtc();
    }
    final cleaned = v.replaceAll(RegExp(r'[-:]'), '');
    final match = RegExp(
      r'^(\d{4})(\d{2})(\d{2})T(\d{2})(\d{2})(\d{2})(Z)?$',
    ).firstMatch(cleaned);
    if (match == null) {
      throw FormatException('Data ICS inválida: $value');
    }
    final y = int.parse(match.group(1)!);
    final mo = int.parse(match.group(2)!);
    final d = int.parse(match.group(3)!);
    final h = int.parse(match.group(4)!);
    final mi = int.parse(match.group(5)!);
    final s = int.parse(match.group(6)!);
    if (match.group(7) == 'Z') {
      return DateTime.utc(y, mo, d, h, mi, s);
    }
    // Floating / TZID: interpret in the device local zone (ADR-050).
    return DateTime(y, mo, d, h, mi, s).toUtc();
  }

  static Duration? _parseDuration(String? raw) {
    if (raw == null || raw.isEmpty) return null;
    final m = RegExp(
      r'^P(?:(\d+)D)?(?:T(?:(\d+)H)?(?:(\d+)M)?(?:(\d+)S)?)?$',
    ).firstMatch(raw.trim().toUpperCase());
    if (m == null) return null;
    final days = int.tryParse(m.group(1) ?? '') ?? 0;
    final hours = int.tryParse(m.group(2) ?? '') ?? 0;
    final minutes = int.tryParse(m.group(3) ?? '') ?? 0;
    final seconds = int.tryParse(m.group(4) ?? '') ?? 0;
    final duration = Duration(
      days: days,
      hours: hours,
      minutes: minutes,
      seconds: seconds,
    );
    return duration == Duration.zero ? null : duration;
  }
}

class _RawEvent {
  String? uid;
  String? summary;
  String? rrule;
  String? duration;
  String? dtStartRaw;
  String? dtStartKey;
  String? dtEndRaw;
  String? dtEndKey;
  final List<DateTime> exdates = [];
}
