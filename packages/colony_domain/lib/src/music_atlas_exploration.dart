import 'dart:convert';
import 'dart:math' as math;

import 'id_generator.dart';
import 'music_atlas.dart';
import 'music_cover_recipe.dart';
import 'music_genre_atlas.dart';

enum MusicListenDepth { unknown, contact, heard, attentive }

abstract final class MusicListenPolicy {
  static MusicListenDepth of(Iterable<MusicEncounter> encounters) {
    var depth = MusicListenDepth.unknown;
    for (final encounter in encounters) {
      switch (encounter.encounterType) {
        case MusicEncounterType.attentiveListen:
        case MusicEncounterType.comparison:
        case MusicEncounterType.practice:
        case MusicEncounterType.live:
          return MusicListenDepth.attentive;
        case MusicEncounterType.listen:
          if (depth.index < MusicListenDepth.heard.index) {
            depth = MusicListenDepth.heard;
          }
        case MusicEncounterType.importListen:
          if ((encounter.durationSeconds ?? 0) >= 30) {
            if (depth.index < MusicListenDepth.heard.index) {
              depth = MusicListenDepth.heard;
            }
          } else if (depth == MusicListenDepth.unknown) {
            depth = MusicListenDepth.contact;
          }
        case MusicEncounterType.contact:
          if (depth == MusicListenDepth.unknown) {
            depth = MusicListenDepth.contact;
          }
      }
    }
    return depth;
  }

  static bool countsAsHeard(MusicListenDepth depth) =>
      depth == MusicListenDepth.heard || depth == MusicListenDepth.attentive;

  static int rank(MusicListenDepth depth) => depth.index;
}

abstract final class MusicNodeKind {
  static bool isAlbumLike(MusicNodeType type) =>
      type == MusicNodeType.releaseGroup ||
      type == MusicNodeType.release ||
      type == MusicNodeType.work;

  static bool isTerritoryLike(MusicNodeType type) =>
      type == MusicNodeType.territory ||
      type == MusicNodeType.scene ||
      type == MusicNodeType.concept;
}

/// Provenance-backed media (cover, notes, territories) — no schema bump.
abstract final class MusicNodeProvenance {
  static Map<String, dynamic> decode(String raw) {
    try {
      final value = jsonDecode(raw);
      if (value is Map<String, dynamic>) return value;
      if (value is Map) return Map<String, dynamic>.from(value);
    } catch (_) {}
    return {};
  }

  static String? coverArtUrl(String raw) {
    final map = decode(raw);
    final url = map['coverArtUrl'] ?? map['imageUrl'];
    if (url is String && url.trim().isNotEmpty) return url.trim();
    return null;
  }

  static String? notesMarkdown(String raw) {
    final map = decode(raw);
    final notes = map['notesMarkdown'] ?? map['notes'];
    if (notes is String && notes.trim().isNotEmpty) return notes.trim();
    return null;
  }

  static List<String> territoryKeys(String raw) {
    final map = decode(raw);
    final keys = map['territoryKeys'];
    if (keys is! List) return const [];
    return [
      for (final key in keys)
        if (key.toString().trim().isNotEmpty) key.toString().trim(),
    ];
  }

  static String merge(
    String raw, {
    String? coverArtUrl,
    String? notesMarkdown,
    List<String>? territoryKeys,
  }) {
    final map = decode(raw);
    if (coverArtUrl != null) {
      if (coverArtUrl.trim().isEmpty) {
        map.remove('coverArtUrl');
        map.remove('imageUrl');
      } else {
        map['coverArtUrl'] = coverArtUrl.trim();
      }
    }
    if (notesMarkdown != null) {
      if (notesMarkdown.trim().isEmpty) {
        map.remove('notesMarkdown');
        map.remove('notes');
      } else {
        map['notesMarkdown'] = notesMarkdown.trim();
      }
    }
    if (territoryKeys != null) {
      map['territoryKeys'] = [
        for (final key in territoryKeys)
          if (key.trim().isNotEmpty) key.trim(),
      ];
    }
    return jsonEncode(map);
  }
}

