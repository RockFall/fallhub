import '../content/habitat_inventory.dart';
import '../identity/identity.dart';

/// Find / return / prefer items (MD 10 R25–R27).
abstract final class ItemSeekResolver {
  /// Last known location + preferred home for return.
  static HabitatItemLocation? lastKnown(
    HabitatInventory inv,
    String itemId,
  ) =>
      inv.items[itemId]?.location;

  static bool returnHome(HabitatInventory inv, String itemId) =>
      inv.returnToPreferred(itemId);

  /// Pick preferred exemplar among candidates (R27).
  static String? preferExemplar({
    required List<String> candidateIds,
    required String pawnId,
    required Map<String, int> usageByPawnItem,
    String? favoriteId,
    Set<String> unavailable = const {},
  }) {
    final available =
        candidateIds.where((id) => !unavailable.contains(id)).toList();
    if (available.isEmpty) return null;
    if (favoriteId != null && available.contains(favoriteId)) {
      // Tendency, not lock — 70% stick.
      final h = Object.hash(pawnId, favoriteId, available.length);
      if ((h.abs() % 100) < 70) return favoriteId;
    }
    available.sort((a, b) {
      final ua = usageByPawnItem['$pawnId::$a'] ?? 0;
      final ub = usageByPawnItem['$pawnId::$b'] ?? 0;
      return ub.compareTo(ua);
    });
    return available.first;
  }

  /// Organized pawns get bonus utility for returning items home.
  static double returnHomeUtility({
    required BehaviorProfile? profile,
    required bool itemAwayFromHome,
  }) {
    if (!itemAwayFromHome) return 0;
    final c = profile?.conscientiousness ?? 0.5;
    return 0.15 + c * 0.45;
  }
}

/// Seek pipeline result (R26).
class ItemSeekResult {
  const ItemSeekResult({
    required this.itemId,
    this.location,
    this.found = false,
    this.cancelReason,
  });

  final String itemId;
  final HabitatItemLocation? location;
  final bool found;
  final String? cancelReason;
}

abstract final class ItemSeekPipeline {
  static ItemSeekResult resolve({
    required HabitatInventory inv,
    required String itemId,
  }) {
    final item = inv.items[itemId];
    if (item == null) {
      return ItemSeekResult(
        itemId: itemId,
        found: false,
        cancelReason: 'item_missing',
      );
    }
    return ItemSeekResult(
      itemId: itemId,
      location: item.location,
      found: true,
    );
  }
}
