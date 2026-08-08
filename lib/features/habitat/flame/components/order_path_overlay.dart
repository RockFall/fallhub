import 'dart:ui';

import 'package:flame/components.dart';

import '../habitat_game.dart';
import 'pawn_job_controller.dart';

/// Thin white path line for a drafted pawn's order (RimWorld-style).
class OrderPathOverlayComponent extends Component
    with HasGameReference<HabitatGame> {
  OrderPathOverlayComponent() : super(priority: 18);

  @override
  void render(Canvas canvas) {
    final pawn = game.draftedPawn;
    if (pawn == null) return;

    final cells = pawn.jobs.remainingPath;
    if (cells.isEmpty) return;
    if (pawn.jobs.kind == HabitatJobKind.wander) return;

    final tile = game.tileSize;
    final points = <Offset>[
      Offset(pawn.position.x, pawn.position.y),
      for (final c in cells)
        Offset(c.$1 * tile + tile / 2, c.$2 * tile + tile / 2),
    ];

    final stroke = Paint()
      ..color = const Color(0xE8FFFFFF)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.35
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final line = Path()..moveTo(points.first.dx, points.first.dy);
    for (var i = 1; i < points.length; i++) {
      line.lineTo(points[i].dx, points[i].dy);
    }
    canvas.drawPath(line, stroke);

    // Destination X (RimWorld destination marker).
    final end = points.last;
    final arm = tile * 0.16;
    canvas.drawLine(
      Offset(end.dx - arm, end.dy - arm),
      Offset(end.dx + arm, end.dy + arm),
      stroke,
    );
    canvas.drawLine(
      Offset(end.dx + arm, end.dy - arm),
      Offset(end.dx - arm, end.dy + arm),
      stroke,
    );
  }
}
