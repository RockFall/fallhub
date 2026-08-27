import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/painting.dart';
import 'package:flame/components.dart';

import '../habitat_door.dart';
import '../habitat_map.dart';
import '../habitat_prop_catalog.dart';
import '../habitat_sprites.dart';
import '../habitat_tint.dart';
import '../furniture/furniture.dart';

/// Draws floor tiles, procedural walls/door, furniture, and prop selection.
class GridMapComponent extends PositionComponent {
  GridMapComponent({
    required this.map,
    required this.tileSize,
    required this.sprites,
  });

  HabitatMap map;
  final double tileSize;
  final HabitatSprites sprites;
  HabitatProp? selectedProp;

  /// Editor ghost (place / move preview).
  HabitatProp? ghostProp;
  bool ghostValid = true;
  bool _ready = false;

  @override
  Future<void> onLoad() async {
    if (_ready) return;
    _syncSize();
    _ready = true;
  }

  void rebindMap(HabitatMap next) {
    map = next;
    selectedProp = null;
    ghostProp = null;
    _syncSize();
  }

  void _syncSize() {
    size = Vector2(map.width * tileSize, map.height * tileSize);
  }

  Sprite _floorSprite(HabitatFloor f) => switch (f) {
        HabitatFloor.wood => sprites.wood,
        HabitatFloor.carpet => sprites.carpet,
        HabitatFloor.concrete => sprites.concrete,
      };

  bool _isWallCell(int x, int y) => map.isWallCell(x, y);

  void _drawWallCell(Canvas canvas, int x, int y) {
    final rect = Rect.fromLTWH(x * tileSize, y * tileSize, tileSize, tileSize);
    final base = Paint()..color = const Color(0xFF2C3138);
    final face = Paint()..color = const Color(0xFF4A525C);
    final lip = Paint()..color = const Color(0xFF6A7380);
    final mortar = Paint()
      ..color = const Color(0x33202226)
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;

    canvas.drawRect(rect, base);
    canvas.drawRect(
      Rect.fromLTWH(rect.left + 2, rect.top + 2, rect.width - 4, rect.height - 6),
      face,
    );
    canvas.drawRect(
      Rect.fromLTWH(rect.left + 2, rect.top + 2, rect.width - 4, 5),
      lip,
    );

    // Brick hatch
    final midY = rect.top + rect.height * 0.55;
    canvas.drawLine(Offset(rect.left + 4, midY), Offset(rect.right - 4, midY), mortar);
    canvas.drawLine(
      Offset(rect.left + rect.width * 0.5, rect.top + 8),
      Offset(rect.left + rect.width * 0.5, midY),
      mortar,
    );
    canvas.drawLine(
      Offset(rect.left + 6, midY),
      Offset(rect.left + 6, rect.bottom - 6),
      mortar,
    );
    canvas.drawLine(
      Offset(rect.right - 6, midY),
      Offset(rect.right - 6, rect.bottom - 6),
      mortar,
    );
  }

  void _drawDoor(Canvas canvas) {
    final door = map.door;
    final (x, y) = door.cell;
    final pos = Vector2(x * tileSize, y * tileSize);
    final cell = Vector2(tileSize, tileSize);

    // Floor under the doorway cell.
    _floorSprite(map.floorAt(x, y)).render(
      canvas,
      position: pos,
      size: cell,
    );

    final doorSprite = sprites.door;
    if (doorSprite != null) {
      _drawDualLeafDoor(canvas, door, doorSprite);
      return;
    }

    final rect = Rect.fromLTWH(x * tileSize, y * tileSize, tileSize, tileSize);
    final frame = Paint()..color = const Color(0xFF5C4030);
    final panel = Paint()..color = const Color(0xFF8B6914);
    final panelInner = Paint()..color = const Color(0xFF9A7618);
    final edge = Paint()
      ..color = const Color(0xFF2A1C12)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    // Full-tile door leaf (was inset to ~64% width — looked squeezed).
    const inset = 2.0;
    final doorRect = Rect.fromLTWH(
      rect.left + inset,
      rect.top + inset,
      rect.width - inset * 2,
      rect.height - inset * 2,
    );

    // Thin wall frame on the outer edge of the cell.
    canvas.drawRect(rect, frame);
    canvas.drawRect(doorRect, panel);

    // Panel detail — fills most of the leaf, still full-tile presence.
    final inner = doorRect.deflate(tileSize * 0.08);
    canvas.drawRect(inner, panelInner);
    canvas.drawRect(doorRect, edge);
    canvas.drawRect(inner, edge);

    // Mid rail + knob (scale with tile so it stays readable).
    final midY = doorRect.center.dy;
    canvas.drawLine(
      Offset(inner.left, midY),
      Offset(inner.right, midY),
      edge,
    );
    final knobR = (tileSize * 0.06).clamp(2.5, 5.0);
    canvas.drawCircle(
      Offset(inner.right - tileSize * 0.12, midY),
      knobR,
      Paint()..color = const Color(0xFFD4AF37),
    );
  }

