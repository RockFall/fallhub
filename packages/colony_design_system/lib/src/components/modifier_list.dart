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
  const ModifierList({
    super.key,
    required this.entries,
    this.compact = false,
    this.emptyLabel,
  });

  final List<ModifierEntry> entries;
  final bool compact;
  final String? emptyLabel;

  @override
  Widget build(BuildContext context) {
    if (entries.isEmpty) {
      final empty = emptyLabel ?? 'Nenhum fator registrado.';
      return Text(
        compact ? empty.toUpperCase() : empty,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          color: ColonyColors.textMuted,
          fontFamily: compact ? ColonyFonts.familyTiny : null,
          fontSize: compact ? 10 : null,
          letterSpacing: compact ? 0.4 : null,
        ),
      );
    }

    return Column(
      children: [
        for (final entry in entries)
          Padding(
            padding: EdgeInsets.symmetric(vertical: compact ? 3 : ColonySpacing.xs),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    compact ? entry.label.toUpperCase() : entry.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: compact
                        ? const TextStyle(
                            fontFamily: ColonyFonts.familyTiny,
                            color: ColonyColors.textSecondary,
                            fontSize: 11,
                            letterSpacing: 0.5,
                            height: 1.25,
                          )
                        : Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  entry.uncertain
                      ? '-?'
                      : entry.impact == null
                      ? '—'
                      : entry.impact! >= 0
                      ? '+${entry.impact}'
                      : '${entry.impact}',
                  style: TextStyle(
                    fontFamily: compact ? ColonyFonts.familyTiny : null,
                    fontSize: compact ? 12 : 14,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.2,
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
      ],
    );
  }
}
