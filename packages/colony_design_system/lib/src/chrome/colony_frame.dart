import 'package:flutter/material.dart';

import '../tokens/colony_tokens.dart';

enum ColonyFrameVariant {
  /// Outer riveted plate (date bar, agenda, work, pawn).
  panel,

  /// Darker well (portrait inset, inset lists).
  inset,

  /// Square nav tile with rivets.
  tile,

  /// Tinted fill, no rivets (agenda cards).
  block,
}

/// Metallic plate with a top-left highlight, bottom-right shade, and corner rivets.
class ColonyFrame extends StatelessWidget {
  const ColonyFrame({
    super.key,
    required this.child,
    this.variant = ColonyFrameVariant.panel,
    this.padding,
    this.fill,
    this.onTap,
    this.width,
    this.height,
    this.selected = false,
    this.grain = true,
  });

  final Widget child;
  final ColonyFrameVariant variant;
  final EdgeInsetsGeometry? padding;
  final Color? fill;
  final VoidCallback? onTap;
  final double? width;
  final double? height;
  final bool selected;
  final bool grain;

  @override
  Widget build(BuildContext context) {
    final radius = switch (variant) {
      ColonyFrameVariant.tile => ColonyRadii.tile,
      ColonyFrameVariant.block => ColonyRadii.md,
      _ => ColonyRadii.md,
    };
    final rivets = variant != ColonyFrameVariant.block;
    final face =
        fill ??
        switch (variant) {
          ColonyFrameVariant.inset => ColonyColors.void_,
          ColonyFrameVariant.block => ColonyColors.void_,
          ColonyFrameVariant.tile => ColonyColors.raised,
          _ => ColonyColors.panel,
        };

    final painted = CustomPaint(
      painter: ColonyRivetPainter(
        fill: face,
        radius: radius,
        rivets: false,
        selected: selected,
        inset:
            variant == ColonyFrameVariant.inset ||
            variant == ColonyFrameVariant.block,
        grain: grain && variant != ColonyFrameVariant.block,
      ),
      foregroundPainter: rivets
          ? ColonyRivetPainter(
              fill: Colors.transparent,
              radius: radius,
              rivets: true,
              selected: selected,
              inset: variant == ColonyFrameVariant.inset,
              strokeOnly: true,
            )
          : null,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(radius),
        child: Padding(padding: padding ?? EdgeInsets.zero, child: child),
      ),
    );

    final sized = SizedBox(width: width, height: height, child: painted);
    if (onTap == null) return sized;
    return Material(
      type: MaterialType.transparency,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(radius),
        splashColor: ColonyColors.hoverOverlay,
        highlightColor: ColonyColors.lightHighlight,
        child: sized,
      ),
    );
  }
}

class ColonyRivetPainter extends CustomPainter {
  const ColonyRivetPainter({
    required this.fill,
    required this.radius,
    required this.rivets,
    required this.selected,
    required this.inset,
    this.strokeOnly = false,
    this.grain = false,
  });