abstract final class MusicIdentityMedia {
  static String? coverArtUrl(String metadataJson) {
    final map = MusicNodeProvenance.decode(metadataJson);
    final url = map['imageUrl'] ?? map['coverArtUrl'] ?? map['url'];
    if (url is String && url.trim().isNotEmpty) return url.trim();
    return null;
  }

  static List<String> genres(String metadataJson) {
    final map = MusicNodeProvenance.decode(metadataJson);
    final raw = map['genres'];
    if (raw is! List) return const [];
    return [
      for (final item in raw)
        if (item.toString().trim().isNotEmpty) item.toString().trim(),
    ];
  }
}

abstract final class MusicAlbumSearch {
  static Uri google({
    required String title,
    String? artist,
    int? year,
  }) {
    final parts = <String>[
      title.trim(),
      if (artist != null && artist.trim().isNotEmpty) artist.trim(),
      if (year != null) '$year',
      'álbum',
    ];
    return Uri.https('www.google.com', '/search', {'q': parts.join(' ')});
  }
}

class MusicExplorationAlbum {
  const MusicExplorationAlbum({
    required this.node,
    required this.recipe,
    required this.depth,
    required this.discovery,
    required this.territoryKeys,
    this.artistCredit,
    this.coverArtUrl,
    this.dossier,
    this.fieldNotes,
    this.lastEncounterAt,
  });

  final MusicNode node;
  final MusicCoverRecipe recipe;
  final MusicListenDepth depth;
  final MusicDiscoveryState discovery;
  final List<String> territoryKeys;
  final String? artistCredit;
  final String? coverArtUrl;
  final MusicAlbumDossier? dossier;
  final String? fieldNotes;
  final DateTime? lastEncounterAt;

  bool get heard => MusicListenPolicy.countsAsHeard(depth);
  bool get hasDossier =>
      dossier != null || (fieldNotes != null && fieldNotes!.trim().isNotEmpty);

  String? get resolvedMarkdown {
    final user = fieldNotes?.trim();
    final bundled = dossier?.markdown.trim();
    if (bundled != null && bundled.isNotEmpty && user != null && user.isNotEmpty) {
      return '$bundled\n\n---\n\n## Notas de campo\n$user';
    }
    if (user != null && user.isNotEmpty) return user;
    return bundled;
  }

  String? get primaryTerritory =>
      territoryKeys.isEmpty ? null : territoryKeys.first;
}

class MusicExplorationTerritory {
  const MusicExplorationTerritory({
    required this.spec,
    required this.heardCount,
    required this.contactCount,
    required this.attentiveCount,
    required this.exploration,
    this.nodeId,
    this.isUserGrown = false,
  });

  final MusicTerritorySpec spec;
  final int heardCount;
  final int contactCount;
  final int attentiveCount;
  final double exploration;
  final EntityId? nodeId;
  final bool isUserGrown;

  String get key => spec.key;
  String get title => spec.title;
  String? get parentKey => spec.parentKey;
  bool get explored => exploration > 0.04 || heardCount > 0;
}

class MusicMapPoint {
  const MusicMapPoint({required this.x, required this.y});

  final double x;
  final double y;
}

class MusicRamificationLayout {
  const MusicRamificationLayout({
    required this.territoryPoints,
    required this.albumPoints,
    required this.width,
    required this.height,
    required this.edges,
  });

  final Map<String, MusicMapPoint> territoryPoints;
  final Map<String, MusicMapPoint> albumPoints;
  final double width;
  final double height;
  final List<(String from, String to)> edges;

  static const empty = MusicRamificationLayout(
    territoryPoints: {},
    albumPoints: {},
    width: 0,
    height: 0,
    edges: [],
  );
}

class MusicExplorationMap {
  const MusicExplorationMap({
    required this.territories,
    required this.albums,
    required this.layout,
  });

