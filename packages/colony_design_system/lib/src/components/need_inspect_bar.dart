import 'package:flutter/material.dart';

import '../chrome/colony_assets.dart';
import '../tokens/colony_tokens.dart';

/// Dense RimWorld-like need rail: label above, cyan fill, optional ticks.
class NeedInspectBar extends StatelessWidget {
  const NeedInspectBar({
    super.key,
    required this.label,
    this.value,
    this.selected = false,
    this.showTicks = true,
    this.onTap,
    this.onLongPress,
    this.semanticId,
  });

  final String label;
  final double? value;
  final bool selected;
  final bool showTicks;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final String? semanticId;

  @override
  Widget build(BuildContext context) {
    final labelColor = selected
        ? ColonyColors.textGoldHi
        : ColonyColors.textSecondary;

    return Semantics(
      button: onTap != null,
      selected: selected,
      identifier: semanticId,
      label: label,
      child: Material(
        color: selected ? ColonyColors.optionSelected : Colors.transparent,
        child: InkWell(
          onTap: onTap,
          onLongPress: onLongPress,
          overlayColor: WidgetStateProperty.all(ColonyColors.hoverOverlay),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(6, 4, 6, 5),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  label.toUpperCase(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: labelColor,
                    fontSize: 9,
                    letterSpacing: 0.6,
                    height: 1.1,
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 3),
                SizedBox(
                  height: 11,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: ColonyColors.void_,
                      border: Border.all(
                        color: selected
                            ? ColonyColors.borderSelected
                            : ColonyColors.borderStandard,
                      ),
                    ),
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final fraction = (value ?? 0).clamp(0.0, 1.0);
                        final width = constraints.maxWidth * fraction;
                        return Stack(
                          children: [
                            if (showTicks)
                              CustomPaint(
                                size: Size(
                                  constraints.maxWidth,
                                  constraints.maxHeight,
                                ),
                                painter: const _NeedTickPainter(),
                              ),
                            if (value == null)
                              const Align(
                                alignment: Alignment.centerLeft,
                                child: Padding(
                                  padding: EdgeInsets.symmetric(horizontal: 3),
                                  child: Text(
                                    '?',
                                    style: TextStyle(
                                      color: ColonyColors.textMuted,
                                      fontSize: 8,
                                      height: 1,
                                    ),
                                  ),
                                ),
                              )
                            else
                              Align(
                                alignment: Alignment.centerLeft,
                                child: Container(
                                  width: width,
                                  decoration: BoxDecoration(
                                    color: ColonyColors.needsFill,
                                    image: DecorationImage(
                                      image: AssetImage(
                                        ColonyAssets.needsBarFill,
                                        package: ColonyAssets.package,
                                      ),
                                      fit: BoxFit.fill,
                                      colorFilter: const ColorFilter.mode(
                                        ColonyColors.needsFill,
                                        BlendMode.modulate,
                                      ),
                                      filterQuality: FilterQuality.none,
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        );
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _NeedTickPainter extends CustomPainter {
  const _NeedTickPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = ColonyColors.borderHighlight.withValues(alpha: 0.28)
      ..strokeWidth = 1;
    for (final t in const [0.25, 0.5, 0.75]) {
      final x = size.width * t;
      canvas.drawLine(Offset(x, 1), Offset(x, size.height - 1), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
