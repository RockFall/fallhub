import 'package:equatable/equatable.dart';

/// Suggested world-knowledge map. Seeded only when the user opts in.
class KnowledgeCatalogEntry extends Equatable {
  const KnowledgeCatalogEntry({
    required this.key,
    required this.title,
    this.description,
    this.iconKey,
    this.children = const [],
    this.catalogPlacements = const [],
  });

  final String key;
  final String title;
  final String? description;
  final String? iconKey;
  final List<KnowledgeCatalogEntry> children;

  /// Catalog keys of extra parents (alias shelves).
  final List<String> catalogPlacements;

  @override
  List<Object?> get props =>
      [key, title, description, iconKey, children, catalogPlacements];
}

abstract final class KnowledgeAreaCatalog {
  static const entries = <KnowledgeCatalogEntry>[
    KnowledgeCatalogEntry(
      key: 'languages',
      title: 'Linguagens',
      iconKey: 'translate',
      description: 'Idiomas, vocabulário, gramática e pronúncia.',
      children: [
        KnowledgeCatalogEntry(key: 'languages.pt', title: 'Português'),
        KnowledgeCatalogEntry(key: 'languages.en', title: 'Inglês'),
        KnowledgeCatalogEntry(key: 'languages.fr', title: 'Francês'),
        KnowledgeCatalogEntry(key: 'languages.es', title: 'Espanhol'),
        KnowledgeCatalogEntry(key: 'languages.de', title: 'Alemão'),
        KnowledgeCatalogEntry(key: 'languages.ja', title: 'Japonês'),
        KnowledgeCatalogEntry(key: 'languages.zh', title: 'Mandarim'),
        KnowledgeCatalogEntry(key: 'languages.la', title: 'Latim'),
      ],
    ),
    KnowledgeCatalogEntry(
      key: 'math',
      title: 'Matemática',
      iconKey: 'functions',
      children: [
        KnowledgeCatalogEntry(key: 'math.algebra', title: 'Álgebra'),
        KnowledgeCatalogEntry(key: 'math.calculus', title: 'Cálculo'),
        KnowledgeCatalogEntry(key: 'math.stats', title: 'Estatística'),
        KnowledgeCatalogEntry(key: 'math.geometry', title: 'Geometria'),
        KnowledgeCatalogEntry(key: 'math.discrete', title: 'Matemática discreta'),
      ],
    ),
    KnowledgeCatalogEntry(
      key: 'science',
      title: 'Ciências',
      iconKey: 'biotech',
      children: [
        KnowledgeCatalogEntry(key: 'science.physics', title: 'Física'),
        KnowledgeCatalogEntry(key: 'science.chemistry', title: 'Química'),
        KnowledgeCatalogEntry(key: 'science.biology', title: 'Biologia'),
        KnowledgeCatalogEntry(key: 'science.astronomy', title: 'Astronomia'),
      ],
    ),
    KnowledgeCatalogEntry(
      key: 'computing',
      title: 'Computação',
      iconKey: 'terminal',
      children: [
        KnowledgeCatalogEntry(key: 'computing.algorithms', title: 'Algoritmos'),
        KnowledgeCatalogEntry(key: 'computing.flutter', title: 'Flutter'),
        KnowledgeCatalogEntry(
          key: 'computing.architecture',
          title: 'Arquitetura de software',
        ),
        KnowledgeCatalogEntry(key: 'computing.systems', title: 'Sistemas'),
        KnowledgeCatalogEntry(key: 'computing.data', title: 'Dados'),
      ],
    ),
    KnowledgeCatalogEntry(
      key: 'humanities',
      title: 'Humanidades',
      iconKey: 'menu_book',
      children: [
        KnowledgeCatalogEntry(
          key: 'humanities.history',
          title: 'História',
          children: [
            KnowledgeCatalogEntry(
              key: 'humanities.history.brazil',
              title: 'História do Brasil',
            ),
            KnowledgeCatalogEntry(
              key: 'humanities.history.art',
              title: 'História da arte',
            ),
          ],
        ),
        KnowledgeCatalogEntry(key: 'humanities.philosophy', title: 'Filosofia'),
        KnowledgeCatalogEntry(key: 'humanities.art', title: 'História da arte'),
        KnowledgeCatalogEntry(key: 'humanities.literature', title: 'Literatura'),
        KnowledgeCatalogEntry(key: 'humanities.cinema', title: 'Cinema'),
      ],
    ),
    KnowledgeCatalogEntry(
      key: 'arts',
      title: 'Artes',
      iconKey: 'piano',
      children: [
        KnowledgeCatalogEntry(
          key: 'arts.music',
          title: 'Música',
          children: [
            KnowledgeCatalogEntry(
              key: 'arts.music.theory',
              title: 'Teoria musical',
            ),
            KnowledgeCatalogEntry(
              key: 'arts.music.tropicalismo',
              title: 'Tropicalismo',
              catalogPlacements: ['humanities.history.brazil'],
            ),
          ],
        ),
        KnowledgeCatalogEntry(key: 'arts.harmony', title: 'Harmonia'),
        KnowledgeCatalogEntry(key: 'arts.piano', title: 'Piano'),
        KnowledgeCatalogEntry(key: 'arts.drawing', title: 'Desenho'),
        KnowledgeCatalogEntry(key: 'arts.photo', title: 'Fotografia'),
      ],
    ),
    KnowledgeCatalogEntry(
      key: 'society',
      title: 'Sociedade',
      iconKey: 'account_balance',
      children: [
        KnowledgeCatalogEntry(key: 'society.law', title: 'Direito'),
        KnowledgeCatalogEntry(key: 'society.econ', title: 'Economia'),
        KnowledgeCatalogEntry(key: 'society.psych', title: 'Psicologia'),
        KnowledgeCatalogEntry(key: 'society.politics', title: 'Política'),
      ],
    ),
    KnowledgeCatalogEntry(
      key: 'life',
      title: 'Vida prática',
      iconKey: 'cottage',
      children: [
        KnowledgeCatalogEntry(key: 'life.cooking', title: 'Culinária'),
        KnowledgeCatalogEntry(key: 'life.health', title: 'Saúde pessoal'),
        KnowledgeCatalogEntry(key: 'life.finance', title: 'Finanças pessoais'),
        KnowledgeCatalogEntry(key: 'life.crafts', title: 'Ofícios'),
      ],
    ),
    KnowledgeCatalogEntry(
      key: 'engineering',
      title: 'Engenharia',
      iconKey: 'precision_manufacturing',
      children: [
        KnowledgeCatalogEntry(key: 'engineering.ee', title: 'Elétrica'),
        KnowledgeCatalogEntry(key: 'engineering.me', title: 'Mecânica'),
        KnowledgeCatalogEntry(key: 'engineering.ce', title: 'Civil'),
        KnowledgeCatalogEntry(
          key: 'engineering.automotive',
          title: 'Automotiva',
          children: [
            KnowledgeCatalogEntry(
              key: 'engineering.automotive.autonomous',
              title: 'Carros autônomos',
              children: [
                KnowledgeCatalogEntry(
                  key: 'engineering.automotive.autonomous.odd',
                  title: 'ODD (Operational Design Domain)',
                  description:
                      'Condições em que o sistema autônomo foi projetado para operar.',
                ),
              ],
            ),
          ],
        ),
      ],
    ),
  ];