  final List<MusicExplorationTerritory> territories;
  final List<MusicExplorationAlbum> albums;
  final MusicRamificationLayout layout;

  static const empty = MusicExplorationMap(
    territories: [],
    albums: [],
    layout: MusicRamificationLayout.empty,
  );

  MusicExplorationTerritory? territory(String key) {
    for (final item in territories) {
      if (item.key == key) return item;
    }
    return null;
  }

  List<MusicExplorationAlbum> albumsIn(
    String key, {
    bool includeDescendants = true,
  }) {
    if (key == MusicGenreAtlas.unmappedKey) {
      return [
        for (final album in albums)
          if (album.territoryKeys.isEmpty) album,
      ];
    }
    final keys = includeDescendants ? _subtree(key) : {key};
    return [
      for (final album in albums)
        if (album.territoryKeys.any(keys.contains)) album,
    ];
  }

  Set<String> _subtree(String key) {
    final keys = {key};
    var growing = true;
    while (growing) {
      growing = false;
      for (final item in territories) {
        if (item.parentKey != null &&
            keys.contains(item.parentKey) &&
            keys.add(item.key)) {
          growing = true;
        }
      }
    }
    return keys;
  }

  MusicExplorationAlbum? albumById(String nodeId) {
    for (final album in albums) {
      if (album.node.id.value == nodeId) return album;
    }
    return null;
  }
}

