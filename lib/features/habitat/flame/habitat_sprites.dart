import 'package:flame/cache.dart';
import 'package:flame/components.dart';
import 'package:living_habitat_assets/living_habitat_assets.dart';

import 'furniture/furniture.dart';
import 'habitat_map.dart';
import 'habitat_prop_catalog.dart';

/// Pre-built sprites for the habitat scene (loaded once in [HabitatGame]).
class HabitatSprites {
  HabitatSprites._({
    required this.wood,
    required this.carpet,
    required this.concrete,
    required this.door,
    required this.bodyByType,
    required this.headByType,
    required this.hairByStyle,
    required this.apparelByPiece,
    required this.hatByStyle,
    required this.beardByStyle,
    required this.props,
    required this.propMasks,
  });

  final Sprite wood;
  final Sprite carpet;
  final Sprite concrete;

  /// Door leaf (`DoorSimple_Mover`); null → procedural fallback.
  final Sprite? door;

  /// bodyType → dir → sprite
  final Map<String, Map<String, Sprite>> bodyByType;
  final Map<String, Map<String, Sprite>> headByType;

  /// style → dir → sprite
  final Map<String, Map<String, Sprite>> hairByStyle;

  /// piece → bodyType → dir → sprite
  final Map<String, Map<String, Map<String, Sprite>>> apparelByPiece;

  /// hat → dir → sprite
  final Map<String, Map<String, Sprite>> hatByStyle;

  /// beard → dir → sprite (north may be absent — use south)
  final Map<String, Map<String, Sprite>> beardByStyle;

  /// `"kind|facing"` → sprite (facing = south|east|north).
  final Map<String, Sprite> props;

  /// Bedding overlays `"kind|facing"` when present.
  final Map<String, Sprite> propMasks;

  Map<String, Sprite> hairFor(String style) =>
      hairByStyle[style] ?? hairByStyle['bob']!;

  Sprite? bodySprite(String bodyType, String dir) =>
      bodyByType[bodyType]?[dir] ?? bodyByType['male']?[dir];

  Sprite? headSprite(String bodyType, String dir) {
    final key = bodyType == 'female' ? 'female' : 'male';
    return headByType[key]?[dir] ?? headByType['male']?[dir];
  }

  Sprite? apparelSprite(String? piece, String bodyType, String dir) {
    if (piece == null) return null;
    return apparelByPiece[piece]?[bodyType]?[dir] ??
        apparelByPiece[piece]?['male']?[dir];
  }

  Sprite? hatSprite(String? style, String dir) {
    if (style == null) return null;
    return hatByStyle[style]?[dir];
  }

  Sprite? beardSprite(String? style, String dir) {
    if (style == null) return null;
    final map = beardByStyle[style];
    if (map == null) return null;
    return map[dir] ?? map['south'];
  }

  Sprite? propSprite(
    String kind, [
    HabitatPropFacing facing = HabitatPropFacing.south,
  ]) {
    final resolved = FurnitureRegistry.resolveId(kind);
    final key = '$resolved|${facing.spriteKey}';
    return props[key] ?? props['$resolved|south'] ?? props['$kind|south'];
  }

  Sprite? propMask(
    String kind, [
    HabitatPropFacing facing = HabitatPropFacing.south,
  ]) {
    final resolved = FurnitureRegistry.resolveId(kind);
    final key = '$resolved|${facing.spriteKey}';
    return propMasks[key] ?? propMasks['$resolved|south'];
  }

  static Sprite? _cached(Images images, String path) {
    if (!images.containsKey(path)) return null;
    return Sprite(images.fromCache(path));
  }

