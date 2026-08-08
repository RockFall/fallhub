// ignore_for_file: avoid_print
import 'dart:io';
import 'dart:ui' as ui;

import 'package:fallhub/features/habitat/flame/habitat_game.dart';
import 'package:fallhub/features/habitat/flame/habitat_map.dart';
import 'package:fallhub/features/habitat/flame/habitat_pawn_draw.dart';
import 'package:fallhub/features/habitat/flame/habitat_tint.dart';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:living_habitat_assets/living_habitat_assets.dart';

/// Zoomed pawn lineup for proportion review.
/// Usage: flutter test tool/capture_pawn_compare.dart
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('capture zoomed pawn lineup', () async {
    const tile = 96.0;
    final game = HabitatGame(tileSize: tile);
    await game.onLoad();

    final samples = <(String, PawnAppearance)>[
      (
        'male',
        PawnAppearance(
          name: 'Male',
          bodyType: 'male',
          hairStyle: 'mop',
          apparelTop: 'shirt_button',
          skin: PawnPalettes.skinMedium,
          hair: PawnPalettes.hairBrown,
          apparelTint: StuffPalettes.clothBlue,
        ),
      ),
      (
        'female',
        PawnAppearance(
          name: 'Female',
          bodyType: 'female',
          hairStyle: 'bob',
          apparelTop: 'shirt_button',
          skin: PawnPalettes.skinLight,
          hair: PawnPalettes.hairBrown,
          apparelTint: StuffPalettes.clothBlue,
        ),
      ),
      (
        'thin',
        PawnAppearance(
          name: 'Thin',
          bodyType: 'thin',
          hairStyle: 'pigtails',
          apparelTop: 'shirt_button',
          skin: PawnPalettes.skinPale,
          hair: PawnPalettes.hairGray,
          apparelTint: StuffPalettes.clothBlue,
        ),
      ),
      (
        'hulk',
        PawnAppearance(
          name: 'Hulk',
          bodyType: 'hulk',
          hairStyle: 'wavy',
          beardStyle: 'full',
          apparelTop: 'shirt_button',
          skin: PawnPalettes.skinTan,
          hair: PawnPalettes.hairBrown,
          apparelTint: StuffPalettes.clothBlue,
        ),
      ),
      (
        'fat',
        PawnAppearance(
          name: 'Fat',
          bodyType: 'fat',
          hairStyle: 'afro',
          apparelTop: 'shirt_button',
          skin: PawnPalettes.skinMedium,
          hair: PawnPalettes.hairBrown,
          apparelTint: StuffPalettes.clothBlue,
        ),
      ),
    ];

    final pawn = game.pawn!;
    final draw = tile * HabitatPawnDraw.mapTiles;
    const pad = 24.0;
    final cellW = draw + pad;
    final cellH = draw + 48;
    final totalW = cellW * samples.length;
    final totalH = cellH;

    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    canvas.drawRect(
      Rect.fromLTWH(0, 0, totalW, totalH),
      Paint()..color = const Color(0xFF6B6B6B),
    );

    // Grid like RW floor
    final grid = Paint()
      ..color = const Color(0x33000000)
      ..style = PaintingStyle.stroke;
    for (var x = 0.0; x < totalW; x += tile) {
      canvas.drawLine(Offset(x, 0), Offset(x, totalH), grid);
    }
    for (var y = 0.0; y < totalH; y += tile) {
      canvas.drawLine(Offset(0, y), Offset(totalW, y), grid);
    }

    for (var i = 0; i < samples.length; i++) {
      final look = samples[i].$2;
      pawn.appearance.copyFrom(look);
      pawn.displayName = look.name;
      pawn.facing = HabitatFacing.south;
      pawn.selected = false;
      pawn.size = Vector2(tile, tile);

      final cx = i * cellW + cellW / 2;
      final cy = totalH * 0.55;
      canvas.save();
      canvas.translate(cx - pawn.size.x / 2, cy - pawn.size.y / 2);
      pawn.render(canvas);
      canvas.restore();

      final tp = TextPainter(
        text: TextSpan(
          text: look.name,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(cx - tp.width / 2, cy + draw * 0.45));

      // 1×1 cell outline under feet for scale reference
      canvas.drawRect(
        Rect.fromCenter(
          center: Offset(cx, cy + tile * 0.15),
          width: tile,
          height: tile,
        ),
        Paint()
          ..color = const Color(0x55FFFF00)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1,
      );
    }

    final picture = recorder.endRecording();
    final image = await picture.toImage(totalW.toInt(), totalH.toInt());
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    expect(bytes, isNotNull);

    final out = File('docs/produto/assets/generated/habitat/pawn_compare.png');
    out.parent.createSync(recursive: true);
    await out.writeAsBytes(bytes!.buffer.asUint8List());
    print('Wrote ${out.path} (${out.lengthSync()} bytes)');
    print('mapTiles=${HabitatPawnDraw.mapTiles} drawPx=$draw tile=$tile');
    game.dispose();
  });
}
