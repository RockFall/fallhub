import 'dart:convert';

import 'package:flutter/painting.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../flame/habitat_tint.dart';

/// Light local persist for colonist cosmetics (doc 07 — before Drift V12).
///
/// SharedPreferences needs a full app rebuild after the plugin is added;
/// hot restart alone leaves a broken pigeon channel — we never throw outward.
abstract final class PawnAppearanceStore {
  static const prefsKey = 'habitat_pawn_appearance_v1';

  static Map<String, Object?> toJson(PawnAppearance a) => {
        'name': a.name,
        'bodyType': a.bodyType,
        'hairStyle': a.hairStyle,
        'beardStyle': a.beardStyle,
        'apparelTop': a.apparelTop,
        'hat': a.hat,
        'loadoutId': a.loadoutId,
        'skin': a.skin.toARGB32(),
        'hair': a.hair.toARGB32(),
        'apparelTint': a.apparelTint.toARGB32(),
        'bio': a.bio,
      };

  static PawnAppearance fromJson(Map<String, Object?> json) {
    return PawnAppearance(
      name: json['name'] as String? ?? 'Colonista',
      bodyType: json['bodyType'] as String? ?? 'male',
      hairStyle: json['hairStyle'] as String? ?? 'bob',
      beardStyle: json['beardStyle'] as String?,
      apparelTop: json['apparelTop'] as String? ?? 'shirt_basic',
      hat: json['hat'] as String?,
      loadoutId: json['loadoutId'] as String? ?? VisualLoadouts.home,
      skin: Color(json['skin'] as int? ?? PawnPalettes.skinMedium.toARGB32()),
      hair: Color(json['hair'] as int? ?? PawnPalettes.hairBrown.toARGB32()),
      apparelTint: Color(
        json['apparelTint'] as int? ?? StuffPalettes.clothBlue.toARGB32(),
      ),
      bio: json['bio'] as String? ?? '',
    );
  }

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

  static Future<PawnAppearance?> load() async {
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

  static Future<void> save(PawnAppearance appearance) async {
    final prefs = await _prefs();
    if (prefs == null) return;
    try {
      await prefs.setString(prefsKey, jsonEncode(toJson(appearance)));
    } on PlatformException {
      // Hot-restart without native plugin rebuild — ignore.
    } on MissingPluginException {
      // Same.
    }
  }
}
