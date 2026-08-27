import '../mirror/mirror_signal.dart';

/// Hierarchical interest path (MD 08 M12), e.g. `music/jazz/bebop`.
class InterestPath {
  const InterestPath(this.segments);

  factory InterestPath.parse(String path) {
    final parts = path
        .split('/')
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();
    return InterestPath(parts);
  }

  final List<String> segments;

  String get id => segments.join('/');
  String? get root => segments.isEmpty ? null : segments.first;
  InterestPath? get parent =>
      segments.length <= 1 ? null : InterestPath(segments.sublist(0, segments.length - 1));

  bool isUnder(InterestPath other) {
    if (other.segments.length > segments.length) return false;
    for (var i = 0; i < other.segments.length; i++) {
      if (segments[i] != other.segments[i]) return false;
    }
    return true;
  }

  @override
  String toString() => id;

  @override
  bool operator ==(Object other) => other is InterestPath && other.id == id;

  @override
  int get hashCode => id.hashCode;
}

class InterestTag {
  const InterestTag({
    required this.path,
    this.label,
  });

  final InterestPath path;
  final String? label;

  String get id => path.id;
  String get display => label ?? path.segments.last;
}

/// Seed taxonomy for Habitat identity (M12) — 30+ tags.
abstract final class InterestTaxonomy {
  static final List<InterestTag> seed = [
    for (final p in const [
      'music',
      'music/jazz',
      'music/jazz/bebop',
      'music/jazz/hard_bop',
      'music/jazz/modal',
      'music/jazz/fusion',
      'music/jazz/jazz_funk',
      'music/classical',
      'music/rock',
      'music/rock/progressive_rock',
      'music/brazilian',
      'music/brazilian/samba',
      'music/brazilian/bossa_nova',
      'art',
      'art/painting',
      'art/photography',
      'film',
      'film/scifi',
      'literature',
      'literature/fiction',
      'game',
      'game/board',
      'game/video',
      'food',
      'food/japanese',
      'cooking',
      'technology',
      'nature',
      'travel',
      'travel/asia',
      'sports',
      'learning',
      'learning/languages',
    ])
      InterestTag(path: InterestPath.parse(p)),
  ];

  static InterestTag? find(String path) {
    final id = InterestPath.parse(path).id;
    for (final t in seed) {
      if (t.id == id) return t;
    }
    return null;
  }

  static Iterable<InterestTag> childrenOf(String path) {
    final parent = InterestPath.parse(path);
    return seed.where(
      (t) =>
          t.path.segments.length == parent.segments.length + 1 &&
          t.path.isUnder(parent),
    );
  }
}

/// Preference reading with mirror provenance (M13).
class PreferenceReading {
  const PreferenceReading({
    required this.path,
    required this.affinity,
    required this.source,
    this.observedAt,
    this.confidence = 1,
  });

  final InterestPath path;

  /// 0..1 (dislike→like).
  final double affinity;
  final MirrorSignalSource source;
  final DateTime? observedAt;
  final double confidence;

  MirrorSignal<double> asSignal() => MirrorSignal<double>(
        id: 'pref.${path.id}',
        value: affinity,
        source: source,
        observedAt: observedAt ?? DateTime.now().toUtc(),
        confidence: confidence,
      );
}

/// Multi-source preference store per pawn (M13).
class PreferenceStore {
  final Map<String, Map<String, List<PreferenceReading>>> _byPawn = {};

  void put(String pawnId, PreferenceReading reading) {
    final bag = _byPawn.putIfAbsent(pawnId, () => {});
    final list = bag.putIfAbsent(reading.path.id, () => []);
    list.add(reading);
  }

  List<PreferenceReading> readings(String pawnId, String pathId) =>
      List.unmodifiable(_byPawn[pawnId]?[pathId] ?? const []);

  double? effectiveAffinity(String pawnId, String pathId) {
    final list = _byPawn[pawnId]?[pathId];
    if (list == null || list.isEmpty) return null;
    PreferenceReading? best;
    var bestRank = 99;
    const rank = {
      MirrorSignalSource.manual: 0,
      MirrorSignalSource.userDeclared: 1,
      MirrorSignalSource.externalObserved: 2,
      MirrorSignalSource.externalDerived: 3,
      MirrorSignalSource.systemDerived: 4,
      MirrorSignalSource.simulated: 5,
      MirrorSignalSource.unknown: 6,
    };
    for (final r in list) {
      final rr = rank[r.source] ?? 9;
      if (best == null || rr < bestRank) {
        best = r;
        bestRank = rr;
      }
    }
    return best?.affinity;
  }

  void seedSimulated(String pawnId) {
    final h = pawnId.hashCode.abs();
    put(
      pawnId,
      PreferenceReading(
        path: InterestPath.parse('music/jazz'),
        affinity: 0.55 + (h % 40) / 100,
        source: MirrorSignalSource.simulated,
      ),
    );
    put(
      pawnId,
      PreferenceReading(
        path: InterestPath.parse('nature'),
        affinity: 0.4 + ((h >> 3) % 45) / 100,
        source: MirrorSignalSource.simulated,
      ),
    );
    put(
      pawnId,
      PreferenceReading(
        path: InterestPath.parse('learning'),
        affinity: 0.35 + ((h >> 5) % 50) / 100,
        source: MirrorSignalSource.simulated,
      ),
    );
  }
}

/// Behavioral personality axes (M14).
class BehaviorProfile {
  const BehaviorProfile({
    this.extraversion = 0.5,
    this.openness = 0.5,
    this.conscientiousness = 0.5,
    this.agreeableness = 0.5,
    this.neuroticism = 0.35,
    this.socialStyle = SocialStyle.balanced,
  });

  final double extraversion;
  final double openness;
  final double conscientiousness;
  final double agreeableness;
  final double neuroticism;
  final SocialStyle socialStyle;

  factory BehaviorProfile.fromSeed(String pawnId) {
    final h = Object.hash(pawnId, 14);
    double axis(int shift) =>
        (0.25 + ((h >> shift) % 55) / 100).clamp(0.15, 0.9);
    final ext = axis(0);
    final style = ext > 0.65
        ? SocialStyle.outgoing
        : ext < 0.35
            ? SocialStyle.reserved
            : SocialStyle.balanced;
    return BehaviorProfile(
      extraversion: ext,
      openness: axis(2),
      conscientiousness: axis(4),
      agreeableness: axis(6),
      neuroticism: axis(8),
      socialStyle: style,
    );
  }
}

enum SocialStyle { reserved, balanced, outgoing }

/// Lightweight novelty memory for stimulation (M11).
class NoveltyTracker {
  final Map<String, Map<String, double>> _lastUsedSim = {};

  void markUsed(String pawnId, String affordanceId, double simSeconds) {
    _lastUsedSim.putIfAbsent(pawnId, () => {})[affordanceId] = simSeconds;
  }

  double novelty(String pawnId, String affordanceId, double simSeconds) {
    final last = _lastUsedSim[pawnId]?[affordanceId];
    if (last == null) return 1;
    final ageH = (simSeconds - last) / 3600.0;
    return (ageH / 6).clamp(0.0, 1.0);
  }
}
