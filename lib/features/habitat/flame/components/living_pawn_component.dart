import 'dart:math' as math;
import 'dart:ui';

import 'package:flame/components.dart';

import '../habitat_game.dart';
import '../habitat_map.dart';
import '../habitat_pawn_draw.dart';
import '../habitat_sprites.dart';
import '../habitat_tint.dart';
import 'pawn_job_controller.dart';

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
  })  : appearance = appearance ?? PawnAppearance(),
        cellX = startCell.$1,
        cellY = startCell.$2 {
    jobs = PawnJobController(pawn: this, map: map, rng: math.Random());
  }

  HabitatMap map;
  final double tileSize;
  final HabitatSprites sprites;

  /// Roster id (V9 multi-pawn).
  final String memberId;
  String displayName;
  final PawnAppearance appearance;

  int cellX;
  int cellY;
  HabitatFacing facing = HabitatFacing.south;
  bool selected = false;

  /// Drafted for click-to-order (enter via hold on pawn; visual ring).
  bool drafted = false;

  late final PawnJobController jobs;
  bool _ready = false;

  Vector2? _slideFrom;
  Vector2? _slideTo;
  double _slideT = 1;
  double _walkBob = 0;
  static const double _walkSpeedTilesPerSec = 2.6;

  bool get isMoving => _slideT < 1;

  double get walkBob => _walkBob;

  /// Lateral offset during clean pose (V9.9).
  double poseOffsetX = 0;

  /// Shared square mesh size in world pixels (RW: one drawSize for all layers).
  double get drawPx => tileSize * HabitatPawnDraw.mapTiles;

  /// World Y near the top of the mesh (bubbles) — includes head offset.
  double get visualTop =>
      position.y -
      drawPx * 0.55 -
      HabitatPawnDraw.headOffsetTiles(appearance.bodyType) * tileSize -
      _walkBob;

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
    _slideFrom = null;
    _slideTo = null;
    _walkBob = 0;
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
    facing = facingFromDelta(dx, dy);
    _slideFrom = position.clone();
    _slideTo = Vector2(
      nx * tileSize + tileSize / 2,
      ny * tileSize + tileSize / 2,
    );
    _slideT = 0;
    cellX = nx;
    cellY = ny;
    // Sparse traffic dirt — most steps leave no mark.
    if (jobs.wander.rng.nextDouble() < HabitatMap.trafficFilthChance) {
      map.addTrafficFilth(nx, ny);
    }
    return true;
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (_slideT < 1 && _slideFrom != null && _slideTo != null) {
      _slideT = (_slideT + dt * _walkSpeedTilesPerSec).clamp(0.0, 1.0);
      position = _slideFrom! + (_slideTo! - _slideFrom!) * _slideT;
      _walkBob = math.sin(_slideT * math.pi) * tileSize * 0.08;
      if (_slideT >= 1) {
        _snapToCell();
      }
    } else {
      _walkBob = 0;
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

    // One square for every layer — same as RimWorld Graphic_Multi mesh.
    final draw = drawPx;
    final squash = isMoving ? 1.0 - (_walkBob / tileSize) * 0.2 : 1.0;
    final drawH = draw * squash;

    canvas.save();
    canvas.translate(poseOffsetX, 0);
    if (facing.flipX) {
      canvas.translate(size.x / 2, 0);
      canvas.scale(-1, 1);
      canvas.translate(-size.x / 2, 0);
    }

    // Body/apparel at cell root; head stack lifted by BodyTypeDef.headOffset.
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
    canvas.restore();

    if (drafted || selected) {
      final center = Offset(size.x / 2, size.y / 2 + tileSize * 0.22);
      final r = tileSize * 0.42;
      if (drafted) {
        // RimWorld-ish draft: cyan outer + bright inner.
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