  /// RimWorld `DrawMovers`: same sprite twice, second flipped; offset by open %.
  void _drawDualLeafDoor(Canvas canvas, HabitatDoor door, Sprite sprite) {
    final (x, y) = door.cell;
    final cx = (x + 0.5) * tileSize;
    final cy = (y + 0.5) * tileSize;
    final offset =
        tileSize * HabitatDoor.maxLeafOffsetTiles * door.openProgress;
    final horizontal = door.slideAxis == HabitatDoorSlideAxis.horizontal;

    void drawLeaf({
      required double worldX,
      required double worldY,
      required bool flipX,
    }) {
      canvas.save();
      canvas.translate(worldX, worldY);
      if (!horizontal) {
        // Door in a N–S wall: rotate so leaves slide along Y.
        canvas.rotate(math.pi / 2);
      }
      if (flipX) {
        canvas.scale(-1, 1);
      }
      sprite.render(
        canvas,
        position: Vector2(-tileSize / 2, -tileSize / 2),
        size: Vector2(tileSize, tileSize),
      );
      canvas.restore();
    }

    if (horizontal) {
      drawLeaf(worldX: cx - offset, worldY: cy, flipX: false);
      drawLeaf(worldX: cx + offset, worldY: cy, flipX: true);
    } else {
      drawLeaf(worldX: cx, worldY: cy - offset, flipX: false);
      drawLeaf(worldX: cx, worldY: cy + offset, flipX: true);
    }
  }

