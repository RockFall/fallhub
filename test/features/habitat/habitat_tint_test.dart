import 'dart:ui';

import 'package:fallhub/features/habitat/flame/habitat_tint.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('tintPaint uses modulate blend', () {
    final paint = tintPaint(const Color(0xFFC68642));
    expect(paint.colorFilter, isNotNull);
    expect(paint.filterQuality, FilterQuality.none);
  });

  test('palettes expose usable swatches', () {
    expect(PawnPalettes.skinSwatches, isNotEmpty);
    expect(PawnPalettes.hairSwatches.length, greaterThanOrEqualTo(6));
    expect(StuffPalettes.furnitureSwatches, contains(StuffPalettes.wood));
  });

  test('PawnAppearance defaults are mutable', () {
    final a = PawnAppearance();
    a.skin = PawnPalettes.skinDeep;
    a.hair = PawnPalettes.hairPink;
    expect(a.skin, PawnPalettes.skinDeep);
    expect(a.hair, PawnPalettes.hairPink);
  });

  test('applyLoadout sets apparel kit', () {
    final a = PawnAppearance();
    a.applyLoadout(VisualLoadouts.outdoors);
    expect(a.apparelTop, 'jacket');
    expect(a.hat, 'cowboy');
    a.applyLoadout(VisualLoadouts.home);
    expect(a.apparelTop, 'shirt_basic');
    expect(a.hat, isNull);
  });

  test('randomizeHair does not change skin', () {
    final a = PawnAppearance(skin: PawnPalettes.skinDark);
    a.randomizeHair();
    expect(a.skin, PawnPalettes.skinDark);
  });
}

