import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:colony_design_system/colony_design_system.dart';
import 'package:colony_domain/colony_domain.dart';
import 'package:flutter/material.dart';

class GeneratedAlbumCover extends StatelessWidget {
  const GeneratedAlbumCover({
    super.key,
    required this.recipe,
    this.heard = false,
    this.ghost = false,
  });

  final MusicCoverRecipe recipe;
  final bool heard;
  final bool ghost;

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 1,
      child: CustomPaint(
        painter: _CoverPainter(
          recipe: recipe,
          heard: heard,
          ghost: ghost,
        ),
      ),
    );
  }
}

class _CoverPainter extends CustomPainter {
  const _CoverPainter({
    required this.recipe,
    required this.heard,
    required this.ghost,
  });

  final MusicCoverRecipe recipe;
  final bool heard;
  final bool ghost;

  Color _hsv(double h, double s, double l, [double a = 1]) {
    return HSVColor.fromAHSV(a, h % 360, s.clamp(0, 1), l.clamp(0, 1)).toColor();
  }

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final r = recipe;
    final ink = _hsv(r.hue, r.saturation, r.lightness, ghost ? 0.55 : 1);
    final wash = _hsv(
      r.secondaryHue ?? (r.hue + 40),
      r.saturation + 0.08,
      (r.lightness + 0.18).clamp(0, 0.72),
      ghost ? 0.45 : 0.95,
    );
    final deep = _hsv(r.hue, r.saturation + 0.1, (r.lightness - 0.14).clamp(0.08, 1));

    canvas.save();
    canvas.clipRRect(RRect.fromRectAndRadius(rect, const Radius.circular(3)));

    final bg = Paint()
      ..shader = ui.Gradient.linear(
        Offset(0, 0),
        Offset(size.width, size.height),
        [deep, ink, wash],
        const [0, 0.52, 1],
      );
    canvas.drawRect(rect, bg);

    switch (r.motif) {
      case MusicCoverMotif.river:
        _rivers(canvas, size, wash);
      case MusicCoverMotif.ember:
        _embers(canvas, size, wash);
      case MusicCoverMotif.lattice:
        _lattice(canvas, size, wash);
      case MusicCoverMotif.spore:
        _spores(canvas, size, wash);
      case MusicCoverMotif.pulse:
        _pulse(canvas, size, wash);
      case MusicCoverMotif.brass:
        _brass(canvas, size, wash);
      case MusicCoverMotif.concrete:
        _concrete(canvas, size, wash);
      case MusicCoverMotif.tide:
        _tide(canvas, size, wash);
      case MusicCoverMotif.ash:
        _ash(canvas, size, wash);
      case MusicCoverMotif.gold:
        _gold(canvas, size, wash);
    }

    _grain(canvas, size);
    _monogram(canvas, size);
    if (r.year != null) _yearStamp(canvas, size, '${r.year}');
    if (heard) _groove(canvas, size);
    if (ghost) {
      canvas.drawRect(
        rect,
        Paint()..color = ColonyColors.void_.withValues(alpha: 0.28),
      );
    }

