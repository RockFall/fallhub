import 'package:colony_design_system/colony_design_system.dart';
import 'package:flutter/material.dart';

/// Compact RimWorld-ish color chip row for tint personalization.
class ColorSwatchRow extends StatelessWidget {
  const ColorSwatchRow({
    super.key,
    required this.label,
    required this.colors,
    required this.selected,
    required this.onSelected,
  });

  final String label;
  final List<Color> colors;
  final Color selected;
  final ValueChanged<Color> onSelected;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: ColonyColors.textSeparator,
              ),
        ),
        const SizedBox(height: ColonySpacing.xs),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [
            for (final c in colors)
              _Swatch(
                color: c,
                selected: c.toARGB32() == selected.toARGB32(),
                onTap: () => onSelected(c),
              ),
          ],
        ),
      ],
    );
  }
}

class _Swatch extends StatelessWidget {
  const _Swatch({
    required this.color,
    required this.selected,
    required this.onTap,
  });

  final Color color;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: '#${color.toARGB32().toRadixString(16).padLeft(8, '0').substring(2)}',
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(2),
        child: Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: color,
            border: Border.all(
              color: selected
                  ? ColonyColors.textMouseover
                  : ColonyColors.borderStandard,
              width: selected ? 2 : 1,
            ),
          ),
        ),
      ),
    );
  }
}
