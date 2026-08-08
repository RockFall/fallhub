import 'package:colony_domain/colony_domain.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/app_providers.dart';
import 'travel_providers.dart';

class TravelController extends AsyncNotifier<void> {
  @override
  Future<void> build() async {}

  Future<Trip?> create({
    required String title,
    List<String> destinations = const [],
    DateTime? startAt,
    DateTime? endAt,
    String? purpose,
    String? notes,
    TripStatus status = TripStatus.planned,
  }) async {
    state = const AsyncLoading();
    Trip? created;
    state = await AsyncValue.guard(() async {
      final profile = await ref.read(repositoriesProvider).profiles.getActive();
      if (profile == null) throw StateError('Perfil não configurado');
      created = await ref.read(repositoriesProvider).trips.create(
            profileId: profile.id,
            title: title,
            destinations: destinations,
            startAt: startAt,
            endAt: endAt,
            purpose: purpose,
            notes: notes,
            status: status,
          );
    });
    if (state.hasError) return null;
    ref.invalidate(tripsProvider);
    return created;
  }

  Future<Trip?> saveTrip(Trip trip) async {
    state = const AsyncLoading();
    Trip? updated;
    state = await AsyncValue.guard(() async {
      updated = await ref.read(repositoriesProvider).trips.save(trip);
    });
    if (state.hasError) return null;
    ref.invalidate(tripsProvider);
    return updated;
  }

  Future<Trip?> setStatus(Trip trip, TripStatus status) async {
    state = const AsyncLoading();
    Trip? updated;
    state = await AsyncValue.guard(() async {
      updated =
          await ref.read(repositoriesProvider).trips.setStatus(trip, status);
    });
    if (state.hasError) return null;
    ref.invalidate(tripsProvider);
    return updated;
  }

  Future<bool> linkInventory({
    required EntityId tripId,
    required EntityId inventoryItemId,
  }) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await ref.read(repositoriesProvider).trips.linkInventoryItem(
            tripId: tripId,
            inventoryItemId: inventoryItemId,
          );
    });
    if (state.hasError) return false;
    ref.invalidate(tripLinkedInventoryProvider(tripId.value));
    return true;
  }

  Future<bool> unlinkInventory({
    required EntityId tripId,
    required EntityId inventoryItemId,
  }) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await ref.read(repositoriesProvider).trips.unlinkInventoryItem(
            tripId: tripId,
            inventoryItemId: inventoryItemId,
          );
    });
    if (state.hasError) return false;
    ref.invalidate(tripLinkedInventoryProvider(tripId.value));
    return true;
  }
}

final travelControllerProvider =
    AsyncNotifierProvider<TravelController, void>(TravelController.new);
