import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../tokens/colony_tokens.dart';

const needSparklinePad = 10.0;

class NeedSparklinePoint {
  const NeedSparklinePoint({required this.x, required this.value});

  /// 0–1 across the visible window.
  final double x;
  final double value;

  @override
  bool operator ==(Object other) =>
      other is NeedSparklinePoint && other.x == x && other.value == value;

  @override
  int get hashCode => Object.hash(x, value);
}

class NeedSparklineHit {
  const NeedSparklineHit({this.pointIndex, required this.dayIndex});

  final int? pointIndex;
  final int dayIndex;
}

/// Maps a 0–1 chart x to a day column and, when present, a sample in that day.
NeedSparklineHit needSparklineHitAt({
  required double x,
  required List<NeedSparklinePoint> points,
  required int dayCount,
}) {
  final n = dayCount <= 0 ? 1 : dayCount;
  final clamped = x.clamp(0.0, 0.999999);
  final dayIndex = (clamped * n).floor().clamp(0, n - 1);
  final start = dayIndex / n;
  final end = (dayIndex + 1) / n;

  int? best;
  var bestD = double.infinity;
  for (var i = 0; i < points.length; i++) {
    final px = points[i].x.clamp(0.0, 1.0);
    final inDay = dayIndex == n - 1
        ? px >= start
        : px >= start && px < end;
    if (!inDay) continue;
    final d = (px - clamped).abs();
    if (d < bestD) {
      best = i;
      bestD = d;
    }
  }
  return NeedSparklineHit(pointIndex: best, dayIndex: dayIndex);
}

double needSparklineTapX(double localDx, double width) {
  final chartW = width - needSparklinePad * 2;
  if (chartW <= 0) return 0;
  return ((localDx - needSparklinePad) / chartW).clamp(0.0, 1.0);
}

class NeedSparkline extends StatelessWidget {
  const NeedSparkline({
    super.key,
    required this.points,
    required this.labels,
    this.selectedIndex,
    this.highlightedDayIndex,
    this.onSelectPoint,
    this.onSelectDay,
    this.height = 108,
  });

  final List<NeedSparklinePoint> points;
  final List<String> labels;
  final int? selectedIndex;
  final int? highlightedDayIndex;
  final ValueChanged<int>? onSelectPoint;
  final ValueChanged<int>? onSelectDay;
  final double height;

  @override
  Widget build(BuildContext context) {
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
                  onTapDown: (onSelectPoint == null && onSelectDay == null)
                      ? null
                      : (details) {
                          final hit = needSparklineHitAt(
                            x: needSparklineTapX(
                              details.localPosition.dx,
                              constraints.maxWidth,
                            ),
                            points: points,
                            dayCount: labels.length,
                          );
                          if (hit.pointIndex != null) {
                            onSelectPoint?.call(hit.pointIndex!);
                          } else {
                            onSelectDay?.call(hit.dayIndex);
                          }
                        },
                  child: CustomPaint(
                    painter: _NeedSparklinePainter(
                      points: points,
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
                    color: i == highlightedDayIndex
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
    required this.points,
    required this.selectedIndex,
  });

  final List<NeedSparklinePoint> points;
  final int? selectedIndex;

  @override
  void paint(Canvas canvas, Size size) {
    final chart = Rect.fromLTWH(
      needSparklinePad,
      needSparklinePad,
      size.width - needSparklinePad * 2,
      size.height - needSparklinePad * 2,
    );

    final grid = Paint()
      ..color = ColonyColors.borderSeparator
      ..strokeWidth = 1;
    for (final t in const [0.0, 0.5, 1.0]) {
      final y = chart.bottom - chart.height * t;
      canvas.drawLine(Offset(chart.left, y), Offset(chart.right, y), grid);
    }

    Offset pointFor(NeedSparklinePoint point) {
      final x = chart.left + chart.width * point.x.clamp(0.0, 1.0);
      final y = chart.bottom - chart.height * point.value.clamp(0.0, 1.0);
      return Offset(x, y);
    }

    if (points.isEmpty) return;

    final line = Paint()
      ..color = ColonyColors.needsFill
      ..strokeWidth = 1.8
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.square;

    for (var i = 0; i < points.length - 1; i++) {
      canvas.drawLine(pointFor(points[i]), pointFor(points[i + 1]), line);
    }

    for (var i = 0; i < points.length; i++) {
      final p = pointFor(points[i]);
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
    return oldDelegate.points != points ||
        oldDelegate.selectedIndex != selectedIndex;
  }
}
