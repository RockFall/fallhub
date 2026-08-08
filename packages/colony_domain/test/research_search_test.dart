import 'package:colony_domain/colony_domain.dart';
import 'package:test/test.dart';

void main() {
  ResearchNode node({
    required String id,
    required String title,
    String? description,
  }) {
    return ResearchNode.create(
      id: EntityId(id),
      profileId: const EntityId('profile-1'),
      title: title,
      type: ResearchNodeType.knowledge,
      createdAt: DateTime.utc(2026, 1, 1),
      description: description,
    );
  }

  ResearchHierarchyNode item(ResearchNode n, {int depth = 0}) {
    return ResearchHierarchyNode(node: n, depth: depth);
  }

  final hierarchy = [
    item(node(id: 'a', title: 'Flutter Basics')),
    item(node(id: 'b', title: 'State Management', description: 'Riverpod patterns'), depth: 1),
    item(node(id: 'c', title: 'Database', description: 'Drift and SQLite')),
  ];

  group('filterResearchHierarchy', () {
    test('returns full hierarchy when query is empty', () {
      expect(
        filterResearchHierarchy(hierarchy: hierarchy, query: ''),
        hierarchy,
      );
      expect(
        filterResearchHierarchy(hierarchy: hierarchy, query: '   '),
        hierarchy,
      );
    });

    test('matches title case-insensitively', () {
      final result = filterResearchHierarchy(
        hierarchy: hierarchy,
        query: 'flutter',
      );
      expect(result, hasLength(1));
      expect(result.single.node.title, 'Flutter Basics');
    });

    test('matches description when title does not match', () {
      final result = filterResearchHierarchy(
        hierarchy: hierarchy,
        query: 'riverpod',
      );
      expect(result, hasLength(1));
      expect(result.single.node.title, 'State Management');
    });

    test('returns empty list when nothing matches', () {
      expect(
        filterResearchHierarchy(hierarchy: hierarchy, query: 'kotlin'),
        isEmpty,
      );
    });

    test('handles null description', () {
      final result = filterResearchHierarchy(
        hierarchy: hierarchy,
        query: 'basics',
      );
      expect(result, hasLength(1));
      expect(result.single.node.description, isNull);
    });
  });
}
