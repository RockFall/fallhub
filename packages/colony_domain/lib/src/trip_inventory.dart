import 'package:equatable/equatable.dart';

import 'id_generator.dart';

/// N:N Trip↔InventoryItem packing list link (Phase 8 depth / §26.1 stub).
class TripInventoryLink extends Equatable {
  const TripInventoryLink({
    required this.tripId,
    required this.inventoryItemId,
    required this.linkedAt,
  });

  final EntityId tripId;
  final EntityId inventoryItemId;
  final DateTime linkedAt;

  @override
  List<Object?> get props => [tripId, inventoryItemId, linkedAt];
}
