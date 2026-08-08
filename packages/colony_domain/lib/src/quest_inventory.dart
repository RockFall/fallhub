import 'package:equatable/equatable.dart';

import 'id_generator.dart';

/// N:N Quest↔InventoryItem link (Phase 8 lite).
class QuestInventoryLink extends Equatable {
  const QuestInventoryLink({
    required this.questId,
    required this.inventoryItemId,
    required this.linkedAt,
  });

  final EntityId questId;
  final EntityId inventoryItemId;
  final DateTime linkedAt;

  @override
  List<Object?> get props => [questId, inventoryItemId, linkedAt];
}
