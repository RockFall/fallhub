import 'package:flutter/material.dart';

import '../tokens/colony_tokens.dart';

/// Compact retention marker. Color is never the only signal — pair with text.
class ColonyHeatDot extends StatelessWidget {
  const ColonyHeatDot({
    super.key,
    required this.retention,
    this.size = 10,
  });

  /// 0–1 from recent reviews; null if unknown.
  final double? retention;
  final double size;

  Color get color {
    final value = retention;
    if (value == null) return ColonyColors.statusUnknown;
    if (value >= 0.85) return ColonyColors.statusGood;
    if (value >= 0.6) return ColonyColors.statusAttention;
    return ColonyColors.statusRisk;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.22),
        shape: BoxShape.circle,
        border: Border.all(color: color, width: 1.5),
      ),
    );
  }
}
