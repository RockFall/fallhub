import 'package:colony_domain/colony_domain.dart';
import 'package:test/test.dart';

void main() {
  group('SkillRubricPolicy', () {
    test('suggestLevel ladders from evidence and sessions', () {
      expect(
        SkillRubricPolicy.suggestLevel(evidenceCount: 0, sessionCount: 0),
        0,
      );
      expect(
        SkillRubricPolicy.suggestLevel(evidenceCount: 0, sessionCount: 1),
        1,
      );
      expect(
        SkillRubricPolicy.suggestLevel(evidenceCount: 1, sessionCount: 0),
        2,
      );
      expect(
        SkillRubricPolicy.suggestLevel(evidenceCount: 1, sessionCount: 1),
        2,
      );
      expect(
        SkillRubricPolicy.suggestLevel(evidenceCount: 2, sessionCount: 1),
        3,
      );
      expect(
        SkillRubricPolicy.suggestLevel(evidenceCount: 3, sessionCount: 2),
        4,
      );
      expect(
        SkillRubricPolicy.suggestLevel(evidenceCount: 4, sessionCount: 4),
        5,
      );
      expect(
        SkillRubricPolicy.suggestLevel(evidenceCount: 5, sessionCount: 5),
        6,
      );
      expect(
        SkillRubricPolicy.suggestLevel(evidenceCount: 20, sessionCount: 20),
        6,
      );
    });

    test('isStale uses last evidence age threshold', () {
      final now = DateTime.utc(2026, 8, 7);
      expect(
        SkillRubricPolicy.isStale(lastEvidenceAt: null, now: now),
        isFalse,
      );
      expect(
        SkillRubricPolicy.isStale(
          lastEvidenceAt: DateTime.utc(2026, 7, 1),
          now: now,
        ),
        isFalse,
      );
      expect(
        SkillRubricPolicy.isStale(
          lastEvidenceAt: DateTime.utc(2026, 5, 1),
          now: now,
        ),
        isTrue,
      );
    });

    test('assess combines level and stale', () {
      final assessment = SkillRubricPolicy.assess(
        evidenceCount: 2,
        sessionCount: 1,
        lastEvidenceAt: DateTime.utc(2026, 1, 1),
        now: DateTime.utc(2026, 8, 7),
      );
      expect(assessment.suggestedLevel, 3);
      expect(assessment.isStale, isTrue);
    });

    test('latestEvidenceAt picks max', () {
      expect(SkillRubricPolicy.latestEvidenceAt(const []), isNull);
      expect(
        SkillRubricPolicy.latestEvidenceAt([
          DateTime.utc(2026, 1, 1),
          DateTime.utc(2026, 3, 1),
          DateTime.utc(2026, 2, 1),
        ]),
        DateTime.utc(2026, 3, 1),
      );
    });
  });
}