  void _drawPropOutline(Canvas canvas, HabitatProp prop) {
    final (ox, oy) = prop.origin;
    final (fw, fh) = prop.size;
    final rect = Rect.fromLTWH(
      ox * tileSize,
      oy * tileSize,
      fw * tileSize,
      fh * tileSize,
    );
    canvas.drawRect(
      rect.inflate(1),
      Paint()..color = const Color(0x33FFEE55),
    );
    canvas.drawRect(
      rect.inflate(1),
      Paint()
        ..color = const Color(0xFFFFEE55)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
  }

  @override
  void render(Canvas canvas) {
    final cell = Vector2(tileSize, tileSize);
    final line = Paint()
      ..color = const Color(0x22000000)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    for (var y = 0; y < map.height; y++) {
      for (var x = 0; x < map.width; x++) {
        if (_isWallCell(x, y)) continue;
        final pos = Vector2(x * tileSize, y * tileSize);
        _floorSprite(map.floorAt(x, y)).render(canvas, position: pos, size: cell);
        canvas.drawRect(Rect.fromLTWH(pos.x, pos.y, tileSize, tileSize), line);
      }
    }

    _drawFilth(canvas);

    for (var y = 0; y < map.height; y++) {
      for (var x = 0; x < map.width; x++) {
        if (_isWallCell(x, y)) _drawWallCell(canvas, x, y);
      }
    }
    _drawDoor(canvas);

    for (final p in map.props) {
      _drawProp(canvas, p, alpha: 1);
    }

    final ghost = ghostProp;
    if (ghost != null) {
      _drawProp(canvas, ghost, alpha: ghostValid ? 0.55 : 0.28);
      canvas.drawRect(
        Rect.fromLTWH(
          ghost.origin.$1 * tileSize,
          ghost.origin.$2 * tileSize,
          ghost.size.$1 * tileSize,
          ghost.size.$2 * tileSize,
        ),
        Paint()
          ..color = ghostValid
              ? const Color(0x8844FF88)
              : const Color(0x88FF4444)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2,
      );
    }

    final selected = selectedProp;
    if (selected != null) {
      _drawPropOutline(canvas, selected);
      _drawQualityBadge(canvas, selected);
    }
  }

  void _drawFilth(Canvas canvas) {
    final rng = math.Random(7);
    for (var y = 0; y < map.height; y++) {
      for (var x = 0; x < map.width; x++) {
        if (map.isWallCell(x, y)) continue;
        final f = map.filthAt(x, y);
        if (f < 0.04) continue;
        final rect = Rect.fromLTWH(x * tileSize, y * tileSize, tileSize, tileSize);
        final alpha = (f * 0.72).clamp(0.0, 0.65);
        final cx = rect.center.dx + (rng.nextDouble() - 0.5) * tileSize * 0.2;
        final cy = rect.center.dy + (rng.nextDouble() - 0.5) * tileSize * 0.15;
        canvas.drawOval(
          Rect.fromCenter(
            center: Offset(cx, cy),
            width: tileSize * (0.35 + f * 0.25),
            height: tileSize * (0.22 + f * 0.18),
          ),
          Paint()..color = Color.fromRGBO(92, 68, 42, alpha),
        );
        if (f > 0.25) {
          canvas.drawOval(
            Rect.fromCenter(
              center: Offset(cx + 4, cy + 3),
              width: tileSize * 0.18,
              height: tileSize * 0.12,
            ),
            Paint()..color = Color.fromRGBO(72, 52, 32, alpha * 0.7),
          );
        }
      }
    }
  }

  void _drawQualityBadge(Canvas canvas, HabitatProp prop) {
    if (prop.quality == HabitatPropQuality.normal) return;
    final (ox, oy) = prop.origin;
    final badgeX = (ox + prop.size.$1) * tileSize - 10;
    final badgeY = oy * tileSize + 2;
    final tp = TextPainter(
      text: TextSpan(
        text: prop.quality.badge,
        style: TextStyle(
          color: const Color(0xFFE8E6E3),
          fontSize: 9,
          fontWeight: FontWeight.w700,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(badgeX - 2, badgeY - 1, tp.width + 4, tp.height + 2),
        const Radius.circular(2),
      ),
      Paint()..color = const Color(0xCC2A2E34),
    );
    tp.paint(canvas, Offset(badgeX, badgeY));
  }

  void _drawProp(Canvas canvas, HabitatProp p, {required double alpha}) {
    final (ox, oy) = p.origin;
    final (fw, fh) = p.size;
    final footW = fw * tileSize;
    final footH = fh * tileSize;

    if (HabitatPropKinds.isProcedural(p.kind)) {
      final (vw, vh) = p.visualSize;
      final drawW = vw * tileSize;
      final drawH = vh * tileSize;
      final px = ox * tileSize + (footW - drawW) / 2;
      final py = switch (p.drawAlign) {
        HabitatPropAlign.center => oy * tileSize + (footH - drawH) / 2,
        HabitatPropAlign.south => oy * tileSize + (footH - drawH),
      };
      _drawProceduralDecor(
        canvas,
        p,
        Rect.fromLTWH(px, py, drawW, drawH),
        alpha: alpha,
      );
      return;
    }

    final sprite = sprites.propSprite(p.kind, p.facing);
    if (sprite == null) return;

    // Native px→tile scale (default 64ppt). Do NOT fit-cover the footprint —
    // that upscales tiny lamps/plants to a full cell (big + blurry).
    final srcW = sprite.srcSize.x;
    final srcH = sprite.srcSize.y;
    if (srcW <= 0 || srcH <= 0) return;
    final ppt = FurnitureRegistry.tryGet(p.kind)?.pixelsPerTile ??
        kDefaultFurniturePixelsPerTile;
    final (drawW, drawH) = furnitureDrawSizePx(
      srcW: srcW,
      srcH: srcH,
      tileSize: tileSize,
      footW: footW,
      footH: footH,
      pixelsPerTile: ppt,
    );
    final px = ox * tileSize + (footW - drawW) / 2;
    final py = switch (p.drawAlign) {
      HabitatPropAlign.center => oy * tileSize + (footH - drawH) / 2,
      HabitatPropAlign.south => oy * tileSize + footH - drawH,
    };

    final tint = p.tint.withValues(alpha: p.tint.a * alpha);

    canvas.save();
    if (p.facing.flipX) {
      canvas.translate(px + drawW / 2, py);
      canvas.scale(-1, 1);
      canvas.translate(-drawW / 2, 0);
      renderTinted(
        sprite,
        canvas,
        position: Vector2.zero(),
        size: Vector2(drawW, drawH),
        tint: tint,
      );
    } else {
      renderTinted(
        sprite,
        canvas,
        position: Vector2(px, py),
        size: Vector2(drawW, drawH),
        tint: tint,
      );
    }
    canvas.restore();

    // Soft “on” cue for powered lights (glow disc under the fixture).
    if (FurnitureInteractions.isLight(p.kind) && p.poweredOn) {
      final glow = Paint()
        ..color = const Color(0x33FFE8A0).withValues(alpha: 0.22 * alpha);
      canvas.drawCircle(
        Offset(px + drawW / 2, py + drawH * 0.35),
        math.max(drawW, drawH) * 0.45,
        glow,
      );
    }
  }

  void _drawProceduralDecor(
    Canvas canvas,
    HabitatProp p,
    Rect box, {
    required double alpha,
  }) {
    final tint = p.tint.withValues(alpha: p.tint.a * alpha);
    final dark = Color.lerp(tint, const Color(0xFF101010), 0.35)!
        .withValues(alpha: tint.a);
    switch (p.kind) {
      case HabitatPropKinds.plant:
        // Pot + foliage.
        final pot = Rect.fromLTWH(
          box.left + box.width * 0.28,
          box.top + box.height * 0.55,
          box.width * 0.44,
          box.height * 0.4,
        );
        canvas.drawRRect(
          RRect.fromRectAndRadius(pot, const Radius.circular(2)),
          Paint()..color = dark,
        );
        canvas.drawCircle(
          Offset(box.center.dx, box.top + box.height * 0.38),
          box.width * 0.32,
          Paint()..color = tint,
        );
        canvas.drawCircle(
          Offset(box.center.dx - box.width * 0.18, box.top + box.height * 0.48),
          box.width * 0.2,
          Paint()..color = tint.withValues(alpha: tint.a * 0.85),
        );
        canvas.drawCircle(
          Offset(box.center.dx + box.width * 0.16, box.top + box.height * 0.5),
          box.width * 0.18,
          Paint()..color = tint.withValues(alpha: tint.a * 0.85),
        );
      case HabitatPropKinds.painting:
        final frame = box.deflate(box.width * 0.08);
        canvas.drawRect(frame, Paint()..color = dark);
        canvas.drawRect(frame.deflate(3), Paint()..color = tint);
        canvas.drawLine(
          Offset(frame.left + 6, frame.center.dy),
          Offset(frame.right - 6, frame.center.dy - 4),
          Paint()
            ..color = const Color(0x3DFFFFFF)
            ..strokeWidth = 2,
        );
      case HabitatPropKinds.rug:
        canvas.drawRRect(
          RRect.fromRectAndRadius(box.deflate(2), const Radius.circular(3)),
          Paint()..color = tint,
        );
        canvas.drawRRect(
          RRect.fromRectAndRadius(box.deflate(6), const Radius.circular(2)),
          Paint()
            ..color = dark
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2,
        );
      case HabitatPropKinds.vase:
        final body = Path()
          ..moveTo(box.center.dx - box.width * 0.18, box.bottom - 2)
          ..lineTo(box.center.dx - box.width * 0.28, box.top + box.height * 0.35)
          ..lineTo(box.center.dx - box.width * 0.14, box.top + box.height * 0.2)
          ..lineTo(box.center.dx + box.width * 0.14, box.top + box.height * 0.2)
          ..lineTo(box.center.dx + box.width * 0.28, box.top + box.height * 0.35)
          ..lineTo(box.center.dx + box.width * 0.18, box.bottom - 2)
          ..close();
        canvas.drawPath(body, Paint()..color = tint);
        canvas.drawCircle(
          Offset(box.center.dx, box.top + box.height * 0.12),
          box.width * 0.1,
          Paint()..color = StuffPalettes.clothGreen.withValues(alpha: alpha),
        );
      case HabitatPropKinds.boardgame:
        canvas.drawRRect(
          RRect.fromRectAndRadius(box.deflate(3), const Radius.circular(2)),
          Paint()..color = tint,
        );
        canvas.drawCircle(
          Offset(box.center.dx - box.width * 0.2, box.center.dy),
          box.width * 0.08,
          Paint()..color = dark,
        );
        canvas.drawCircle(
          Offset(box.center.dx + box.width * 0.15, box.center.dy + 2),
          box.width * 0.06,
          Paint()..color = dark.withValues(alpha: dark.a * 0.8),
        );
      case HabitatPropKinds.tv:
        final screen = Rect.fromLTWH(
          box.left + box.width * 0.1,
          box.top + box.height * 0.12,
          box.width * 0.8,
          box.height * 0.55,
        );
        canvas.drawRect(screen, Paint()..color = dark);
        canvas.drawRect(screen.deflate(2), Paint()..color = tint);
        canvas.drawRect(
          Rect.fromLTWH(
            box.center.dx - box.width * 0.12,
            box.bottom - box.height * 0.18,
            box.width * 0.24,
            box.height * 0.1,
          ),
          Paint()..color = dark,
        );
      case HabitatPropKinds.instrument:
        canvas.drawOval(
          Rect.fromCenter(
            center: Offset(box.center.dx, box.top + box.height * 0.55),
            width: box.width * 0.7,
            height: box.height * 0.45,
          ),
          Paint()..color = tint,
        );
        canvas.drawRect(
          Rect.fromLTWH(
            box.center.dx - box.width * 0.06,
            box.top + box.height * 0.08,
            box.width * 0.12,
            box.height * 0.55,
          ),
          Paint()..color = dark,
        );
      case HabitatPropKinds.heater:
        canvas.drawRRect(
          RRect.fromRectAndRadius(box.deflate(4), const Radius.circular(3)),
          Paint()..color = tint,
        );
        for (var i = 0; i < 3; i++) {
          canvas.drawLine(
            Offset(box.left + 6 + i * 8, box.top + 8),
            Offset(box.left + 6 + i * 8, box.bottom - 6),
            Paint()
              ..color = dark
              ..strokeWidth = 2,
          );
        }
      case HabitatPropKinds.cooler:
        canvas.drawRRect(
          RRect.fromRectAndRadius(box.deflate(4), const Radius.circular(3)),
          Paint()..color = tint,
        );
        canvas.drawCircle(
          Offset(box.center.dx, box.center.dy),
          box.width * 0.22,
          Paint()
            ..color = const Color(0xAAE8F4FF)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2,
        );
      case HabitatPropKinds.gatheringSpot:
        canvas.drawCircle(
          box.center,
          box.width * 0.28,
          Paint()
            ..color = tint.withValues(alpha: tint.a * 0.55)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2.5,
        );
        canvas.drawCircle(
          box.center,
          box.width * 0.12,
          Paint()..color = tint,
        );
        canvas.drawLine(
          Offset(box.left + 4, box.bottom - 4),
          Offset(box.right - 4, box.top + 4),
          Paint()
            ..color = tint.withValues(alpha: tint.a * 0.7)
            ..strokeWidth = 1.5,
        );
      default:
        canvas.drawRect(box, Paint()..color = tint);
    }
  }
}