  static KnowledgeCatalogEntry? byKey(String key) {
    KnowledgeCatalogEntry? walk(List<KnowledgeCatalogEntry> nodes) {
      for (final node in nodes) {
        if (node.key == key) return node;
        final child = walk(node.children);
        if (child != null) return child;
      }
      return null;
    }

    return walk(entries);
  }

  /// Selected keys plus placement parents (and, via [needed], their ancestors).
  static Set<String> expandKeys(Iterable<String> keys) {
    final selected = keys.toSet();
    if (selected.isEmpty) return selected;
    var changed = true;
    while (changed) {
      changed = false;
      void walk(KnowledgeCatalogEntry entry) {
        final inSubtree = selected.contains(entry.key) ||
            entry.children.any((child) => _subtreeSelected(child, selected));
        if (inSubtree) {
          for (final parent in entry.catalogPlacements) {
            if (selected.add(parent)) changed = true;
          }
        }
        for (final child in entry.children) {
          walk(child);
        }
      }

      for (final root in entries) {
        walk(root);
      }
    }
    return selected;
  }

  static bool _subtreeSelected(
    KnowledgeCatalogEntry entry,
    Set<String> selected,
  ) {
    if (selected.contains(entry.key)) return true;
    return entry.children.any((child) => _subtreeSelected(child, selected));
  }

  static List<String> flattenKeys([List<KnowledgeCatalogEntry>? nodes]) {
    final out = <String>[];
    void walk(List<KnowledgeCatalogEntry> list) {
      for (final node in list) {
        out.add(node.key);
        walk(node.children);
      }
    }

    walk(nodes ?? entries);
    return out;
  }

  /// Root-to-leaf titles, e.g. `Linguagens > Português`.
  static List<String> labeledTitlePaths() {
    final out = <String>[];
    void walk(KnowledgeCatalogEntry entry, List<String> prefix) {
      final path = [...prefix, entry.title];
      out.add(path.join(' > '));
      for (final child in entry.children) {
        walk(child, path);
      }
    }

    for (final root in entries) {
      walk(root, const []);
    }
    return out;
  }

  static KnowledgeCatalogEntry? childNamed(
    KnowledgeCatalogEntry? parent,
    String title,
  ) {
    final haystack = parent?.children ?? entries;
    final needle = title.trim().toLowerCase();
    for (final entry in haystack) {
      final t = entry.title.toLowerCase();
      if (t == needle) return entry;
      if (t.startsWith('$needle ') || t.startsWith('$needle (')) return entry;
    }
    return null;
  }
}
