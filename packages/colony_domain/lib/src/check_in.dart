import 'package:equatable/equatable.dart';

import 'id_generator.dart';
import 'need_enums.dart';

/// Converts 1–5 picker values to normalized 0–1.
double normalizeScale5(int value) => (value.clamp(1, 5) - 1) / 4;

/// Converts normalized 0–1 back to 1–5 for display.
int denormalizeScale5(double value) => (value * 4).round().clamp(1, 5) + 1;

class CheckIn extends Equatable {
  const CheckIn({
    required this.id,
    required this.profileId,
    required this.observedAt,
    required this.createdAt,
    required this.mood,
    required this.energy,
    required this.tension,
    required this.focus,
    this.note,
    this.contextTags = const [],
    this.moodScale = MoodScale.five,
  });

  final EntityId id;
  final EntityId profileId;
  final DateTime observedAt;
  final DateTime createdAt;
  final double mood;
  final double energy;
  final double tension;
  final double focus;
  final String? note;
  final List<String> contextTags;
  final MoodScale moodScale;

  String get moodLabel => _scaleLabel(mood);

  String get energyLabel => _scaleLabel(energy);

  static String _scaleLabel(double value) {
    if (value >= 0.85) return 'Muito bom';
    if (value >= 0.65) return 'Bom';
    if (value >= 0.45) return 'Neutro';
    if (value >= 0.25) return 'Baixo';
    return 'Muito baixo';
  }

  @override
  List<Object?> get props => [
        id,
        profileId,
        observedAt,
        createdAt,
        mood,
        energy,
        tension,
        focus,
        note,
        contextTags,
        moodScale,
      ];
}

class MoodFactor extends Equatable {
  const MoodFactor({
    required this.id,
    required this.checkInId,
    required this.label,
    required this.kind,
    this.impact,
    this.uncertain = false,
  });

  final EntityId id;
  final EntityId checkInId;
  final String label;
  final MoodFactorKind kind;
  final int? impact;
  final bool uncertain;

  @override
  List<Object?> get props => [id, checkInId, label, kind, impact, uncertain];
}

class DailyReview extends Equatable {
  const DailyReview({
    required this.id,
    required this.profileId,
    required this.reviewDate,
    required this.createdAt,
    this.whatHappened,
    this.currentState,
    this.tomorrowCommitments,
    this.routeCorrection,
  });

  final EntityId id;
  final EntityId profileId;
  final DateTime reviewDate;
  final DateTime createdAt;
  final String? whatHappened;
  final String? currentState;
  final String? tomorrowCommitments;
  final String? routeCorrection;

  @override
  List<Object?> get props => [
        id,
        profileId,
        reviewDate,
        createdAt,
        whatHappened,
        currentState,
        tomorrowCommitments,
        routeCorrection,
      ];
}

abstract final class CheckInPrompts {
  static const daily = [
    'O que consumiu energia?',
    'O que restaurou energia?',
    'Qual preocupação precisa virar ação, decisão ou aceitação?',
    'O que foi melhor do que parecia?',
  ];
}

abstract final class SuggestedMoodFactors {
  static const labels = [
    'Interação positiva',
    'Preocupação com prazo',
    'Ambiente agradável',
    'Frustração técnica',
    'Música ou prática',
    'Descanso',
    'Avanço significativo',
    'Sono curto',
  ];
}
