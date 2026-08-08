import 'package:colony_domain/colony_domain.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/app_providers.dart';
import 'zones_providers.dart';

class ZonesController extends AsyncNotifier<void> {
  @override
  Future<void> build() async {}

  Future<ContextZone?> create({
    required String name,
    String? locationLabel,
    List<String> capabilities = const [],
    List<String> unavailableWorkTypes = const [],
    ZoneConnectivity connectivity = ZoneConnectivity.unknown,
    String? notes,
  }) async {
    state = const AsyncLoading();
    ContextZone? created;
    state = await AsyncValue.guard(() async {
      final profile = await ref.read(repositoriesProvider).profiles.getActive();
      if (profile == null) throw StateError('Perfil não configurado');
      created = await ref.read(repositoriesProvider).contextZones.create(
            profileId: profile.id,
            name: name,
            locationLabel: locationLabel,
            capabilities: capabilities,
            unavailableWorkTypes: unavailableWorkTypes,
            connectivity: connectivity,
            notes: notes,
          );
    });
    if (state.hasError) return null;
    ref.invalidate(contextZonesProvider);
    return created;
  }

  Future<ContextZone?> save(ContextZone zone) async {
    state = const AsyncLoading();
    ContextZone? updated;
    state = await AsyncValue.guard(() async {
      updated = await ref.read(repositoriesProvider).contextZones.save(zone);
    });
    if (state.hasError) return null;
    ref.invalidate(contextZonesProvider);
    return updated;
  }

  Future<ContextZone?> archive(ContextZone zone) async {
    state = const AsyncLoading();
    ContextZone? archived;
    state = await AsyncValue.guard(() async {
      archived =
          await ref.read(repositoriesProvider).contextZones.archive(zone);
    });
    if (state.hasError) return null;
    ref.invalidate(contextZonesProvider);
    return archived;
  }

  Future<bool> linkTrip({
    required EntityId zoneId,
    required EntityId tripId,
  }) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await ref.read(repositoriesProvider).contextZones.linkTrip(
            zoneId: zoneId,
            tripId: tripId,
          );
    });
    if (state.hasError) return false;
    ref.invalidate(zoneLinkedTripsProvider(zoneId.value));
    return true;
  }

  Future<bool> unlinkTrip({
    required EntityId zoneId,
    required EntityId tripId,
  }) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await ref.read(repositoriesProvider).contextZones.unlinkTrip(
            zoneId: zoneId,
            tripId: tripId,
          );
    });
    if (state.hasError) return false;
    ref.invalidate(zoneLinkedTripsProvider(zoneId.value));
    return true;
  }
}

final zonesControllerProvider =
    AsyncNotifierProvider<ZonesController, void>(ZonesController.new);
