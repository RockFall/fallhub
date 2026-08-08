import 'package:colony_design_system/colony_design_system.dart';
import 'package:colony_domain/colony_domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/localization/app_strings.dart';
import '../application/inventory_controllers.dart';
import '../application/inventory_providers.dart';
import 'widgets/create_inventory_item_sheet.dart';
import 'widgets/edit_inventory_item_sheet.dart';

class InventoryScreen extends ConsumerWidget {
  const InventoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final itemsAsync = ref.watch(inventoryItemsProvider);

    return Padding(
      padding: const EdgeInsets.all(ColonySpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            AppStrings.inventoryTitle,
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: ColonySpacing.sm),
          Text(
            AppStrings.inventoryHint,
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: ColonySpacing.lg),
          Expanded(
            child: itemsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (_, __) => Center(child: Text(AppStrings.errorGeneric)),
              data: (items) {
                final visible = items
                    .where((i) => !i.status.isHiddenFromActiveList)
                    .toList();
                if (visible.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(AppStrings.inventoryEmpty),
                        const SizedBox(height: ColonySpacing.sm),
                        Text(
                          AppStrings.inventoryEmptyHint,
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
                    final item = visible[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: ColonySpacing.sm),
                      child: ListTile(
                        title: Text(item.name),
                        subtitle: Text(
                          [
                            AppStrings.inventoryCategoryLabel(item.category),
                            AppStrings.inventoryStatusLabel(item.status),
                            if (item.locationLabel != null) item.locationLabel!,
                            if (item.purchasePriceMinor != null &&
                                item.purchaseCurrency != null)
                              AppStrings.inventoryPriceLabel(
                                item.purchasePriceMinor!,
                                item.purchaseCurrency!,
                              ),
                          ].join(' · '),
                        ),
                        onTap: () =>
                            EditInventoryItemSheet.show(context, item),
                        trailing: IconButton(
                          tooltip: AppStrings.inventoryArchive,
                          icon: const Icon(Icons.archive_outlined),
                          onPressed: () => ref
                              .read(inventoryControllerProvider.notifier)
                              .archive(item),
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
            onPressed: () => CreateInventoryItemSheet.show(context),
            icon: const Icon(Icons.add),
            label: Text(AppStrings.inventoryNewItem),
          ),
        ],
      ),
    );
  }
}
