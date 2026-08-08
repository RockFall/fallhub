import 'package:colony_domain/colony_domain.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/app_providers.dart';

final contextZonesProvider = StreamProvider<List<ContextZone>>((ref) async* {
  final profile = await ref.watch(profileProvider.future);
  if (profile == null) {
    yield [];
    return;
  }
  yield* ref.watch(repositoriesProvider).contextZones.watchAll(profile.id);
});

final zoneLinkedTripsProvider =
    StreamProvider.family<List<Trip>, String>((ref, zoneId) {
  return ref
      .watch(repositoriesProvider)
      .contextZones
      .watchLinkedTrips(EntityId(zoneId));
});
