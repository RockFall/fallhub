import '../embodied/pawn_embodied_state.dart';
import '../mirror/mirror_provenance.dart';
import '../mirror/mirror_signal.dart';
import '../mirror/mirror_value_quality.dart';
import '../mirror/effective_state_resolver.dart';

/// Builds human-readable explain chains for inspect (MD 08 M4+).
abstract final class StateExplain {
  static String needLine(NeedReading n) {
    final pct = (n.pressure * 100).round();
    return '${_needLabel(n.kind)}: ${n.pressure.toStringAsFixed(2)} '
        '($pct%) · ${n.source.name} · ${_trend(n.trend)}';
  }

  static String needExplain(NeedReading n, {DateTime? now}) {
    final at = now ?? DateTime.now().toUtc();
    final age = n.observedAt == null
        ? '—'
        : '${at.difference(n.observedAt!).inSeconds}s';
    return '${_needLabel(n.kind)}\n'
        '  pressure: ${n.pressure.toStringAsFixed(2)}\n'
        '  source: ${n.source.name}\n'
        '  trend: ${n.trend.name} (${n.trendPerSimHour.toStringAsFixed(3)}/h)\n'
        '  last update: $age';
  }

  static String capacityLine(CapacityReading c) {
    return '${_capLabel(c.kind)}: ${c.level.toStringAsFixed(2)} · ${c.source.name}';
  }

  static String capacityExplain(CapacityReading c) {
    final buf = StringBuffer()
      ..writeln(_capLabel(c.kind))
      ..writeln('  level: ${c.level.toStringAsFixed(2)}')
      ..writeln('  source: ${c.source.name}')
      ..writeln('  policy: systemDerived from contributors');
    if (c.derivedFrom.isNotEmpty) {
      buf.writeln('  derived from:');
      for (final d in c.derivedFrom) {
        buf.writeln('    · $d');
      }
    }
    return buf.toString().trimRight();
  }

  static String conditionLine(PawnCondition c) {
    return '${c.label} ${(c.intensity * 100).round()}% · ${c.source.name}';
  }

  static String effectiveExplain(EffectiveValue<Object?> eff) {
    return '${eff.explanation}\n'
        '  reason: ${eff.reason.name}\n'
        '  winning: ${eff.source.name}\n'
        '  policy: override > declared > observed > derived > simulated';
  }

  static String signalLine(
    MirrorSignal<Object?> signal, {
    DateTime? now,
  }) {
    if (signal.isSensitive) {
      return '${signal.id}: <redacted> · ${signal.source.name}';
    }
    return MirrorProvenance.debugLine(signal, now: now);
  }

  static String freshnessLabel(
    MirrorSignal<Object?> signal, {
    required DateTime now,
  }) =>
      MirrorValueQuality.freshness(signal, now: now).name;

  static String _needLabel(NeedKind k) => switch (k) {
        NeedKind.sleep => 'Sleep',
        NeedKind.food => 'Food',
        NeedKind.movement => 'Movement',
        NeedKind.rest => 'Rest',
        NeedKind.socialConnection => 'Social',
        NeedKind.solitude => 'Solitude',
        NeedKind.recreation => 'Recreation',
        NeedKind.stimulation => 'Stimulation',
        NeedKind.creativeExpression => 'Creative',
        NeedKind.comfort => 'Comfort',
      };

  static String _capLabel(CapacityKind k) => switch (k) {
        CapacityKind.energy => 'Energy',
        CapacityKind.focus => 'Focus',
        CapacityKind.physicalReadiness => 'Physical',
        CapacityKind.socialTolerance => 'Social tol.',
        CapacityKind.creativeCapacity => 'Creative',
        CapacityKind.decisionCapacity => 'Decision',
        CapacityKind.recovery => 'Recovery',
      };

  static String _trend(EmbodiedTrend t) => switch (t) {
        EmbodiedTrend.rising => '↑',
        EmbodiedTrend.steady => '→',
        EmbodiedTrend.falling => '↓',
      };
}
