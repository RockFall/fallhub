import 'package:colony_domain/colony_domain.dart';
import 'package:test/test.dart';

void main() {
  final profileId = const EntityId('profile-1');
  final clock = DateTime.utc(2026, 1, 1);

  ResearchNode node(String id, ResearchNodeStatus status) {
    return ResearchNode.create(
      id: EntityId(id),
      profileId: profileId,
      title: id,
      type: ResearchNodeType.knowledge,
      createdAt: clock,
      status: status,
    );
  }

  group('computeResearchTreeProgress', () {
    test('returns zero for empty tree', () {
      final progress = computeResearchTreeProgress(const []);
      expect(progress.demonstratedCount, 0);
      expect(progress.activeTotal, 0);
      expect(progress.availableCount, 0);
      expect(progress.inResearchCount, 0);
      expect(progress.archivedCount, 0);
      expect(progress.demonstratedFraction, 0);
    });

    test('counts demonstrated over active total excluding archived', () {
      final progress = computeResearchTreeProgress([
        node('a', ResearchNodeStatus.demonstrated),
        node('b', ResearchNodeStatus.demonstrated),
        node('c', ResearchNodeStatus.available),
        node('d', ResearchNodeStatus.archived),
      ]);

      expect(progress.demonstratedCount, 2);
      expect(progress.activeTotal, 3);
      expect(progress.archivedCount, 1);
      expect(progress.demonstratedFraction, closeTo(2 / 3, 0.001));
    });

    test('tracks inResearch and available counts', () {
      final progress = computeResearchTreeProgress([
        node('a', ResearchNodeStatus.inResearch),
        node('b', ResearchNodeStatus.available),
      ]);

      expect(progress.inResearchCount, 1);
      expect(progress.availableCount, 1);
      expect(progress.demonstratedCount, 0);
    });

    test('all demonstrated yields fraction 1', () {
      final progress = computeResearchTreeProgress([
        node('a', ResearchNodeStatus.demonstrated),
        node('b', ResearchNodeStatus.demonstrated),
      ]);

      expect(progress.demonstratedFraction, 1);
    });
  });

  group('computeResearchNodeActivity', () {
    test('returns zero for empty sessions and evidence', () {
      final summary = computeResearchNodeActivity(
        sessions: const [],
        evidence: const [],
      );
      expect(summary.sessionCount, 0);
      expect(summary.totalDurationMinutes, 0);
      expect(summary.evidenceCount, 0);
      expect(summary.canDemonstrate, isFalse);
    });

    test('rolls up session minutes and evidence count', () {
      final nodeId = const EntityId('node-1');
      final summary = computeResearchNodeActivity(
        sessions: [
          LearningSession.create(
            id: const EntityId('s1'),
            profileId: profileId,
            nodeId: nodeId,
            startedAt: clock,
            durationMinutes: 30,
            mode: LearningSessionMode.read,
          ),
          LearningSession.create(
            id: const EntityId('s2'),
            profileId: profileId,
            nodeId: nodeId,
            startedAt: clock,
            durationMinutes: 15,
            mode: LearningSessionMode.practice,
          ),
        ],
        evidence: [
          ResearchEvidence.create(
            id: const EntityId('e1'),
            profileId: profileId,
            nodeId: nodeId,
            type: ResearchEvidenceType.note,
            title: 'Note',
            body: 'Body',
            createdAt: clock,
          ),
        ],
      );

      expect(summary.sessionCount, 2);
      expect(summary.totalDurationMinutes, 45);
      expect(summary.evidenceCount, 1);
      expect(summary.canDemonstrate, isTrue);
    });

    test('canDemonstrate is false without evidence', () {
      final summary = computeResearchNodeActivity(
        sessions: [
          LearningSession.create(
            id: const EntityId('s1'),
            profileId: profileId,
            nodeId: const EntityId('node-1'),
            startedAt: clock,
            durationMinutes: 10,
            mode: LearningSessionMode.review,
          ),
        ],
        evidence: const [],
      );

      expect(summary.canDemonstrate, isFalse);
    });
  });
}
