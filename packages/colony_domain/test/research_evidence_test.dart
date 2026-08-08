import 'package:colony_domain/colony_domain.dart';
import 'package:test/test.dart';

void main() {
  group('ResearchEvidence', () {
    test('create trims title and body', () {
      final evidence = ResearchEvidence.create(
        id: const EntityId('evidence-1'),
        profileId: const EntityId('profile-1'),
        nodeId: const EntityId('node-1'),
        type: ResearchEvidenceType.note,
        title: '  Título  ',
        body: '  Corpo  ',
        createdAt: DateTime.utc(2026, 8, 6, 12),
      );

      expect(evidence.title, 'Título');
      expect(evidence.body, 'Corpo');
    });
  });

  group('ResearchDemonstrationPolicy', () {
    test('canDemonstrate requires at least one evidence', () {
      expect(
        ResearchDemonstrationPolicy.canDemonstrate(evidenceCount: 0),
        isFalse,
      );
      expect(
        ResearchDemonstrationPolicy.canDemonstrate(evidenceCount: 1),
        isTrue,
      );
      expect(
        ResearchDemonstrationPolicy.canDemonstrate(evidenceCount: 3),
        isTrue,
      );
    });

    test('canDeleteEvidence blocks last evidence on demonstrated node', () {
      expect(
        ResearchDemonstrationPolicy.canDeleteEvidence(
          nodeStatus: ResearchNodeStatus.demonstrated,
          evidenceCount: 1,
        ),
        isFalse,
      );
      expect(
        ResearchDemonstrationPolicy.canDeleteEvidence(
          nodeStatus: ResearchNodeStatus.demonstrated,
          evidenceCount: 2,
        ),
        isTrue,
      );
      expect(
        ResearchDemonstrationPolicy.canDeleteEvidence(
          nodeStatus: ResearchNodeStatus.inResearch,
          evidenceCount: 1,
        ),
        isTrue,
      );
    });
  });
}