abstract final class MusicAtlasCartographer {
  static MusicExplorationMap compose({
    required MusicAtlasOverview overview,
    List<MusicRelationClaim> claims = const [],
    String? selectedTerritoryKey,
  }) {
    final encountersByNode = <String, List<MusicEncounter>>{};
    for (final encounter in overview.encounters) {
      encountersByNode
          .putIfAbsent(encounter.nodeId.value, () => [])
          .add(encounter);
    }
    final identitiesByNode = <String, List<MusicExternalIdentity>>{};
    for (final identity in overview.identities) {
      identitiesByNode
          .putIfAbsent(identity.nodeId.value, () => [])
          .add(identity);
    }

    final userTerritoryKeys = <EntityId, String>{};
    for (final node in overview.nodes) {
      if (!MusicNodeKind.isTerritoryLike(node.nodeType)) continue;
      final fromProvenance = MusicNodeProvenance.territoryKeys(
        node.provenanceJson,
      );
      String? matched;
      for (final key in fromProvenance) {
        if (MusicGenreAtlas.byKey.containsKey(key)) {
          matched = key;
          break;
        }
      }
      matched ??= MusicGenreAtlas.matchGenreLabel(node.canonicalName);
      userTerritoryKeys[node.id] =
          matched ?? 'user.${_slug(node.canonicalName)}';
    }

    final extraUserSpecs = <MusicTerritorySpec>[];
    for (final node in overview.nodes) {
      if (!MusicNodeKind.isTerritoryLike(node.nodeType)) continue;
      final key = userTerritoryKeys[node.id];
      if (key == null || MusicGenreAtlas.byKey.containsKey(key)) continue;
      if (extraUserSpecs.any((spec) => spec.key == key)) continue;
      extraUserSpecs.add(
        MusicTerritorySpec(
          key: key,
          title: node.canonicalName,
          parentKey: MusicGenreAtlas.userRootKey,
          hue: (MusicCoverRecipe.hash(key) % 3600) / 10,
          motif: MusicCoverMotif.gold,
          loreMarkdown:
              node.description?.trim().isNotEmpty == true
              ? node.description!
              : 'Território nascido na tua colónia.',
        ),
      );
    }

    final albums = <MusicExplorationAlbum>[];
    for (final node in overview.nodes) {
      if (!MusicNodeKind.isAlbumLike(node.nodeType)) continue;
      final identities = identitiesByNode[node.id.value] ?? const [];
      final encounters = encountersByNode[node.id.value] ?? const [];
      final state = overview.stateOf(node.id);
      final artist = node.description;
      final dossier = MusicGenreAtlas.dossierFor(
        title: node.canonicalName,
        artist: artist,
      );
      final keys = <String>{
        ...MusicNodeProvenance.territoryKeys(node.provenanceJson),
        ...?dossier?.territoryKeys,
      };
      for (final identity in identities) {
        keys.addAll(
          MusicGenreAtlas.matchGenreLabels(
            MusicIdentityMedia.genres(identity.metadataJson),
          ),
        );
        final fromMeta = MusicNodeProvenance.territoryKeys(identity.metadataJson);
        keys.addAll(fromMeta);
      }
      for (final claim in claims) {
        if (claim.deletedAt != null) continue;
        EntityId? other;
        if (claim.fromNodeId == node.id) other = claim.toNodeId;
        if (claim.toNodeId == node.id) other = claim.fromNodeId;
        if (other == null) continue;
        final mapped = userTerritoryKeys[other];
        if (mapped != null) keys.add(mapped);
      }
      keys.removeWhere(
        (key) =>
            key == MusicGenreAtlas.unmappedKey ||
            key == MusicGenreAtlas.userRootKey,
      );

      String? cover = MusicNodeProvenance.coverArtUrl(node.provenanceJson);
      if (cover == null) {
        for (final identity in identities) {
          cover = MusicIdentityMedia.coverArtUrl(identity.metadataJson);
          if (cover != null) break;
        }
      }
      final notes =
          MusicNodeProvenance.notesMarkdown(node.provenanceJson) ??
          state?.personalSummary;
      final depth = MusicListenPolicy.of(encounters);
      final primary = keys.isEmpty ? null : keys.first;
      final spec = primary == null ? null : MusicGenreAtlas.byKey[primary];
      albums.add(
        MusicExplorationAlbum(
          node: node,
          recipe: MusicCoverRecipe.from(
            title: node.canonicalName,
            artist: artist,
            year: node.beginYear,
            territoryHue: spec?.hue,
            motif: spec?.motif,
          ),
          depth: depth,
          discovery: state?.discoveryState ?? MusicDiscoveryState.unmapped,
          territoryKeys: keys.toList(),
          artistCredit: artist,
          coverArtUrl: cover,
          dossier: dossier,
          fieldNotes: notes,
          lastEncounterAt: state?.lastEncounterAt,
        ),
      );
    }

    albums.sort((a, b) {
      final depth = MusicListenPolicy.rank(b.depth) - MusicListenPolicy.rank(a.depth);
      if (depth != 0) return depth;
      final aAt = a.lastEncounterAt;
      final bAt = b.lastEncounterAt;
      if (aAt != null && bAt != null) return bAt.compareTo(aAt);
      return a.node.sortName.compareTo(b.node.sortName);
    });

    final heardByKey = <String, int>{};
    final contactByKey = <String, int>{};
    final attentiveByKey = <String, int>{};
    void bump(String key, MusicExplorationAlbum album) {
      for (final ancestor in MusicGenreAtlas.ancestorKeys(
        key,
        extra: extraUserSpecs,
      )) {
        if (album.depth == MusicListenDepth.attentive) {
          attentiveByKey[ancestor] = (attentiveByKey[ancestor] ?? 0) + 1;
        }
        if (MusicListenPolicy.countsAsHeard(album.depth)) {
          heardByKey[ancestor] = (heardByKey[ancestor] ?? 0) + 1;
        } else if (album.depth == MusicListenDepth.contact) {
          contactByKey[ancestor] = (contactByKey[ancestor] ?? 0) + 1;
        }
      }
    }

    for (final album in albums) {
      if (album.territoryKeys.isEmpty) {
        if (MusicListenPolicy.countsAsHeard(album.depth)) {
          heardByKey[MusicGenreAtlas.unmappedKey] =
              (heardByKey[MusicGenreAtlas.unmappedKey] ?? 0) + 1;
        } else if (album.depth == MusicListenDepth.contact) {
          contactByKey[MusicGenreAtlas.unmappedKey] =
              (contactByKey[MusicGenreAtlas.unmappedKey] ?? 0) + 1;
        }
        continue;
      }
      for (final key in album.territoryKeys) {
        bump(key, album);
      }
    }

    double explorationFor(String key) {
      final heard = heardByKey[key] ?? 0;
      final contact = contactByKey[key] ?? 0;
      final attentive = attentiveByKey[key] ?? 0;
      if (heard == 0 && contact == 0 && attentive == 0) return 0;
      final raw =
          (contact * 0.12) + (heard * 0.28) + (attentive * 0.18);
      return math.min(1, raw);
    }

    final nodeIdByKey = <String, EntityId>{};
    userTerritoryKeys.forEach((id, key) => nodeIdByKey[key] = id);

    final territories = <MusicExplorationTerritory>[
      for (final spec in MusicGenreAtlas.territories)
        MusicExplorationTerritory(
          spec: spec,
          heardCount: heardByKey[spec.key] ?? 0,
          contactCount: contactByKey[spec.key] ?? 0,
          attentiveCount: attentiveByKey[spec.key] ?? 0,
          exploration: explorationFor(spec.key),
          nodeId: nodeIdByKey[spec.key],
        ),
      if (extraUserSpecs.isNotEmpty)
        MusicExplorationTerritory(
          spec: MusicGenreAtlas.userRoot,
          heardCount: extraUserSpecs.fold<int>(
            0,
            (sum, spec) => sum + (heardByKey[spec.key] ?? 0),
          ),
          contactCount: extraUserSpecs.fold<int>(
            0,
            (sum, spec) => sum + (contactByKey[spec.key] ?? 0),
          ),
          attentiveCount: extraUserSpecs.fold<int>(
            0,
            (sum, spec) => sum + (attentiveByKey[spec.key] ?? 0),
          ),
          exploration: extraUserSpecs.isEmpty
              ? 0
              : extraUserSpecs
                    .map((spec) => explorationFor(spec.key))
                    .reduce(math.max),
          isUserGrown: true,
        ),
      for (final spec in extraUserSpecs)
        MusicExplorationTerritory(
          spec: spec,
          heardCount: heardByKey[spec.key] ?? 0,
          contactCount: contactByKey[spec.key] ?? 0,
          attentiveCount: attentiveByKey[spec.key] ?? 0,
          exploration: explorationFor(spec.key),
          nodeId: nodeIdByKey[spec.key],
          isUserGrown: true,
        ),
      MusicExplorationTerritory(
        spec: MusicGenreAtlas.unmapped,
        heardCount: heardByKey[MusicGenreAtlas.unmappedKey] ?? 0,
        contactCount: contactByKey[MusicGenreAtlas.unmappedKey] ?? 0,
        attentiveCount: attentiveByKey[MusicGenreAtlas.unmappedKey] ?? 0,
        exploration: explorationFor(MusicGenreAtlas.unmappedKey),
      ),
    ];

    final selectedAlbums = selectedTerritoryKey == null
        ? const <MusicExplorationAlbum>[]
        : [
            for (final album in albums)
              if (selectedTerritoryKey == MusicGenreAtlas.unmappedKey
                  ? album.territoryKeys.isEmpty
                  : album.territoryKeys.any(
                      (key) => MusicGenreAtlas.descendantKeys(
                        selectedTerritoryKey,
                        extra: extraUserSpecs,
                      ).contains(key),
                    ))
                album,
          ];

    final layout = MusicRamificationLayouter.layout(
      territories: territories,
      selectedKey: selectedTerritoryKey,
      selectedAlbums: selectedAlbums,
    );

    return MusicExplorationMap(
      territories: territories,
      albums: albums,
      layout: layout,
    );
  }

