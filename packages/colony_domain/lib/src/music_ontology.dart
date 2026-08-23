import 'package:equatable/equatable.dart';

/// One axis of the musical atlas. Genre is not tradition is not scene.
enum MusicAxisKind {
  genre,
  tradition,
  scene,
  movement,
  form,
  function,
  technique,
  descriptor,
  geography,
  era,
  concept,
}

/// Semantic edge between taxons — the atlas is a graph, not a folder tree.
enum MusicTaxonLinkKind {
  parentOf,
  derivedFrom,
  influencedBy,
  fusedWith,
  siblingOf,
  historicallyPrecedes,
  regionalVariantOf,
  revivalOf,
  sceneAssociatedWith,
  movementAssociatedWith,
  commonlyOverlaps,
}

class MusicTaxonLink extends Equatable {
  const MusicTaxonLink({
    required this.kind,
    required this.fromKey,
    required this.toKey,
  });

  final MusicTaxonLinkKind kind;
  final String fromKey;
  final String toKey;

  @override
  List<Object?> get props => [kind, fromKey, toKey];
}

/// A node on one axis. Secondary parents make a polyhierarchy (Blackgaze, Zeuhl).
class MusicTaxon extends Equatable {
  const MusicTaxon({
    required this.key,
    required this.title,
    required this.axis,
    this.parentKeys = const [],
    this.secondaryParentKeys = const [],
    this.aliases = const [],
    this.traditionKeys = const [],
    this.sceneKeys = const [],
    this.movementKeys = const [],
    this.formKeys = const [],
    this.functionKeys = const [],
    this.techniqueKeys = const [],
    this.descriptorKeys = const [],
    this.geographyKeys = const [],
    this.eraKeys = const [],
    this.loreMarkdown = '',
  });

  final String key;
  final String title;
  final MusicAxisKind axis;
  final List<String> parentKeys;
  final List<String> secondaryParentKeys;
  final List<String> aliases;
  final List<String> traditionKeys;
  final List<String> sceneKeys;
  final List<String> movementKeys;
  final List<String> formKeys;
  final List<String> functionKeys;
  final List<String> techniqueKeys;
  final List<String> descriptorKeys;
  final List<String> geographyKeys;
  final List<String> eraKeys;
  final String loreMarkdown;

  String? get primaryParent => parentKeys.isEmpty ? null : parentKeys.first;

  bool get isGenreRiver => axis == MusicAxisKind.genre;

  Iterable<String> get allParentKeys => {...parentKeys, ...secondaryParentKeys};

  @override
  List<Object?> get props => [
    key,
    title,
    axis,
    parentKeys,
    secondaryParentKeys,
    aliases,
  ];
}

abstract final class MusicOntologyPolicy {
  /// Moods, production adjectives and lone "Progressive" are not mother genres.
  static const forbiddenGenreRoots = {
    'progressive',
    'experimental',
    'revival',
    'fusion',
    'neo',
    'post',
    'traditional',
    'melancholic',
    'euphoric',
    'aggressive',
    'dreamy',
    'dark',
    'warm',
    'romantic',
    'acoustic',
    'electric',
    'lo-fi',
    'lofi',
    'hi-fi',
    'world',
    'world music',
  };

  static bool isFunctionalAxis(MusicAxisKind axis) =>
      axis == MusicAxisKind.function ||
      axis == MusicAxisKind.technique ||
      axis == MusicAxisKind.descriptor ||
      axis == MusicAxisKind.form;

  static String axisLabel(MusicAxisKind axis) {
    return switch (axis) {
      MusicAxisKind.genre => 'Género',
      MusicAxisKind.tradition => 'Tradição',
      MusicAxisKind.scene => 'Cena',
      MusicAxisKind.movement => 'Movimento',
      MusicAxisKind.form => 'Forma',
      MusicAxisKind.function => 'Função',
      MusicAxisKind.technique => 'Técnica',
      MusicAxisKind.descriptor => 'Descritor',
      MusicAxisKind.geography => 'Geografia',
      MusicAxisKind.era => 'Era',
      MusicAxisKind.concept => 'Conceito',
    };
  }
}
