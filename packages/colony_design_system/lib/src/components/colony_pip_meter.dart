import 'package:flutter/material.dart';

import '../tokens/colony_tokens.dart';

/// Three cyan status pips (descanso / humor).
class ColonyPipMeter extends StatelessWidget {
  const ColonyPipMeter({
    super.key,
    required this.label,
    required this.filled,
    this.total = 3,
    this.size = 7,
  });

  final String label;
  final int filled;
  final int total;
  final double size;

  static int countFor(double? value, {int total = 3}) {
    if (value == null) return 0;
    if (value >= 0.75) return total;
    if (value >= 0.45) return total >= 2 ? 2 : total;
    if (value >= 0.2) return 1;
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    final n = filled.clamp(0, total);
    return Semantics(
      label: '$label, $n de $total',
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label.toUpperCase(),
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: ColonyColors.textMuted,
              fontSize: 9,
              letterSpacing: 0.7,
            ),
          ),
          const SizedBox(width: 6),
          for (var i = 0; i < total; i++) ...[
            if (i > 0) const SizedBox(width: 5),
            _Pip(on: i < n, size: size),
          ],
        ],
      ),
    );
  }
}

class _Pip extends StatelessWidget {
  const _Pip({required this.on, required this.size});

  final bool on;
  final double size;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size.square(size + 4),
      painter: _PipPainter(on: on, core: size),
    );
  }
}

class _PipPainter extends CustomPainter {
  const _PipPainter({required this.on, required this.core});

  final bool on;
  final double core;

  @override
  void paint(Canvas canvas, Size size) {
    final c = Offset(size.width / 2, size.height / 2);
    if (on) {
      canvas.drawCircle(
        c,
        core * 0.95,
        Paint()..color = const Color(0x665AD4EC),
      );
    }
    canvas.drawCircle(
      c,
      core / 2,
      Paint()..color = on ? ColonyColors.accentCyan : ColonyColors.borderDark,
    );
    canvas.drawCircle(
      c,
      core / 2,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1
        ..color = on ? const Color(0xFFB8F4FF) : ColonyColors.borderStandard,
    );
    if (on) {
      canvas.drawCircle(
        c.translate(-0.8, -0.8),
        0.9,
        Paint()..color = const Color(0xCCE8FFFF),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _PipPainter oldDelegate) =>
      on != oldDelegate.on || core != oldDelegate.core;
}
