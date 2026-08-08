import 'package:colony_design_system/colony_design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/localization/app_strings.dart';
import '../application/zones_providers.dart';
import 'widgets/create_zone_sheet.dart';
import 'widgets/edit_zone_sheet.dart';

class ZonesScreen extends ConsumerWidget {
  const ZonesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final zonesAsync = ref.watch(contextZonesProvider);

    return Padding(
      padding: const EdgeInsets.all(ColonySpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            AppStrings.zonesTitle,
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: ColonySpacing.sm),
          Text(
            AppStrings.zonesDisclaimer,
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: ColonySpacing.lg),
          Expanded(
            child: zonesAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (_, __) =>
                  Center(child: Text(AppStrings.errorGeneric)),
              data: (zones) {
                final visible = zones.where((z) => !z.isArchived).toList();
                if (visible.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(AppStrings.zonesEmpty),
                        const SizedBox(height: ColonySpacing.sm),
                        Text(
                          AppStrings.zonesEmptyHint,
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
                    final z = visible[index];
                    return Card(
                      margin:
                          const EdgeInsets.only(bottom: ColonySpacing.sm),
                      child: ListTile(
                        title: Text(z.name),
                        subtitle: Text(
                          [
                            AppStrings.zoneConnectivityLabel(z.connectivity),
                            if (z.locationLabel != null) z.locationLabel!,
                            if (z.capabilities.isNotEmpty)
                              z.capabilities.join(', '),
                            if (z.unavailableWorkTypes.isNotEmpty)
                              AppStrings.zoneUnavailableWorkTypesLabel(
                                z.unavailableWorkTypes,
                              ),
                          ].join(' · '),
                        ),
                        onTap: () => EditZoneSheet.show(context, z),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          const SizedBox(height: ColonySpacing.md),
          FilledButton.icon(
            onPressed: () => CreateZoneSheet.show(context),
            icon: const Icon(Icons.add),
            label: Text(AppStrings.zoneNew),
          ),
        ],
      ),
    );
  }
}
