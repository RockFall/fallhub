import 'learning_session.dart';
import 'research_evidence.dart';
import 'research_node.dart';

class ResearchTreeProgress {
  const ResearchTreeProgress({
    required this.demonstratedCount,
    required this.activeTotal,
    required this.availableCount,
    required this.inResearchCount,
    required this.archivedCount,
  });

  final int demonstratedCount;
  final int availableCount;
  final int inResearchCount;
  final int archivedCount;

  /// Total nodes excluding archived (denominator for completion fraction).
  final int activeTotal;

  double get demonstratedFraction =>
      activeTotal == 0 ? 0 : demonstratedCount / activeTotal;

  static const zero = ResearchTreeProgress(
    demonstratedCount: 0,
    activeTotal: 0,
    availableCount: 0,
    inResearchCount: 0,
    archivedCount: 0,
  );
}

ResearchTreeProgress computeResearchTreeProgress(List<ResearchNode> nodes) {
  var demonstrated = 0;
  var available = 0;
  var inResearch = 0;
  var archived = 0;

  for (final node in nodes) {
    switch (node.status) {
      case ResearchNodeStatus.demonstrated:
        demonstrated++;
      case ResearchNodeStatus.available:
        available++;
      case ResearchNodeStatus.inResearch:
        inResearch++;
      case ResearchNodeStatus.archived:
        archived++;
    }
  }

  return ResearchTreeProgress(
    demonstratedCount: demonstrated,
    activeTotal: nodes.length - archived,
    availableCount: available,
    inResearchCount: inResearch,
    archivedCount: archived,
  );
}

class ResearchNodeActivitySummary {
  const ResearchNodeActivitySummary({
    required this.sessionCount,
    required this.totalDurationMinutes,
    required this.evidenceCount,
  });

  final int sessionCount;
  final int totalDurationMinutes;
  final int evidenceCount;

  bool get canDemonstrate => evidenceCount >= 1;

  static const zero = ResearchNodeActivitySummary(
    sessionCount: 0,
    totalDurationMinutes: 0,
    evidenceCount: 0,
  );
}

ResearchNodeActivitySummary computeResearchNodeActivity({
  required List<LearningSession> sessions,
  required List<ResearchEvidence> evidence,
}) {
  return ResearchNodeActivitySummary(
    sessionCount: sessions.length,
    totalDurationMinutes: sessions.fold<int>(
      0,
      (sum, session) => sum + session.durationMinutes,
    ),
    evidenceCount: evidence.length,
  );
}
