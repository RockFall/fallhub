import 'package:colony_design_system/colony_design_system.dart';
import 'package:colony_domain/colony_domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/localization/app_strings.dart';
import '../../../travel/application/travel_providers.dart';
import '../../application/zones_controllers.dart';
import '../../application/zones_providers.dart';

class ZoneLinkedTripsSection extends ConsumerWidget {
  const ZoneLinkedTripsSection({super.key, required this.zone});

  final ContextZone zone;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final linked = ref.watch(zoneLinkedTripsProvider(zone.id.value));
    final allTrips = ref.watch(tripsProvider);

    return Padding(
      padding: const EdgeInsets.only(top: ColonySpacing.md),
      child: ColonyPanel(
        title: AppStrings.zoneLinkedTrips,
        icon: Icons.flight_takeoff_outlined,
        actions: [
          IconButton(
            tooltip: AppStrings.zoneLinkTrip,
            icon: const Icon(Icons.link, size: 20),
            onPressed: () async {
              final current = linked.maybeWhen(
                data: (trips) => trips,
                orElse: () => const <Trip>[],
              );
              final available = allTrips.maybeWhen(
                data: (trips) => trips
                    .where(
                      (t) =>
                          !t.status.isHiddenFromActiveList &&
                          !current.any((c) => c.id == t.id),
                    )
                    .toList(),
                orElse: () => const <Trip>[],
              );
              if (available.isEmpty) {
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(AppStrings.zoneTripPickerEmpty),
                  ),
                );
                return;
              }
              final selected = await showDialog<Trip>(
                context: context,
                builder: (ctx) => SimpleDialog(
                  title: const Text(AppStrings.zoneLinkTrip),
                  children: available
                      .map(
                        (trip) => SimpleDialogOption(
                          onPressed: () => Navigator.pop(ctx, trip),
                          child: Text(trip.title),
                        ),
                      )
                      .toList(),
                ),
              );
              if (selected == null) return;
              await ref.read(zonesControllerProvider.notifier).linkTrip(
                    zoneId: zone.id,
                    tripId: selected.id,
                  );
            },
          ),
        ],
        child: linked.when(
          loading: () => const Text(AppStrings.loading),
          error: (_, __) => const Text(AppStrings.errorGeneric),
          data: (trips) {
            if (trips.isEmpty) {
              return Text(
                AppStrings.zoneNoLinkedTrips,
                style: Theme.of(context).textTheme.bodyMedium,
              );
            }
            return Column(
              children: trips
                  .map(
                    (trip) => ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(trip.title),
                      trailing: IconButton(
                        tooltip: AppStrings.zoneUnlinkTrip,
                        icon: const Icon(Icons.link_off, size: 20),
                        onPressed: () => ref
                            .read(zonesControllerProvider.notifier)
                            .unlinkTrip(
                              zoneId: zone.id,
                              tripId: trip.id,
                            ),
                      ),
                    ),
                  )
                  .toList(),
            );
          },
        ),
      ),
    );
  }
}
