import 'package:colony_design_system/colony_design_system.dart';
import 'package:colony_domain/colony_domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/localization/app_strings.dart';
import '../../../inventory/application/inventory_providers.dart';
import '../../application/travel_controllers.dart';
import '../../application/travel_providers.dart';

class TripPackingListSection extends ConsumerWidget {
  const TripPackingListSection({super.key, required this.trip});

  final Trip trip;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final linked = ref.watch(tripLinkedInventoryProvider(trip.id.value));
    final allItems = ref.watch(inventoryItemsProvider);

    return Padding(
      padding: const EdgeInsets.only(top: ColonySpacing.md),
      child: ColonyPanel(
        title: AppStrings.tripPackingList,
        icon: Icons.luggage_outlined,
        actions: [
          IconButton(
            tooltip: AppStrings.tripLinkInventoryItem,
            icon: const Icon(Icons.link, size: 20),
            onPressed: () async {
              final current = linked.maybeWhen(
                data: (items) => items,
                orElse: () => const <InventoryItem>[],
              );
              final available = allItems.maybeWhen(
                data: (items) => items
                    .where(
                      (item) =>
                          !item.status.isHiddenFromActiveList &&
                          !current.any((c) => c.id == item.id),
                    )
                    .toList(),
                orElse: () => const <InventoryItem>[],
              );
              if (available.isEmpty) {
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(AppStrings.tripInventoryPickerEmpty),
                  ),
                );
                return;
              }
              final selected = await showDialog<InventoryItem>(
                context: context,
                builder: (ctx) => SimpleDialog(
                  title: const Text(AppStrings.tripLinkInventoryItem),
                  children: available
                      .map(
                        (item) => SimpleDialogOption(
                          onPressed: () => Navigator.pop(ctx, item),
                          child: Text(item.name),
                        ),
                      )
                      .toList(),
                ),
              );
              if (selected == null) return;
              await ref.read(travelControllerProvider.notifier).linkInventory(
                    tripId: trip.id,
                    inventoryItemId: selected.id,
                  );
            },
          ),
        ],
        child: linked.when(
          loading: () => const Text(AppStrings.loading),
          error: (_, __) => const Text(AppStrings.errorGeneric),
          data: (items) {
            if (items.isEmpty) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    AppStrings.tripNoPackingItems,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: ColonySpacing.xs),
                  Text(
                    AppStrings.tripPackingEmptyHint,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              );
            }
            return Column(
              children: items
                  .map(
                    (item) => ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(item.name),
                      trailing: IconButton(
                        tooltip: AppStrings.tripUnlinkInventoryItem,
                        icon: const Icon(Icons.link_off, size: 20),
                        onPressed: () => ref
                            .read(travelControllerProvider.notifier)
                            .unlinkInventory(
                              tripId: trip.id,
                              inventoryItemId: item.id,
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
