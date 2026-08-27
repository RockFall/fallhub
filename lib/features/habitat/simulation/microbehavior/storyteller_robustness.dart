import 'habitat_rng.dart';

/// Block K — storyteller, tuning and final robustness (MD 10 R112–R119).

class ForeshadowCue {
  const ForeshadowCue({
    required this.id,
    required this.label,
    required this.firesAt,
    required this.eventKind,
  });

  final String id;
  final String label;
  final double firesAt;
  final String eventKind;
}

class ForeshadowingBoard {
  final List<ForeshadowCue> pending = [];

  void schedule(ForeshadowCue cue) => pending.add(cue);

  List<ForeshadowCue> due(double now) {
    final ready = pending.where((c) => now >= c.firesAt).toList();
    pending.removeWhere((c) => now >= c.firesAt);
    return ready;
  }
}

class CausalityLink {
  const CausalityLink({
    required this.causeId,
    required this.effectId,
    required this.label,
  });

  final String causeId;
  final String effectId;
  final String label;
}

class CausalityChainDebug {
  final List<CausalityLink> links = [];

  void record(CausalityLink link) {
    links.add(link);
    if (links.length > 80) links.removeAt(0);
  }

  List<CausalityLink> chainFor(String eventId) => [
        for (final l in links)
          if (l.causeId == eventId || l.effectId == eventId) l,
      ];
}

class SnapshotAutoFrame {
  const SnapshotAutoFrame({
    required this.center,
    required this.zoom,
  });

  final (double, double) center;
  final double zoom;
}

abstract final class SnapshotFraming {
  static SnapshotAutoFrame compute({
    required List<(int, int)> focusCells,
    required double tileSize,
  }) {
    if (focusCells.isEmpty) {
      return const SnapshotAutoFrame(center: (0, 0), zoom: 1);
    }
    var sx = 0.0, sy = 0.0;
    for (final c in focusCells) {
      sx += c.$1;
      sy += c.$2;
    }
    final n = focusCells.length.toDouble();
    final cx = (sx / n) * tileSize;
    final cy = (sy / n) * tileSize;
    final zoom = focusCells.length <= 2 ? 1.15 : 0.95;
    return SnapshotAutoFrame(center: (cx, cy), zoom: zoom);
  }
}

class SinceLastVisitDigest {
  const SinceLastVisitDigest({
    required this.lines,
    required this.elapsedSeconds,
  });

  final List<String> lines;
  final double elapsedSeconds;
}

abstract final class SinceLastVisit {
  static SinceLastVisitDigest build({
    required double elapsedSeconds,
    required int activitiesFinished,
    required int visitorsCame,
    required bool slept,
  }) {
    final lines = <String>[];
    if (elapsedSeconds < 30) {
      return SinceLastVisitDigest(lines: lines, elapsedSeconds: elapsedSeconds);
    }
    if (slept) lines.add('Alguém dormiu enquanto você estava fora.');
    if (visitorsCame > 0) {
      lines.add('$visitorsCame visita(s) passaram por aqui.');
    }
    if (activitiesFinished > 0) {
      lines.add('$activitiesFinished atividades terminaram.');
    }
    if (lines.isEmpty) lines.add('A casa ficou quieta.');
    return SinceLastVisitDigest(
      lines: lines,
      elapsedSeconds: elapsedSeconds,
    );
  }
}

class CooldownFamily {
  CooldownFamily({
    required this.id,
    required this.baseSeconds,
  });

  final String id;
  final double baseSeconds;
  final Map<String, double> lastAt = {};
  final Map<String, int> repeats = {};

  bool ready(String key, double now) {
    final last = lastAt[key];
    if (last == null) return true;
    final n = repeats[key] ?? 0;
    final habituation = 1.0 + n * 0.35;
    return now - last >= baseSeconds * habituation;
  }

  void mark(String key, double now) {
    lastAt[key] = now;
    repeats[key] = (repeats[key] ?? 0) + 1;
  }
}

abstract final class StableStochasticity {
  /// Close-call chooser: when scores are near, use stable hash not Random.
  static T chooseCloseCall<T>({
    required List<(T, double)> scored,
    required String salt,
    double epsilon = 0.08,
  }) {
    assert(scored.isNotEmpty);
    scored.sort((a, b) => b.$2.compareTo(a.$2));
    final top = scored.first.$2;
    final contenders =
        scored.where((e) => top - e.$2 <= epsilon).map((e) => e.$1).toList();
    if (contenders.length == 1) return contenders.first;
    final i = (HabitatRng.unit(salt, 'close') * contenders.length)
        .floor()
        .clamp(0, contenders.length - 1);
    return contenders[i];
  }
}

class AntiLoopDetector {
  AntiLoopDetector({this.window = 8, this.threshold = 3});

  final int window;
  final int threshold;
  final Map<String, List<String>> _recent = {};

  bool observe(String pawnId, String actionId) {
    final list = _recent.putIfAbsent(pawnId, () => []);
    list.add(actionId);
    while (list.length > window) {
      list.removeAt(0);
    }
    final counts = <String, int>{};
    for (final a in list) {
      counts[a] = (counts[a] ?? 0) + 1;
    }
    return counts.values.any((c) => c >= threshold);
  }

  void clear(String pawnId) => _recent.remove(pawnId);
}

class RefinementGateResult {
  const RefinementGateResult({
    required this.passed,
    required this.checks,
  });

  final bool passed;
  final Map<String, bool> checks;
}

abstract final class HabitatRefinementGate {
  /// Final gate R119 — structural readiness of refinement pack.
  static RefinementGateResult evaluate({
    required bool blockA,
    required bool blockB,
    required bool blockC,
    required bool blockD,
    required bool blockE,
    required bool blockF,
    required bool blockG,
    required bool blockH,
    required bool blockI,
    required bool blockJ,
    required bool blockK,
    required bool testsGreen,
  }) {
    final checks = {
      'A_body_timing': blockA,
      'B_nav_space': blockB,
      'C_objects': blockC,
      'D_social': blockD,
      'E_collective': blockE,
      'F_sleep_routine': blockF,
      'G_atmosphere': blockG,
      'H_pets': blockH,
      'I_editor': blockI,
      'J_camera_ui': blockJ,
      'K_story_robust': blockK,
      'tests': testsGreen,
    };
    return RefinementGateResult(
      passed: checks.values.every((v) => v),
      checks: checks,
    );
  }
}
