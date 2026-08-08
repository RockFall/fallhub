import 'package:colony_domain/colony_domain.dart';
import 'package:test/test.dart';

void main() {
  final now = DateTime.utc(2026, 8, 6, 12);
  const profileId = EntityId('profile-1');

  ResearchNode node(String id, {ResearchNodeStatus status = ResearchNodeStatus.available}) {
    return ResearchNode.create(
      id: EntityId(id),
      profileId: profileId,
      title: id,
      type: ResearchNodeType.knowledge,
      createdAt: now,
      status: status,
    );
  }

  group('ResearchPrerequisitePolicy', () {
    test('rejects self-link', () {
      expect(
        () => ResearchPrerequisitePolicy.validateLink(
          existingLinks: const [],
          nodeId: EntityId('a'),
          prerequisiteNodeId: EntityId('a'),
        ),
        throwsA(isA<ResearchPrerequisiteException>()),
      );
    });

    test('detects cycle', () {
      final links = [
        ResearchPrerequisiteLink(
          nodeId: EntityId('b'),
          prerequisiteNodeId: EntityId('a'),
          linkedAt: now,
        ),
      ];
      expect(
        ResearchPrerequisitePolicy.wouldCreateCycle(
          existingLinks: links,
          nodeId: EntityId('a'),
          prerequisiteNodeId: EntityId('b'),
        ),
        isTrue,
      );
    });

    test('blocks inResearch when prerequisites not demonstrated', () {
      final target = node('target');
      final prereq = node('prereq');
      expect(
        ResearchPrerequisitePolicy.canSetInResearch(
          node: target,
          prerequisites: [prereq],
        ),
        isFalse,
      );
    });

    test('allows inResearch when prerequisites demonstrated', () {
      final target = node('target');
      final prereq = node('prereq', status: ResearchNodeStatus.demonstrated);
      expect(
        ResearchPrerequisitePolicy.canSetInResearch(
          node: target,
          prerequisites: [prereq],
        ),
        isTrue,
      );
    });
  });

  group('ActiveResearchPolicy', () {
    test('allows first focus', () {
      final nodes = [node('a')];
      expect(
        ActiveResearchPolicy.canStartFocus(node: nodes.first, allNodes: nodes),
        isTrue,
      );
    });

    test('blocks second focus', () {
      final nodes = [
        node('a', status: ResearchNodeStatus.inResearch),
        node('b'),
      ];
      expect(
        ActiveResearchPolicy.canStartFocus(node: nodes[1], allNodes: nodes),
        isFalse,
      );
    });
  });

  group('buildResearchHierarchy', () {
    test('orders prerequisites before dependents with depth', () {
      final nodes = [
        node('child'),
        node('parent', status: ResearchNodeStatus.demonstrated),
      ];
      final links = [
        ResearchPrerequisiteLink(
          nodeId: EntityId('child'),
          prerequisiteNodeId: EntityId('parent'),
          linkedAt: now,
        ),
      ];

      final hierarchy = buildResearchHierarchy(nodes: nodes, links: links);
      expect(hierarchy, hasLength(2));
      expect(hierarchy.first.node.id.value, 'parent');
      expect(hierarchy.first.depth, 0);
      expect(hierarchy.last.node.id.value, 'child');
      expect(hierarchy.last.depth, 1);
    });
  });

  group('ResearchLifecyclePolicy', () {
    test('allows available to inResearch', () {
      expect(
        ResearchLifecyclePolicy.canTransition(
          ResearchNodeStatus.available,
          ResearchNodeStatus.inResearch,
        ),
        isTrue,
      );
    });

    test('blocks available to demonstrated', () {
      expect(
        ResearchLifecyclePolicy.canTransition(
          ResearchNodeStatus.available,
          ResearchNodeStatus.demonstrated,
        ),
        isFalse,
      );
    });
  });
}
