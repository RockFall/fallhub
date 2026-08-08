import 'package:colony_domain/colony_domain.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/app_providers.dart';

final tripsProvider = StreamProvider<List<Trip>>((ref) async* {
  final profile = await ref.watch(profileProvider.future);
  if (profile == null) {
    yield [];
    return;
  }
  yield* ref.watch(repositoriesProvider).trips.watchAll(profile.id);
});

final tripLinkedInventoryProvider =
    StreamProvider.family<List<InventoryItem>, String>((ref, tripId) {
  return ref
      .watch(repositoriesProvider)
      .trips
      .watchLinkedInventory(EntityId(tripId));
});
