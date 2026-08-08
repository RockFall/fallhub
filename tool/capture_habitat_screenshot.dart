// ignore_for_file: avoid_print
import 'dart:io';
import 'dart:ui' as ui;

import 'package:fallhub/features/habitat/application/colony_roster.dart';
import 'package:fallhub/features/habitat/flame/habitat_bubbles.dart';
import 'package:fallhub/features/habitat/flame/habitat_editor.dart';
import 'package:fallhub/features/habitat/flame/habitat_game.dart';
import 'package:fallhub/features/habitat/flame/habitat_locations.dart';
import 'package:fallhub/features/habitat/flame/habitat_map.dart';
import 'package:fallhub/features/habitat/flame/habitat_prop_catalog.dart';
import 'package:fallhub/features/habitat/flame/habitat_room_stats.dart';
import 'package:fallhub/features/habitat/flame/habitat_tint.dart';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Usage: flutter test tool/capture_habitat_screenshot.dart
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('capture distinct habitat screenshots', () async {
    final outDir = Directory('docs/produto/assets/generated/habitat');
    outDir.createSync(recursive: true);

    Future<List<int>> captureScene(
      HabitatGame game, {
      void Function(Canvas canvas, double mapW, double mapH)? decorate,
      int extraWidth = 0,
    }) async {
      final mapW = game.map.width * game.tileSize;
      final mapH = game.map.height * game.tileSize;
      final totalW = mapW + extraWidth;
      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder);
      canvas.drawRect(
        Rect.fromLTWH(0, 0, totalW, mapH),
        Paint()..color = const Color(0xFF15191D),
      );
      game.renderWorldTo(canvas);
      decorate?.call(canvas, mapW, mapH);
      final picture = recorder.endRecording();
      final image = await picture.toImage(totalW.toInt(), mapH.toInt());
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      expect(byteData, isNotNull);
      return byteData!.buffer.asUint8List();
    }

    // --- V0 wander: mid-walk, no selection, no bubble ---
    final v0 = HabitatGame(tileSize: 48);
    await v0.onLoad();
    final pawn0 = v0.pawn!;
    pawn0.appearance.skin = const Color(0xFFE0AC69);
    pawn0.appearance.hair = const Color(0xFF5C3A21);
    pawn0.selected = false;
    for (var i = 0; i < 40; i++) {
      pawn0.update(0.05);
    }
    final v0Bytes = await captureScene(v0);
    await File('${outDir.path}/v0_wander.png').writeAsBytes(v0Bytes);
    v0.dispose();

    // --- V4 inspect: prop selected + outline + inspect strip ---
    final v4 = HabitatGame(tileSize: 48);
    await v4.onLoad();
    final pawn4 = v4.pawn!;
    pawn4.appearance.skin = const Color(0xFFE0AC69);
    pawn4.appearance.hair = const Color(0xFF3D6FBF);
    final bed = v4.map.props.firstWhere((p) => p.id == 'bed');
    v4.selectProp(bed);
    for (var i = 0; i < 20; i++) {
      pawn4.update(0.05);
    }
    const stripW = 220.0;
    final v4Bytes = await captureScene(
      v4,
      extraWidth: stripW.toInt(),
      decorate: (canvas, mapW, mapH) {
        final strip = Rect.fromLTWH(mapW, 0, stripW, mapH);
        canvas.drawRect(strip, Paint()..color = const Color(0xFF1E242B));
        canvas.drawRect(
          strip,
          Paint()
            ..color = const Color(0xFF4A525C)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2,
        );
        final title = TextPainter(
          text: const TextSpan(
            text: 'Cama',
            style: TextStyle(
              color: Color(0xFFE8E6E3),
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          textDirection: TextDirection.ltr,
        )..layout(maxWidth: stripW - 24);
        title.paint(canvas, Offset(mapW + 12, 16));
        final body = TextPainter(
          text: const TextSpan(
            text: 'Ocupação: 2x2\nStuff: pano azul\n\n• Ir até o objeto\n• Dormir',
            style: TextStyle(color: Color(0xFFA8B0B8), fontSize: 12, height: 1.4),
          ),
          textDirection: TextDirection.ltr,
        )..layout(maxWidth: stripW - 24);
        body.paint(canvas, Offset(mapW + 12, 48));
      },
    );
    await File('${outDir.path}/v4_inspect.png').writeAsBytes(v4Bytes);
    v4.dispose();

    // --- V5 bubbles: speech bubble mid-life ---
    final v5 = HabitatGame(tileSize: 48);
    await v5.onLoad();
    final pawn5 = v5.pawn!;
    pawn5.appearance.skin = const Color(0xFFE0AC69);
    pawn5.appearance.hair = const Color(0xFF3D6FBF);
    pawn5.selected = true;
    for (var i = 0; i < 80; i++) {
      pawn5.update(0.05);
    }
    v5.pushBubble(pawn5, 'Sim?', kind: HabitatBubbleKind.speech);
    if (v5.bubbles.isNotEmpty) {
      v5.bubbles.first.age = 0.8;
    }
    final v5Bytes = await captureScene(v5);
    await File('${outDir.path}/v5_bubbles.png').writeAsBytes(v5Bytes);
    v5.dispose();

    // --- V6 cosmetics: distinct body/loadout/beard ---
    final v6 = HabitatGame(tileSize: 48);
    await v6.onLoad();
    final pawn6 = v6.pawn!;
    pawn6.appearance
      ..bodyType = 'female'
      ..hairStyle = 'pigtails'
      ..skin = const Color(0xFFF1C27D)
      ..hair = const Color(0xFF8B3A2A)
      ..applyLoadout(VisualLoadouts.outdoors)
      ..apparelTint = const Color(0xFF6B8F71);
    pawn6.selected = true;
    for (var i = 0; i < 60; i++) {
      pawn6.update(0.05);
    }
    final v6Bytes = await captureScene(v6);
    await File('${outDir.path}/v6_cosmetics.png').writeAsBytes(v6Bytes);
    v6.dispose();

    // --- V7 room edit: floors + extra prop + wall + ghost ---
    final v7 = HabitatGame(tileSize: 48);
    await v7.onLoad();
    v7.setEditMode(true);
    v7.editor.tool = HabitatEditTool.floor;
    v7.editor.paintFloor = HabitatFloor.carpet;
    for (var x = 3; x <= 6; x++) {
      for (var y = 6; y <= 8; y++) {
        v7.editor.applyTap(x, y);
      }
    }
    v7.editor.tool = HabitatEditTool.wall;
    v7.editor.applyTap(10, 5);
    v7.editor.tool = HabitatEditTool.place;
    v7.editor.placeKind = HabitatPropKinds.chair;
    v7.editor.placeTint = StuffPalettes.clothRed;
    v7.editor.applyTap(4, 8);
    v7.editor.tool = HabitatEditTool.place;
    v7.editor.placeKind = HabitatPropKinds.lamp;
    v7.setHoverCell((13, 6));
    final pawn7 = v7.pawn!;
    pawn7.selected = false;
    for (var i = 0; i < 40; i++) {
      pawn7.update(0.05);
    }
    final v7Bytes = await captureScene(v7);
    await File('${outDir.path}/v7_room_edit.png').writeAsBytes(v7Bytes);
    v7.dispose();

    // --- V8 multi-map: kitchen layout (distinct from bedroom) ---
    final v8 = HabitatGame(
      tileSize: 48,
      locationId: HabitatLocationIds.kitchen,
    );
    await v8.onLoad();
    final pawn8 = v8.pawn!;
    pawn8.appearance.skin = const Color(0xFFE0AC69);
    pawn8.appearance.hair = const Color(0xFF5C3A21);
    pawn8.selected = false;
    for (var i = 0; i < 30; i++) {
      pawn8.update(0.05);
    }
    final v8Bytes = await captureScene(v8);
    await File('${outDir.path}/v8_multi_map.png').writeAsBytes(v8Bytes);
    v8.dispose();

    // --- V9 multi-pawn: full roster on bedroom ---
    final v9 = HabitatGame(
      tileSize: 48,
      roster: ColonyRosterStore.seedDefaults(),
    );
    await v9.onLoad();
    expect(v9.pawns.length, greaterThanOrEqualTo(2));
    v9.selectPawn(v9.pawns.last);
    for (final p in v9.pawns) {
      for (var i = 0; i < 25; i++) {
        p.update(0.05);
      }
    }
    v9.pushBubble(v9.pawns.first, 'Sim?', kind: HabitatBubbleKind.speech);
    final v9Bytes = await captureScene(v9);
    await File('${outDir.path}/v9_multi_pawn.png').writeAsBytes(v9Bytes);
    v9.dispose();

    // --- V9.5 polish: dusk tint + zoomed framing ---
    final v95 = HabitatGame(
      tileSize: 48,
      roster: ColonyRosterStore.seedDefaults(),
    );
    await v95.onLoad();
    v95.presence.syncFromClock(DateTime(2026, 8, 7, 19, 0)); // entardecer
    v95.onGameResize(Vector2(960, 640));
    v95.zoomBy(0.35);
    v95.selectPawn(v95.pawns.first);
    for (final p in v95.pawns) {
      for (var i = 0; i < 20; i++) {
        p.update(0.05);
      }
    }
    final v95Bytes = await captureScene(v95);
    await File('${outDir.path}/v95_polish.png').writeAsBytes(v95Bytes);
    v95.dispose();

    // --- V9.6 draft + hold order mid-path ---
    final v96 = HabitatGame(
      tileSize: 48,
      roster: ColonyRosterStore.seedDefaults(),
    );
    await v96.onLoad();
    v96.onGameResize(Vector2(960, 640));
    final drafted = v96.pawns.first;
    v96.draftPawn(drafted);
    final walk = v96.map.walkableCells();
    final dest = walk.firstWhere(
      (c) => c != (drafted.cellX, drafted.cellY),
      orElse: () => walk.first,
    );
    v96.issueHoldOrder(cell: dest, hit: HabitatCellSelection(dest));
    for (var i = 0; i < 18; i++) {
      drafted.update(0.05);
    }
    final v96Bytes = await captureScene(v96);
    await File('${outDir.path}/v96_draft_hold.png').writeAsBytes(v96Bytes);
    v96.dispose();

    // --- V9.7 room role + meters strip overlay ---
    final v97 = HabitatGame(
      tileSize: 48,
      locationId: HabitatLocationIds.bedroom,
      roster: ColonyRosterStore.seedDefaults(),
    );
    await v97.onLoad();
    v97.refreshRoomStats();
    final stats = v97.roomStats;
    final roleName = switch (stats.role) {
      HabitatRoomRole.bedroom => 'Quarto',
      HabitatRoomRole.dining => 'Refeitório',
      HabitatRoomRole.office => 'Escritório',
      HabitatRoomRole.exterior => 'Exterior',
      HabitatRoomRole.generic => 'Cômodo',
    };
    final impressName = switch (stats.impressiveness) {
      HabitatImpressiveness.mediocre => 'Medíocre',
      HabitatImpressiveness.pleasant => 'Agradável',
      HabitatImpressiveness.nice => 'Bonito',
      HabitatImpressiveness.glorious => 'Extasiado',
    };
    final v97Bytes = await captureScene(
      v97,
      decorate: (canvas, mapW, mapH) {
        const stripH = 54.0;
        final strip = Rect.fromLTWH(12, 10, 280, stripH);
        canvas.drawRRect(
          RRect.fromRectAndRadius(strip, const Radius.circular(3)),
          Paint()..color = const Color(0xCC141416),
        );
        canvas.drawRRect(
          RRect.fromRectAndRadius(strip, const Radius.circular(3)),
          Paint()
            ..color = const Color(0x66FFFFFF)
            ..style = PaintingStyle.stroke,
        );
        final title = TextPainter(
          text: TextSpan(
            text: '$roleName  ·  $impressName',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
          textDirection: TextDirection.ltr,
        )..layout();
        title.paint(canvas, const Offset(22, 16));
        final meters = TextPainter(
          text: TextSpan(
            text:
                'Beleza ${stats.beauty}   Espaço ${stats.space}   '
                'Limpeza ${stats.cleanliness}   Riqueza ${stats.wealth}',
            style: const TextStyle(color: Color(0xFFB8C4D4), fontSize: 11),
          ),
          textDirection: TextDirection.ltr,
        )..layout();
        meters.paint(canvas, const Offset(22, 36));
      },
    );
    await File('${outDir.path}/v97_room_stats.png').writeAsBytes(v97Bytes);
    v97.dispose();

    // --- V9.8 beauty overlay + decor props ---
    final v98 = HabitatGame(tileSize: 48);
    await v98.onLoad();
    v98.onGameResize(Vector2(960, 640));
    v98.map.placeProp(
      HabitatPropCatalog.spawn(HabitatPropKinds.plant, (7, 4)),
    );
    v98.map.placeProp(
      HabitatPropCatalog.spawn(HabitatPropKinds.painting, (10, 2)),
    );
    v98.map.placeProp(
      HabitatPropCatalog.spawn(HabitatPropKinds.vase, (4, 5)),
    );
    v98.notifyMapVisualChanged(rippleAt: (7, 4));
    v98.setBeautyOverlay(true);
    for (var i = 0; i < 40; i++) {
      v98.update(0.05);
    }
    final v98Bytes = await captureScene(v98);
    await File('${outDir.path}/v98_beauty.png').writeAsBytes(v98Bytes);
    v98.dispose();

    // --- V9.9 filth + clean pose ---
    final v99 = HabitatGame(tileSize: 48);
    await v99.onLoad();
    for (var i = 0; i < 30; i++) {
      v99.map.addTrafficFilth(5 + (i % 4), 6 + (i ~/ 4), 0.08);
    }
    final v99Pawn = v99.pawn!;
    v99.draftPawn(v99Pawn);
    v99Pawn.jobs.orderCleanCell((6, 7));
    for (var i = 0; i < 12; i++) {
      v99Pawn.update(0.05);
    }
    final v99Bytes = await captureScene(v99);
    await File('${outDir.path}/v99_filth.png').writeAsBytes(v99Bytes);
    v99.dispose();

    // --- V9.10 joy / recreate ---
    final v910 = HabitatGame(tileSize: 48);
    await v910.onLoad();
    v910.map.placeProp(
      HabitatPropCatalog.spawn(HabitatPropKinds.boardgame, (6, 5)),
    );
    final v910Pawn = v910.pawn!;
    v910Pawn.jobs.orderRecreate(v910.map.props.last);
    for (var i = 0; i < 60; i++) {
      v910Pawn.update(0.05);
    }
    v910.pushBubble(
      v910Pawn,
      'Hora de relaxar.',
      kind: HabitatBubbleKind.speech,
    );
    final v910Bytes = await captureScene(v910);
    await File('${outDir.path}/v910_joy.png').writeAsBytes(v910Bytes);
    v910.dispose();

    // --- V9.11 comfort + light ---
    final v911 = HabitatGame(tileSize: 48);
    await v911.onLoad();
    v911.presence.syncFromClock(DateTime(2026, 8, 7, 22, 0));
    v911.map.placeProp(
      HabitatPropCatalog.spawn(
        HabitatPropKinds.lamp,
        (8, 4),
        quality: HabitatPropQuality.excellent,
      ),
    );
    v911.notifyMapVisualChanged();
    for (var i = 0; i < 30; i++) {
      v911.update(0.05);
    }
    final v911Bytes = await captureScene(v911);
    await File('${outDir.path}/v911_comfort_light.png').writeAsBytes(v911Bytes);
    v911.dispose();

    // --- V9.12 temperature ---
    final v912 = HabitatGame(
      tileSize: 48,
      locationId: HabitatLocationIds.terrace,
    );
    await v912.onLoad();
    v912.setOutdoorTemperature(5);
    v912.map.placeProp(
      HabitatPropCatalog.spawn(HabitatPropKinds.heater, (7, 5)),
    );
    for (var i = 0; i < 25; i++) {
      v912.update(0.05);
    }
    final v912Bytes = await captureScene(v912);
    await File('${outDir.path}/v912_temperature.png').writeAsBytes(v912Bytes);
    v912.dispose();

    // --- V9.13 zones: hatch overlay on restricted area ---
    final v913 = HabitatGame(tileSize: 48);
    await v913.onLoad();
    final pawn913 = v913.pawns.first;
    v913.focusedPawn = pawn913;
    v913.allowedZones[pawn913.memberId] = {
      (pawn913.cellX, pawn913.cellY),
      (pawn913.cellX + 1, pawn913.cellY),
      (pawn913.cellX, pawn913.cellY + 1),
    };
    v913.editor.enabled = true;
    v913.editor.tool = HabitatEditTool.zone;
    v913.zoneOverlay?.bumpPaintAnim();
    for (var i = 0; i < 15; i++) {
      v913.update(0.05);
    }
    final v913Bytes = await captureScene(v913);
    await File('${outDir.path}/v913_zones.png').writeAsBytes(v913Bytes);
    v913.dispose();

    // --- V9.14 social: facing pair + dialogue bubbles ---
    final v914 = HabitatGame(tileSize: 48);
    await v914.onLoad();
    if (v914.pawns.length >= 2) {
      final a = v914.pawns[0];
      final b = v914.pawns[1];
      final meet = (a.cellX, a.cellY);
      a.teleportToCell(meet);
      b.teleportToCell((meet.$1 + 1, meet.$2));
      a.facing = facingFromDelta(1, 0);
      b.facing = facingFromDelta(-1, 0);
      a.poseOffsetX = 2;
      b.poseOffsetX = -2;
      a.jobs.wander.pause();
      b.jobs.wander.pause();
      v914.pushBubble(
        a,
        'Olha… mesa boa pra conversa.',
        kind: HabitatBubbleKind.speech,
      );
      v914.pushBubble(b, 'Né?', kind: HabitatBubbleKind.thought);
      if (v914.bubbles.isNotEmpty) {
        v914.bubbles.first.age = 0.5;
      }
      if (v914.bubbles.length > 1) {
        v914.bubbles[1].age = 0.3;
      }
    }
    for (var i = 0; i < 20; i++) {
      v914.update(0.05);
    }
    final v914Bytes = await captureScene(v914);
    await File('${outDir.path}/v914_social.png').writeAsBytes(v914Bytes);
    v914.dispose();

    print('Wrote ${outDir.path}/v0_wander.png (${v0Bytes.length} bytes)');
    print('Wrote ${outDir.path}/v4_inspect.png (${v4Bytes.length} bytes)');
    print('Wrote ${outDir.path}/v5_bubbles.png (${v5Bytes.length} bytes)');
    print('Wrote ${outDir.path}/v6_cosmetics.png (${v6Bytes.length} bytes)');
    print('Wrote ${outDir.path}/v7_room_edit.png (${v7Bytes.length} bytes)');
    print('Wrote ${outDir.path}/v8_multi_map.png (${v8Bytes.length} bytes)');
    print('Wrote ${outDir.path}/v9_multi_pawn.png (${v9Bytes.length} bytes)');
    print('Wrote ${outDir.path}/v95_polish.png (${v95Bytes.length} bytes)');
    print('Wrote ${outDir.path}/v96_draft_hold.png (${v96Bytes.length} bytes)');
    print('Wrote ${outDir.path}/v97_room_stats.png (${v97Bytes.length} bytes)');
    print('Wrote ${outDir.path}/v98_beauty.png (${v98Bytes.length} bytes)');
    print('Wrote ${outDir.path}/v99_filth.png (${v99Bytes.length} bytes)');
    print('Wrote ${outDir.path}/v910_joy.png (${v910Bytes.length} bytes)');
    print('Wrote ${outDir.path}/v911_comfort_light.png (${v911Bytes.length} bytes)');
    print('Wrote ${outDir.path}/v912_temperature.png (${v912Bytes.length} bytes)');
    print('Wrote ${outDir.path}/v913_zones.png (${v913Bytes.length} bytes)');
    print('Wrote ${outDir.path}/v914_social.png (${v914Bytes.length} bytes)');

    expect(v0Bytes.length, greaterThan(20000));
    expect(v4Bytes.length, greaterThan(20000));
    expect(v5Bytes.length, greaterThan(20000));
    expect(v6Bytes.length, greaterThan(20000));
    expect(v7Bytes.length, greaterThan(20000));
    expect(v8Bytes.length, greaterThan(20000));
    expect(v9Bytes.length, greaterThan(20000));
    expect(v95Bytes.length, greaterThan(20000));
    expect(v96Bytes.length, greaterThan(20000));
    expect(v97Bytes.length, greaterThan(20000));
    expect(v98Bytes.length, greaterThan(20000));
    // Distinct frames — not the old “copy same PNG thrice” trap.
    expect(v0Bytes, isNot(equals(v4Bytes)));
    expect(v0Bytes, isNot(equals(v5Bytes)));
    expect(v4Bytes, isNot(equals(v5Bytes)));
    expect(v6Bytes, isNot(equals(v0Bytes)));
    expect(v7Bytes, isNot(equals(v6Bytes)));
    expect(v8Bytes, isNot(equals(v0Bytes)));
    expect(v9Bytes, isNot(equals(v0Bytes)));
    expect(v95Bytes, isNot(equals(v9Bytes)));
    expect(v96Bytes, isNot(equals(v95Bytes)));
    expect(v97Bytes, isNot(equals(v96Bytes)));
    expect(v98Bytes, isNot(equals(v97Bytes)));
    expect(v99Bytes.length, greaterThan(20000));
    expect(v910Bytes.length, greaterThan(20000));
    expect(v911Bytes.length, greaterThan(20000));
    expect(v912Bytes.length, greaterThan(20000));
    expect(v99Bytes, isNot(equals(v98Bytes)));
    expect(v910Bytes, isNot(equals(v99Bytes)));
    expect(v911Bytes, isNot(equals(v910Bytes)));
    expect(v912Bytes, isNot(equals(v911Bytes)));
    expect(v913Bytes.length, greaterThan(20000));
    expect(v914Bytes.length, greaterThan(20000));
    expect(v913Bytes, isNot(equals(v912Bytes)));
    expect(v914Bytes, isNot(equals(v913Bytes)));
  });
}
