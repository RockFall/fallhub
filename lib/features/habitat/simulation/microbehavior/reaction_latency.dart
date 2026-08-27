import '../identity/identity.dart';
import 'habitat_rng.dart';

/// Classes of stimulus that schedule a delayed reaction (MD 10 R2).
enum ReactionEventClass {
  /// Draft / click-to-order — must stay snappy.
  manualOrder,

  /// Conversation beat / turn taking.
  conversationBeat,

  /// Weather, distant noise, ambient curiosity.
  ambientEvent,

  /// Soft probe to join a group / social approach.
  groupJoinProbe,
}

/// Inputs that stretch or shrink reaction delay.
class ReactionLatencyContext {
  const ReactionLatencyContext({
    required this.eventClass,
    required this.pawnId,
    this.worldSeed = 0,
    this.salience = 0.5,
    this.busyCommitment = 0,
    this.hasAttentionFocus = false,
    this.profile,
    this.salt = 0,
  });

  final ReactionEventClass eventClass;
  final String pawnId;
  final int worldSeed;

  /// 0..1 — higher salience shortens delay.
  final double salience;

  /// 0..1 — higher commitment (posing, conversing) lengthens ambient delay.
  final double busyCommitment;

  final bool hasAttentionFocus;
  final BehaviorProfile? profile;

  /// Extra salt so successive events for the same pawn diverge.
  final int salt;
}

/// Base ranges from MD 10 R2 (seconds).
abstract final class ReactionLatencyRanges {
  static (double, double) forClass(ReactionEventClass c) => switch (c) {
        ReactionEventClass.manualOrder => (0.0, 0.12),
        ReactionEventClass.conversationBeat => (0.12, 0.60),
        ReactionEventClass.ambientEvent => (0.25, 1.40),
        ReactionEventClass.groupJoinProbe => (0.40, 1.80),
      };
}

/// Pure deterministic reaction delay (R2).
abstract final class ReactionLatency {
  static double compute(ReactionLatencyContext ctx) {
    // Manual orders stay immediate — never gate on personality.
    if (ctx.eventClass == ReactionEventClass.manualOrder) {
      final (lo, hi) = ReactionLatencyRanges.forClass(ctx.eventClass);
      return HabitatRng.range(
        lo,
        hi,
        a: ctx.pawnId,
        b: 'manual',
        c: ctx.salt,
      );
    }

    var (lo, hi) = ReactionLatencyRanges.forClass(ctx.eventClass);
    final mid = (lo + hi) * 0.5;
    var delay = HabitatRng.range(
      lo,
      hi,
      a: ctx.pawnId,
      b: ctx.eventClass.name,
      c: Object.hash(ctx.worldSeed, ctx.salt),
    );

    // Salience compresses toward the low end.
    final sal = ctx.salience.clamp(0.0, 1.0);
    delay = delay + (lo - delay) * sal * 0.55;

    // Busy commitment stretches ambient / group probes.
    if (ctx.eventClass == ReactionEventClass.ambientEvent ||
        ctx.eventClass == ReactionEventClass.groupJoinProbe) {
      delay += ctx.busyCommitment.clamp(0.0, 1.0) * 0.35;
    }

    // Already looking elsewhere → slight extra latency to "notice".
    if (ctx.hasAttentionFocus &&
        ctx.eventClass != ReactionEventClass.conversationBeat) {
      delay += 0.08;
    }

    final p = ctx.profile;
    if (p != null) {
      // Neuroticism reacts faster to ambient; conscientiousness a bit slower.
      delay += (0.5 - p.neuroticism) * 0.18;
      delay += (p.conscientiousness - 0.5) * 0.1;
      // Reserved social style hesitates on group joins.
      if (ctx.eventClass == ReactionEventClass.groupJoinProbe) {
        delay += switch (p.socialStyle) {
          SocialStyle.reserved => 0.25,
          SocialStyle.balanced => 0.0,
          SocialStyle.outgoing => -0.12,
        };
      }
    }

    // Keep within a soft envelope around the class range.
    final softLo = lo * 0.85;
    final softHi = hi * 1.15 + mid * 0.05;
    return delay.clamp(softLo, softHi);
  }
}

/// One scheduled reaction waiting to fire.
class PendingReaction {
  PendingReaction({
    required this.id,
    required this.eventClass,
    required this.firesAt,
    required this.payload,
  });

  final String id;
  final ReactionEventClass eventClass;
  final double firesAt;
  final Object? payload;

  bool isReady(double now) => now >= firesAt;
}

/// Per-pawn (or world) queue of delayed reactions.
class ReactionScheduler {
  final List<PendingReaction> _pending = [];

  List<PendingReaction> get pending => List.unmodifiable(_pending);

  void schedule(PendingReaction reaction) {
    // Manual orders preempt ambient clutter of the same id.
    _pending.removeWhere(
      (r) =>
          r.id == reaction.id ||
          (reaction.eventClass == ReactionEventClass.manualOrder &&
              r.eventClass != ReactionEventClass.manualOrder &&
              r.id.startsWith(reaction.id)),
    );
    _pending.add(reaction);
  }

  /// Drain all reactions ready at [now], sorted by fire time.
  List<PendingReaction> drainReady(double now) {
    final ready = _pending.where((r) => r.isReady(now)).toList()
      ..sort((a, b) => a.firesAt.compareTo(b.firesAt));
    for (final r in ready) {
      _pending.remove(r);
    }
    return ready;
  }

  void cancelWhere(bool Function(PendingReaction r) test) {
    _pending.removeWhere(test);
  }

  void clear() => _pending.clear();
}
