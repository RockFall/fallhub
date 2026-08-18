import 'package:colony_design_system/colony_design_system.dart';
import 'package:colony_domain/colony_domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../app/localization/app_strings.dart';
import '../../../../core/providers/app_providers.dart';
import '../../application/flashcard_providers.dart';

class FlashcardPacePanel extends ConsumerStatefulWidget {
  const FlashcardPacePanel({super.key});

  @override
  ConsumerState<FlashcardPacePanel> createState() => _FlashcardPacePanelState();
}

class _FlashcardPacePanelState extends ConsumerState<FlashcardPacePanel> {
  final _perDay = TextEditingController();
  final _days = TextEditingController();
  var _daysSeeded = false;
  var _perDaySeeded = false;

  @override
  void dispose() {
    _perDay.dispose();
    _days.dispose();
    super.dispose();
  }

  void _seed(FlashcardPaceMetrics metrics) {
    if (!_daysSeeded) {
      _daysSeeded = true;
      _days.text = '30';
    }
    if (!_perDaySeeded && metrics.suggestedCardsPerDay > 0) {
      _perDaySeeded = true;
      _perDay.text = '${metrics.suggestedCardsPerDay}';
    }
  }

  int _parse(TextEditingController controller) {
    return int.tryParse(controller.text.trim()) ?? 0;
  }

  @override
  Widget build(BuildContext context) {
    final metrics = ref.watch(flashcardPaceMetricsProvider);
    final logs = ref.watch(flashcardLogsProvider).asData?.value ?? const [];
    final now = ref.watch(clockProvider)();
    _seed(metrics);
    final perDay = _parse(_perDay);
    final targetDays = _parse(_days);
    final forecast = FlashcardPacePolicy.forecast(
      metrics: metrics,
      cardsPerDay: perDay,
      now: now,
      logs: logs,
    );
    final recommended = FlashcardPacePolicy.recommendCardsPerDay(
      reviewsRemaining: metrics.reviewsRemaining,
      targetDays: targetDays,
    );
    final dateLabel = forecast.finishOn == null
        ? ''
        : DateFormat('dd/MM/yyyy').format(forecast.finishOn!);
    final text = Theme.of(context).textTheme;

    return ColonyPanel(
      title: AppStrings.flashcardsPaceTitle,
      icon: Icons.speed_outlined,
      helpText: AppStrings.flashcardsPaceHelp,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Wrap(
            spacing: ColonySpacing.md,
            runSpacing: ColonySpacing.sm,
            children: [
              _Stat(
                label: AppStrings.flashcardsPaceMeanTime,
                value: metrics.meanDurationMs == null
                    ? '—'
                    : FlashcardPacePolicy.formatDurationMs(
                        metrics.meanDurationMs!,
                      ),
              ),
              _Stat(
                label: AppStrings.flashcardsPaceCardsDay,
                value: metrics.hasPaceSample
                    ? metrics.meanCardsPerActiveDay.toStringAsFixed(1)
                    : '—',
              ),
              _Stat(
                label: AppStrings.flashcardsPaceReviewsDay,
                value: metrics.hasPaceSample
                    ? metrics.meanReviewsPerActiveDay.toStringAsFixed(1)
                    : '—',
              ),
              _Stat(
                label: AppStrings.flashcardsPaceRepetitions,
                value: metrics.meanRepetitions.toStringAsFixed(1),
              ),
              _Stat(
                label: AppStrings.flashcardsPaceLapses,
                value: metrics.meanLapses.toStringAsFixed(1),
              ),
              _Stat(
                label: AppStrings.flashcardsPaceReviewsPerCard,
                value: metrics.reviewsPerCard.toStringAsFixed(1),
              ),
              _Stat(
                label: AppStrings.flashcardsPaceAgainRate,
                value: AppStrings.flashcardsPacePercent(metrics.againRate),
              ),
            ],
          ),
          const SizedBox(height: ColonySpacing.md),
          Text(
            '${AppStrings.flashcardsPaceRemaining}: '
            '${AppStrings.flashcardsPaceRemainingCount(
              remaining: metrics.remainingToGraduate,
              reviews: metrics.reviewsRemaining,
            )}',
            style: text.bodyMedium,
          ),
          if (!metrics.hasPaceSample && !metrics.hasDurationSample) ...[
            const SizedBox(height: ColonySpacing.sm),
            Text(
              AppStrings.flashcardsPaceNoSample,
              style: text.bodySmall?.copyWith(color: ColonyColors.textMuted),
            ),
          ],
          const SizedBox(height: ColonySpacing.md),
          TextField(
            key: const Key('flashcards.pace.per_day'),
            controller: _perDay,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: const InputDecoration(
              labelText: AppStrings.flashcardsPaceTargetPerDay,
            ),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: ColonySpacing.sm),
          Text(
            metrics.reviewsRemaining == 0
                ? AppStrings.flashcardsPaceAllDone
                : forecast.days == null
                    ? AppStrings.flashcardsPaceNeedSample
                    : AppStrings.flashcardsPaceFinishIn(
                        forecast.days!,
                        dateLabel,
                      ),
            style: text.titleSmall?.copyWith(color: ColonyColors.accentCyan),
          ),
          if (forecast.days != null && forecast.cardsPerDay > 0) ...[
            const SizedBox(height: ColonySpacing.xs),
            Text(
              AppStrings.flashcardsMinutes(forecast.estimatedMinutesPerDay),
              style: text.bodySmall?.copyWith(color: ColonyColors.textMuted),
            ),
          ],
          const SizedBox(height: ColonySpacing.md),
          TextField(
            key: const Key('flashcards.pace.days'),
            controller: _days,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: const InputDecoration(
              labelText: AppStrings.flashcardsPaceTargetDays,
            ),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: ColonySpacing.sm),
          Wrap(
            spacing: ColonySpacing.sm,
            children: [
              for (final days in const [7, 14, 30, 60])
                ActionChip(
                  label: Text('$days d'),
                  onPressed: () => setState(() => _days.text = '$days'),
                ),
            ],
          ),
          const SizedBox(height: ColonySpacing.sm),
          Text(
            AppStrings.flashcardsPaceRecommend(
              recommended,
              targetDays < 1 ? 0 : targetDays,
            ),
            style: text.titleSmall?.copyWith(color: ColonyColors.accentCyan),
          ),
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: text.labelSmall?.copyWith(color: ColonyColors.textMuted),
        ),
        Text(value, style: text.titleMedium),
      ],
    );
  }
}
