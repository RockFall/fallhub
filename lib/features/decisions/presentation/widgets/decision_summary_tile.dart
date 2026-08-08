import 'package:colony_design_system/colony_design_system.dart';
import 'package:colony_domain/colony_domain.dart';
import 'package:flutter/material.dart';

import '../../../../app/localization/app_strings.dart';

class DecisionSummaryTile extends StatelessWidget {
  const DecisionSummaryTile({
    super.key,
    required this.decision,
    this.onTap,
    this.trailing,
  });

  final DecisionRecord decision;
  final VoidCallback? onTap;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(decision.title),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: ColonySpacing.xs),
          Text(
            decision.decision,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: ColonySpacing.xs),
          Chip(
            label: Text(
              AppStrings.decisionReversibilityLabel(decision.reversibility),
              style: theme.textTheme.labelSmall,
            ),
            visualDensity: VisualDensity.compact,
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
        ],
      ),
      trailing: trailing,
      onTap: onTap,
    );
  }
}
