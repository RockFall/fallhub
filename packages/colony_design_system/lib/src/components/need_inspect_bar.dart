import 'package:flutter/material.dart';

import '../tokens/colony_tokens.dart';

/// Dense inspect rail: label above a solid cyan trough, quarter ticks,
/// optional white pointer under the current value.
class NeedInspectBar extends StatelessWidget {
  const NeedInspectBar({
    super.key,
    required this.label,
    this.value,
    this.selected = false,
    this.showTicks = true,
    this.showPointer = false,
    this.prominent = false,
    this.fillSlot = false,
    this.onTap,
    this.onLongPress,
    this.semanticId,
  });

  final String label;
  final double? value;
  final bool selected;
  final bool showTicks;
  final bool showPointer;
  final bool prominent;
  final bool fillSlot;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final String? semanticId;

  double get _railHeight => prominent ? 22 : 14;
  double get _pointerGutter => showPointer ? 8 : 0;
  double get _labelSize => prominent ? 11 : 9;

  @override
  Widget build(BuildContext context) {
    final labelColor = selected
        ? ColonyColors.textGoldHi
        : ColonyColors.textSecondary;

    final column = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          height: _labelSize,
          child: Text(
            label.toUpperCase(),
            maxLines: 1,
            overflow: TextOverflow.clip,
            style: TextStyle(
              fontFamily: ColonyFonts.familyTiny,
              color: labelColor,
              fontSize: _labelSize,
              letterSpacing: 0.7,
              height: 1.0,
              leadingDistribution: TextLeadingDistribution.even,
              fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
        ),
        SizedBox(height: prominent ? 3 : 1),
        SizedBox(
          height: _railHeight + _pointerGutter,
          child: CustomPaint(
            painter: NeedInspectRailPainter(
              value: value,
              showTicks: showTicks,
              showPointer: showPointer && value != null,
              selected: selected,
              railHeight: _railHeight,
            ),
          ),
        ),
      ],
    );

    final padded = Padding(
      padding: EdgeInsets.fromLTRB(
        prominent ? 0 : 2,
        0,
        prominent ? 0 : 4,
        0,
      ),
      child: column,
    );

    final slotted = fillSlot
        ? LayoutBuilder(
            builder: (context, constraints) {
              return FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.center,
                child: SizedBox(width: constraints.maxWidth, child: padded),
              );
            },
          )
        : padded;

    return Semantics(
      button: onTap != null,
      selected: selected,
      identifier: semanticId,
      label: label,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          onLongPress: onLongPress,
          overlayColor: WidgetStateProperty.all(ColonyColors.hoverOverlay),
          child: fillSlot ? SizedBox.expand(child: slotted) : slotted,
        ),
      ),
    );
  }
}

/// Paints a solid cyan fill on a black trough — not the striped need-bar texture.
class NeedInspectRailPainter extends CustomPainter {
  const NeedInspectRailPainter({
    required this.value,
    required this.showTicks,
    required this.showPointer,
    required this.selected,
    required this.railHeight,
  });

  final double? value;
  final bool showTicks;
  final bool showPointer;
  final bool selected;
  final double railHeight;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width < 4 || railHeight < 4) return;

    final rail = Rect.fromLTWH(0, 0, size.width, railHeight);
    canvas.drawRect(rail, Paint()..color = ColonyColors.void_);

    final inner = rail.deflate(1);
    final fraction = value?.clamp(0.0, 1.0);
    if (fraction != null && fraction > 0) {
      canvas.drawRect(
        Rect.fromLTWH(
          inner.left,
          inner.top,
          inner.width * fraction,
          inner.height,
        ),
        Paint()..color = ColonyColors.needsFill,
      );
    }

    if (showTicks) {
      final tick = Paint()
        ..color = const Color(0x997A848C)
        ..strokeWidth = 1
        ..strokeCap = StrokeCap.square;
      for (final t in const [0.25, 0.5, 0.75]) {
        final x = (inner.left + inner.width * t).floorToDouble() + 0.5;
        canvas.drawLine(
          Offset(x, inner.top),
          Offset(x, inner.bottom),
          tick,
        );
      }
    }

    canvas.drawRect(
      rail.deflate(0.5),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1
        ..color = selected
            ? ColonyColors.borderSelected
            : ColonyColors.borderStandard,
    );

    if (showPointer && fraction != null) {
      final x = inner.left + inner.width * fraction;
      final top = rail.bottom + 1;
      final path = Path()
        ..moveTo(x, top)
        ..lineTo(x - 3.5, top + 5)
        ..lineTo(x + 3.5, top + 5)
        ..close();
      canvas.drawPath(path, Paint()..color = const Color(0xFFF4F0E8));
    }
  }

  @override
  bool shouldRepaint(covariant NeedInspectRailPainter oldDelegate) {
    return oldDelegate.value != value ||
        oldDelegate.showTicks != showTicks ||
        oldDelegate.showPointer != showPointer ||
        oldDelegate.selected != selected ||
        oldDelegate.railHeight != railHeight;
  }
}
