import 'package:colony_design_system/colony_design_system.dart';
import 'package:colony_domain/colony_domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/localization/app_strings.dart';
import '../application/health_controllers.dart';
import '../application/health_providers.dart';
import 'widgets/create_health_appointment_sheet.dart';
import 'widgets/create_health_condition_sheet.dart';
import 'widgets/edit_health_appointment_sheet.dart';
import 'widgets/edit_health_condition_sheet.dart';

class HealthScreen extends ConsumerWidget {
  const HealthScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final conditionsAsync = ref.watch(healthConditionsProvider);
    final appointmentsAsync = ref.watch(healthAppointmentsProvider);

    return Padding(
      padding: const EdgeInsets.all(ColonySpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            AppStrings.healthTitle,
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: ColonySpacing.sm),
          _HealthDisclaimerBanner(),
          const SizedBox(height: ColonySpacing.sm),
          Text(
            AppStrings.healthSeekCareHint,
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: ColonySpacing.lg),
          Text(
            AppStrings.healthAppointmentsTitle,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: ColonySpacing.xs),
          Text(
            AppStrings.healthAppointmentsHint,
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: ColonySpacing.sm),
          appointmentsAsync.when(
            loading: () => const LinearProgressIndicator(),
            error: (_, __) => Text(AppStrings.errorGeneric),
            data: (appointments) {
              final visible = appointments
                  .where((a) => !a.status.isHiddenFromActiveList)
                  .toList();
              if (visible.isEmpty) {
                return Text(
                  AppStrings.healthAppointmentsEmpty,
                  style: Theme.of(context).textTheme.bodyMedium,
                );
              }
              return Column(
                children: [
                  for (final a in visible.take(5))
                    Card(
                      margin: const EdgeInsets.only(bottom: ColonySpacing.sm),
                      child: ListTile(
                        title: Text(a.title),
                        subtitle: Text(
                          [
                            a.scheduledAt.toLocal().toIso8601String(),
                            if (a.locationLabel != null) a.locationLabel!,
                          ].join(' · '),
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              tooltip: AppStrings.healthEditAppointment,
                              icon: const Icon(Icons.edit_outlined),
                              onPressed: () => EditHealthAppointmentSheet.show(
                                context,
                                a,
                              ),
                            ),
                            IconButton(
                              tooltip: AppStrings.healthAppointmentMarkCancelled,
                              icon: const Icon(Icons.cancel_outlined),
                              onPressed: () => ref
                                  .read(healthControllerProvider.notifier)
                                  .markAppointmentCancelled(a),
                            ),
                            IconButton(
                              tooltip: AppStrings.healthAppointmentMarkDone,
                              icon: const Icon(Icons.check_circle_outline),
                              onPressed: () => ref
                                  .read(healthControllerProvider.notifier)
                                  .markAppointmentDone(a),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: () => CreateHealthAppointmentSheet.show(context),
              icon: const Icon(Icons.event_available_outlined),
              label: Text(AppStrings.healthNewAppointment),
            ),
          ),
          const SizedBox(height: ColonySpacing.md),
          Expanded(
            child: conditionsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (_, __) => Center(child: Text(AppStrings.errorGeneric)),
              data: (conditions) {
                final visible = conditions
                    .where((c) => c.status != HealthConditionStatus.archived)
                    .toList();
                if (visible.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(AppStrings.healthEmpty),
                        const SizedBox(height: ColonySpacing.sm),
                        Text(
                          AppStrings.healthEmptyHint,
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  );
                }
                return ListView.builder(
                  itemCount: visible.length,
                  itemBuilder: (context, index) {
                    final condition = visible[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: ColonySpacing.sm),
                      child: ListTile(
                        title: Text(condition.title),
                        subtitle: Text(
                          [
                            AppStrings.healthConditionTypeLabel(condition.type),
                            AppStrings.healthConditionStatusLabel(
                              condition.status,
                            ),
                            if (condition.severityUserReported != null)
                              AppStrings.healthSeverityValue(
                                condition.severityUserReported!,
                              ),
                          ].join(' · '),
                        ),
                        onTap: () => EditHealthConditionSheet.show(
                          context,
                          condition,
                        ),
                        trailing: condition.status.isTerminal
                            ? null
                            : IconButton(
                                tooltip: AppStrings.healthArchive,
                                icon: const Icon(Icons.archive_outlined),
                                onPressed: () => ref
                                    .read(healthControllerProvider.notifier)
                                    .archive(condition),
                              ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          const SizedBox(height: ColonySpacing.md),
          FilledButton.icon(
            onPressed: () => CreateHealthConditionSheet.show(context),
            icon: const Icon(Icons.add),
            label: Text(AppStrings.healthNewCondition),
          ),
        ],
      ),
    );
  }
}

class _HealthDisclaimerBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(ColonySpacing.md),
      decoration: BoxDecoration(
        color: ColonyColors.panel,
        border: Border.all(color: ColonyColors.borderStandard),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.info_outline,
            size: 20,
            color: ColonyColors.textMuted,
          ),
          const SizedBox(width: ColonySpacing.sm),
          Expanded(
            child: Text(
              AppStrings.healthDisclaimer,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
        ],
      ),
    );
  }
}
