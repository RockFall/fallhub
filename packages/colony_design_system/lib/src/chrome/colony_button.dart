import 'package:flutter/material.dart';

import '../tokens/colony_tokens.dart';

enum ColonyButtonVariant {
  /// Copper plate, cream/gold label.
  action,

  /// Copper plate, dark inscribed label (work-row CTAs).
  inscribed,

  /// Quiet metal plate.
  subtle,
}

/// Bevelled terminal button (physical switch: light top, dark base).
class ColonyButton extends StatefulWidget {
  const ColonyButton({
    super.key,
    required this.onPressed,
    required this.child,
    this.variant = ColonyButtonVariant.action,
    this.expanded = false,
    this.height = 32,
    this.minWidth = 88,
    this.padding = const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
  });

  final VoidCallback? onPressed;
  final Widget child;
  final ColonyButtonVariant variant;
  final bool expanded;
  final double height;
  final double minWidth;
  final EdgeInsetsGeometry padding;

  @override
  State<ColonyButton> createState() => _ColonyButtonState();
}

class _ColonyButtonState extends State<ColonyButton> {
  bool _hover = false;
  bool _pressed = false;

  bool get _enabled => widget.onPressed != null;

  bool get _copper => widget.variant != ColonyButtonVariant.subtle;

  Color get _fill {
    if (!_enabled) return ColonyColors.actionDisabled;
    if (widget.variant == ColonyButtonVariant.subtle) {
      if (_pressed) return ColonyColors.optionSelected;
      if (_hover) return ColonyColors.raised;
      return ColonyColors.subtle;
    }
    if (_pressed) return ColonyColors.actionPressed;
    if (_hover) return ColonyColors.actionHover;
    return ColonyColors.actionBase;
  }

  Color get _labelColor {
    if (!_enabled) return ColonyColors.textDisabled;
    if (widget.variant == ColonyButtonVariant.inscribed) {
      return ColonyColors.textInscribed;
    }
    if (widget.variant == ColonyButtonVariant.subtle) {
      return ColonyColors.textPrimary;
    }
    return ColonyColors.textGoldHi;
  }

  @override
  Widget build(BuildContext context) {
    final labelStyle = Theme.of(context).textTheme.labelLarge?.copyWith(
      color: _labelColor,
      fontWeight: FontWeight.w700,
      letterSpacing: 1.05,
      fontSize: 11,
      height: 1.0,
    );

    final button = MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() {
        _hover = false;
        _pressed = false;
      }),
      child: GestureDetector(
        onTapDown: _enabled ? (_) => setState(() => _pressed = true) : null,
        onTapUp: _enabled
            ? (_) {
                setState(() => _pressed = false);
                widget.onPressed?.call();
              }
            : null,
        onTapCancel: () => setState(() => _pressed = false),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            minWidth: widget.minWidth,
            minHeight: widget.height,
            maxHeight: widget.height,
          ),
          child: CustomPaint(
            painter: ColonyBevelPainter(
              fill: _fill,
              pressed: _pressed,
              copper: _copper,
              enabled: _enabled,
              radius: ColonyRadii.sm,
            ),
            child: Padding(
              padding: widget.padding,
              child: Center(
                child: DefaultTextStyle.merge(
                  style: labelStyle ?? const TextStyle(),
                  child: IconTheme.merge(
                    data: IconThemeData(color: _labelColor, size: 16),
                    child: widget.child,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );

    if (widget.expanded) {
      return SizedBox(width: double.infinity, child: button);
    }
    return button;
  }
}

/// Shared 3D plate bevel used by buttons and chrome icon buttons.
class ColonyBevelPainter extends CustomPainter {
  const ColonyBevelPainter({
    required this.fill,
    required this.pressed,
    required this.copper,
    required this.enabled,
    required this.radius,
  });

  final Color fill;
  final bool pressed;
  final bool copper;
  final bool enabled;
  final double radius;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final rrect = RRect.fromRectAndRadius(
      rect.deflate(0.5),
      Radius.circular(radius),
    );
    canvas.drawRRect(rrect, Paint()..color = fill);

    canvas.drawRRect(
      rrect,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2
        ..color = copper
            ? (enabled ? ColonyColors.actionBorder : ColonyColors.borderDark)
            : ColonyColors.borderOuter,
    );

    final inner = rrect.deflate(1.2);
    final hiColor = pressed
        ? const Color(0x66000000)
        : copper
        ? const Color(0x88E0A878)
        : const Color(0x55C8D0D4);
    final shColor = pressed ? const Color(0x33FFFFFF) : const Color(0xAA000000);

    final hi = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..color = hiColor;
    final sh = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.15
      ..color = shColor;

    final r = inner.tlRadiusX.clamp(1.0, 6.0);
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

  @override
  bool shouldRepaint(covariant ColonyBevelPainter oldDelegate) {
    return fill != oldDelegate.fill ||
        pressed != oldDelegate.pressed ||
        copper != oldDelegate.copper ||
        enabled != oldDelegate.enabled ||
        radius != oldDelegate.radius;
  }
}