  static String _slug(String title) {
    return MusicIdentityPolicy.normalizeTitle(title)
        .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
        .replaceAll(RegExp(r'-+'), '-')
        .replaceAll(RegExp(r'^-|-$'), '');
  }
}

abstract final class MusicRamificationLayouter {
  static const padding = 140.0;
  static const depthGap = 268.0;
  static const siblingGap = 108.0;
  static const rootGap = 86.0;

  static MusicRamificationLayout layout({
    required List<MusicExplorationTerritory> territories,
    String? selectedKey,
    List<MusicExplorationAlbum> selectedAlbums = const [],
  }) {
    if (territories.isEmpty) return MusicRamificationLayout.empty;
    final byKey = {for (final item in territories) item.key: item};
    final children = <String?, List<MusicExplorationTerritory>>{};
    for (final item in territories) {
      if (item.key == MusicGenreAtlas.unmappedKey) continue;
      children.putIfAbsent(item.parentKey, () => []).add(item);
    }
    for (final list in children.values) {
      list.sort((a, b) => a.title.compareTo(b.title));
    }

    final points = <String, MusicMapPoint>{};
    var cursorY = padding;

    double place(MusicExplorationTerritory node, int depth, double minY) {
      final kids = children[node.key] ?? const <MusicExplorationTerritory>[];
      final x =
          padding +
          depth * depthGap +
          math.sin(MusicCoverRecipe.hash(node.key) / 400) * 22;
      if (kids.isEmpty) {
        final y = minY;
        points[node.key] = MusicMapPoint(x: x, y: y);
        return minY + siblingGap;
      }
      var childY = minY;
      final childYs = <double>[];
      for (final child in kids) {
        final next = place(child, depth + 1, childY);
        childYs.add(points[child.key]!.y);
        childY = next;
      }
      final y = (childYs.first + childYs.last) / 2;
      points[node.key] = MusicMapPoint(x: x, y: y);
      return childY;
    }

    final roots = children[null] ?? const <MusicExplorationTerritory>[];
    for (final root in roots) {
      cursorY = place(root, 0, cursorY) + rootGap;
    }

    final unmapped = byKey[MusicGenreAtlas.unmappedKey];
    if (unmapped != null) {
      points[unmapped.key] = MusicMapPoint(
        x: padding,
        y: cursorY + 40,
      );
    }

    final edges = <(String, String)>[];
    for (final item in territories) {
      final parent = item.parentKey;
      if (parent != null &&
          points.containsKey(parent) &&
          points.containsKey(item.key)) {
        edges.add((parent, item.key));
      }
    }

    final albumPoints = <String, MusicMapPoint>{};
    if (selectedKey != null && points.containsKey(selectedKey)) {
      final origin = points[selectedKey]!;
      final n = selectedAlbums.length;
      for (var i = 0; i < n; i++) {
        final album = selectedAlbums[i];
        final t = n == 1 ? 0.5 : i / (n - 1);
        final ring = i ~/ 10;
        final indexInRing = i % 10;
        final ringCount = math.min(10, n - ring * 10);
        final localT = ringCount == 1 ? 0.5 : indexInRing / (ringCount - 1);
        final angle = -1.05 + 2.1 * (n <= 10 ? t : localT);
        final radius = 168.0 + ring * 92 + (i % 3) * 10;
        albumPoints[album.node.id.value] = MusicMapPoint(
          x: origin.x + 188 + math.cos(angle) * radius * 1.18,
          y: origin.y + math.sin(angle) * radius,
        );
      }
    }

    var maxX = 800.0;
    var maxY = 600.0;
    for (final point in [...points.values, ...albumPoints.values]) {
      if (point.x > maxX) maxX = point.x;
      if (point.y > maxY) maxY = point.y;
    }

    return MusicRamificationLayout(
      territoryPoints: points,
      albumPoints: albumPoints,
      width: maxX + padding + 220,
      height: maxY + padding + 160,
      edges: edges,
    );
  }
}