    canvas.restore();
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect.deflate(0.6), const Radius.circular(3)),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2
        ..color = ColonyColors.borderHighlight.withValues(alpha: 0.45),
    );
  }

  void _rivers(Canvas canvas, Size size, Color wash) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6
      ..color = wash.withValues(alpha: 0.55);
    for (var i = 0; i < 7; i++) {
      final path = Path();
      final y0 = size.height * (0.12 + i * 0.12);
      path.moveTo(-4, y0);
      for (var x = 0.0; x <= size.width + 4; x += 8) {
        final wobble =
            math.sin((x / size.width) * math.pi * 2 + i + recipe.unit(i) * 4) *
            10;
        path.lineTo(x, y0 + wobble);
      }
      canvas.drawPath(path, paint);
    }
  }

  void _embers(Canvas canvas, Size size, Color wash) {
    final rnd = math.Random(recipe.seed);
    for (var i = 0; i < 28; i++) {
      final cx = rnd.nextDouble() * size.width;
      final cy = rnd.nextDouble() * size.height;
      final rad = 3 + rnd.nextDouble() * 16;
      canvas.drawCircle(
        Offset(cx, cy),
        rad,
        Paint()..color = wash.withValues(alpha: 0.08 + rnd.nextDouble() * 0.2),
      );
    }
  }

  void _lattice(Canvas canvas, Size size, Color wash) {
    final paint = Paint()
      ..color = wash.withValues(alpha: 0.28)
      ..strokeWidth = 0.8;
    const step = 14.0;
    for (var x = 0.0; x < size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x + size.height * 0.2, size.height), paint);
    }
    for (var y = 0.0; y < size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y + 6), paint);
    }
  }

  void _spores(Canvas canvas, Size size, Color wash) {
    final rnd = math.Random(recipe.seed ^ 17);
    for (var i = 0; i < 18; i++) {
      final c = Offset(
        rnd.nextDouble() * size.width,
        rnd.nextDouble() * size.height,
      );
      canvas.drawCircle(
        c,
        6 + rnd.nextDouble() * 22,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1
          ..color = wash.withValues(alpha: 0.35),
      );
    }
  }

  void _pulse(Canvas canvas, Size size, Color wash) {
    final mid = size.height * 0.55;
    final path = Path()..moveTo(0, mid);
    for (var x = 0.0; x <= size.width; x += 3) {
      final n = recipe.unit((x * 7).toInt());
      final amp = 8 + n * 28;
      path.lineTo(x, mid + math.sin(x / 9) * amp * (x / size.width));
    }
    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.2
        ..color = wash.withValues(alpha: 0.7),
    );
  }

  void _brass(Canvas canvas, Size size, Color wash) {
    final c = Offset(size.width * 0.52, size.height * 0.48);
    for (var i = 5; i >= 1; i--) {
      canvas.drawCircle(
        c,
        size.shortestSide * (0.12 * i),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.4
          ..color = wash.withValues(alpha: 0.16 * i),
      );
    }
    canvas.drawCircle(c, 5, Paint()..color = wash.withValues(alpha: 0.8));
  }

  void _concrete(Canvas canvas, Size size, Color wash) {
    final paint = Paint()..color = wash.withValues(alpha: 0.2);
    final rnd = math.Random(recipe.seed);
    for (var i = 0; i < 9; i++) {
      canvas.drawRect(
        Rect.fromLTWH(
          rnd.nextDouble() * size.width,
          rnd.nextDouble() * size.height,
          18 + rnd.nextDouble() * 40,
          6 + rnd.nextDouble() * 18,
        ),
        paint,
      );
    }
  }

  void _tide(Canvas canvas, Size size, Color wash) {
    for (var i = 0; i < 6; i++) {
      final path = Path();
      final y = size.height * (0.2 + i * 0.12);
      path.moveTo(0, y);
      path.cubicTo(
        size.width * 0.3,
        y - 16,
        size.width * 0.7,
        y + 16,
        size.width,
        y,
      );
      canvas.drawPath(
        path,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.3
          ..color = wash.withValues(alpha: 0.4),
      );
    }
  }

  void _ash(Canvas canvas, Size size, Color wash) {
    final rnd = math.Random(recipe.seed);
    for (var i = 0; i < 80; i++) {
      canvas.drawCircle(
        Offset(rnd.nextDouble() * size.width, rnd.nextDouble() * size.height),
        rnd.nextDouble() * 1.6,
        Paint()..color = wash.withValues(alpha: 0.25 + rnd.nextDouble() * 0.4),
      );
    }
  }

  void _gold(Canvas canvas, Size size, Color wash) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.1
      ..color = wash.withValues(alpha: 0.55);
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(12, 12, size.width - 24, size.height - 24), const Radius.circular(2)),
      paint,
    );
    canvas.drawLine(
      Offset(18, size.height * 0.72),
      Offset(size.width - 18, size.height * 0.72),
      paint,
    );
  }

  void _grain(Canvas canvas, Size size) {
    final rnd = math.Random(recipe.seed ^ 99);
    final paint = Paint()..color = Colors.white.withValues(alpha: 0.05);
    for (var i = 0; i < 90; i++) {
      canvas.drawRect(
        Rect.fromLTWH(
          rnd.nextDouble() * size.width,
          rnd.nextDouble() * size.height,
          1.2,
          1.2,
        ),
        paint,
      );
    }
  }

  void _monogram(Canvas canvas, Size size) {
    final tp = TextPainter(
      text: TextSpan(
        text: recipe.monogram,
        style: TextStyle(
          fontFamily: ColonyFonts.familyPrimary,
          fontSize: size.shortestSide * 0.28,
          fontWeight: FontWeight.w600,
          letterSpacing: 1.2,
          color: ColonyColors.textPrimary.withValues(alpha: ghost ? 0.45 : 0.88),
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: size.width * 0.8);
    tp.paint(
      canvas,
      Offset((size.width - tp.width) / 2, size.height * 0.34 - tp.height / 2),
    );
  }

  void _yearStamp(Canvas canvas, Size size, String year) {
    final tp = TextPainter(
      text: TextSpan(
        text: year,
        style: TextStyle(
          fontFamily: ColonyFonts.familyTiny,
          fontSize: 10,
          letterSpacing: 1.4,
          color: ColonyColors.textPrimary.withValues(alpha: 0.7),
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, Offset(size.width - tp.width - 8, size.height - 16));
  }

  void _groove(Canvas canvas, Size size) {
    final c = Offset(size.width * 0.86, size.height * 0.14);
    canvas.drawCircle(
      c,
      7,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.4
        ..color = ColonyColors.accentCyan.withValues(alpha: 0.85),
    );
    canvas.drawCircle(c, 2.2, Paint()..color = ColonyColors.accentCyan);
  }

  @override
  bool shouldRepaint(covariant _CoverPainter old) =>
      old.recipe != recipe || old.heard != heard || old.ghost != ghost;
}
