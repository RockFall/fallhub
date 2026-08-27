/// Block I — editor and environment creation polish (MD 10 R88–R103).
library;

class SnapResult {
  const SnapResult({
    required this.cell,
    required this.snapped,
    this.reason = '',
  });

  final (int, int) cell;
  final bool snapped;
  final String reason;
}

abstract final class SmartSnapping {
  static SnapResult snap({
    required (int, int) raw,
    required List<(int, int)> wallCells,
    required List<(int, int)> furnitureOrigins,
    int grid = 1,
  }) {
    var cell = (raw.$1, raw.$2);
    // Align to adjacent furniture edge if within 1 cell.
    for (final f in furnitureOrigins) {
      if ((f.$1 - cell.$1).abs() + (f.$2 - cell.$2).abs() == 1) {
        return SnapResult(cell: cell, snapped: true, reason: 'furnitureEdge');
      }
    }
    for (final w in wallCells) {
      if ((w.$1 - cell.$1).abs() + (w.$2 - cell.$2).abs() == 1) {
        return SnapResult(cell: cell, snapped: true, reason: 'wall');
      }
    }
    return SnapResult(cell: cell, snapped: false);
  }
}

enum OrientationPreviewHint { faceTv, faceTable, faceRoom, fixed }

abstract final class RotationOrientationPreview {
  static OrientationPreviewHint hintFor(String kind) {
    final k = kind.toLowerCase();
    if (k.contains('sofa') || k.contains('couch')) {
      return OrientationPreviewHint.faceTv;
    }
    if (k.contains('dining') || k.contains('chair')) {
      return OrientationPreviewHint.faceTable;
    }
    if (k.contains('reading')) return OrientationPreviewHint.faceRoom;
    return OrientationPreviewHint.fixed;
  }
}

class MarqueeSelection {
  MarqueeSelection(this.cells);
  final Set<(int, int)> cells;

  static MarqueeSelection fromRect((int, int) a, (int, int) b) {
    final minX = a.$1 < b.$1 ? a.$1 : b.$1;
    final maxX = a.$1 > b.$1 ? a.$1 : b.$1;
    final minY = a.$2 < b.$2 ? a.$2 : b.$2;
    final maxY = a.$2 > b.$2 ? a.$2 : b.$2;
    final cells = <(int, int)>{};
    for (var y = minY; y <= maxY; y++) {
      for (var x = minX; x <= maxX; x++) {
        cells.add((x, y));
      }
    }
    return MarqueeSelection(cells);
  }
}

abstract final class AlignDistribute {
  static List<(int, int)> alignLeft(List<(int, int)> cells) {
    if (cells.isEmpty) return cells;
    final minX = cells.map((c) => c.$1).reduce((a, b) => a < b ? a : b);
    return [for (final c in cells) (minX, c.$2)];
  }

  static List<(int, int)> distributeHorizontal(List<(int, int)> cells) {
    if (cells.length < 3) return List.of(cells);
    final sorted = [...cells]..sort((a, b) => a.$1.compareTo(b.$1));
    final minX = sorted.first.$1;
    final maxX = sorted.last.$1;
    final step = (maxX - minX) / (sorted.length - 1);
    return [
      for (var i = 0; i < sorted.length; i++)
        ((minX + (step * i)).round(), sorted[i].$2),
    ];
  }
}

class EditorClipboardItem {
  const EditorClipboardItem({
    required this.kind,
    required this.facing,
    required this.relative,
  });

  final String kind;
  final String facing;
  final (int, int) relative;
}

class EditorClipboard {
  final List<EditorClipboardItem> items = [];

  void copy(List<EditorClipboardItem> next) {
    items
      ..clear()
      ..addAll(next);
  }

  List<EditorClipboardItem> pasteAt((int, int) origin) => [
        for (final i in items)
          EditorClipboardItem(
            kind: i.kind,
            facing: i.facing,
            relative: (origin.$1 + i.relative.$1, origin.$2 + i.relative.$2),
          ),
      ];
}

abstract final class QuickReplace {
  static String? replacementInFamily(String kind, List<String> family) {
    if (family.isEmpty) return null;
    final i = family.indexOf(kind);
    if (i < 0) return family.first;
    return family[(i + 1) % family.length];
  }
}

class CatalogFilter {
  const CatalogFilter({
    this.query = '',
    this.tag,
    this.favoritesOnly = false,
  });

  final String query;
  final String? tag;
  final bool favoritesOnly;
}