  final Color fill;
  final double radius;
  final bool rivets;
  final bool selected;
  final bool inset;
  final bool strokeOnly;
  final bool grain;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width < 4 || size.height < 4) return;
    final rect = Rect.fromLTWH(0.5, 0.5, size.width - 1, size.height - 1);
    final rrect = RRect.fromRectAndRadius(rect, Radius.circular(radius));

    if (!strokeOnly && fill.a > 0) {
      canvas.drawRRect(rrect, Paint()..color = fill);
      if (grain) {
        canvas.save();
        canvas.clipRRect(rrect);
        _grain(canvas, size);
        canvas.restore();
      }
    }

    final outer = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = selected ? 1.8 : 1.5
      ..color = selected
          ? ColonyColors.borderSelected
          : ColonyColors.borderOuter;
    canvas.drawRRect(rrect, outer);

    if (!strokeOnly) {
      _bevel(canvas, rrect);
    }

    if (rivets && strokeOnly) {
      const pad = 7.0;
      _rivet(canvas, Offset(pad, pad));
      _rivet(canvas, Offset(size.width - pad, pad));
      _rivet(canvas, Offset(pad, size.height - pad));
      _rivet(canvas, Offset(size.width - pad, size.height - pad));
    }
  }

  void _bevel(Canvas canvas, RRect rrect) {
    final inner = rrect.deflate(1.4);
    final r = inner.tlRadiusX.clamp(1.0, 8.0);

    final hi = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.1
      ..strokeCap = StrokeCap.square
      ..color = inset ? const Color(0x66000000) : const Color(0x59B8C0C8);

    final sh = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2
      ..strokeCap = StrokeCap.square
      ..color = inset ? const Color(0x33FFFFFF) : const Color(0x99000000);

    final hiPath = Path()
      ..moveTo(inner.left, inner.bottom - r)
      ..lineTo(inner.left, inner.top + r)
      ..arcToPoint(
        Offset(inner.left + r, inner.top),
        radius: Radius.circular(r),
      )
      ..lineTo(inner.right - r, inner.top);
    canvas.drawPath(hiPath, hi);

    final shPath = Path()
      ..moveTo(inner.right, inner.top + r)
      ..lineTo(inner.right, inner.bottom - r)
      ..arcToPoint(
        Offset(inner.right - r, inner.bottom),
        radius: Radius.circular(r),
      )
      ..lineTo(inner.left + r, inner.bottom);
    canvas.drawPath(shPath, sh);
  }

  void _grain(Canvas canvas, Size size) {
    final hatch = Paint()
      ..color = const Color(0x0AFFFFFF)
      ..strokeWidth = 1;
    for (var y = 3.0; y < size.height; y += 4) {
      canvas.drawLine(Offset(2, y), Offset(size.width - 2, y), hatch);
    }
    final speckle = Paint()..color = const Color(0x14A8B0B8);
    for (var y = 5.0; y < size.height - 4; y += 6) {
      for (var x = 5.0 + (y % 12); x < size.width - 4; x += 8) {
        canvas.drawRect(Rect.fromLTWH(x, y, 1, 1), speckle);
      }
    }
  }

  void _rivet(Canvas canvas, Offset c) {
    canvas.drawCircle(c, 2.6, Paint()..color = const Color(0xFF050608));
    canvas.drawCircle(c, 1.9, Paint()..color = ColonyColors.rivetCore);
    canvas.drawCircle(c, 1.3, Paint()..color = const Color(0xFF8A9098));
    canvas.drawCircle(
      c.translate(-0.6, -0.6),
      0.55,
      Paint()..color = const Color(0xFFD0D4D8),
    );
  }

  @override
  bool shouldRepaint(covariant ColonyRivetPainter oldDelegate) {
    return fill != oldDelegate.fill ||
        radius != oldDelegate.radius ||
        rivets != oldDelegate.rivets ||
        selected != oldDelegate.selected ||
        inset != oldDelegate.inset ||
        strokeOnly != oldDelegate.strokeOnly ||
        grain != oldDelegate.grain;
  }
}

/// Full-screen charcoal mill-grain behind terminal pages.
class ColonyVoidBackdrop extends StatelessWidget {
  const ColonyVoidBackdrop({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: ColonyColors.void_,
      child: CustomPaint(painter: const _VoidGrainPainter(), child: child),
    );
  }
}

class _VoidGrainPainter extends CustomPainter {
  const _VoidGrainPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final hatch = Paint()
      ..color = const Color(0x0A6A727A)
      ..strokeWidth = 1;
    for (var y = 0.0; y < size.height; y += 5) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), hatch);
    }
    final speckle = Paint()..color = const Color(0x129AA2AA);
    for (var y = 2.0; y < size.height; y += 7) {
      for (var x = (y * 3) % 11; x < size.width; x += 11) {
        canvas.drawRect(Rect.fromLTWH(x, y, 1, 1), speckle);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
