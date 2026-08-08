/// Lite skill rubric (spec §15.3 / §15.5) — suggested level 0–6 from local
/// evidence/session counts, plus a stale hint from last-evidence age.
/// Does not persist levels or silently decay stored competence.
class SkillRubricAssessment {
  const SkillRubricAssessment({
    required this.suggestedLevel,
    required this.isStale,
  });

  /// Heuristic level in 0–6 (never written back to the node).
  final int suggestedLevel;

  /// True when last evidence is older than the stale threshold.
  final bool isStale;
}

class SkillRubricPolicy {
  const SkillRubricPolicy._();

  static const int maxLevel = 6;
  static const int defaultStaleDays = 60;

  /// Suggests a display-only level from local activity counts.
  static int suggestLevel({
    required int evidenceCount,
    required int sessionCount,
  }) {
    final evidence = evidenceCount < 0 ? 0 : evidenceCount;
    final sessions = sessionCount < 0 ? 0 : sessionCount;
    final score = evidence * 2 + sessions;
    if (score <= 0) return 0;
    if (score <= 1) return 1;
    if (score <= 3) return 2;
    if (score <= 5) return 3;
    if (score <= 8) return 4;
    if (score <= 12) return 5;
    return maxLevel;
  }

  /// Stale confidence when last evidence is older than [thresholdDays].
  /// No evidence → not stale (level 0 / no confidence to decay).
  static bool isStale({
    required DateTime? lastEvidenceAt,
    required DateTime now,
    int thresholdDays = defaultStaleDays,
  }) {
    if (lastEvidenceAt == null) return false;
    final age = now.toUtc().difference(lastEvidenceAt.toUtc());
    return age.inDays >= thresholdDays;
  }

  static SkillRubricAssessment assess({
    required int evidenceCount,
    required int sessionCount,
    required DateTime? lastEvidenceAt,
    required DateTime now,
    int staleThresholdDays = defaultStaleDays,
  }) {
    return SkillRubricAssessment(
      suggestedLevel: suggestLevel(
        evidenceCount: evidenceCount,
        sessionCount: sessionCount,
      ),
      isStale: isStale(
        lastEvidenceAt: lastEvidenceAt,
        now: now,
        thresholdDays: staleThresholdDays,
      ),
    );
  }

  static DateTime? latestEvidenceAt(Iterable<DateTime> createdAts) {
    DateTime? latest;
    for (final at in createdAts) {
      if (latest == null || at.isAfter(latest)) latest = at;
    }
    return latest;
  }
}
