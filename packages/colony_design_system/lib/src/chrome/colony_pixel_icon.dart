import 'package:flutter/material.dart';

import 'colony_assets.dart';

/// Nearest-neighbour pixel sprite from the Fallhub Terminal kit.
class ColonyPixelIcon extends StatelessWidget {
  const ColonyPixelIcon(
    this.name, {
    super.key,
    this.size = 24,
    this.mono = false,
    this.color,
    this.semanticLabel,
  });

  final String name;
  final double size;
  final bool mono;
  final Color? color;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final asset = mono ? ColonyGfx.iconMono(name) : ColonyGfx.icon(name);
    Widget image = Image.asset(
      asset,
      package: ColonyGfx.package,
      width: size,
      height: size,
      filterQuality: FilterQuality.none,
      isAntiAlias: false,
      errorBuilder: (_, _, _) =>
          _Fallback(name: name, size: size, color: color),
    );
    if (color != null) {
      image = ColorFiltered(
        colorFilter: ColorFilter.mode(color!, BlendMode.srcIn),
        child: image,
      );
    }
    return Semantics(
      label: semanticLabel ?? name,
      excludeSemantics: semanticLabel == null,
      child: SizedBox(width: size, height: size, child: image),
    );
  }
}

class _Fallback extends StatelessWidget {
  const _Fallback({required this.name, required this.size, this.color});

  final String name;
  final double size;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size.square(size),
      painter: _PixelFallbackPainter(color ?? const Color(0xFFD2B06A)),
    );
  }
}

class _PixelFallbackPainter extends CustomPainter {
  const _PixelFallbackPainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;
    final s = size.width / 8;
    canvas.drawRect(Rect.fromLTWH(s * 2, s * 2, s * 4, s * 4), paint);
  }

  @override
  bool shouldRepaint(covariant _PixelFallbackPainter oldDelegate) =>
      oldDelegate.color != color;
}
