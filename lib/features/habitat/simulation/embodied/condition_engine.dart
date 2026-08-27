import '../mirror/mirror_signal.dart';
import 'pawn_embodied_state.dart';

/// Temporary conditions with decay / presentation (MD 08 M7).
class ConditionEngine {
  ConditionEngine({this.tickIntervalSimSeconds = 8});

  final double tickIntervalSimSeconds;
  final Map<String, double> _lastTickAt = {};

  static ConditionPresentation presentationFor(PawnConditionKind kind) {
    return switch (kind) {
      PawnConditionKind.sleepy => const ConditionPresentation(
          moteTag: 'yawn',
          bubbleTag: 'sleepy',
          walkSpeedMultiplier: 0.88,
          idleDurationMultiplier: 1.35,
        ),
      PawnConditionKind.tired => const ConditionPresentation(
          walkSpeedMultiplier: 0.9,
          idleDurationMultiplier: 1.2,
        ),
      PawnConditionKind.wellRested => const ConditionPresentation(
          walkSpeedMultiplier: 1.05,
          idleDurationMultiplier: 0.9,
        ),
      PawnConditionKind.groggy => const ConditionPresentation(
          moteTag: 'groggy',
          bubbleTag: 'groggy',
          walkSpeedMultiplier: 0.82,
          idleDurationMultiplier: 1.5,
        ),
      PawnConditionKind.physicallyTired => const ConditionPresentation(
          walkSpeedMultiplier: 0.85,
        ),
      PawnConditionKind.mentallyFatigued => const ConditionPresentation(
          idleDurationMultiplier: 1.25,
        ),
      PawnConditionKind.sociallyDrained => const ConditionPresentation(
          bubbleTag: 'need_space',
        ),
      PawnConditionKind.restless => const ConditionPresentation(
          walkSpeedMultiplier: 1.08,
          idleDurationMultiplier: 0.7,
        ),
      PawnConditionKind.relaxed => const ConditionPresentation(
          idleDurationMultiplier: 1.15,
        ),
      PawnConditionKind.inspired => const ConditionPresentation(
          moteTag: 'spark',
        ),
      PawnConditionKind.cold => const ConditionPresentation(
          bubbleTag: 'cold',
          walkSpeedMultiplier: 0.95,
        ),
      PawnConditionKind.hot => const ConditionPresentation(
          bubbleTag: 'hot',
          walkSpeedMultiplier: 0.95,
        ),
    };
  }

  static Map<CapacityKind, double> capacityModsFor(PawnConditionKind kind) {
    return switch (kind) {
      PawnConditionKind.sleepy => {
          CapacityKind.energy: -0.15,
          CapacityKind.focus: -0.2,
        },
      PawnConditionKind.tired => {
          CapacityKind.energy: -0.2,
          CapacityKind.physicalReadiness: -0.1,
        },
      PawnConditionKind.wellRested => {
          CapacityKind.energy: 0.12,
          CapacityKind.focus: 0.08,
        },
      PawnConditionKind.groggy => {
          CapacityKind.focus: -0.3,
          CapacityKind.decisionCapacity: -0.25,
          CapacityKind.energy: -0.15,
        },
      PawnConditionKind.physicallyTired => {
          CapacityKind.physicalReadiness: -0.35,
          CapacityKind.recovery: -0.1,
        },
      PawnConditionKind.mentallyFatigued => {
          CapacityKind.focus: -0.25,
          CapacityKind.creativeCapacity: -0.15,
        },
      PawnConditionKind.sociallyDrained => {
          CapacityKind.socialTolerance: -0.4,
        },
      PawnConditionKind.restless => {
          CapacityKind.physicalReadiness: 0.1,
          CapacityKind.focus: -0.05,
        },
      PawnConditionKind.relaxed => {
          CapacityKind.recovery: 0.15,
          CapacityKind.socialTolerance: 0.05,
        },
      PawnConditionKind.inspired => {
          CapacityKind.creativeCapacity: 0.25,
          CapacityKind.focus: 0.1,
        },
      PawnConditionKind.cold || PawnConditionKind.hot => {
          CapacityKind.focus: -0.08,
          CapacityKind.energy: -0.05,
        },
    };
  }

