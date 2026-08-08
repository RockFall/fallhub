import 'package:flutter/material.dart';

import '../tokens/colony_tokens.dart';

enum ConfidenceDisplay {
  high,
  medium,
  low,
  insufficient,
}

class ConfidenceChip extends StatelessWidget {
  const ConfidenceChip({super.key, required this.level});

  final ConfidenceDisplay level;

  @override
  Widget build(BuildContext context) {
    final label = switch (level) {
      ConfidenceDisplay.high => 'Alta',
      ConfidenceDisplay.medium => 'Média',
      ConfidenceDisplay.low => 'Baixa',
      ConfidenceDisplay.insufficient => 'Insuficiente',
    };

    final color = switch (level) {
      ConfidenceDisplay.high => ColonyColors.statusGood,
      ConfidenceDisplay.medium => ColonyColors.statusInfo,
      ConfidenceDisplay.low => ColonyColors.statusAttention,
      ConfidenceDisplay.insufficient => ColonyColors.statusUnknown,
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: ColonyColors.optionUnselected,
        border: Border.all(color: color),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: color,
              fontSize: 11,
            ),
      ),
    );
  }
}
