import 'research_node.dart';

/// Gate for transitioning research nodes to demonstrated status.
class ResearchDemonstrationPolicy {
  const ResearchDemonstrationPolicy._();

  static bool canDemonstrate({required int evidenceCount}) => evidenceCount >= 1;

  /// Demonstrated nodes must keep at least one evidence record.
  static bool canDeleteEvidence({
    required ResearchNodeStatus nodeStatus,
    required int evidenceCount,
  }) {
    if (nodeStatus != ResearchNodeStatus.demonstrated) return true;
    return evidenceCount > 1;
  }
}

class ResearchDemonstrationException implements Exception {
  ResearchDemonstrationException(this.message);

  final String message;

  @override
  String toString() => message;
}

class ResearchEvidenceDeleteException implements Exception {
  const ResearchEvidenceDeleteException();

  @override
  String toString() => 'last evidence on demonstrated node';
}