  factory HabitatSprites.fromCache(Images images, HabitatMap map) {
    Sprite floor(String path) => Sprite(
          images.fromCache(path),
          srcPosition: Vector2(256, 256),
          srcSize: Vector2(128, 128),
        );

    final bodyByType = <String, Map<String, Sprite>>{};
    for (final body in HabitatAssets.bodyTypes) {
      final dirs = <String, Sprite>{};
      for (final dir in HabitatAssets.directions) {
        final s = _cached(images, HabitatAssets.body(dir, bodyType: body));
        if (s != null) dirs[dir] = s;
      }
      if (dirs.isNotEmpty) bodyByType[body] = dirs;
    }

    final headByType = <String, Map<String, Sprite>>{};
    for (final body in const ['male', 'female']) {
      final dirs = <String, Sprite>{};
      for (final dir in HabitatAssets.directions) {
        final s = _cached(images, HabitatAssets.head(dir, bodyType: body));
        if (s != null) dirs[dir] = s;
      }
      if (dirs.isNotEmpty) headByType[body] = dirs;
    }

    final hairByStyle = <String, Map<String, Sprite>>{};
    for (final style in HabitatAssets.hairStyles) {
      final dirs = <String, Sprite>{};
      for (final dir in HabitatAssets.directions) {
        final s = _cached(images, HabitatAssets.hair(dir, style: style));
        if (s != null) dirs[dir] = s;
      }
      if (dirs.isNotEmpty) hairByStyle[style] = dirs;
    }

    final apparelByPiece = <String, Map<String, Map<String, Sprite>>>{};
    for (final piece in HabitatAssets.apparelTops) {
      final byBody = <String, Map<String, Sprite>>{};
      for (final body in HabitatAssets.bodyTypes) {
        final dirs = <String, Sprite>{};
        for (final dir in HabitatAssets.directions) {
          final s = _cached(images, HabitatAssets.apparel(piece, body, dir));
          if (s != null) dirs[dir] = s;
        }
        if (dirs.isNotEmpty) byBody[body] = dirs;
      }
      if (byBody.isNotEmpty) apparelByPiece[piece] = byBody;
    }

    final hatByStyle = <String, Map<String, Sprite>>{};
    for (final h in HabitatAssets.hats) {
      final dirs = <String, Sprite>{};
      for (final dir in HabitatAssets.directions) {
        final s = _cached(images, HabitatAssets.hat(h, dir));
        if (s != null) dirs[dir] = s;
      }
      if (dirs.isNotEmpty) hatByStyle[h] = dirs;
    }

    final beardByStyle = <String, Map<String, Sprite>>{};
    for (final style in HabitatAssets.beardStyles) {
      final dirs = <String, Sprite>{};
      for (final dir in const ['south', 'east']) {
        final s = _cached(images, HabitatAssets.beard(style, dir));
        if (s != null) dirs[dir] = s;
      }
      if (dirs.isNotEmpty) beardByStyle[style] = dirs;
    }

    final props = <String, Sprite>{};
    final propMasks = <String, Sprite>{};

    void putProp(String kind, String facing, String path) {
      final s = _cached(images, path);
      if (s != null) props['$kind|$facing'] = s;
    }

    for (final def in FurnitureRegistry.all) {
      for (final dir in const ['south', 'east', 'north']) {
        putProp(def.id, dir, def.assetPath(dir));
        final mask = def.maskPath(dir);
        if (mask != null) {
          final s = _cached(images, mask);
          if (s != null) propMasks['${def.id}|$dir'] = s;
        }
      }
    }

    putProp(HabitatPropKinds.tv, 'south', HabitatAssets.tvSouth);

    for (final p in map.props) {
      putProp(p.kind, p.facing.spriteKey, p.assetPath);
    }

    return HabitatSprites._(
      wood: floor(HabitatAssets.woodFloor),
      carpet: floor(HabitatAssets.carpet),
      concrete: floor(HabitatAssets.concrete),
      door: _cached(images, HabitatAssets.doorSimpleMover),
      bodyByType: bodyByType,
      headByType: headByType,
      hairByStyle: hairByStyle,
      apparelByPiece: apparelByPiece,
      hatByStyle: hatByStyle,
      beardByStyle: beardByStyle,
      props: props,
      propMasks: propMasks,
    );
  }
}
