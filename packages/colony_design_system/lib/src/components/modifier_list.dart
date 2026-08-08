import 'package:flutter/material.dart';

import '../tokens/colony_tokens.dart';

class ModifierEntry {
  const ModifierEntry({
    required this.label,
    this.impact,
    this.note,
    this.uncertain = false,
  });

  final String label;
  final int? impact;
  final String? note;
  final bool uncertain;
}

class ModifierList extends StatelessWidget {
  const ModifierList({super.key, required this.entries});

  final List<ModifierEntry> entries;

  @override
  Widget build(BuildContext context) {
    if (entries.isEmpty) {
      return Text(
        'Nenhum fator registrado.',
        style: Theme.of(context).textTheme.bodySmall,
      );
    }

    return Column(
      children: entries
          .map(
            (entry) => Padding(
              padding: const EdgeInsets.symmetric(vertical: ColonySpacing.xs),
              child: Row(
                children: [
                  Expanded(child: Text(entry.label)),
                  Text(
                    entry.uncertain
                        ? '-?'
                        : entry.impact == null
                            ? '—'
                            : entry.impact! >= 0
                                ? '+${entry.impact}'
                                : '${entry.impact}',
                    style: TextStyle(
                      color: entry.uncertain
                          ? ColonyColors.statusUnknown
                          : (entry.impact ?? 0) >= 0
                              ? ColonyColors.statusGood
                              : ColonyColors.statusRisk,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                  if (entry.note != null) ...[
                    const SizedBox(width: ColonySpacing.sm),
                    Flexible(
                      child: Text(
                        entry.note!,
                        style: Theme.of(context).textTheme.bodySmall,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          )
          .toList(),
    );
  }
}
