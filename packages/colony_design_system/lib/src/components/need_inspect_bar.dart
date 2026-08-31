import 'package:flutter/material.dart';

import '../tokens/colony_tokens.dart';

/// Visual weight of an inspect rail. Primary needs sit above a dotted rule;
/// the rest stay compact so a long catalog still fits.
enum NeedInspectBarScale {
  compact,
  primary,
  featured,
}

/// Dense inspect rail: label above a solid cyan trough, quarter ticks,
/// optional white pointer under the current value.
///
/// When [onValueCommit] is set, a horizontal drag snaps the fill to the
/// 1–5 scale (0, 0.25, 0.5, 0.75, 1) and reports the value.
class NeedInspectBar extends StatefulWidget {
  const NeedInspectBar({
    super.key,
    required this.label,
    this.value,
    this.selected = false,
    this.showTicks = true,
    this.showPointer = false,
    this.showChevron = false,
    this.scale = NeedInspectBarScale.compact,
    this.fillSlot = false,
    this.onTap,
    this.onLongPress,
    this.onValueChanged,
    this.onValueCommit,
    this.semanticId,
  });

  final String label;
  final double? value;
  final bool selected;
  final bool showTicks;
  final bool showPointer;
  final bool showChevron;
  final NeedInspectBarScale scale;
  final bool fillSlot;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final ValueChanged<double>? onValueChanged;
  final ValueChanged<double>? onValueCommit;
  final String? semanticId;

  static double snapScale5(double value) =>
      (value.clamp(0.0, 1.0) * 4).round() / 4.0;

  @override
  State<NeedInspectBar> createState() => _NeedInspectBarState();
}

class _NeedInspectBarState extends State<NeedInspectBar> {
  final _trackKey = GlobalKey();
  var _dragging = false;
  double? _dragValue;

  bool get _interactive =>
      widget.onValueChanged != null || widget.onValueCommit != null;

  double get _railHeight => switch (widget.scale) {
    NeedInspectBarScale.featured => 24,
    NeedInspectBarScale.primary => 18,
    NeedInspectBarScale.compact => 12,
  };

  double get _labelSize => switch (widget.scale) {
    NeedInspectBarScale.featured => 12,
    NeedInspectBarScale.primary => 12,
    NeedInspectBarScale.compact => 9,
  };

  double get _labelGap => switch (widget.scale) {
    NeedInspectBarScale.featured => 4,
    NeedInspectBarScale.primary => 3,
    NeedInspectBarScale.compact => 2,
  };

  bool get _showPointer => widget.showPointer;
  double get _pointerGutter => _showPointer ? 8 : 0;
  double get _chevronSize =>
      widget.scale == NeedInspectBarScale.primary ? 6 : 5;

  double? get _shown => _dragValue ?? widget.value;

