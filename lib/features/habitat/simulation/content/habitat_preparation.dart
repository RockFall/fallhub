import 'habitat_inventory.dart';

/// What a context/appointment expects the pawn to bring (MD 08 M39).
enum PrepRequirementMode { required, optional }

class PreparationRequirement {
  const PreparationRequirement({
    required this.itemTag,
    this.mode = PrepRequirementMode.required,
    this.quantity = 1,
    this.preferredStorage,
    this.reasonTag,
  });

  final String itemTag;
  final PrepRequirementMode mode;
  final int quantity;
  final String? preferredStorage;
  final String? reasonTag;
}

class PreparationPlan {
  const PreparationPlan({
    required this.contextId,
    required this.requirements,
  });

  final String contextId;
  final List<PreparationRequirement> requirements;
}

class PrepCheckResult {
  const PrepCheckResult({
    required this.satisfied,
    required this.missingRequired,
    required this.missingOptional,
    this.collectedItemIds = const [],
  });

  final bool satisfied;
  final List<String> missingRequired;
  final List<String> missingOptional;
  final List<String> collectedItemIds;
}

/// Resolves prep kits against virtual inventory (M39).
class PreparationDirector {
  final Map<String, PreparationPlan> plans = {
    'work': const PreparationPlan(
      contextId: 'work',
      requirements: [
        PreparationRequirement(itemTag: 'laptop', reasonTag: 'work'),
        PreparationRequirement(
          itemTag: 'bag',
          mode: PrepRequirementMode.optional,
        ),
      ],
    ),
    'travel': const PreparationPlan(
      contextId: 'travel',
      requirements: [
        PreparationRequirement(itemTag: 'passport', reasonTag: 'travel'),
        PreparationRequirement(itemTag: 'suitcase', reasonTag: 'travel'),
      ],
    ),
    'exercise': const PreparationPlan(
      contextId: 'exercise',
      requirements: [
        PreparationRequirement(
          itemTag: 'waterBottle',
          mode: PrepRequirementMode.optional,
        ),
        PreparationRequirement(itemTag: 'trainingClothes'),
      ],
    ),
    'music': const PreparationPlan(
      contextId: 'music',
      requirements: [
        PreparationRequirement(itemTag: 'instrument'),
        PreparationRequirement(
          itemTag: 'score',
          mode: PrepRequirementMode.optional,
        ),
      ],
    ),
  };

  final List<String> debugLog = [];

  void seedPrepItems(HabitatInventory inventory) {
    if (inventory.items.containsKey('laptop.demo')) return;
    inventory.containers.putIfAbsent(
      'deskDrawer',
      () => HabitatStorageContainer(
        id: 'deskDrawer',
        kind: 'deskDrawer',
        capacity: 4,
      )..ensureSlots(),
    );
    inventory.putNew(
      HabitatItem(
        id: 'laptop.demo',
        label: 'Notebook',
        tags: {'laptop', 'electronics'},
        location: HabitatItemLocation.storage('deskDrawer', '0'),
        preferredStorageId: 'deskDrawer',
      ),
    );
    inventory.putNew(
      HabitatItem(
        id: 'passport.demo',
        label: 'Passaporte',
        tags: {'passport', 'document'},
        location: HabitatItemLocation.storage('wardrobe', '1'),
        preferredStorageId: 'wardrobe',
      ),
    );
    inventory.putNew(
      HabitatItem(
        id: 'water.demo',
        label: 'Garrafa',
        tags: {'waterBottle'},
        location: HabitatItemLocation.surface('table', '1'),
      ),
    );
  }

  PrepCheckResult check({
    required String contextId,
    required HabitatInventory inventory,
    required String pawnId,
    bool collect = false,
  }) {
    final plan = plans[contextId];
    if (plan == null) {
      return const PrepCheckResult(
        satisfied: true,
        missingRequired: [],
        missingOptional: [],
      );
    }
    final missingReq = <String>[];
    final missingOpt = <String>[];
    final collected = <String>[];

    for (final req in plan.requirements) {
      final match = inventory.items.values.where(
        (it) => it.tags.contains(req.itemTag),
      );
      if (match.isEmpty) {
        if (req.mode == PrepRequirementMode.required) {
          missingReq.add(req.itemTag);
        } else {
          missingOpt.add(req.itemTag);
        }
        continue;
      }
      final item = match.first;
      if (collect) {
        inventory.pickUp(itemId: item.id, pawnId: pawnId);
        collected.add(item.id);
        // Prefer bag when leaving.
        if (inventory.containers.containsKey('bag')) {
          inventory.putInBag(item.id);
        }
      }
    }

    final ok = missingReq.isEmpty;
    debugLog.add(
      'prep $contextId ok=$ok missReq=$missingReq missOpt=$missingOpt',
    );
    return PrepCheckResult(
      satisfied: ok,
      missingRequired: missingReq,
      missingOptional: missingOpt,
      collectedItemIds: collected,
    );
  }
}
