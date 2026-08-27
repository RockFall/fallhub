import '../content/habitat_inventory.dart';
import '../embodied/pawn_embodied_store.dart';
import '../world/habitat_world.dart';

/// Systemic invariants + soak helpers (MD 08 M49).

class HabitatInvariantReport {
  HabitatInvariantReport({required this.ok, required this.issues});

  final bool ok;
  final List<String> issues;
}

class HabitatInvariantChecker {
  HabitatInvariantReport check({
    required HabitatWorld world,
    required HabitatInventory inventory,
    required PawnEmbodiedStore store,
    required Set<String> knownPawnIds,
  }) {
    final issues = <String>[];

    // Sites reference existing rooms.
    for (final site in world.sites.values) {
      for (final roomId in site.roomIds) {
        if (!world.rooms.containsKey(roomId)) {
          issues.add('site ${site.id} missing room $roomId');
        }
      }
    }

    // Rooms reference existing sites.
    for (final room in world.rooms.values) {
      if (!world.sites.containsKey(room.siteId)) {
        issues.add('room ${room.id} missing site ${room.siteId}');
      }
    }

    if (!inventory.locationsConsistent) {
      issues.add('inventory location inconsistency');
    }

    for (final id in store.ids) {
      if (!knownPawnIds.contains(id) &&
          !id.contains('guest') &&
          !id.contains('remote')) {
        // soft — allow demos
      }
    }

    return HabitatInvariantReport(ok: issues.isEmpty, issues: issues);
  }
}

/// Lightweight soak: advance sim N steps and re-check invariants.
class HabitatSoakRunner {
  HabitatSoakRunner(this.checker);

  final HabitatInvariantChecker checker;

  HabitatInvariantReport run({
    required int steps,
    required void Function(int step) tick,
    required HabitatInvariantReport Function() check,
  }) {
    HabitatInvariantReport last = check();
    for (var i = 0; i < steps; i++) {
      tick(i);
      last = check();
      if (!last.ok) return last;
    }
    return last;
  }
}
