import 'music_ontology.dart';

/// Compact tree node used to author the canonical atlas.
class MusicCanonNode {
  const MusicCanonNode(
    this.slug,
    this.title, {
    this.children = const [],
    this.aliases = const [],
    this.secondary = const [],
    this.traditions = const [],
    this.scenes = const [],
    this.movements = const [],
    this.forms = const [],
    this.functions = const [],
    this.techniques = const [],
    this.descriptors = const [],
    this.geographies = const [],
    this.eras = const [],
    this.axis = MusicAxisKind.genre,
    this.lore = '',
  });

  final String slug;
  final String title;
  final List<MusicCanonNode> children;
  final List<String> aliases;
  final List<String> secondary;
  final List<String> traditions;
  final List<String> scenes;
  final List<String> movements;
  final List<String> forms;
  final List<String> functions;
  final List<String> techniques;
  final List<String> descriptors;
  final List<String> geographies;
  final List<String> eras;
  final MusicAxisKind axis;
  final String lore;
}

MusicCanonNode n(
  String slug,
  String title, {
  List<MusicCanonNode> children = const [],
  List<String> aliases = const [],
  List<String> secondary = const [],
  List<String> traditions = const [],
  List<String> scenes = const [],
  List<String> movements = const [],
  List<String> forms = const [],
  List<String> functions = const [],
  List<String> techniques = const [],
  List<String> descriptors = const [],
  List<String> geographies = const [],
  List<String> eras = const [],
  MusicAxisKind axis = MusicAxisKind.genre,
  String lore = '',
}) {
  return MusicCanonNode(
    slug,
    title,
    children: children,
    aliases: aliases,
    secondary: secondary,
    traditions: traditions,
    scenes: scenes,
    movements: movements,
    forms: forms,
    functions: functions,
    techniques: techniques,
    descriptors: descriptors,
    geographies: geographies,
    eras: eras,
    axis: axis,
    lore: lore,
  );
}

List<MusicTaxon> flattenCanon(
  List<MusicCanonNode> roots, {
  String? prefix,
  MusicAxisKind? defaultAxis,
}) {
  final out = <MusicTaxon>[];
  void walk(MusicCanonNode node, String? parentKey) {
    final actualKey = parentKey == null
        ? (prefix == null ? node.slug : '$prefix.${node.slug}')
        : '$parentKey.${node.slug}';
    final lore = node.lore.trim().isEmpty
        ? '## ${node.title}\n${MusicOntologyPolicy.axisLabel(node.axis)} '
              'na cartografia canónica do Atlas. Não é um mood nem uma pasta.'
        : node.lore;
    out.add(
      MusicTaxon(
        key: actualKey,
        title: node.title,
        axis: defaultAxis ?? node.axis,
        parentKeys: [if (parentKey != null) parentKey],
        secondaryParentKeys: node.secondary,
        aliases: node.aliases,
        traditionKeys: node.traditions,
        sceneKeys: node.scenes,
        movementKeys: node.movements,
        formKeys: node.forms,
        functionKeys: node.functions,
        techniqueKeys: node.techniques,
        descriptorKeys: node.descriptors,
        geographyKeys: node.geographies,
        eraKeys: node.eras,
        loreMarkdown: lore,
      ),
    );
    for (final child in node.children) {
      walk(child, actualKey);
    }
  }

  for (final root in roots) {
    walk(root, null);
  }
  return out;
}

/// Apply graph edges after the trees exist.
List<MusicTaxonLink> linksFor(Iterable<(MusicTaxonLinkKind, String, String)> raw) {
  return [
    for (final item in raw)
      MusicTaxonLink(kind: item.$1, fromKey: item.$2, toKey: item.$3),
  ];
}