  @override
  void didUpdateWidget(covariant NeedInspectBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_dragging && widget.value != oldWidget.value) {
      _dragValue = null;
    }
  }

  void _applyGlobal(Offset global) {
    final box = _trackKey.currentContext?.findRenderObject() as RenderBox?;
    if (box == null || !box.hasSize || box.size.width <= 0) return;
    final snapped = NeedInspectBar.snapScale5(
      box.globalToLocal(global).dx / box.size.width,
    );
    setState(() {
      _dragging = true;
      _dragValue = snapped;
    });
    widget.onValueChanged?.call(snapped);
  }

  void _endDrag() {
    final committed = _dragValue;
    setState(() => _dragging = false);
    if (committed != null) widget.onValueCommit?.call(committed);
  }

  void _cancelDrag() {
    setState(() {
      _dragging = false;
      _dragValue = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final selected = widget.selected;
    final scale = widget.scale;
    final labelColor = selected
        ? ColonyColors.textGoldHi
        : scale == NeedInspectBarScale.compact
        ? ColonyColors.textMuted
        : ColonyColors.textSecondary;

    final rail = SizedBox(
      key: _trackKey,
      height: _railHeight + _pointerGutter,
      child: CustomPaint(
        painter: NeedInspectRailPainter(
          value: _shown,
          showTicks: widget.showTicks,
          showPointer: _showPointer && _shown != null,
          selected: selected,
          railHeight: _railHeight,
        ),
      ),
    );

    final track = widget.showChevron
        ? Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: EdgeInsets.only(
                  top: ((_railHeight - _chevronSize) / 2).clamp(0, 8),
                  right: 3,
                ),
                child: CustomPaint(
                  size: Size(_chevronSize * 0.72, _chevronSize),
                  painter: const _NeedChevronPainter(),
                ),
              ),
              Expanded(child: rail),
            ],
          )
        : rail;

    final column = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          height: _labelSize,
          child: Text(
            widget.label.toUpperCase(),
            maxLines: 1,
            overflow: TextOverflow.clip,
            style: TextStyle(
              fontFamily: ColonyFonts.familyTiny,
              color: labelColor,
              fontSize: _labelSize,
              letterSpacing: scale == NeedInspectBarScale.compact ? 0.5 : 0.8,
              height: 1.0,
              leadingDistribution: TextLeadingDistribution.even,
              fontWeight: selected || scale != NeedInspectBarScale.compact
                  ? FontWeight.w700
                  : FontWeight.w500,
            ),
          ),
        ),
        SizedBox(height: _labelGap),
        track,
      ],
    );

    final padded = Padding(
      padding: EdgeInsets.fromLTRB(
        scale == NeedInspectBarScale.featured ? 0 : 1,
        0,
        scale == NeedInspectBarScale.featured ? 0 : 2,
        0,
      ),
      child: column,
    );

    final slotted = widget.fillSlot
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

    final hitChild = widget.fillSlot
        ? SizedBox.expand(child: slotted)
        : slotted;

    final Widget body;
    if (_interactive) {
      body = GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: widget.onTap,
        onLongPress: widget.onLongPress,
        onHorizontalDragStart: (details) => _applyGlobal(details.globalPosition),
        onHorizontalDragUpdate: (details) =>
            _applyGlobal(details.globalPosition),
        onHorizontalDragEnd: (_) => _endDrag(),
        onHorizontalDragCancel: _cancelDrag,
        child: hitChild,
      );
    } else {
      body = Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: widget.onTap,
          onLongPress: widget.onLongPress,
          overlayColor: WidgetStateProperty.all(ColonyColors.hoverOverlay),
          child: hitChild,
        ),
      );
    }

    return Semantics(
      button: widget.onTap != null || _interactive,
      selected: selected,
      identifier: widget.semanticId,
      label: widget.label,
      child: body,
    );
  }
}

/// Dotted rule between the primary trio and the compact catalog.
class NeedInspectGroupRule extends StatelessWidget {
  const NeedInspectGroupRule({super.key});

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 6, horizontal: 4),
      child: SizedBox(
        height: 1,
        child: CustomPaint(
          painter: _DottedRulePainter(),
          child: SizedBox.expand(),
        ),
      ),
    );
  }
}

/// Cyan/gold 1–5 slider used under inspect charts and the check-in window.
class NeedInspectSlider extends StatefulWidget {
  const NeedInspectSlider({
    super.key,
    required this.value,
    required this.onCommit,
    this.onChanged,
    this.labelOf,
    this.semanticId,
  });

  final double? value;
  final ValueChanged<double> onCommit;
  final ValueChanged<double>? onChanged;
  final String Function(double value)? labelOf;
  final String? semanticId;

  @override
  State<NeedInspectSlider> createState() => _NeedInspectSliderState();
}

class _NeedInspectSliderState extends State<NeedInspectSlider> {
  late double _value;

  @override
  void initState() {
    super.initState();
    _value = widget.value ?? 0.5;
  }

