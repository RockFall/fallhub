import 'id_generator.dart';

/// Which inventory item ids to link when copying packing from another trip.
abstract final class TripPackingCopyPolicy {
  /// Returns source item ids not already present on the target trip.
  static List<EntityId> missingItemIds({
    required Iterable<EntityId> sourceItemIds,
    required Iterable<EntityId> targetItemIds,
  }) {
    final present = targetItemIds.map((e) => e.value).toSet();
    final seen = <String>{};
    final missing = <EntityId>[];
    for (final id in sourceItemIds) {
      if (present.contains(id.value)) continue;
      if (!seen.add(id.value)) continue;
      missing.add(id);
    }
    return missing;
  }
}
