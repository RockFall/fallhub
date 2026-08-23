import 'package:equatable/equatable.dart';

import 'music_atlas.dart';

/// Visual grammar for a sleeve when no cover file exists yet.
enum MusicCoverMotif {
  river,
  ember,
  lattice,
  spore,
  pulse,
  brass,
  concrete,
  tide,
  ash,
  gold,
}

/// Deterministic cover recipe — same title/artist/year always paints the same sleeve.
class MusicCoverRecipe extends Equatable {
  const MusicCoverRecipe({
    required this.seed,
    required this.hue,
    required this.saturation,
    required this.lightness,
    required this.motif,
    required this.monogram,
    this.year,
    this.secondaryHue,
  });

  final int seed;
  final double hue;
  final double saturation;
  final double lightness;
  final MusicCoverMotif motif;
  final String monogram;
  final int? year;
  final double? secondaryHue;

  factory MusicCoverRecipe.from({
    required String title,
    String? artist,
    int? year,
    double? territoryHue,
    MusicCoverMotif? motif,
  }) {
    final seed = MusicCoverRecipe.hash(
      '${MusicIdentityPolicy.normalizeTitle(title)}|${artist ?? ''}|${year ?? ''}',
    );
    final motifs = MusicCoverMotif.values;
    return MusicCoverRecipe(
      seed: seed,
      hue: territoryHue ?? ((seed % 3600) / 10),
      saturation: 0.42 + (seed % 28) / 100,
      lightness: 0.28 + (seed % 17) / 100,
      motif: motif ?? motifs[seed % motifs.length],
      monogram: monogramOf(title),
      year: year,
      secondaryHue: ((seed ~/ 17) % 3600) / 10,
    );
  }

  /// FNV-1a 32-bit — stable across isolates, no crypto dependency.
  static int hash(String value) {
    var hash = 2166136261;
    for (final unit in value.codeUnits) {
      hash ^= unit;
      hash = (hash * 16777619) & 0xFFFFFFFF;
    }
    return hash;
  }

  static String monogramOf(String title) {
    final words = title
        .trim()
        .split(RegExp(r'\s+'))
        .where((w) => w.isNotEmpty)
        .where((w) => !RegExp(
              r'^(the|a|an|os|as|o|um|uma|de|da|do|of|and|et|e|y)$',
              caseSensitive: false,
            ).hasMatch(w))
        .toList();
    if (words.isEmpty) return '?';
    if (words.length == 1) {
      final w = words.first;
      return w.length == 1 ? w.toUpperCase() : w.substring(0, 2).toUpperCase();
    }
    return '${words[0][0]}${words[1][0]}'.toUpperCase();
  }

  double unit(int salt) {
    final mixed = (seed ^ (salt * 374761393)) & 0xFFFFFFFF;
    return (mixed % 10000) / 10000;
  }

  @override
  List<Object?> get props =>
      [seed, hue, saturation, lightness, motif, monogram, year, secondaryHue];
}
