import 'package:equatable/equatable.dart';

/// Suggested world-knowledge map. Seeded only when the user opts in.
class KnowledgeCatalogEntry extends Equatable {
  const KnowledgeCatalogEntry({
    required this.key,
    required this.title,
    this.description,
    this.iconKey,
    this.children = const [],
  });

  final String key;
  final String title;
  final String? description;
  final String? iconKey;
  final List<KnowledgeCatalogEntry> children;

  @override
  List<Object?> get props => [key, title, description, iconKey, children];
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
        KnowledgeCatalogEntry(key: 'humanities.history', title: 'História'),
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
        KnowledgeCatalogEntry(key: 'arts.music', title: 'Música'),
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
}
