import 'integration.dart';

/// Minimal ICS VEVENT parser for offline import stub (ADR-032).
abstract final class IcsCodec {
  /// Parses VEVENT blocks; returns preview rows. Throws [FormatException].
  static List<IcsEventPreview> parsePreview(String ics) {
    final unfolded = _unfold(ics);
    if (unfolded.trim().isEmpty) {
      throw const FormatException('ICS vazio');
    }
    final events = <IcsEventPreview>[];
    final lines = unfolded.split(RegExp(r'\r?\n'));
    Map<String, String>? current;
    for (final raw in lines) {
      final line = raw.trimRight();
      if (line.isEmpty) continue;
      final upper = line.toUpperCase();
      if (upper == 'BEGIN:VEVENT') {
        current = {};
        continue;
      }
      if (upper == 'END:VEVENT') {
        if (current != null) {
          events.add(_toPreview(current));
        }
        current = null;
        continue;
      }
      if (current == null) continue;
      final colon = line.indexOf(':');
      if (colon <= 0) continue;
      final keyPart = line.substring(0, colon);
      final value = line.substring(colon + 1).trim();
      final key = keyPart.split(';').first.toUpperCase();
      current[key] = value;
      // Keep params for DTSTART/DTEND (e.g. VALUE=DATE).
      if (key == 'DTSTART' || key == 'DTEND') {
        current['${key}_RAW'] = line.substring(colon + 1);
        current['${key}_KEY'] = keyPart;
      }
    }
    if (events.isEmpty) {
      throw const FormatException('Nenhum VEVENT encontrado');
    }
    return events;
  }

  static String _unfold(String source) {
    // RFC 5545 line folding: CRLF + space/tab continuation.
    return source.replaceAll(RegExp(r'\r?\n[ \t]'), '');
  }

  static IcsEventPreview _toPreview(Map<String, String> props) {
    final summary = (props['SUMMARY'] ?? 'Sem título').trim();
    final startRaw = props['DTSTART_RAW'] ?? props['DTSTART'];
    final endRaw = props['DTEND_RAW'] ?? props['DTEND'];
    if (startRaw == null || startRaw.isEmpty) {
      throw const FormatException('VEVENT sem DTSTART');
    }
    final startKey = props['DTSTART_KEY'] ?? 'DTSTART';
    final endKey = props['DTEND_KEY'] ?? 'DTEND';
    final startAt = _parseIcsDateTime(startRaw, startKey);
    final endAt = endRaw == null || endRaw.isEmpty
        ? startAt.add(const Duration(hours: 1))
        : _parseIcsDateTime(endRaw, endKey);
    if (!endAt.isAfter(startAt)) {
      throw const FormatException('VEVENT com intervalo inválido');
    }
    final uid = props['UID']?.trim();
    return IcsEventPreview(
      uid: (uid == null || uid.isEmpty) ? null : uid,
      summary: summary.isEmpty ? 'Sem título' : summary,
      startAt: startAt,
      endAt: endAt,
    );
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
      return DateTime.utc(y, m, d);
    }
    // FORMATS: 20260807T140000Z or 20260807T140000
    final cleaned = v.replaceAll(RegExp(r'[-:]'), '');
    final match = RegExp(r'^(\d{4})(\d{2})(\d{2})T(\d{2})(\d{2})(\d{2})(Z)?$')
        .firstMatch(cleaned);
    if (match == null) {
      throw FormatException('Data ICS inválida: $value');
    }
    final dt = DateTime.utc(
      int.parse(match.group(1)!),
      int.parse(match.group(2)!),
      int.parse(match.group(3)!),
      int.parse(match.group(4)!),
      int.parse(match.group(5)!),
      int.parse(match.group(6)!),
    );
    return dt;
  }
}
