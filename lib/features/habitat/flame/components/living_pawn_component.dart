import 'dart:math' as math;
import 'dart:ui';

import 'package:flame/components.dart';

import '../../simulation/embodied/pawn_embodied_state.dart';
import '../../simulation/microbehavior/microbehavior.dart';
import '../habitat_game.dart';
import '../habitat_map.dart';
import '../habitat_pawn_draw.dart';
import '../habitat_sprites.dart';
import '../habitat_tint.dart';
import 'pawn_job_controller.dart';

MicroFacing _microFacing(HabitatFacing f) => microFacingFromHabitat(f);

/// Layered RimWorld-style pawn: body + head + hair (tinted).
///
/// Selection / draft is handled by [HabitatGame] hit-testing (hold-to-draft)
/// so taps are not double-fired by a component [TapCallbacks] mixin.
class LivingPawnComponent extends PositionComponent
    with HasGameReference<HabitatGame> {
  LivingPawnComponent({
    required this.map,
    required this.tileSize,
    required this.sprites,
    required (int, int) startCell,
    this.memberId = 'player',
    this.displayName = 'Colonista',
    PawnAppearance? appearance,
    int worldSeed = 0,
    bool reducedMotion = false,
  })  : appearance = appearance ?? PawnAppearance(),
        cellX = startCell.$1,
        cellY = startCell.$2,
        micro = PawnMicrobehavior(
          pawnId: memberId,
          worldSeed: worldSeed,
          reducedMotion: reducedMotion,
        ) {
    final rng = HabitatRng.stream(
      pawnId: memberId,
      concern: 'jobs',
      worldSeed: worldSeed,
    );
    jobs = PawnJobController(
      pawn: this,
      map: map,
      rng: rng,
      nowSeconds: () => _sessionNow,
    );
  }

  HabitatMap map;
  final double tileSize;
  final HabitatSprites sprites;

  /// Roster id (V9 multi-pawn).
  final String memberId;
  String displayName;
  final PawnAppearance appearance;

  /// Block A microbehavior bag (attention, arrival, posture, …).
  final PawnMicrobehavior micro;

  /// Debug/sim: item held in hand (drawn above head).
  String? heldLabel;

  int cellX;
  int cellY;
  HabitatFacing facing = HabitatFacing.south;

  /// Locomotor facing while moving — attention may override when idle.
  HabitatFacing locomotorFacing = HabitatFacing.south;

  bool selected = false;

  /// Drafted for click-to-order (enter via hold on pawn; visual ring).
  bool drafted = false;

  late final PawnJobController jobs;
  bool _ready = false;

  Vector2? _slideFrom;
  Vector2? _slideTo;
  double _slideT = 1;
  double _slideVisualT = 1;
  double _walkBob = 0;
  bool _slideEase = false;
  static const double _walkSpeedTilesPerSec = 2.6;

  /// Filled by HabitatGame each frame (session clock).
  double _sessionNow = 0;

  bool get isMoving => _slideT < 1;

  double get walkBob => _walkBob;

  /// Lateral offset during clean pose (V9.9) / micro-idles.
  double poseOffsetX = 0;

  /// Shared square mesh size in world pixels (RW: one drawSize for all layers).
  double get drawPx => tileSize * HabitatPawnDraw.mapTiles;

  /// World Y near the top of the mesh (bubbles) — includes head offset.
  double get visualTop =>
      position.y -
      drawPx * 0.55 -
      HabitatPawnDraw.headOffsetTiles(appearance.bodyType) * tileSize -
      _walkBob;

  void syncSessionClock(double sessionSeconds) {
    _sessionNow = sessionSeconds;
  }

  @override
  Future<void> onLoad() async {
    if (_ready) return;
    size = Vector2(tileSize, tileSize);
    anchor = Anchor.center;
    priority = 20;
    _snapToCell();
    _ready = true;
  }

  void _snapToCell() {
    position = Vector2(
      cellX * tileSize + tileSize / 2,
      cellY * tileSize + tileSize / 2,
    );
    _slideT = 1;
    _slideVisualT = 1;
    _slideFrom = null;
    _slideTo = null;
    _walkBob = 0;
    _slideEase = false;
  }

  /// Instant cell teleport (editor rebuild / map swap).
  void teleportToCell((int, int) cell) {
    cellX = cell.$1;
    cellY = cell.$2;
    _snapToCell();
  }

  /// Point pawn + jobs at another locale map (V8).
  void rebindMap(HabitatMap next) {
    map = next;
    jobs.map = next;
    jobs.wander.map = next;
    jobs.order(HabitatJobKind.wander);
  }

  bool tryStep(int dx, int dy) {
    if (isMoving) return false;
    final nx = cellX + dx;
    final ny = cellY + dy;
    if (!map.isWalkable(nx, ny)) return false;
    if (map.doorBlocksStep(nx, ny)) {
      map.door.requestOpen();
      return false;
    }
    locomotorFacing = facingFromDelta(dx, dy);
    facing = locomotorFacing;
    _slideFrom = position.clone();
    _slideTo = Vector2(
      nx * tileSize + tileSize / 2,
      ny * tileSize + tileSize / 2,
    );
    _slideT = 0;
    _slideVisualT = 0;
    // R6: ease when path is long enough and not an urgent manual hop.
    _slideEase = LocomotionEasing.shouldEase(
      pathLengthIncludingCurrentStep: math.max(1, micro.lastPathLengthHint),
      urgent: micro.urgentLocomotion,
    );
    cellX = nx;
    cellY = ny;
    if (jobs.wander.rng.nextDouble() < HabitatMap.trafficFilthChance) {
      map.addTrafficFilth(nx, ny);
    }
    return true;
  }

  /// Resolve display facing from attention when idle (R0).
  void _applyAttentionFacing() {
    if (isMoving) return;
    final att = micro.attention.current;
    if (att == null) return;
    // Don't fight arrival settle / posture facing.
    final phase = micro.arrival.state.phase;
    if (phase == ArrivalPhase.settling || phase == ArrivalPhase.anticipating) {
      return;
    }
    int? tx = att.cellX;
    int? ty = att.cellY;
    if (tx == null || ty == null) return;
    final dx = tx - cellX;
    final dy = ty - cellY;
    if (dx == 0 && dy == 0) return;
    facing = facingFromDelta(dx, dy);
  }

  /// Brief look while walking for high-salience events only (R0).
  void _applyWalkingGlance() {
    if (!isMoving) return;
    final att = micro.attention.current;
    if (att == null) return;
    if (att.reason != AttentionReason.interestingEvent &&
        att.reason != AttentionReason.passingPawn) {
      facing = locomotorFacing;
      return;
    }
    if (att.cellX == null || att.cellY == null) {
      facing = locomotorFacing;
      return;
    }
    // Only glance during mid-slide, then restore locomotor facing feel.
    if (_slideVisualT > 0.25 && _slideVisualT < 0.75) {
      facing = facingFromDelta(att.cellX! - cellX, att.cellY! - cellY);
    } else {
      facing = locomotorFacing;
    }
  }

  @override
  void update(double dt) {
    super.update(dt);
    final speedMul = micro.locomotor.speedMultiplier;
    if (_slideT < 1 && _slideFrom != null && _slideTo != null) {
      _slideT =
          (_slideT + dt * _walkSpeedTilesPerSec * speedMul).clamp(0.0, 1.0);
      _slideVisualT = LocomotionEasing.easeProgress(
        _slideT,
        applyEnvelope: _slideEase,
      );
      position = _slideFrom! + (_slideTo! - _slideFrom!) * _slideVisualT;
      final bobAmp = micro.locomotor.bobAmpMultiplier;
      _walkBob =
          math.sin(_slideVisualT * math.pi) * tileSize * 0.08 * bobAmp;
      if (_slideT >= 1) {
        _snapToCell();
      }
      _applyWalkingGlance();
    } else {
      _walkBob = 0;
      _applyAttentionFacing();
    }

    // Micro-idles when truly idle (R3).
    final speakingImportant = (() {
      try {
        final enc = game.social.active;
        if (enc == null) return false;
        return enc.aId == memberId || enc.bId == memberId;
      } catch (_) {
        return false;
      }
    })();
    final seated = micro.posture.state.isSettledSeated ||
        jobs.kind == HabitatJobKind.sit ||
        jobs.kind == HabitatJobKind.goToTable;
    final eligible = !drafted &&
        !isMoving &&
        jobs.kind == HabitatJobKind.wander &&
        !micro.arrival.state.isBusy &&
        !micro.posture.state.isTransient;
    ConditionPresentation? presentation;
    try {
      presentation = game.embodiedRuntime.presentationFor(memberId);
    } catch (_) {
      presentation = null;
    }
    micro.microIdle.tick(
      now: _sessionNow,
      eligible: eligible,
      seated: seated,
      speakingImportant: speakingImportant,
      profile: micro.profile,
      idleDurationMultiplier: presentation?.idleDurationMultiplier ?? 1,
      preferredIdlePoseTag: presentation?.idlePoseTag,
    );
    if (micro.microIdle.isPlaying && jobs.kind == HabitatJobKind.wander) {
      poseOffsetX = micro.microIdlePoseOffsetX(_sessionNow, tileSize);
      final idle = micro.microIdle.active;
      if (idle != null && idle.presentation.affectsFacing && !isMoving) {
        // Brief left/right glance without changing locomotor memory.
        final bias = idle.facingBiasSign;
        facing = bias < 0
            ? HabitatFacing.west
            : bias > 0
                ? HabitatFacing.east
                : facing;
      }
    } else if (jobs.kind == HabitatJobKind.wander && !isMoving) {
      // Decay residual micro-idle offset.
      poseOffsetX *= 0.85;
      if (poseOffsetX.abs() < 0.15) poseOffsetX = 0;
    }

    // Brief glance at nearby moving pawns (R0 passingPawn) — no path change.
    if (!isMoving &&
        jobs.kind == HabitatJobKind.wander &&
        micro.attention.current == null) {
      try {
        for (final other in game.pawns) {
          if (identical(other, this) || !other.isMoving) continue;
          final dist = (other.cellX - cellX).abs() + (other.cellY - cellY).abs();
          if (dist > 0 && dist <= 3) {
            micro.attention.lookAt(
              reason: AttentionReason.passingPawn,
              now: _sessionNow,
              entityId: other.memberId,
              cellX: other.cellX,
              cellY: other.cellY,
            );
            break;
          }
        }
      } catch (_) {
        // Game not attached yet.
      }
    }

    jobs.update(dt);
  }

  @override
  void render(Canvas canvas) {
    final key = facing.spriteKey;
    final body = sprites.bodySprite(appearance.bodyType, key);
    final head = sprites.headSprite(appearance.bodyType, key);
    final hair = sprites.hairFor(appearance.hairStyle)[key];
    if (body == null || head == null || hair == null) return;

    final apparel = sprites.apparelSprite(
      appearance.apparelTop,
      appearance.bodyType,
      key,
    );
    final beard = sprites.beardSprite(appearance.beardStyle, key);
    final hat = sprites.hatSprite(appearance.hat, key);

    final draw = drawPx;
    final postureSquash = micro.postureSquash(_sessionNow);
    final squash =
        (isMoving ? 1.0 - (_walkBob / tileSize) * 0.2 : 1.0) * postureSquash;
    final drawH = draw * squash;

    canvas.save();
    canvas.translate(poseOffsetX, 0);
    if (facing.flipX) {
      canvas.translate(size.x / 2, 0);
      canvas.scale(-1, 1);
      canvas.translate(-size.x / 2, 0);
    }

    final origin = Vector2(
      (size.x - draw) / 2,
      (size.y - drawH) / 2 - tileSize * 0.12 - _walkBob,
    );
    final s = Vector2(draw, drawH);
    final headOff = HabitatPawnDraw.headPixelOffset(
      bodyType: appearance.bodyType,
      facing: key,
      tileOrSize: tileSize,
    );
    final headOrigin = Vector2(origin.x + headOff.dx, origin.y + headOff.dy);

    renderTinted(body, canvas, position: origin, size: s, tint: appearance.skin);
    if (apparel != null) {
      renderTinted(
        apparel,
        canvas,
        position: origin,
        size: s,
        tint: appearance.apparelTint,
      );
    }
    renderTinted(head, canvas, position: headOrigin, size: s, tint: appearance.skin);
    if (beard != null) {
      renderTinted(
        beard,
        canvas,
        position: headOrigin,
        size: s,
        tint: appearance.hair,
      );
    }
    renderTinted(hair, canvas, position: headOrigin, size: s, tint: appearance.hair);
    if (hat != null) {
      renderTinted(
        hat,
        canvas,
        position: headOrigin,
        size: s,
        tint: appearance.apparelTint,
      );
    }
    final held = heldLabel;
    if (held != null && held.isNotEmpty) {
      final anchor = HeldItemAnchorProfile.resolve(
        facing: _microFacing(facing),
      );
      final book = RRect.fromRectAndRadius(
        Rect.fromLTWH(
          size.x * 0.5 + anchor.dxTiles * tileSize - draw * 0.14,
          origin.y + drawH * 0.35 + anchor.dyTiles * tileSize,
          draw * 0.28,
          draw * 0.22,
        ),
        const Radius.circular(2),
      );
      canvas.drawRRect(book, Paint()..color = const Color(0xFF5D4037));
      canvas.drawRRect(
        book.deflate(1.5),
        Paint()..color = const Color(0xFFE8D5A3),
      );
    }
    canvas.restore();

    if (drafted || selected) {
      final center = Offset(size.x / 2, size.y / 2 + tileSize * 0.22);
      final r = tileSize * 0.42;
      if (drafted) {
        canvas.drawCircle(
          center,
          r,
          Paint()
            ..color = const Color(0xFF3DB8A8)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2.5,
        );
        canvas.drawCircle(
          center,
          r * 0.72,
          Paint()
            ..color = const Color(0x66FFFFFF)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.2,
        );
      } else {
        canvas.drawCircle(
          center,
          r * 0.9,
          Paint()
            ..color = const Color(0xFFFFEE55)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2,
        );
      }
    }
  }

  /// Full mesh hit — interaction with the map still uses [cellX]/[cellY].
  bool containsWorldPoint(Vector2 world) {
    final half = drawPx * 0.52;
    return (world.x - position.x).abs() <= half &&
        (world.y - position.y).abs() <= half;
  }
}
