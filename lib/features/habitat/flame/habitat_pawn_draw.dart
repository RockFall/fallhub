import 'dart:ui';

/// RimWorld-accurate pawn mesh scale + head placement.
///
/// Vanilla humanlike body/head share one square mesh in **tile units**
/// (~`drawSize` `(1.5, 1.5)`). Layers share that size, but head / hair /
/// beard / hat are shifted by [BodyTypeDef.headOffset] so the chin sits on
/// the collar instead of mid-torso (sprites park the head near canvas center
/// while the body sits lower).
abstract final class HabitatPawnDraw {
  /// Map draw size in cells (width = height).
  static const double mapTiles = 1.55;

  /// Inspect / create portrait base size in logical pixels.
  static const double portraitPx = 140;

  /// Hair-style chip / mini swatch.
  static const double chipPx = 72;

  /// Vanilla-ish [BodyTypeDef.headOffset].y in cells (north = screen-up).
  /// Fat uses a slightly smaller lift; torso already fills more vertical space.
  static double headOffsetTiles(String bodyType) {
    switch (bodyType) {
      case 'fat':
        return 0.28;
      case 'hulk':
        return 0.36;
      case 'thin':
        return 0.34;
      case 'female':
        return 0.34;
      case 'male':
      default:
        return 0.34;
    }
  }

  /// Pixel offset for head stack (Y+ is down). Same for map and Flutter preview.
  static Offset headPixelOffset({
    required String bodyType,
    required String facing,
    required double tileOrSize,
  }) {
    final dy = -headOffsetTiles(bodyType) * tileOrSize;
    // East: small +X; west is mirrored via flip, so use +X there too.
    final dx = (facing == 'east' || facing == 'west')
        ? 0.07 * tileOrSize
        : 0.0;
    return Offset(dx, dy);
  }
}
