import 'package:colony_design_system/colony_design_system.dart';
import 'package:colony_domain/colony_domain.dart';
import 'package:flutter/material.dart';

import '../../../../app/localization/app_strings.dart';

class FlashcardDueHero extends StatelessWidget {
  const FlashcardDueHero({
    super.key,
    required this.digest,
    required this.onStudy,
    this.onPractice,
    this.onLater,
    this.onTimebox,
  });

  final FlashcardTodayDigest digest;
  final VoidCallback onStudy;
  final VoidCallback? onPractice;
  final VoidCallback? onLater;
  final ValueChanged<int>? onTimebox;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final capped = digest.cappedForSession;
    final session = digest.sessionByBucket;
    return Semantics(
      container: true,
      identifier: 'flashcards.hero',
      label: AppStrings.flashcardsLearningToday,
      child: ColonyPanel(
        title: AppStrings.flashcardsHeroToday,
        icon: Icons.today_outlined,
        helpText: AppStrings.flashcardsTodayDigestHelp,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              capped == 0
                  ? AppStrings.flashcardsDueTodayZero
                  : AppStrings.flashcardsHeroStudyCount(capped),
              style: text.headlineMedium?.copyWith(
                fontWeight: FontWeight.w600,
                letterSpacing: -0.8,
              ),
            ),
            if (capped > 0) ...[
              const SizedBox(height: ColonySpacing.xs),
              Text(
                AppStrings.flashcardsMinutes(digest.estimatedMinutes),
                style: text.titleMedium?.copyWith(color: ColonyColors.accentCyan),
              ),
              const SizedBox(height: ColonySpacing.xs),
              Text(
                AppStrings.flashcardsSessionBuckets(
                  learning: session.learningCount,
                  review: session.reviewCount,
                  news: session.newCount,
                ),
                style: text.labelMedium?.copyWith(color: ColonyColors.textMuted),
              ),
            ],
            const SizedBox(height: ColonySpacing.md),
            Wrap(
              spacing: ColonySpacing.md,
              runSpacing: ColonySpacing.xs,
              children: [
                if (digest.dueLaterToday > 0)
                  _Chip(
                    label: AppStrings.flashcardsLaterToday,
                    value: digest.dueLaterToday,
                    onTap: onLater,
                  ),
                if (digest.limitDeferred > 0)
                  _Chip(
                    label: AppStrings.flashcardsLimitDeferred,
                    value: digest.limitDeferred,
                  ),
                if (digest.completedToday > 0)
                  _Chip(
                    label: AppStrings.flashcardsCompletedToday,
                    value: digest.completedToday,
                  ),
                if (digest.unscheduledCount > 0)
                  _Chip(
                    label: AppStrings.flashcardsUnscheduled,
                    value: digest.unscheduledCount,
                  ),
              ],
            ),
            const SizedBox(height: ColonySpacing.lg),
            FilledButton.icon(
              onPressed: capped == 0 ? null : onStudy,
              icon: const Icon(Icons.play_arrow_rounded),
              label: const Text(AppStrings.flashcardsStudyNow),
            ),
            if (onPractice != null && digest.unscheduledCount > 0) ...[
              const SizedBox(height: ColonySpacing.sm),
              OutlinedButton.icon(
                onPressed: onPractice,
                icon: const Icon(Icons.bolt_outlined),
                label: const Text(AppStrings.flashcardsPracticeSaved),
              ),
            ],
            if (onTimebox != null && capped > 0) ...[
              const SizedBox(height: ColonySpacing.sm),
              Wrap(
                spacing: ColonySpacing.sm,
                children: [
                  ActionChip(
                    label: const Text(AppStrings.flashcardsTimebox5),
                    onPressed: () => onTimebox!(5),
                  ),
                  ActionChip(
                    label: const Text(AppStrings.flashcardsTimebox10),
                    onPressed: () => onTimebox!(10),
                  ),
                  ActionChip(
                    label: const Text(AppStrings.flashcardsTimebox20),
                    onPressed: () => onTimebox!(20),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({required this.label, required this.value, this.onTap});

  final String label;
  final int value;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final child = Text(
      '$value $label',
      style: Theme.of(context).textTheme.labelMedium?.copyWith(
            color: onTap == null ? ColonyColors.textMuted : ColonyColors.accentCyan,
          ),
    );
    if (onTap == null) return child;
    return InkWell(onTap: onTap, child: child);
  }
}
