import 'package:colony_design_system/colony_design_system.dart';
import 'package:colony_domain/colony_domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../app/localization/app_locale.dart';
import '../../../../app/localization/app_strings.dart';
import '../../application/work_providers.dart';

class ScheduleConflictPanel extends ConsumerWidget {
  const ScheduleConflictPanel({
    super.key,
    required this.day,
    required this.use24Hour,
    required this.locale,
  });

  final DateTime day;
  final bool use24Hour;
  final String locale;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final conflictsAsync = ref.watch(scheduleConflictsProvider(day));

    return conflictsAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (_, __) => Text(AppStrings.errorGeneric),
      data: (conflicts) {
        if (conflicts.isEmpty) {
          return const SizedBox.shrink();
        }

        final timeFormat = AppLocale.time(use24Hour: use24Hour, locale: locale);

        return ColonyPanel(
          title: AppStrings.scheduleConflicts,
          icon: Icons.warning_amber_outlined,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                AppStrings.scheduleConflictsHelp,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: ColonyColors.textSecondary,
                    ),
              ),
              const SizedBox(height: ColonySpacing.md),
              for (final conflict in conflicts)
                Padding(
                  padding: const EdgeInsets.only(bottom: ColonySpacing.sm),
                  child: _ConflictRow(
                    conflict: conflict,
                    timeFormat: timeFormat,
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

class _ConflictRow extends StatelessWidget {
  const _ConflictRow({
    required this.conflict,
    required this.timeFormat,
  });

  final ScheduleConflict conflict;
  final DateFormat timeFormat;

  @override
  Widget build(BuildContext context) {
    final overlapStart = timeFormat.format(conflict.overlapStart.toLocal());
    final overlapEnd = timeFormat.format(conflict.overlapEnd.toLocal());

    return Container(
      decoration: BoxDecoration(
        border: Border(
          left: const BorderSide(color: ColonyColors.statusCritical, width: 3),
          bottom: BorderSide(color: ColonyColors.borderSubtle.withValues(alpha: 0.5)),
        ),
      ),
      padding: const EdgeInsets.fromLTRB(
        ColonySpacing.md,
        ColonySpacing.sm,
        0,
        ColonySpacing.sm,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppStrings.scheduleConflictPair(
              conflict.itemA.label,
              conflict.itemB.label,
            ),
            style: Theme.of(context).textTheme.titleSmall,
          ),
          const SizedBox(height: ColonySpacing.xs),
          Text(
            AppStrings.scheduleConflictOverlap(
              overlapStart,
              overlapEnd,
              conflict.overlapDuration,
            ),
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: ColonyColors.textSecondary,
                ),
          ),
        ],
      ),
    );
  }
}
