/// Virtual item locations in the Habitat (MD 08 M32).
enum HabitatItemLocationKind {
  heldByPawn,
  storageSlot,
  surfaceSlot,
  floorCell,
  transit,
  unknown,
}

class HabitatItemLocation {
  const HabitatItemLocation({
    required this.kind,
    this.pawnId,
    this.containerId,
    this.slotId,
    this.cell,
  });

  final HabitatItemLocationKind kind;
  final String? pawnId;
  final String? containerId;
  final String? slotId;
  final (int, int)? cell;

  factory HabitatItemLocation.held(String pawnId) => HabitatItemLocation(
        kind: HabitatItemLocationKind.heldByPawn,
        pawnId: pawnId,
      );

  factory HabitatItemLocation.storage(String containerId, String slotId) =>
      HabitatItemLocation(
        kind: HabitatItemLocationKind.storageSlot,
        containerId: containerId,
        slotId: slotId,
      );

  factory HabitatItemLocation.surface(String containerId, String slotId) =>
      HabitatItemLocation(
        kind: HabitatItemLocationKind.surfaceSlot,
        containerId: containerId,
        slotId: slotId,
      );

  factory HabitatItemLocation.floor((int, int) cell) => HabitatItemLocation(
        kind: HabitatItemLocationKind.floorCell,
        cell: cell,
      );
}

class HabitatItem {
  HabitatItem({
    required this.id,
    required this.label,
    required this.tags,
    required this.location,
    this.preferredStorageId,
  });

  final String id;
  final String label;
  final Set<String> tags;
  HabitatItemLocation location;
  final String? preferredStorageId;
}

class HabitatStorageContainer {
  HabitatStorageContainer({
    required this.id,
    required this.kind,
    required this.capacity,
    this.acceptedItemTags = const {},
  });

  final String id;
  final String kind;
  final int capacity;
  final Set<String> acceptedItemTags;
  final Map<String, String?> slots = {};

  void ensureSlots() {
    if (slots.isNotEmpty) return;
    for (var i = 0; i < capacity; i++) {
      slots['$i'] = null;
    }
  }

  String? firstFreeSlot() {
    ensureSlots();
    for (final e in slots.entries) {
      if (e.value == null) return e.key;
    }
    return null;
  }
}

/// In-memory habitat inventory — one location per item (M32).
class HabitatInventory {
  final Map<String, HabitatItem> items = {};
  final Map<String, HabitatStorageContainer> containers = {};
  final List<String> debugLog = [];

  void seedDemo() {
    if (items.isNotEmpty) return;
    for (final c in [
      HabitatStorageContainer(
        id: 'bookshelf',
        kind: 'bookshelf',
        capacity: 4,
        acceptedItemTags: {'book', 'media'},
      ),
      HabitatStorageContainer(
        id: 'recordShelf',
        kind: 'recordShelf',
        capacity: 4,
        acceptedItemTags: {'album', 'media'},
      ),
      HabitatStorageContainer(
        id: 'wardrobe',
        kind: 'wardrobe',
        capacity: 3,
        acceptedItemTags: {'clothing'},
      ),
      HabitatStorageContainer(
        id: 'bag',
        kind: 'bag',
        capacity: 2,
        acceptedItemTags: {},
      ),
      HabitatStorageContainer(
        id: 'table',
        kind: 'surface',
        capacity: 2,
        acceptedItemTags: {},
      ),
    ]) {
      c.ensureSlots();
      containers[c.id] = c;
    }

    putNew(
      HabitatItem(
        id: 'book.dune',
        label: 'Duna',
        tags: {'book', 'media'},
        location: HabitatItemLocation.storage('bookshelf', '0'),
        preferredStorageId: 'bookshelf',
      ),
    );
    putNew(
      HabitatItem(
        id: 'album.kind_of_blue',
        label: 'Kind of Blue',
        tags: {'album', 'media'},
        location: HabitatItemLocation.storage('recordShelf', '0'),
        preferredStorageId: 'recordShelf',
      ),
    );
    putNew(
      HabitatItem(
        id: 'mug.blue',
        label: 'Caneca azul',
        tags: {'cup'},
        location: HabitatItemLocation.surface('table', '0'),
        preferredStorageId: 'wardrobe',
      ),
    );
  }

  void putNew(HabitatItem item) {
    assert(!items.containsKey(item.id), 'duplicate item ${item.id}');
    _occupy(item);
    items[item.id] = item;
  }

  void _vacate(HabitatItem item) {
    final loc = item.location;
    if (loc.kind == HabitatItemLocationKind.storageSlot ||
        loc.kind == HabitatItemLocationKind.surfaceSlot) {
      final c = containers[loc.containerId];
      if (c != null && loc.slotId != null) {
        c.slots[loc.slotId!] = null;
      }
    }
  }

  void _occupy(HabitatItem item) {
    final loc = item.location;
    if (loc.kind == HabitatItemLocationKind.storageSlot ||
        loc.kind == HabitatItemLocationKind.surfaceSlot) {
      final c = containers[loc.containerId];
      if (c != null && loc.slotId != null) {
        assert(
          c.slots[loc.slotId!] == null || c.slots[loc.slotId!] == item.id,
          'slot occupied',
        );
        c.slots[loc.slotId!] = item.id;
      }
    }
  }

  void _move(String itemId, HabitatItemLocation next) {
    final item = items[itemId];
    if (item == null) return;
    _vacate(item);
    item.location = next;
    _occupy(item);
    debugLog.add('${item.id} → ${next.kind.name}');
  }

  void pickUp({required String itemId, required String pawnId}) {
    _move(itemId, HabitatItemLocation.held(pawnId));
  }

  bool putIn({
    required String itemId,
    required String containerId,
  }) {
    final c = containers[containerId];
    final item = items[itemId];
    if (c == null || item == null) return false;
    if (c.acceptedItemTags.isNotEmpty &&
        item.tags.intersection(c.acceptedItemTags).isEmpty) {
      return false;
    }
    final slot = c.firstFreeSlot();
    if (slot == null) return false;
    final kind = c.kind == 'surface' || c.kind == 'table'
        ? HabitatItemLocationKind.surfaceSlot
        : HabitatItemLocationKind.storageSlot;
    _move(
      itemId,
      HabitatItemLocation(
        kind: kind,
        containerId: containerId,
        slotId: slot,
      ),
    );
    return true;
  }

  bool placeOnTable(String itemId) =>
      putIn(itemId: itemId, containerId: 'table');

  bool putInBag(String itemId) => putIn(itemId: itemId, containerId: 'bag');

  bool returnToPreferred(String itemId) {
    final item = items[itemId];
    final pref = item?.preferredStorageId;
    if (item == null || pref == null) return false;
    return putIn(itemId: itemId, containerId: pref);
  }

  /// Invariant helper for tests.
  bool get locationsConsistent {
    final seen = <String>{};
    for (final item in items.values) {
      if (!seen.add(item.id)) return false;
      final loc = item.location;
      if (loc.kind == HabitatItemLocationKind.storageSlot ||
          loc.kind == HabitatItemLocationKind.surfaceSlot) {
        final c = containers[loc.containerId];
        if (c == null || loc.slotId == null) return false;
        if (c.slots[loc.slotId!] != item.id) return false;
      }
    }
    return true;
  }
}
