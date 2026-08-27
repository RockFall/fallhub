import 'attention_target.dart';
import 'habitat_rng.dart';

/// Block H — pets more convincing (MD 10 R82–R87).

class PetAttention {
  PetAttention();

  AttentionTarget? current;

  void lookAt({
    required String? entityId,
    required (int, int) cell,
    required double now,
    AttentionReason reason = AttentionReason.passingPawn,
  }) {
    current = AttentionTarget(
      entityId: entityId,
      cellX: cell.$1,
      cellY: cell.$2,
      reason: reason,
      priority: AttentionPriority.forReason(reason),
      expiresAt: now + 1.2,
    );
  }

  void tick(double now) {
    if (current != null && current!.isExpired(now)) current = null;
  }
}

class PetFavoriteSpot {
  const PetFavoriteSpot({
    required this.cell,
    required this.score,
    this.tag = '',
  });

  final (int, int) cell;
  final double score;
  final String tag;
}

abstract final class PetFavoriteSpots {
  static PetFavoriteSpot? pick({
    required List<(int, int)> candidates,
    required Map<(int, int), double> warmth,
    required Map<(int, int), double> softFloor,
    required String petId,
  }) {
    if (candidates.isEmpty) return null;
    PetFavoriteSpot? best;
    for (final c in candidates) {
      final s = (warmth[c] ?? 0) * 0.6 +
          (softFloor[c] ?? 0) * 0.5 +
          HabitatRng.unit(petId, c.$1, c.$2) * 0.1;
      if (best == null || s > best.score) {
        best = PetFavoriteSpot(cell: c, score: s, tag: 'cozy');
      }
    }
    return best;
  }
}

enum PetPlayObject { ball, string, box, none }

abstract final class PetObjectPlay {
  static PetPlayObject choose(String petId, Set<String> availableTags) {
    if (availableTags.contains('ball') &&
        HabitatRng.unit(petId, 'ball') > 0.3) {
      return PetPlayObject.ball;
    }
    if (availableTags.contains('string')) return PetPlayObject.string;
    if (availableTags.contains('box')) return PetPlayObject.box;
    return PetPlayObject.none;
  }
}

enum PetFollowMode { follow, avoid, ignore }

abstract final class PetFollowAvoid {
  static PetFollowMode decide({
    required double affinity,
    required bool humanBusy,
    required bool humanMovingFast,
    required double solitudeNeed,
  }) {
    if (humanBusy && solitudeNeed > 0.6) return PetFollowMode.avoid;
    if (humanMovingFast && affinity < 0.4) return PetFollowMode.avoid;
    if (affinity > 0.45) return PetFollowMode.follow;
    return PetFollowMode.ignore;
  }
}

abstract final class PetActivityEtiquette {
  static bool mayInterrupt({
    required String activityKind,
    required double playfulness,
  }) {
    if (activityKind == 'sleep' || activityKind == 'call') return false;
    return playfulness > 0.55;
  }

  static double interruptDelay(String petId) =>
      HabitatRng.range(0.4, 1.6, a: petId, b: 'interrupt');
}

enum PetEnergyPhase { calm, play, zoomies, windDown, sleep }

class PetEnergyPacing {
  PetEnergyPacing({this.phase = PetEnergyPhase.calm});

  PetEnergyPhase phase;
  double phaseEndsAt = 0;

  void tick(double now, {required double energy}) {
    if (now < phaseEndsAt) return;
    if (energy > 0.85) {
      phase = PetEnergyPhase.zoomies;
      phaseEndsAt = now + HabitatRng.range(4, 10, a: 'zoom');
    } else if (energy > 0.55) {
      phase = PetEnergyPhase.play;
      phaseEndsAt = now + 8;
    } else if (energy < 0.25) {
      phase = PetEnergyPhase.sleep;
      phaseEndsAt = now + 20;
    } else if (phase == PetEnergyPhase.zoomies) {
      phase = PetEnergyPhase.windDown;
      phaseEndsAt = now + 5;
    } else {
      phase = PetEnergyPhase.calm;
      phaseEndsAt = now + 6;
    }
  }
}
