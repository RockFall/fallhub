import 'mirror_signal.dart';
import 'mirror_value_quality.dart';

/// Debug / explain helpers for [MirrorSignal] provenance.
abstract final class MirrorProvenance {
  /// Single-line debug summary. Sensitive values are redacted.
  static String debugLine(
    MirrorSignal<Object?> signal, {
    DateTime? now,
  }) {
    final at = now ?? DateTime.now().toUtc();
    final fresh = MirrorValueQuality.freshness(signal, now: at);
    final valuePart =
        signal.isSensitive ? '<redacted>' : _formatValue(signal.value);
    return '${signal.id}=$valuePart '
        'source=${signal.source.name} '
        'confidence=${signal.confidence.toStringAsFixed(2)} '
        'freshness=${fresh.name}'
        '${signal.transformationChain.isEmpty ? '' : ' chain=[${signal.transformationChain.join(' → ')}]'}';
  }

  /// Multi-line explain block for inspect / debug HUD.
  static String explain(
    MirrorSignal<Object?> signal, {
    DateTime? now,
  }) {
    final at = now ?? DateTime.now().toUtc();
    final fresh = MirrorValueQuality.freshness(signal, now: at);
    final buf = StringBuffer()
      ..writeln(signal.id)
      ..writeln(
        '  value: ${signal.isSensitive ? '<redacted>' : _formatValue(signal.value)}',
      )
      ..writeln('  source: ${signal.source.name}')
      ..writeln('  confidence: ${signal.confidence.toStringAsFixed(2)}')
      ..writeln('  freshness: ${fresh.name}')
      ..writeln('  observedAt: ${signal.observedAt.toIso8601String()}');
    if (signal.validUntil != null) {
      buf.writeln('  validUntil: ${signal.validUntil!.toIso8601String()}');
    }
    if (signal.sourceRef != null) {
      buf.writeln('  sourceRef: ${signal.sourceRef}');
    }
    if (signal.transformationChain.isNotEmpty) {
      buf.writeln(
        '  chain: ${signal.transformationChain.join(' → ')}',
      );
    }
    return buf.toString().trimRight();
  }

  /// Safe log line — never prints sensitive payloads.
  static String logLine(MirrorSignal<Object?> signal) {
    if (signal.isSensitive) {
      return '${signal.id} source=${signal.source.name} '
          'confidence=${signal.confidence.toStringAsFixed(2)} <sensitive>';
    }
    return debugLine(signal);
  }

  static String _formatValue(Object? value) {
    if (value is double) {
      if (value == value.roundToDouble()) {
        return value.toStringAsFixed(0);
      }
      return value.toStringAsFixed(1);
    }
    return value.toString();
  }
}

/// Well-known Habitat signal ids (M0+).
abstract final class HabitatMirrorIds {
  static const indoorTemperatureC = 'habitat.indoor_temperature_c';
}
