import '../identity/identity.dart';
import '../mirror/mirror_signal.dart';

enum MediaKind { book, album, movie, game, score, magazine }

enum MediaProgress { notStarted, inProgress, completed }

/// Concrete media that lives in the Habitat (MD 08 M15).
class HabitatMediaItem {
  const HabitatMediaItem({
    required this.id,
    required this.kind,
    required this.title,
    required this.interestTags,
    this.durationHintHours = 1,
    this.creator,
    this.progress = MediaProgress.notStarted,
    this.progressFraction = 0,
  });

  final String id;
  final MediaKind kind;
  final String title;
  final Set<String> interestTags;
  final double durationHintHours;
  final String? creator;
  final MediaProgress progress;
  final double progressFraction;

  HabitatMediaItem copyWith({
    MediaProgress? progress,
    double? progressFraction,
  }) {
    return HabitatMediaItem(
      id: id,
      kind: kind,
      title: title,
      interestTags: interestTags,
      durationHintHours: durationHintHours,
      creator: creator,
      progress: progress ?? this.progress,
      progressFraction: progressFraction ?? this.progressFraction,
    );
  }
}

/// In-memory library + selection by preference (M15).
class HabitatMediaLibrary {
  HabitatMediaLibrary({List<HabitatMediaItem>? seed})
      : items = List.of(seed ?? defaultSeed);

  final List<HabitatMediaItem> items;

  /// Per-pawn now-playing / reading.
  final Map<String, String> activeByPawn = {};

  static final List<HabitatMediaItem> defaultSeed = [
    const HabitatMediaItem(
      id: 'album.kind_of_blue',
      kind: MediaKind.album,
      title: 'Kind of Blue',
      creator: 'Miles Davis',
      interestTags: {'music', 'music/jazz', 'music/jazz/modal'},
      durationHintHours: 0.75,
    ),
    const HabitatMediaItem(
      id: 'album.head_hunters',
      kind: MediaKind.album,
      title: 'Head Hunters',
      creator: 'Herbie Hancock',
      interestTags: {'music', 'music/jazz', 'music/jazz/fusion'},
      durationHintHours: 0.7,
    ),
    const HabitatMediaItem(
      id: 'album.bossa',
      kind: MediaKind.album,
      title: 'Getz/Gilberto',
      creator: 'Stan Getz & João Gilberto',
      interestTags: {'music', 'music/brazilian', 'music/brazilian/bossa_nova'},
      durationHintHours: 0.6,
    ),
    const HabitatMediaItem(
      id: 'book.dune',
      kind: MediaKind.book,
      title: 'Duna',
      creator: 'Frank Herbert',
      interestTags: {'literature', 'learning'},
      durationHintHours: 12,
    ),
    const HabitatMediaItem(
      id: 'book.cooking',
      kind: MediaKind.book,
      title: 'Sabores de casa',
      interestTags: {'food', 'cooking'},
      durationHintHours: 4,
    ),
    const HabitatMediaItem(
      id: 'movie.arrival',
      kind: MediaKind.movie,
      title: 'A Chegada',
      interestTags: {'film', 'learning'},
      durationHintHours: 2,
    ),
    const HabitatMediaItem(
      id: 'game.chess',
      kind: MediaKind.game,
      title: 'Xadrez',
      interestTags: {'game', 'learning'},
      durationHintHours: 1,
    ),
    const HabitatMediaItem(
      id: 'score.nocturne',
      kind: MediaKind.score,
      title: 'Nocturne Op.9',
      creator: 'Chopin',
      interestTags: {'music', 'music/classical', 'art'},
      durationHintHours: 0.2,
    ),
  ];

  HabitatMediaItem? byId(String id) {
    for (final i in items) {
      if (i.id == id) return i;
    }
    return null;
  }

  /// Score media for a pawn given affinities (path id → 0..1).
  double scoreItem(
    HabitatMediaItem item,
    Map<String, double> affinities, {
    double novelty = 1,
    bool social = false,
  }) {
    var interest = 0.0;
    var n = 0;
    for (final tag in item.interestTags) {
      interest += affinities[tag] ?? affinities[_parent(tag)] ?? 0.25;
      n++;
    }
    if (n > 0) interest /= n;
    var progressPenalty = switch (item.progress) {
      MediaProgress.completed => 0.15,
      MediaProgress.inProgress => 0.05,
      MediaProgress.notStarted => 0.0,
    };
    // Albums are better for shared listening.
    final socialBoost =
        social && item.kind == MediaKind.album ? 0.15 : 0.0;
    return (interest * 0.7 + novelty * 0.2 + socialBoost - progressPenalty)
        .clamp(0.0, 1.5);
  }

  String? pickForPawn({
    required String pawnId,
    required Map<String, double> affinities,
    required PreferenceStore prefs,
    MediaKind? preferKind,
    bool social = false,
  }) {
    // Merge preference store into affinities.
    final merged = Map<String, double>.from(affinities);
    for (final tag in InterestTaxonomy.seed) {
      final a = prefs.effectiveAffinity(pawnId, tag.id);
      if (a != null) merged[tag.id] = a;
    }

    HabitatMediaItem? best;
    var bestScore = -1.0;
    for (final item in items) {
      if (preferKind != null && item.kind != preferKind) continue;
      final s = scoreItem(item, merged, social: social);
      if (s > bestScore) {
        bestScore = s;
        best = item;
      }
    }
    if (best == null) return null;
    activeByPawn[pawnId] = best.id;
    return best.id;
  }

  HabitatMediaItem? advanceProgress(String itemId, double delta) {
    final i = items.indexWhere((e) => e.id == itemId);
    if (i < 0) return null;
    final cur = items[i];
    final nextFrac = (cur.progressFraction + delta).clamp(0.0, 1.0);
    final progress = nextFrac <= 0
        ? MediaProgress.notStarted
        : nextFrac >= 1
            ? MediaProgress.completed
            : MediaProgress.inProgress;
    final updated = cur.copyWith(
      progress: progress,
      progressFraction: nextFrac,
    );
    items[i] = updated;
    return updated;
  }

  String? _parent(String tag) {
    final p = InterestPath.parse(tag).parent;
    return p?.id;
  }

  MirrorSignal<String>? activeSignal(String pawnId) {
    final id = activeByPawn[pawnId];
    if (id == null) return null;
    return MirrorSignal<String>(
      id: 'media.active.$pawnId',
      value: id,
      source: MirrorSignalSource.simulated,
      observedAt: DateTime.now().toUtc(),
      confidence: 1,
    );
  }
}
