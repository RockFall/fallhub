import 'micro_facing.dart';

/// How a seat decides functional facing when occupied (MD 10 R11).
enum SeatOrientationPolicy {
  /// Use prop.facing as-is.
  fixed,

  /// Face nearest prop with [targetTag] (e.g. tv, fireplace).
  faceTargetTag,

  /// Face geometric center of linked table / dining cluster.
  faceTableCenter,

  /// Face approximate room center.
  faceRoomCenter,

  /// Face average of conversation partners.
  faceConversationCluster,

  /// Infer from tags: table→tableCenter, joy/tv→targetTag, else fixed.
  auto,
}

class SeatOrientationContext {
  const SeatOrientationContext({
    required this.seatCell,
    required this.propFacing,
    this.policy = SeatOrientationPolicy.auto,
    this.propKind = '',
    this.tags = const {},
    this.targetTagCells = const {},
    this.tableCenter,
    this.roomCenter,
    this.conversationCells = const [],
  });

  final (int, int) seatCell;
  final MicroFacing propFacing;
  final SeatOrientationPolicy policy;
  final String propKind;
  final Set<String> tags;

  /// tag → list of prop centers (tv, window, …).
  final Map<String, List<(int, int)>> targetTagCells;

  final (int, int)? tableCenter;
  final (int, int)? roomCenter;
  final List<(int, int)> conversationCells;
}

class SeatOrientationResult {
  const SeatOrientationResult({
    required this.facing,
    required this.policyApplied,
    this.lookAtCell,
  });

  final MicroFacing facing;
  final SeatOrientationPolicy policyApplied;
  final (int, int)? lookAtCell;
}

abstract final class SeatOrientationResolver {
  static SeatOrientationResult resolve(SeatOrientationContext ctx) {
    final policy = ctx.policy == SeatOrientationPolicy.auto
        ? _inferPolicy(ctx)
        : ctx.policy;

    switch (policy) {
      case SeatOrientationPolicy.fixed:
        return SeatOrientationResult(
          facing: ctx.propFacing,
          policyApplied: policy,
        );
      case SeatOrientationPolicy.faceTargetTag:
        final look = _nearestTagged(ctx);
        if (look == null) {
          return SeatOrientationResult(
            facing: ctx.propFacing,
            policyApplied: SeatOrientationPolicy.fixed,
          );
        }
        return SeatOrientationResult(
          facing: _facingToward(ctx.seatCell, look),
          policyApplied: policy,
          lookAtCell: look,
        );
      case SeatOrientationPolicy.faceTableCenter:
        final t = ctx.tableCenter ?? _nearestTagged(ctx, prefer: 'table');
        if (t == null) {
          return SeatOrientationResult(
            facing: ctx.propFacing,
            policyApplied: SeatOrientationPolicy.fixed,
          );
        }
        return SeatOrientationResult(
          facing: _facingToward(ctx.seatCell, t),
          policyApplied: policy,
          lookAtCell: t,
        );
      case SeatOrientationPolicy.faceRoomCenter:
        final r = ctx.roomCenter;
        if (r == null) {
          return SeatOrientationResult(
            facing: ctx.propFacing,
            policyApplied: SeatOrientationPolicy.fixed,
          );
        }
        return SeatOrientationResult(
          facing: _facingToward(ctx.seatCell, r),
          policyApplied: policy,
          lookAtCell: r,
        );
      case SeatOrientationPolicy.faceConversationCluster:
        if (ctx.conversationCells.isEmpty) {
          return SeatOrientationResult(
            facing: ctx.propFacing,
            policyApplied: SeatOrientationPolicy.fixed,
          );
        }
        final avg = _averageCell(ctx.conversationCells);
        return SeatOrientationResult(
          facing: _facingToward(ctx.seatCell, avg),
          policyApplied: policy,
          lookAtCell: avg,
        );
      case SeatOrientationPolicy.auto:
        return SeatOrientationResult(
          facing: ctx.propFacing,
          policyApplied: SeatOrientationPolicy.fixed,
        );
    }
  }

  static SeatOrientationPolicy _inferPolicy(SeatOrientationContext ctx) {
    final kind = ctx.propKind.toLowerCase();
    final tags = ctx.tags.map((t) => t.toLowerCase()).toSet();
    if (kind.contains('sofa') ||
        kind.contains('couch') ||
        tags.contains('tv') ||
        kind.contains('tv')) {
      return SeatOrientationPolicy.faceTargetTag;
    }
    if (kind.contains('dining') ||
        kind.contains('table') ||
        tags.contains('table') ||
        kind.contains('chair') && tags.contains('dining')) {
      return SeatOrientationPolicy.faceTableCenter;
    }
    if (kind.contains('reading') ||
        kind.contains('armchair') ||
        tags.contains('reading')) {
      return SeatOrientationPolicy.faceRoomCenter;
    }
    if (ctx.conversationCells.isNotEmpty) {
      return SeatOrientationPolicy.faceConversationCluster;
    }
    return SeatOrientationPolicy.fixed;
  }

  static (int, int)? _nearestTagged(
    SeatOrientationContext ctx, {
    String? prefer,
  }) {
    final keys = prefer != null
        ? [prefer, 'tv', 'window', 'fireplace']
        : ['tv', 'window', 'fireplace', 'table'];
    (int, int)? best;
    var bestD = 1 << 30;
    for (final key in keys) {
      final list = ctx.targetTagCells[key];
      if (list == null) continue;
      for (final c in list) {
        final d = (c.$1 - ctx.seatCell.$1).abs() + (c.$2 - ctx.seatCell.$2).abs();
        if (d < bestD) {
          bestD = d;
          best = c;
        }
      }
      if (prefer != null && key == prefer && best != null) return best;
    }
    return best;
  }

  static (int, int) _averageCell(List<(int, int)> cells) {
    var sx = 0, sy = 0;
    for (final c in cells) {
      sx += c.$1;
      sy += c.$2;
    }
    return (sx ~/ cells.length, sy ~/ cells.length);
  }

  static MicroFacing _facingToward((int, int) from, (int, int) to) =>
      microFacingFromDelta(to.$1 - from.$1, to.$2 - from.$2);

  /// Editor / inspect preview arrow without resolving full world context.
  static MicroFacing previewFacing({
    required MicroFacing propFacing,
    required SeatOrientationPolicy policy,
  }) {
    // Preview: auto shows as fixed until live targets exist.
    if (policy == SeatOrientationPolicy.auto) return propFacing;
    return propFacing;
  }
}
