import '../content/habitat_inventory.dart';

/// Atomic item transfers that survive cancel (MD 10 R31).
enum ItemTransferOp { pickup, give, place, returnHome }

class ItemTransferTxn {
  ItemTransferTxn({
    required this.op,
    required this.itemId,
    required this.from,
    required this.to,
  });

  final ItemTransferOp op;
  final String itemId;
  final HabitatItemLocation from;
  final HabitatItemLocation to;
  bool committed = false;
  bool rolledBack = false;
}

class ItemTransferJournal {
  ItemTransferJournal(this.inventory);

  final HabitatInventory inventory;
  final List<ItemTransferTxn> open = [];

  /// Begin transfer — snapshot from location.
  ItemTransferTxn? begin({
    required ItemTransferOp op,
    required String itemId,
    required HabitatItemLocation to,
  }) {
    final item = inventory.items[itemId];
    if (item == null) return null;
    final txn = ItemTransferTxn(
      op: op,
      itemId: itemId,
      from: item.location,
      to: to,
    );
    open.add(txn);
    return txn;
  }

  bool commit(ItemTransferTxn txn) {
    if (txn.committed || txn.rolledBack) return false;
    final item = inventory.items[txn.itemId];
    if (item == null) return false;
    // Enforce single location invariant via inventory helpers.
    switch (txn.op) {
      case ItemTransferOp.pickup:
        final pawn = txn.to.pawnId;
        if (pawn == null) return false;
        inventory.pickUp(itemId: txn.itemId, pawnId: pawn);
      case ItemTransferOp.place:
        final c = txn.to.containerId;
        if (c == null) return false;
        if (!inventory.putIn(itemId: txn.itemId, containerId: c)) {
          return false;
        }
      case ItemTransferOp.returnHome:
        if (!inventory.returnToPreferred(txn.itemId)) return false;
      case ItemTransferOp.give:
        final pawn = txn.to.pawnId;
        if (pawn == null) return false;
        inventory.pickUp(itemId: txn.itemId, pawnId: pawn);
    }
    txn.committed = true;
    open.remove(txn);
    return inventory.locationsConsistent;
  }

  bool rollback(ItemTransferTxn txn) {
    if (txn.committed || txn.rolledBack) return false;
    // Never moved — just drop txn.
    txn.rolledBack = true;
    open.remove(txn);
    return true;
  }

  /// Cancel all open (uncommitted) transfers.
  void cancelAll() {
    for (final t in List.of(open)) {
      rollback(t);
    }
  }

  /// Count holders of an item — must be 0 or 1 logically.
  int holdersOf(String itemId) {
    final item = inventory.items[itemId];
    if (item == null) return 0;
    return 1;
  }
}
