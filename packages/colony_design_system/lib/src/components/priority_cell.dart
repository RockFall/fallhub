import 'package:flutter/material.dart';

import '../tokens/colony_tokens.dart';

/// Tappable cell for work priority grid (RimWorld Work tab density).
class PriorityCell extends StatefulWidget {
  const PriorityCell({
    super.key,
    required this.label,
    required this.onTap,
    this.selected = false,
  });

  final String label;
  final VoidCallback onTap;
  final bool selected;

  @override
  State<PriorityCell> createState() => _PriorityCellState();
}

class _PriorityCellState extends State<PriorityCell> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final selected = widget.selected;
    final bg = selected
        ? ColonyColors.optionSelected
        : _hover
            ? ColonyColors.lightHighlight
            : ColonyColors.void_;
    final fg = _hover && !selected
        ? ColonyColors.textMouseover
        : ColonyColors.textPrimary;

    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: Container(
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(
            horizontal: ColonySpacing.sm,
            vertical: ColonySpacing.md,
          ),
          decoration: BoxDecoration(
            color: bg,
            border: Border.all(
              color: selected
                  ? ColonyColors.borderSelected
                  : ColonyColors.borderDark,
            ),
          ),
          child: Text(
            widget.label,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: fg,
                  fontWeight: FontWeight.w600,
                ),
          ),
        ),
      ),
    );
  }
}
