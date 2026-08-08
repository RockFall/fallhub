import 'package:flutter/material.dart';

import '../tokens/colony_tokens.dart';

enum ProvenanceDisplay {
  manual,
  imported,
  integration,
  inferred,
  ai,
  corrected,
  conflicted,
}

class DataProvenanceBadge extends StatelessWidget {
  const DataProvenanceBadge({super.key, required this.kind, this.compact = true});

  final ProvenanceDisplay kind;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final (label, icon) = switch (kind) {
      ProvenanceDisplay.manual => ('Manual', Icons.edit_outlined),
      ProvenanceDisplay.imported => ('Importado', Icons.upload_file),
      ProvenanceDisplay.integration => ('Integração', Icons.link),
      ProvenanceDisplay.inferred => ('Inferido', Icons.auto_awesome),
      ProvenanceDisplay.ai => ('IA', Icons.smart_toy_outlined),
      ProvenanceDisplay.corrected => ('Corrigido', Icons.build_circle_outlined),
      ProvenanceDisplay.conflicted => ('Conflito', Icons.warning_amber),
    };

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? ColonySpacing.sm : ColonySpacing.md,
        vertical: ColonySpacing.xs,
      ),
      decoration: BoxDecoration(
        color: ColonyColors.optionUnselected,
        border: Border.all(color: ColonyColors.borderStandard),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: ColonyColors.textSecondary),
          if (!compact) ...[
            const SizedBox(width: ColonySpacing.xs),
            Text(label, style: Theme.of(context).textTheme.bodySmall),
          ],
        ],
      ),
    );
  }
}
