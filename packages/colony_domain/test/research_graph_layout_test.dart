import 'package:colony_domain/colony_domain.dart';
import 'package:test/test.dart';

void main() {
  final profileId = const EntityId('profile-1');
  final clock = DateTime.utc(2026, 1, 1);

  ResearchNode node(String id, String title) {
    return ResearchNode.create(
      id: EntityId(id),
      profileId: profileId,
      title: title,
      type: ResearchNodeType.knowledge,
      createdAt: clock,
    );
  }

  ResearchPrerequisiteLink link(String from, String to) {
    return ResearchPrerequisiteLink(
      nodeId: EntityId(to),
      prerequisiteNodeId: EntityId(from),
      linkedAt: clock,
    );
  }

  group('buildResearchGraphLayout', () {
    test('returns empty layout for no nodes', () {
      final layout = buildResearchGraphLayout(nodes: const [], links: const []);
      expect(layout.nodes, isEmpty);
      expect(layout.edges, isEmpty);
      expect(layout.width, 0);
      expect(layout.height, 0);
    });

    test('places single node at layer 0', () {
      final layout = buildResearchGraphLayout(
        nodes: [node('a', 'Alpha')],
        links: const [],
      );
      expect(layout.nodes, hasLength(1));
      expect(layout.nodes.single.layer, 0);
      expect(layout.nodes.single.indexInLayer, 0);
      expect(layout.nodes.single.position.x, researchGraphPadding);
      expect(layout.nodes.single.position.y, researchGraphPadding);
      expect(layout.edges, isEmpty);
    });

    test('linear chain stacks layers vertically', () {
      final layout = buildResearchGraphLayout(
        nodes: [
          node('a', 'A'),
          node('b', 'B'),
          node('c', 'C'),
        ],
        links: [
          link('a', 'b'),
          link('b', 'c'),
        ],
      );

      expect(layout.nodes, hasLength(3));
      expect(layout.edges, hasLength(2));

      final byId = {for (final n in layout.nodes) n.node.id.value: n};
      expect(byId['a']!.layer, 0);
      expect(byId['b']!.layer, 1);
      expect(byId['c']!.layer, 2);
      expect(byId['b']!.position.y, greaterThan(byId['a']!.position.y));
      expect(byId['c']!.position.y, greaterThan(byId['b']!.position.y));
    });

    test('fork places siblings on same layer with stable order', () {
      final layout = buildResearchGraphLayout(
        nodes: [
          node('a', 'A'),
          node('b', 'B'),
          node('c', 'C'),
        ],
        links: [
          link('a', 'b'),
          link('a', 'c'),
        ],
      );

      final layer1 = layout.nodes.where((n) => n.layer == 1).toList()
        ..sort((a, b) => a.indexInLayer.compareTo(b.indexInLayer));
      expect(layer1, hasLength(2));
      expect(layer1[0].node.title, 'B');
      expect(layer1[1].node.title, 'C');
      expect(layer1[1].position.x, greaterThan(layer1[0].position.x));
    });

    test('ignores orphan prerequisite links', () {
      final layout = buildResearchGraphLayout(
        nodes: [node('a', 'A')],
        links: [link('missing', 'a')],
      );
      expect(layout.nodes, hasLength(1));
      expect(layout.edges, isEmpty);
    });

    test('layout order is deterministic for same input', () {
      final nodes = [
        node('c', 'C'),
        node('a', 'A'),
        node('b', 'B'),
      ];
      final links = [link('a', 'b'), link('b', 'c')];

      final first = buildResearchGraphLayout(nodes: nodes, links: links);
      final second = buildResearchGraphLayout(nodes: nodes, links: links);

      expect(
        first.nodes.map((n) => n.node.id.value).toList(),
        second.nodes.map((n) => n.node.id.value).toList(),
      );
    });
  });
}
