import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../flame/habitat_locations.dart';
import '../flame/habitat_map.dart';
import '../flame/habitat_prop_catalog.dart';

/// Persisted Habitat layouts (cosmetic edits before Drift V14).
class HabitatWorldSave {
  const HabitatWorldSave({
    required this.locationId,
    required this.maps,
  });

  final String locationId;
  final Map<String, HabitatMap> maps;
}

/// SharedPreferences store for multi-locale habitat maps.
abstract final class HabitatMapStore {
  static const prefsKey = 'habitat_maps_v1';

  static Future<SharedPreferences?> _prefs() async {
    try {
      return await SharedPreferences.getInstance();
    } on PlatformException {
      return null;
    } on MissingPluginException {
      return null;
    } catch (_) {
      return null;
    }
  }

  static Future<HabitatWorldSave?> load() async {
    final prefs = await _prefs();
    if (prefs == null) return null;
    final raw = prefs.getString(prefsKey);
    if (raw == null || raw.isEmpty) return null;
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map) return null;
      return fromJson(Map<String, Object?>.from(decoded));
    } catch (_) {
      return null;
    }
  }

  static Future<void> save(HabitatWorldSave world) async {
    final prefs = await _prefs();
    if (prefs == null) return;
    try {
      await prefs.setString(prefsKey, jsonEncode(toJson(world)));
    } on PlatformException {
      // Hot-restart without native plugin — ignore.
    } on MissingPluginException {
      // Same as PlatformException.
    } catch (_) {
      // Prefs unavailable in some test / desktop edge cases.
    }
  }

  static Map<String, Object?> toJson(HabitatWorldSave world) => {
        'locationId': world.locationId,
        'maps': {
          for (final e in world.maps.entries) e.key: mapToJson(e.value),
        },
      };

  static HabitatWorldSave? fromJson(Map<String, Object?> json) {
    final locationId = json['locationId'] as String? ?? HabitatLocationIds.bedroom;
    final mapsRaw = json['maps'];
    if (mapsRaw is! Map) return null;
    final maps = <String, HabitatMap>{};
    for (final e in mapsRaw.entries) {
      final id = e.key.toString();
      final value = e.value;
      if (value is! Map) continue;
      final map = mapFromJson(Map<String, Object?>.from(value));
      if (map != null) maps[id] = map;
    }
    if (maps.isEmpty) return null;
    return HabitatWorldSave(locationId: locationId, maps: maps);
  }

  static Map<String, Object?> mapToJson(HabitatMap map) => {
        'width': map.width,
        'height': map.height,
        'floors': [for (final f in map.floors) f.index],
        'filth': map.filth,
        'door': [map.doorCell.$1, map.doorCell.$2],
        'walls': [
          for (final c in map.customWalls) [c.$1, c.$2],
        ],
        'props': [
          for (final p in map.props)
            {
              'id': p.id,
              'kind': p.kind,
              'ox': p.origin.$1,
              'oy': p.origin.$2,
              'tint': p.tint.toARGB32(),
              'quality': p.quality.name,
            },
        ],
      };

  static HabitatMap? mapFromJson(Map<String, Object?> json) {
    final width = json['width'] as int?;
    final height = json['height'] as int?;
    final floorsRaw = json['floors'];
    if (width == null || height == null || floorsRaw is! List) return null;
    if (floorsRaw.length != width * height) return null;

    final floors = <HabitatFloor>[
      for (final v in floorsRaw)
        HabitatFloor.values[((v as num).toInt()).clamp(0, HabitatFloor.values.length - 1)],
    ];

    final doorRaw = json['door'];
    (int, int)? door;
    if (doorRaw is List && doorRaw.length >= 2) {
      door = ((doorRaw[0] as num).toInt(), (doorRaw[1] as num).toInt());
    }

    final walls = <(int, int)>{};
    final wallsRaw = json['walls'];
    if (wallsRaw is List) {
      for (final w in wallsRaw) {
        if (w is List && w.length >= 2) {
          walls.add(((w[0] as num).toInt(), (w[1] as num).toInt()));
        }
      }
    }

    final props = <HabitatProp>[];
    final propsRaw = json['props'];
    if (propsRaw is List) {
      for (final raw in propsRaw) {
        if (raw is! Map) continue;
        final m = Map<String, Object?>.from(raw);
        final kind = m['kind'] as String?;
        final ox = m['ox'];
        final oy = m['oy'];
        if (kind == null || ox is! num || oy is! num) continue;
        if (!HabitatPropKinds.all.contains(kind)) continue;
        final tint = m['tint'];
        final qualityName = m['quality'] as String? ?? 'normal';
        final quality = HabitatPropQuality.values.firstWhere(
          (q) => q.name == qualityName,
          orElse: () => HabitatPropQuality.normal,
        );
        props.add(
          HabitatPropCatalog.spawn(
            kind,
            (ox.toInt(), oy.toInt()),
            id: m['id'] as String?,
            tint: tint is int ? Color(tint) : null,
            quality: quality,
          ),
        );
      }
    }

    final map = HabitatMap(
      width: width,
      height: height,
      floors: floors,
      props: props,
      doorCell: door,
      customWalls: walls,
    );

    final filthRaw = json['filth'];
    if (filthRaw is List && filthRaw.length == map.filth.length) {
      for (var i = 0; i < map.filth.length; i++) {
        map.filth[i] = (filthRaw[i] as num).toDouble().clamp(0.0, 1.0);
      }
    }
    return map;
  }
}
