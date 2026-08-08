import 'package:equatable/equatable.dart';

import 'id_generator.dart';

enum DecisionReversibility {
  easy,
  moderate,
  hard;

  bool get isHard => this == hard;
}

class DecisionRecord extends Equatable {
  const DecisionRecord({
    required this.id,
    required this.profileId,
    required this.title,
    required this.context,
    required this.decision,
    required this.alternatives,
    required this.criteria,
    required this.assumptions,
    required this.expectedOutcomes,
    required this.risks,
    required this.reversibility,
    required this.decidedAt,
    required this.createdAt,
    required this.updatedAt,
    this.reviewAt,
    this.outcomeReview,
    this.version = 1,
  });

  final EntityId id;
  final EntityId profileId;
  final String title;
  final String context;
  final String decision;
  final List<String> alternatives;
  final List<String> criteria;
  final List<String> assumptions;
  final List<String> expectedOutcomes;
  final List<String> risks;
  final DecisionReversibility reversibility;
  final DateTime decidedAt;
  final DateTime? reviewAt;
  final String? outcomeReview;
  final DateTime createdAt;
  final DateTime updatedAt;
  final int version;

  factory DecisionRecord.create({
    required EntityId id,
    required EntityId profileId,
    required String title,
    required String context,
    required String decision,
    required DateTime decidedAt,
    required DateTime createdAt,
    List<String> alternatives = const [],
    List<String> criteria = const [],
    List<String> assumptions = const [],
    List<String> expectedOutcomes = const [],
    List<String> risks = const [],
    DecisionReversibility reversibility = DecisionReversibility.moderate,
    DateTime? reviewAt,
  }) {
    return DecisionRecord(
      id: id,
      profileId: profileId,
      title: title.trim(),
      context: context.trim(),
      decision: decision.trim(),
      alternatives: alternatives.map((s) => s.trim()).where((s) => s.isNotEmpty).toList(),
      criteria: criteria.map((s) => s.trim()).where((s) => s.isNotEmpty).toList(),
      assumptions: assumptions.map((s) => s.trim()).where((s) => s.isNotEmpty).toList(),
      expectedOutcomes:
          expectedOutcomes.map((s) => s.trim()).where((s) => s.isNotEmpty).toList(),
      risks: risks.map((s) => s.trim()).where((s) => s.isNotEmpty).toList(),
      reversibility: reversibility,
      decidedAt: decidedAt,
      reviewAt: reviewAt,
      createdAt: createdAt,
      updatedAt: createdAt,
    );
  }

  DecisionRecord copyWith({
    String? title,
    String? context,
    String? decision,
    List<String>? alternatives,
    List<String>? criteria,
    List<String>? assumptions,
    List<String>? expectedOutcomes,
    List<String>? risks,
    DecisionReversibility? reversibility,
    DateTime? decidedAt,
    DateTime? reviewAt,
    String? outcomeReview,
    DateTime? updatedAt,
    int? version,
    bool clearReviewAt = false,
    bool clearOutcomeReview = false,
  }) {
    return DecisionRecord(
      id: id,
      profileId: profileId,
      title: title ?? this.title,
      context: context ?? this.context,
      decision: decision ?? this.decision,
      alternatives: alternatives ?? this.alternatives,
      criteria: criteria ?? this.criteria,
      assumptions: assumptions ?? this.assumptions,
      expectedOutcomes: expectedOutcomes ?? this.expectedOutcomes,
      risks: risks ?? this.risks,
      reversibility: reversibility ?? this.reversibility,
      decidedAt: decidedAt ?? this.decidedAt,
      reviewAt: clearReviewAt ? null : (reviewAt ?? this.reviewAt),
      outcomeReview:
          clearOutcomeReview ? null : (outcomeReview ?? this.outcomeReview),
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      version: version ?? this.version,
    );
  }

  @override
  List<Object?> get props => [
        id,
        profileId,
        title,
        context,
        decision,
        alternatives,
        criteria,
        assumptions,
        expectedOutcomes,
        risks,
        reversibility,
        decidedAt,
        reviewAt,
        outcomeReview,
        createdAt,
        updatedAt,
        version,
      ];
}

class QuestDecisionLink extends Equatable {
  const QuestDecisionLink({
    required this.questId,
    required this.decisionId,
    required this.linkedAt,
  });

  final EntityId questId;
  final EntityId decisionId;
  final DateTime linkedAt;

  @override
  List<Object?> get props => [questId, decisionId, linkedAt];
}
