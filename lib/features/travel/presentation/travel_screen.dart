import 'package:colony_design_system/colony_design_system.dart';
import 'package:colony_domain/colony_domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/localization/app_strings.dart';
import '../application/travel_controllers.dart';
import '../application/travel_providers.dart';
import 'widgets/create_trip_sheet.dart';
import 'widgets/edit_trip_sheet.dart';

class TravelScreen extends ConsumerWidget {
  const TravelScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tripsAsync = ref.watch(tripsProvider);

    return Padding(
      padding: const EdgeInsets.all(ColonySpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            AppStrings.travelTitle,
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: ColonySpacing.sm),
          Text(
            AppStrings.travelDisclaimer,
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: ColonySpacing.lg),
          Expanded(
            child: tripsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (_, __) => Center(child: Text(AppStrings.errorGeneric)),
              data: (trips) {
                final visible = trips
                    .where((t) => !t.status.isHiddenFromActiveList)
                    .toList();
                if (visible.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(AppStrings.travelEmpty),
                        const SizedBox(height: ColonySpacing.sm),
                        Text(
                          AppStrings.travelEmptyHint,
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
                    final trip = visible[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: ColonySpacing.sm),
                      child: ListTile(
                        title: Text(trip.title),
                        subtitle: Text(
                          [
                            AppStrings.tripStatusLabel(trip.status),
                            if (trip.destinations.isNotEmpty)
                              trip.destinations.join(', '),
                            if (trip.purpose != null) trip.purpose!,
                          ].join(' · '),
                        ),
                        onTap: () => EditTripSheet.show(context, trip),
                        trailing: trip.status == TripStatus.completed
                            ? null
                            : IconButton(
                                tooltip: AppStrings.tripComplete,
                                icon: const Icon(Icons.check_circle_outline),
                                onPressed: () => ref
                                    .read(travelControllerProvider.notifier)
                                    .setStatus(trip, TripStatus.completed),
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
            onPressed: () => CreateTripSheet.show(context),
            icon: const Icon(Icons.add),
            label: Text(AppStrings.tripNew),
          ),
        ],
      ),
    );
  }
}