abstract final class CatalogSearch {
  static List<String> filter({
    required List<String> ids,
    required Map<String, Set<String>> tagsById,
    required Set<String> favorites,
    required CatalogFilter filter,
  }) {
    final q = filter.query.toLowerCase().trim();
    return [
      for (final id in ids)
        if ((!filter.favoritesOnly || favorites.contains(id)) &&
            (filter.tag == null ||
                (tagsById[id]?.contains(filter.tag!) ?? false)) &&
            (q.isEmpty || id.toLowerCase().contains(q)))
          id,
    ];
  }
}

class RecentlyUsedCatalog {
  RecentlyUsedCatalog({this.limit = 12});

  final int limit;
  final List<String> _ids = [];

  List<String> get ids => List.unmodifiable(_ids);

  void push(String id) {
    _ids.remove(id);
    _ids.insert(0, id);
    while (_ids.length > limit) {
      _ids.removeLast();
    }
  }
}

class AffordancePreview {
  const AffordancePreview({
    required this.kind,
    required this.slots,
    required this.facingHint,
  });

  final String kind;
  final List<(int, int)> slots;
  final String facingHint;
}

abstract final class EditorAffordancePreview {
  static AffordancePreview forProp({
    required String kind,
    required (int, int) origin,
    required (int, int) size,
  }) {
    final slots = <(int, int)>[
      (origin.$1, origin.$2 + size.$2),
      (origin.$1 - 1, origin.$2),
      (origin.$1 + size.$1, origin.$2),
    ];
    return AffordancePreview(
      kind: kind,
      slots: slots,
      facingHint: RotationOrientationPreview.hintFor(kind).name,
    );
  }
}

abstract final class NavigationPreview {
  static bool reachable({
    required List<(int, int)> path,
    required (int, int) target,
  }) =>
      path.isNotEmpty && path.last == target;
}

enum SemanticCoverageHint { missingSeat, missingSleep, missingLight, ok }

abstract final class SemanticCoverage {
  static List<SemanticCoverageHint> evaluate({
    required bool hasSeat,
    required bool hasSleep,
    required bool hasLight,
  }) {
    final out = <SemanticCoverageHint>[];
    if (!hasSeat) out.add(SemanticCoverageHint.missingSeat);
    if (!hasSleep) out.add(SemanticCoverageHint.missingSleep);
    if (!hasLight) out.add(SemanticCoverageHint.missingLight);
    if (out.isEmpty) out.add(SemanticCoverageHint.ok);
    return out;
  }
}

class RoomBoundsOverlay {
  const RoomBoundsOverlay({
    required this.rooms,
    required this.portals,
  });

  final List<({String id, Set<(int, int)> cells})> rooms;
  final List<(int, int)> portals;
}

class BlueprintDiff {
  const BlueprintDiff({
    required this.added,
    required this.removed,
    required this.moved,
  });

  final List<String> added;
  final List<String> removed;
  final List<String> moved;

  bool get isEmpty => added.isEmpty && removed.isEmpty && moved.isEmpty;
}

abstract final class BlueprintPreview {
  static BlueprintDiff diff({
    required Set<String> beforeIds,
    required Set<String> afterIds,
    required Set<String> movedIds,
  }) =>
      BlueprintDiff(
        added: afterIds.difference(beforeIds).toList(),
        removed: beforeIds.difference(afterIds).toList(),
        moved: movedIds.toList(),
      );
}

class EditorHistoryEntry {
  const EditorHistoryEntry({
    required this.label,
    required this.at,
  });

  final String label;
  final double at;
}

class EditorHistoryPane {
  final List<EditorHistoryEntry> entries = [];

  void push(String label, double at) {
    entries.insert(0, EditorHistoryEntry(label: label, at: at));
    if (entries.length > 40) entries.removeLast();
  }
}

abstract final class EditorShortcuts {
  static const map = <String, String>{
    'ctrl+z': 'undo',
    'ctrl+y': 'redo',
    'ctrl+d': 'duplicate',
    'delete': 'delete',
    'r': 'rotate',
    'f': 'favorite',
    'ctrl+a': 'selectAll',
    'ctrl+c': 'copy',
    'ctrl+v': 'paste',
  };

  static String? actionFor(String chord) => map[chord.toLowerCase()];
}

enum MobileEditorGesture { pan, pinchZoom, longPressPlace, twoFingerRotate }

abstract final class MobileEditorGestures {
  static MobileEditorGesture interpret({
    required int pointers,
    required bool longPress,
    required bool pinch,
  }) {
    if (pinch) return MobileEditorGesture.pinchZoom;
    if (pointers >= 2) return MobileEditorGesture.twoFingerRotate;
    if (longPress) return MobileEditorGesture.longPressPlace;
    return MobileEditorGesture.pan;
  }
}
