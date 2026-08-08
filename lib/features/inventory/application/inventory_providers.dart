import 'package:colony_domain/colony_domain.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/app_providers.dart';

final inventoryItemsProvider =
    StreamProvider<List<InventoryItem>>((ref) async* {
  final profile = await ref.watch(profileProvider.future);
  if (profile == null) {
    yield [];
    return;
  }
  yield* ref.watch(repositoriesProvider).inventory.watchAll(profile.id);
});

final inventoryLinkedQuestsProvider =
    StreamProvider.family<List<Quest>, String>((ref, itemId) {
  return ref
      .watch(repositoriesProvider)
      .inventory
      .watchLinkedQuests(EntityId(itemId));
});
