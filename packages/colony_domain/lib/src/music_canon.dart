import 'music_canon_data.dart';
import 'music_cover_recipe.dart';
import 'music_ontology.dart';

/// Canonical Genre Base v1 — graph of genres, traditions, scenes and the rest.
abstract final class MusicCanon {
  static const genreRootKeys = <String>[
    'western_art',
    'global_art',
    'folk',
    'blues',
    'jazz',
    'rnb',
    'soul',
    'funk',
    'gospel',
    'country',
    'rock',
    'punk',
    'metal',
    'pop',
    'hiphop',
    'reggae',
    'electronic',
    'industrial',
    'experimental',
    'brazilian',
    'latin',
    'african',
    'mena',
    'south_asian',
    'east_asian',
    'southeast_asian',
  ];

  static const familyHue = <String, double>{
    'western_art': 38,
    'global_art': 52,
    'folk': 34,
    'blues': 222,
    'jazz': 198,
    'rnb': 330,
    'soul': 12,
    'funk': 328,
    'gospel': 46,
    'country': 28,
    'rock': 8,
    'punk': 300,
    'metal': 0,
    'pop': 320,
    'hiphop': 268,
    'reggae': 118,
    'electronic': 188,
    'industrial': 210,
    'experimental': 250,
    'brazilian': 42,
    'latin': 16,
    'african': 64,
    'mena': 48,
    'south_asian': 30,
    'east_asian': 354,
    'southeast_asian': 72,
  };

  static const familyMotif = <String, MusicCoverMotif>{
    'western_art': MusicCoverMotif.gold,
    'global_art': MusicCoverMotif.brass,
    'folk': MusicCoverMotif.ember,
    'blues': MusicCoverMotif.tide,
    'jazz': MusicCoverMotif.river,
    'rnb': MusicCoverMotif.pulse,
    'soul': MusicCoverMotif.ember,
    'funk': MusicCoverMotif.pulse,
    'gospel': MusicCoverMotif.gold,
    'country': MusicCoverMotif.ember,
    'rock': MusicCoverMotif.concrete,
    'punk': MusicCoverMotif.ash,
    'metal': MusicCoverMotif.concrete,
    'pop': MusicCoverMotif.lattice,
    'hiphop': MusicCoverMotif.spore,
    'reggae': MusicCoverMotif.tide,
    'electronic': MusicCoverMotif.lattice,
    'industrial': MusicCoverMotif.ash,
    'experimental': MusicCoverMotif.spore,
    'brazilian': MusicCoverMotif.gold,
    'latin': MusicCoverMotif.brass,
    'african': MusicCoverMotif.pulse,
    'mena': MusicCoverMotif.tide,
    'south_asian': MusicCoverMotif.brass,
    'east_asian': MusicCoverMotif.lattice,
    'southeast_asian': MusicCoverMotif.river,
  };

  static final List<MusicTaxon> all = [
    ...canonWesternArt(),
    ...canonGlobalArt(),
    ...canonFolk(),
    ...canonBlues(),
    ...canonJazz(),
    ...canonRnb(),
    ...canonSoul(),
    ...canonFunk(),
    ...canonGospel(),
    ...canonCountry(),
    ...canonRock(),
    ...canonPunk(),
    ...canonMetal(),
    ...canonPop(),
    ...canonHiphop(),
    ...canonReggae(),
    ...canonElectronic(),
    ...canonIndustrial(),
    ...canonExperimental(),
    ...canonBrazilian(),
    ...canonLatin(),
    ...canonAfrican(),
    ...canonMena(),
    ...canonSouthAsian(),
    ...canonEastAsian(),
    ...canonSoutheastAsian(),
    ...canonTraditions(),
    ...canonScenes(),
    ...canonMovements(),
    ...canonForms(),
    ...canonFunctions(),
    ...canonTechniques(),
    ...canonDescriptors(),
    ...canonGeographies(),
    ...canonEras(),
    ...canonConcepts(),
  ];

