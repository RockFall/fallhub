import 'dart:convert';

/// Versioned Mirror-Ready habitat snapshot (MD 08 M47).

class MirrorReadyHabitatSnapshot {
  MirrorReadyHabitatSnapshot({
    required this.schemaVersion,
    required this.worldSeed,
    required this.clockState,
    required this.payload,
  });

  final int schemaVersion;
  final int worldSeed;
  final Map<String, Object?> clockState;
  final Map<String, Object?> payload;

  static const currentVersion = 3;

  Map<String, Object?> toJson() => {
        'schemaVersion': schemaVersion,
        'worldSeed': worldSeed,
        'clockState': clockState,
        'payload': payload,
      };

  factory MirrorReadyHabitatSnapshot.fromJson(Map<String, Object?> json) {
    return MirrorReadyHabitatSnapshot(
      schemaVersion: json['schemaVersion'] as int? ?? 1,
      worldSeed: json['worldSeed'] as int? ?? 0,
      clockState: Map<String, Object?>.from(
        json['clockState'] as Map? ?? const {},
      ),
      payload: Map<String, Object?>.from(json['payload'] as Map? ?? const {}),
    );
  }

  String encode() => jsonEncode(toJson());

  static MirrorReadyHabitatSnapshot? tryDecode(String raw) {
    try {
      final map = jsonDecode(raw) as Map<String, dynamic>;
      return MirrorReadyHabitatSnapshot.fromJson(
        Map<String, Object?>.from(map),
      );
    } catch (_) {
      return null;
    }
  }
}

/// Migrates snapshots v1→v2→v3; cosmetic failures reset isolately.
class HabitatSnapshotMigrator {
  MirrorReadyHabitatSnapshot migrate(MirrorReadyHabitatSnapshot snap) {
    var s = snap;
    if (s.schemaVersion < 2) {
      final payload = Map<String, Object?>.from(s.payload);
      payload.putIfAbsent('sites', () => <String, Object?>{});
      s = MirrorReadyHabitatSnapshot(
        schemaVersion: 2,
        worldSeed: s.worldSeed,
        clockState: s.clockState,
        payload: payload,
      );
    }
    if (s.schemaVersion < 3) {
      final payload = Map<String, Object?>.from(s.payload);
      payload.putIfAbsent('workpieces', () => <String, Object?>{});
      payload.putIfAbsent('customContent', () => <String, Object?>{});
      // Drop invalid cosmetic blob if present.
      payload.remove('particles');
      payload.remove('bubbles');
      s = MirrorReadyHabitatSnapshot(
        schemaVersion: 3,
        worldSeed: s.worldSeed,
        clockState: s.clockState,
        payload: payload,
      );
    }
    return s;
  }
}

/// Debounced dirty-flag saver (no write-per-frame).
class HabitatSnapshotStore {
  HabitatSnapshotStore({this.debounceWrites = 3});

  final int debounceWrites;
  final HabitatSnapshotMigrator migrator = HabitatSnapshotMigrator();
  String? _encoded;
  bool dirty = false;
  int writeCount = 0;
  int _dirtyTicks = 0;

  void markDirty() {
    dirty = true;
    _dirtyTicks++;
  }

  /// Returns true when a write actually happened.
  bool maybeFlush(MirrorReadyHabitatSnapshot Function() build) {
    if (!dirty) return false;
    if (_dirtyTicks < debounceWrites) return false;
    final snap = migrator.migrate(build());
    _encoded = snap.encode();
    dirty = false;
    _dirtyTicks = 0;
    writeCount++;
    return true;
  }

  MirrorReadyHabitatSnapshot? load() {
    final raw = _encoded;
    if (raw == null) return null;
    final decoded = MirrorReadyHabitatSnapshot.tryDecode(raw);
    if (decoded == null) {
      // Corrupt → empty fallback so app still opens.
      return MirrorReadyHabitatSnapshot(
        schemaVersion: MirrorReadyHabitatSnapshot.currentVersion,
        worldSeed: 0,
        clockState: const {},
        payload: const {},
      );
    }
    return migrator.migrate(decoded);
  }

  /// Force save (lifecycle / editor commit).
  void forceSave(MirrorReadyHabitatSnapshot snap) {
    _encoded = migrator.migrate(snap).encode();
    dirty = false;
    _dirtyTicks = 0;
    writeCount++;
  }
}
