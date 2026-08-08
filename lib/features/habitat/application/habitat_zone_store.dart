import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../flame/habitat_zones.dart';

/// Per-pawn allowed cells (null = unrestricted). V9.13.
abstract final class HabitatZoneStore {
  static const prefsKey = 'habitat_zones_v1';

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

  static Future<Map<String, Set<(int, int)>?>> load() async {
    final prefs = await _prefs();
    if (prefs == null) return {};
    final raw = prefs.getString(prefsKey);
    if (raw == null || raw.isEmpty) return {};
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map) return {};
      return fromJson(Map<String, Object?>.from(decoded));
    } catch (_) {
      return {};
    }
  }

  static Future<void> save(Map<String, Set<(int, int)>?> zones) async {
    final prefs = await _prefs();
    if (prefs == null) return;
    try {
      await prefs.setString(prefsKey, jsonEncode(toJson(zones)));
    } on PlatformException {
      // ignore
    } on MissingPluginException {
      // ignore
    } catch (_) {
      // ignore
    }
  }

  static Map<String, Object?> toJson(Map<String, Set<(int, int)>?> zones) => {
        for (final e in zones.entries)
          e.key: e.value == null
              ? null
              : HabitatZones.encodeCells(e.value!),
      };

  static Map<String, Set<(int, int)>?> fromJson(Map<String, Object?> json) {
    final out = <String, Set<(int, int)>?>{};
    for (final e in json.entries) {
      final v = e.value;
      if (v == null) {
        out[e.key] = null;
      } else if (v is List) {
        out[e.key] = HabitatZones.decodeCells(v);
      }
    }
    return out;
  }
}
