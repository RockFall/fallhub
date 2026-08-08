import 'package:colony_design_system/colony_design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/localization/app_strings.dart';
import '../application/home_controllers.dart';
import '../application/home_providers.dart';
import 'widgets/create_home_maintenance_sheet.dart';
import 'widgets/edit_home_maintenance_sheet.dart';

class HomeMaintenanceScreen extends ConsumerWidget {
  const HomeMaintenanceScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tasksAsync = ref.watch(homeMaintenanceTasksProvider);

    return Padding(
      padding: const EdgeInsets.all(ColonySpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            AppStrings.homeMaintenanceTitle,
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: ColonySpacing.sm),
          Text(
            AppStrings.homeMaintenanceDisclaimer,
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: ColonySpacing.lg),
          Expanded(
            child: tasksAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (_, __) =>
                  Center(child: Text(AppStrings.errorGeneric)),
              data: (tasks) {
                final visible =
                    tasks.where((t) => !t.isArchived).toList();
                if (visible.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(AppStrings.homeMaintenanceEmpty),
                        const SizedBox(height: ColonySpacing.sm),
                        Text(
                          AppStrings.homeMaintenanceEmptyHint,
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
                    final task = visible[index];
                    return Card(
                      margin:
                          const EdgeInsets.only(bottom: ColonySpacing.sm),
                      child: ListTile(
                        title: Text(task.title),
                        subtitle: Text(
                          [
                            task.systemOrItem,
                            if (task.cadenceDays != null)
                              AppStrings.homeMaintenanceCadenceLabel(
                                task.cadenceDays!,
                              ),
                            if (task.nextDueAt != null)
                              AppStrings.homeMaintenanceNextDue(
                                task.nextDueAt!,
                              ),
                          ].join(' · '),
                        ),
                        onTap: () =>
                            EditHomeMaintenanceSheet.show(context, task),
                        trailing: IconButton(
                          tooltip: AppStrings.homeMaintenanceMarkDone,
                          icon: const Icon(Icons.check_circle_outline),
                          onPressed: () => ref
                              .read(homeControllerProvider.notifier)
                              .markDone(task),
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
            onPressed: () => CreateHomeMaintenanceSheet.show(context),
            icon: const Icon(Icons.add),
            label: Text(AppStrings.homeMaintenanceNew),
          ),
        ],
      ),
    );
  }
}
