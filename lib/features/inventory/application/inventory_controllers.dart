import 'package:colony_domain/colony_domain.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/app_providers.dart';
import 'inventory_providers.dart';

class InventoryController extends AsyncNotifier<void> {
  @override
  Future<void> build() async {}

  Future<InventoryItem?> create({
    required String name,
    required InventoryCategory category,
    InventoryItemStatus status = InventoryItemStatus.active,
    String? locationLabel,
    String? notes,
    List<String> tags = const [],
    DateTime? purchaseDate,
    int? purchasePriceMinor,
    String? purchaseCurrency,
    DateTime? warrantyEnd,
  }) async {
    state = const AsyncLoading();
    InventoryItem? created;
    state = await AsyncValue.guard(() async {
      final profile = await ref.read(repositoriesProvider).profiles.getActive();
      if (profile == null) throw StateError('Perfil não configurado');
      created = await ref.read(repositoriesProvider).inventory.create(
            profileId: profile.id,
            name: name,
            category: category,
            status: status,
            locationLabel: locationLabel,
            notes: notes,
            tags: tags,
            purchaseDate: purchaseDate,
            purchasePriceMinor: purchasePriceMinor,
            purchaseCurrency: purchaseCurrency,
            warrantyEnd: warrantyEnd,
          );
    });
    if (state.hasError) return null;
    ref.invalidate(inventoryItemsProvider);
    return created;
  }

  Future<InventoryItem?> saveItem(InventoryItem item) async {
    state = const AsyncLoading();
    InventoryItem? updated;
    state = await AsyncValue.guard(() async {
      updated = await ref.read(repositoriesProvider).inventory.save(item);
    });
    if (state.hasError) return null;
    ref.invalidate(inventoryItemsProvider);
    return updated;
  }

  Future<InventoryItem?> archive(InventoryItem item) async {
    state = const AsyncLoading();
    InventoryItem? archived;
    state = await AsyncValue.guard(() async {
      archived = await ref.read(repositoriesProvider).inventory.archive(item);
    });
    if (state.hasError) return null;
    ref.invalidate(inventoryItemsProvider);
    return archived;
  }

  Future<bool> linkQuest({
    required EntityId inventoryItemId,
    required EntityId questId,
  }) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await ref.read(repositoriesProvider).inventory.linkQuest(
            questId: questId,
            inventoryItemId: inventoryItemId,
          );
    });
    if (state.hasError) return false;
    ref.invalidate(inventoryLinkedQuestsProvider(inventoryItemId.value));
    return true;
  }

  Future<bool> unlinkQuest({
    required EntityId inventoryItemId,
    required EntityId questId,
  }) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await ref.read(repositoriesProvider).inventory.unlinkQuest(
            questId: questId,
            inventoryItemId: inventoryItemId,
          );
    });
    if (state.hasError) return false;
    ref.invalidate(inventoryLinkedQuestsProvider(inventoryItemId.value));
    return true;
  }
}

final inventoryControllerProvider =
    AsyncNotifierProvider<InventoryController, void>(InventoryController.new);