  static Map<String, double> affordanceModsFor(PawnConditionKind kind) {
    return switch (kind) {
      PawnConditionKind.sleepy => {'sleep': 0.4, 'sit': 0.25, 'wander': -0.15},
      PawnConditionKind.tired => {'rest': 0.3, 'sleep': 0.2},
      PawnConditionKind.groggy => {'sleep': 0.15, 'creativeShort': -0.3},
      PawnConditionKind.restless => {
          'stretch': 0.35,
          'wander': 0.25,
          'sit': -0.2,
        },
      PawnConditionKind.inspired => {'creativeShort': 0.4, 'listenMusic': 0.15},
      PawnConditionKind.sociallyDrained => {
          'socialChat': -0.45,
          'listenMusic': 0.2,
        },
      PawnConditionKind.physicallyTired => {
          'stretch': -0.2,
          'terraceWalk': -0.25,
          'sit': 0.2,
        },
      _ => const {},
    };
  }

  PawnCondition create({
    required PawnConditionKind kind,
    required double intensity,
    required double atSimSeconds,
    double? durationSeconds,
    MirrorSignalSource source = MirrorSignalSource.systemDerived,
  }) {
    return PawnCondition(
      id: '${kind.name}-$atSimSeconds',
      kind: kind,
      intensity: intensity.clamp(0.0, 1.0),
      source: source,
      startedAtSimSeconds: atSimSeconds,
      expectedEndAtSimSeconds:
          durationSeconds == null ? null : atSimSeconds + durationSeconds,
      capacityModifiers: capacityModsFor(kind),
      affordanceModifiers: affordanceModsFor(kind),
      presentation: presentationFor(kind),
    );
  }

  PawnEmbodiedState upsert(
    PawnEmbodiedState state,
    PawnCondition condition,
  ) {
    final others =
        state.conditions.where((c) => c.kind != condition.kind).toList();
    return state.copyWith(conditions: [...others, condition]);
  }

  PawnEmbodiedState maybeTick({
    required PawnEmbodiedState state,
    required double simSeconds,
  }) {
    final last = _lastTickAt[state.pawnId] ?? 0;
    if (simSeconds - last < tickIntervalSimSeconds) return state;
    final dt = simSeconds - last;
    _lastTickAt[state.pawnId] = simSeconds;

    final next = <PawnCondition>[];
    for (final c in state.conditions) {
      if (!c.isActiveAt(simSeconds)) continue;
      // Soft decay when no hard end, or approaching end.
      var intensity = c.intensity;
      if (c.expectedEndAtSimSeconds != null) {
        final left = c.expectedEndAtSimSeconds! - simSeconds;
        if (left < 30) {
          intensity *= (left / 30).clamp(0.0, 1.0);
        }
      } else {
        intensity = (intensity - 0.01 * (dt / 60)).clamp(0.0, 1.0);
      }
      if (intensity <= 0.02) continue;
      next.add(c.copyWith(intensity: intensity));
    }
    return state.copyWith(conditions: next);
  }

  /// Combined walk speed from active conditions (clamped).
  static double combinedWalkSpeed(List<PawnCondition> conditions) {
    var m = 1.0;
    for (final c in conditions) {
      m *= c.presentation.walkSpeedMultiplier;
    }
    return m.clamp(0.7, 1.2);
  }

  /// Presentation snapshot for renderer — no rule internals.
  static ConditionPresentation combinedPresentation(
    List<PawnCondition> conditions,
  ) {
    if (conditions.isEmpty) return const ConditionPresentation();
    // Strongest intensity wins mote/bubble; multipliers multiply.
    PawnCondition? best;
    for (final c in conditions) {
      if (best == null || c.intensity > best.intensity) best = c;
    }
    return ConditionPresentation(
      moteTag: best?.presentation.moteTag,
      bubbleTag: best?.presentation.bubbleTag,
      walkSpeedMultiplier: combinedWalkSpeed(conditions),
      idlePoseTag: best?.presentation.idlePoseTag,
      idleDurationMultiplier: conditions.fold(
        1.0,
        (a, c) => a * c.presentation.idleDurationMultiplier,
      ),
    );
  }
}