  @override
  void didUpdateWidget(covariant NeedInspectSlider oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value && widget.value != null) {
      _value = widget.value!;
    }
  }

  @override
  Widget build(BuildContext context) {
    final slider = SliderTheme(
      data: SliderTheme.of(context).copyWith(
        activeTrackColor: ColonyColors.needsFill,
        inactiveTrackColor: ColonyColors.borderSeparator,
        thumbColor: ColonyColors.textGoldHi,
        overlayColor: ColonyColors.needsFill.withValues(alpha: 0.16),
      ),
      child: Slider(
        value: _value.clamp(0, 1),
        min: 0,
        max: 1,
        divisions: 4,
        label: widget.labelOf?.call(_value),
        onChanged: (v) {
          setState(() => _value = v);
          widget.onChanged?.call(v);
        },
        onChangeEnd: widget.onCommit,
      ),
    );
    if (widget.semanticId == null) return slider;
    return Semantics(identifier: widget.semanticId, child: slider);
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
    canvas.drawRect(rail, Paint()..color = const Color(0xFF07090C));

    final hi = Paint()
      ..color = const Color(0x99000000)
      ..strokeWidth = 1
      ..isAntiAlias = false;
    canvas.drawLine(
      Offset(rail.left + 0.5, rail.top + 0.5),
      Offset(rail.right - 0.5, rail.top + 0.5),
      hi,
    );
    canvas.drawLine(
      Offset(rail.left + 0.5, rail.top + 0.5),
      Offset(rail.left + 0.5, rail.bottom - 0.5),
      hi,
    );
    final lift = Paint()
      ..color = const Color(0x28FFFFFF)
      ..strokeWidth = 1
      ..isAntiAlias = false;
    canvas.drawLine(
      Offset(rail.left + 1, rail.bottom - 0.5),
      Offset(rail.right - 0.5, rail.bottom - 0.5),
      lift,
    );

    final inner = rail.deflate(1.5);
    final fraction = value?.clamp(0.0, 1.0);
    if (fraction != null && fraction > 0) {
      final fill = Rect.fromLTWH(
        inner.left,
        inner.top,
        inner.width * fraction,
        inner.height,
      );
      canvas.drawRect(fill, Paint()..color = ColonyColors.needsFill);
      canvas.drawLine(
        Offset(fill.left, fill.top + 0.5),
        Offset(fill.right, fill.top + 0.5),
        Paint()
          ..color = const Color(0x66E8FFFF)
          ..strokeWidth = 1
          ..isAntiAlias = false,
      );
      canvas.drawLine(
        Offset(fill.left, fill.bottom - 0.5),
        Offset(fill.right, fill.bottom - 0.5),
        Paint()
          ..color = const Color(0x33000C18)
          ..strokeWidth = 1
          ..isAntiAlias = false,
      );
    }

    if (showTicks) {
      for (final t in const [0.25, 0.5, 0.75]) {
        final x = (inner.left + inner.width * t).floorToDouble() + 0.5;
        final overFill = fraction != null && t <= fraction;
        canvas.drawLine(
          Offset(x, inner.top),
          Offset(x, inner.bottom),
          Paint()
            ..color = overFill
                ? const Color(0x99050A10)
                : const Color(0x8A7A848C)
            ..strokeWidth = 1
            ..isAntiAlias = false,
        );
      }
    }

    canvas.drawRect(
      rail.deflate(0.5),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1
        ..isAntiAlias = false
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
      canvas.drawPath(path, Paint()..color = const Color(0xFFE8E0D4));
      canvas.drawPath(
        path,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 0.8
          ..color = const Color(0xAA050608),
      );
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

class _NeedChevronPainter extends CustomPainter {
  const _NeedChevronPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFC47B48)
      ..isAntiAlias = false;
    final u = (size.height / 5).clamp(1.0, 1.6);
    void px(int x, int y) {
      canvas.drawRect(Rect.fromLTWH(x * u, y * u, u, u), paint);
    }

    px(0, 0);
    px(0, 1);
    px(0, 2);
    px(0, 3);
    px(0, 4);
    px(1, 1);
    px(1, 2);
    px(1, 3);
    px(2, 2);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _DottedRulePainter extends CustomPainter {
  const _DottedRulePainter();

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0x8A7A848C)
      ..strokeWidth = 1
      ..strokeCap = StrokeCap.square;
    const dash = 3.0;
    const gap = 3.0;
    var x = 0.0;
    final y = 0.5;
    while (x < size.width) {
      final end = (x + dash).clamp(0, size.width).toDouble();
      canvas.drawLine(Offset(x, y), Offset(end, y), paint);
      x += dash + gap;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
