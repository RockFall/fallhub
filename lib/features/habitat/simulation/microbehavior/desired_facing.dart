import 'attention_target.dart';
import 'micro_facing.dart';

export 'micro_facing.dart';

/// Sources considered when settling facing after arrival (MD 10 R1).
enum FacingSettleSource {
  affordanceTarget,
  partnerOrGroup,
  seatFunctional,
  roomInterest,
  attention,
  lastFacing,
}

/// Result of [DesiredFacingResolver.resolve].
class DesiredFacingResult {
  const DesiredFacingResult({
    required this.facing,
    required this.source,
    required this.settleDelaySeconds,
  });

  final MicroFacing facing;
  final FacingSettleSource source;

  /// 80–220 ms settle before applying (R1).
  final double settleDelaySeconds;
}

/// Context for facing priority — pure data.
class FacingSettleContext {
  const FacingSettleContext({
    required this.pawnCell,
    required this.lastFacing,
    this.affordanceTargetCell,
    this.partnerCell,
    this.seatFacing,
    this.roomInterestCell,
    this.attention,
    this.settleDelayUnit = 0.5,
    this.now = 0,
  });

  final (int, int) pawnCell;
  final MicroFacing lastFacing;
  final (int, int)? affordanceTargetCell;
  final (int, int)? partnerCell;

  /// Functional seat / bed orientation (chair faces TV, etc.).
  final MicroFacing? seatFacing;

  /// Soft room POI (window, fireplace, table center).
  final (int, int)? roomInterestCell;

  final AttentionTarget? attention;

  /// Deterministic 0..1 for settle delay lerp.
  final double settleDelayUnit;

  /// Used to honour attention expiry.
  final double now;
}

/// Priority: affordance → partner → seat → room → attention → last (R1).
abstract final class DesiredFacingResolver {
  static const double settleMin = 0.08;
  static const double settleMax = 0.22;

  static DesiredFacingResult resolve(FacingSettleContext ctx) {
    final delay = settleMin +
        (settleMax - settleMin) * ctx.settleDelayUnit.clamp(0.0, 1.0);

    MicroFacing? fromCell((int, int)? target) {
      if (target == null) return null;
      final dx = target.$1 - ctx.pawnCell.$1;
      final dy = target.$2 - ctx.pawnCell.$2;
      if (dx == 0 && dy == 0) return null;
      return microFacingFromDelta(dx, dy);
    }

    final affordance = fromCell(ctx.affordanceTargetCell);
    if (affordance != null) {
      return DesiredFacingResult(
        facing: affordance,
        source: FacingSettleSource.affordanceTarget,
        settleDelaySeconds: delay,
      );
    }

    final partner = fromCell(ctx.partnerCell);
    if (partner != null) {
      return DesiredFacingResult(
        facing: partner,
        source: FacingSettleSource.partnerOrGroup,
        settleDelaySeconds: delay,
      );
    }

    final seat = ctx.seatFacing;
    if (seat != null) {
      return DesiredFacingResult(
        facing: seat,
        source: FacingSettleSource.seatFunctional,
        settleDelaySeconds: delay,
      );
    }

    final room = fromCell(ctx.roomInterestCell);
    if (room != null) {
      return DesiredFacingResult(
        facing: room,
        source: FacingSettleSource.roomInterest,
        settleDelaySeconds: delay,
      );
    }

    final att = ctx.attention;
    if (att != null &&
        !att.isExpired(ctx.now) &&
        att.cellX != null &&
        att.cellY != null) {
      final look = fromCell((att.cellX!, att.cellY!));
      if (look != null) {
        return DesiredFacingResult(
          facing: look,
          source: FacingSettleSource.attention,
          settleDelaySeconds: delay,
        );
      }
    }

    return DesiredFacingResult(
      facing: ctx.lastFacing,
      source: FacingSettleSource.lastFacing,
      settleDelaySeconds: delay * 0.5,
    );
  }
}