  static final List<MusicTaxonLink> links = canonLinks();

  static final Map<String, MusicTaxon> byKey = {
    for (final taxon in all) taxon.key: taxon,
  };

  static List<MusicTaxon> get genres => [
    for (final taxon in all)
      if (taxon.axis == MusicAxisKind.genre) taxon,
  ];

  static List<MusicTaxon> get genreRoots => [
    for (final key in genreRootKeys)
      if (byKey[key] != null) byKey[key]!,
  ];

  static String familyOf(String key) {
    if (key.startsWith('tradition.') ||
        key.startsWith('scene.') ||
        key.startsWith('movement.') ||
        key.startsWith('form.') ||
        key.startsWith('function.') ||
        key.startsWith('technique.') ||
        key.startsWith('descriptor.') ||
        key.startsWith('geo.') ||
        key.startsWith('era.') ||
        key.startsWith('concept.')) {
      return key.split('.').first;
    }
    return key.split('.').first;
  }

  static double hueOf(MusicTaxon taxon) {
    final family = familyOf(taxon.key);
    final base = familyHue[family] ?? 200;
    final depth = taxon.key.split('.').length - 1;
    return (base + depth * 7 + (MusicCoverRecipe.hash(taxon.key) % 11)) % 360;
  }

  static MusicCoverMotif motifOf(MusicTaxon taxon) {
    return familyMotif[familyOf(taxon.key)] ?? MusicCoverMotif.ash;
  }

  static List<MusicTaxon> ofAxis(MusicAxisKind axis) => [
    for (final taxon in all)
      if (taxon.axis == axis) taxon,
  ];

  static List<MusicTaxonLink> linksFrom(String key) => [
    for (final link in links)
      if (link.fromKey == key) link,
  ];

  /// Compact living catalog for the external-AI prompt. Not the full tree.
  static String promptCatalog() {
    final buffer = StringBuffer();
    buffer.writeln(
      'FAMÍLIAS DE GÉNERO — desça até à folha mais específica de que tiver certeza:',
    );
    for (final key in genreRootKeys) {
      final root = byKey[key];
      if (root == null) continue;
      buffer.writeln('- $key — ${root.title}');
      final children = [
        for (final taxon in genres)
          if (taxon.primaryParent == key) taxon,
      ];
      if (children.isEmpty) continue;
      buffer.writeln(
        '  ${children.map((child) => child.key.split('.').last).join(', ')}',
      );
      for (final child in children) {
        final grands = [
          for (final taxon in genres)
            if (taxon.primaryParent == child.key) taxon.key.split('.').last,
        ];
        if (grands.isEmpty) continue;
        buffer.writeln('  ${child.key}: ${grands.join(', ')}');
      }
    }

    void axisBlock(String title, MusicAxisKind axis) {
      final items = ofAxis(axis);
      if (items.isEmpty) return;
      buffer.writeln();
      buffer.writeln('$title');
      for (final taxon in items) {
        buffer.writeln('- ${taxon.key} — ${taxon.title}');
      }
    }

    axisBlock('CENAS (eixo scene — não as force como pasta de género):', MusicAxisKind.scene);
    axisBlock('TRADIÇÕES (eixo tradition):', MusicAxisKind.tradition);
    axisBlock('MOVIMENTOS (eixo movement):', MusicAxisKind.movement);
    axisBlock('FUNÇÕES (não são géneros-mãe):', MusicAxisKind.function);

    buffer.writeln();
    buffer.writeln('ALIASES QUE O APP RESOLVE (prefira a chave canónica):');
    var aliases = 0;
    for (final taxon in all) {
      for (final alias in taxon.aliases) {
        if (alias == taxon.key || alias == taxon.title) continue;
        buffer.writeln('- $alias → ${taxon.key}');
        aliases++;
        if (aliases >= 80) return buffer.toString();
      }
    }
    return buffer.toString();
  }
}
