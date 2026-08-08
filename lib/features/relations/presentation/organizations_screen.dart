import 'package:colony_design_system/colony_design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/localization/app_strings.dart';
import '../application/relations_controllers.dart';
import '../application/relations_providers.dart';
import 'widgets/create_organization_sheet.dart';
import 'widgets/edit_organization_sheet.dart';

class OrganizationsScreen extends ConsumerWidget {
  const OrganizationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final orgsAsync = ref.watch(organizationsProvider);

    return Padding(
      padding: const EdgeInsets.all(ColonySpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            AppStrings.organizationsTitle,
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: ColonySpacing.sm),
          Text(
            AppStrings.organizationsDisclaimer,
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: ColonySpacing.lg),
          Expanded(
            child: orgsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (_, __) => Center(child: Text(AppStrings.errorGeneric)),
              data: (orgs) {
                final visible = orgs.where((o) => !o.isArchived).toList();
                if (visible.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(AppStrings.organizationsEmpty),
                        const SizedBox(height: ColonySpacing.sm),
                        Text(
                          AppStrings.organizationsEmptyHint,
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
                    final org = visible[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: ColonySpacing.sm),
                      child: ListTile(
                        title: Text(org.name),
                        subtitle: Text(
                          AppStrings.organizationKindLabel(org.kind),
                        ),
                        onTap: () => EditOrganizationSheet.show(context, org),
                        trailing: IconButton(
                          tooltip: AppStrings.organizationArchive,
                          icon: const Icon(Icons.archive_outlined),
                          onPressed: () => ref
                              .read(relationsControllerProvider.notifier)
                              .archiveOrganization(org),
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
            onPressed: () => CreateOrganizationSheet.show(context),
            icon: const Icon(Icons.add),
            label: Text(AppStrings.organizationNew),
          ),
        ],
      ),
    );
  }
}
