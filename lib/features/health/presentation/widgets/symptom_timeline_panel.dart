import 'package:colony_design_system/colony_design_system.dart';
import 'package:colony_domain/colony_domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../app/localization/app_strings.dart';
import '../../application/health_providers.dart';
import 'log_symptom_entry_sheet.dart';

class SymptomTimelinePanel extends ConsumerWidget {
  const SymptomTimelinePanel({super.key, required this.condition});

  final HealthCondition condition;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final entriesAsync =
        ref.watch(symptomEntriesForConditionProvider(condition.id.value));
    final dateFormat = DateFormat.yMd().add_Hm();

    return ColonyPanel(
      title: AppStrings.healthSymptomTimeline,
      actions: [
        IconButton(
          tooltip: AppStrings.healthLogSymptom,
          icon: const Icon(Icons.add),
          onPressed: () => LogSymptomEntrySheet.show(context, condition),
        ),
      ],
      child: entriesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => Text(AppStrings.errorGeneric),
        data: (entries) {
          if (entries.isEmpty) {
            return Text(AppStrings.healthSymptomEmpty);
          }
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (final entry in entries.take(8))
                Padding(
                  padding: const EdgeInsets.only(bottom: ColonySpacing.sm),
                  child: Text(
                    [
                      dateFormat.format(entry.occurredAt.toLocal()),
                      AppStrings.healthSymptomIntensityValue(entry.intensity),
                      if (entry.bodyRegion != null) entry.bodyRegion!,
                      if (entry.note != null) entry.note!,
                    ].join(' · '),
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}
