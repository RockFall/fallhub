import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../tokens/colony_tokens.dart';

class NeedSparkline extends StatelessWidget {
  const NeedSparkline({
    super.key,
    required this.values,
    required this.labels,
    this.selectedIndex,
    this.onSelect,
    this.height = 108,
  });

  /// Normalized 0–1, null = no sample that day.
  final List<double?> values;
  final List<String> labels;
  final int? selectedIndex;
  final ValueChanged<int>? onSelect;
  final double height;

  @override
  Widget build(BuildContext context) {
    assert(values.length == labels.length);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          height: height,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: ColonyColors.void_,
              border: Border.all(color: ColonyColors.borderStandard),
            ),
            child: LayoutBuilder(
              builder: (context, constraints) {
                return GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTapDown: onSelect == null
                      ? null
                      : (details) {
                          if (values.isEmpty) return;
                          final i =
                              (details.localPosition.dx /
                                      constraints.maxWidth *
                                      values.length)
                                  .floor()
                                  .clamp(0, values.length - 1);
                          onSelect!(i);
                        },
                  child: CustomPaint(
                    painter: _NeedSparklinePainter(
                      values: values,
                      selectedIndex: selectedIndex,
                    ),
                    child: const SizedBox.expand(),
                  ),
                );
              },
            ),
          ),
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            for (var i = 0; i < labels.length; i++)
              Expanded(
                child: Text(
                  labels[i],
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: ColonyFonts.familyTiny,
                    color: i == selectedIndex
                        ? ColonyColors.textGoldHi
                        : ColonyColors.textMuted,
                    fontSize: 10,
                    letterSpacing: 0.4,
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }
}

class _NeedSparklinePainter extends CustomPainter {
  const _NeedSparklinePainter({
    required this.values,
    required this.selectedIndex,
  });

  final List<double?> values;
  final int? selectedIndex;

  @override
  void paint(Canvas canvas, Size size) {
    if (values.isEmpty) return;
    const pad = 10.0;
    final chart = Rect.fromLTWH(
      pad,
      pad,
      size.width - pad * 2,
      size.height - pad * 2,
    );

    final grid = Paint()
      ..color = ColonyColors.borderSeparator
      ..strokeWidth = 1;
    for (final t in const [0.0, 0.5, 1.0]) {
      final y = chart.bottom - chart.height * t;
      canvas.drawLine(Offset(chart.left, y), Offset(chart.right, y), grid);
    }

    Offset pointFor(int i, double value) {
      final t = values.length == 1 ? 0.5 : i / (values.length - 1);
      final x = chart.left + chart.width * t;
      final y = chart.bottom - chart.height * value.clamp(0.0, 1.0);
      return Offset(x, y);
    }

    final line = Paint()
      ..color = ColonyColors.needsFill
      ..strokeWidth = 1.8
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.square;

    Offset? prev;
    for (var i = 0; i < values.length; i++) {
      final v = values[i];
      if (v == null) {
        prev = null;
        continue;
      }
      final p = pointFor(i, v);
      if (prev != null) canvas.drawLine(prev, p, line);
      prev = p;
    }

    for (var i = 0; i < values.length; i++) {
      final v = values[i];
      if (v == null) continue;
      final p = pointFor(i, v);
      final selected = i == selectedIndex;
      if (selected) {
        canvas.save();
        canvas.translate(p.dx, p.dy);
        canvas.rotate(math.pi / 4);
        canvas.drawRect(
          Rect.fromCenter(center: Offset.zero, width: 8, height: 8),
          Paint()..color = ColonyColors.textGoldHi,
        );
        canvas.restore();
      } else {
        canvas.drawRect(
          Rect.fromCenter(center: p, width: 5, height: 5),
          Paint()..color = ColonyColors.needsFill,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant _NeedSparklinePainter oldDelegate) {
    return oldDelegate.values != values ||
        oldDelegate.selectedIndex != selectedIndex;
  }
}
