import 'package:colony_design_system/colony_design_system.dart';
import 'package:colony_domain/colony_domain.dart';
import 'package:flutter/material.dart';

import '../../../../app/localization/app_strings.dart';

class FlashcardDueHero extends StatelessWidget {
  const FlashcardDueHero({
    super.key,
    required this.counts,
    required this.onStudy,
  });

  final FlashcardQueueCounts counts;
  final VoidCallback onStudy;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return ColonyPanel(
      title: AppStrings.flashcardsTitle,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            AppStrings.flashcardsSubtitle,
            style: text.bodySmall?.copyWith(color: ColonyColors.textMuted),
          ),
          const SizedBox(height: ColonySpacing.lg),
          Row(
            children: [
              _Stat(label: AppStrings.flashcardsDue, value: counts.reviewCount),
              _Stat(
                label: AppStrings.flashcardsLearning,
                value: counts.learningCount,
              ),
              _Stat(label: AppStrings.flashcardsNew, value: counts.newCount),
            ],
          ),
          const SizedBox(height: ColonySpacing.lg),
          FilledButton.icon(
            onPressed: counts.dueTotal == 0 ? null : onStudy,
            icon: const Icon(Icons.play_arrow_rounded),
            label: Text(AppStrings.flashcardsStudyNow),
          ),
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.label, required this.value});

  final String label;
  final int value;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text(
            '$value',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  letterSpacing: -0.8,
                ),
          ),
          const SizedBox(height: ColonySpacing.xs),
          Text(
            label,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: ColonyColors.textMuted,
                ),
          ),
        ],
      ),
    );
  }
}
