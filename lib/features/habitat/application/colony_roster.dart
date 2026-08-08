import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../flame/habitat_tint.dart';
import 'pawn_appearance_store.dart';

/// One cosmetic colonist in the visual colony (V9 — no domain relations).
class ColonyMember {
  ColonyMember({
    required this.id,
    required this.appearance,
    this.isPlayer = false,
  });

  final String id;
  final bool isPlayer;
  PawnAppearance appearance;

  ColonyMember copy() => ColonyMember(
        id: id,
        isPlayer: isPlayer,
        appearance: appearance.copy(),
      );

  Map<String, Object?> toJson() => {
        'id': id,
        'isPlayer': isPlayer,
        'appearance': PawnAppearanceStore.toJson(appearance),
      };

  static ColonyMember fromJson(Map<String, Object?> json) {
    final raw = json['appearance'];
    final appearance = raw is Map
        ? PawnAppearanceStore.fromJson(Map<String, Object?>.from(raw))
        : PawnAppearance();
    return ColonyMember(
      id: json['id'] as String? ?? 'member',
      isPlayer: json['isPlayer'] as bool? ?? false,
      appearance: appearance,
    );
  }
}

abstract final class ColonyRosterStore {
  static const prefsKey = 'habitat_colony_roster_v1';
  static const maxMembers = 4;

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

  static Future<List<ColonyMember>?> load() async {
    final prefs = await _prefs();
    if (prefs == null) return null;
    final raw = prefs.getString(prefsKey);
    if (raw == null || raw.isEmpty) return null;
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return null;
      return [
        for (final e in decoded)
          if (e is Map)
            ColonyMember.fromJson(Map<String, Object?>.from(e)),
      ];
    } catch (_) {
      return null;
    }
  }

  static Future<void> save(List<ColonyMember> members) async {
    final prefs = await _prefs();
    if (prefs == null) return;
    try {
      await prefs.setString(
        prefsKey,
        jsonEncode([for (final m in members) m.toJson()]),
      );
    } on PlatformException {
      // ignore stale pigeon
    } on MissingPluginException {
      // ignore
    }
  }

  static List<ColonyMember> seedDefaults({PawnAppearance? playerLook}) {
    final rng = math.Random(7);
    final player = ColonyMember(
      id: 'player',
      isPlayer: true,
      appearance: (playerLook ?? PawnAppearance()).copy()
        ..name = (playerLook?.name.isNotEmpty ?? false)
            ? playerLook!.name
            : 'Você',
    );
    final friend = ColonyMember(
      id: 'friend_a',
      appearance: PawnAppearance(
        name: 'Mira',
        bodyType: 'female',
        hairStyle: 'bob',
        apparelTop: 'shirt_button',
        skin: PawnPalettes.skinLight,
        hair: PawnPalettes.hairAuburn,
        apparelTint: StuffPalettes.clothPurple,
      )..randomizeHair(rng: rng),
    );
    final buddy = ColonyMember(
      id: 'friend_b',
      appearance: PawnAppearance(
        name: 'Rex',
        bodyType: 'thin',
        hairStyle: 'mohawk',
        beardStyle: 'goatee',
        apparelTop: 'jacket',
        skin: PawnPalettes.skinTan,
        hair: PawnPalettes.hairBlack,
        apparelTint: StuffPalettes.clothGreen,
      ),
    );
    return [player, friend, buddy];
  }
}

class ColonyRosterNotifier extends Notifier<List<ColonyMember>> {
  int _epoch = 0;

  @override
  List<ColonyMember> build() {
    final start = _epoch;
    unawaited(_hydrate(start));
    return ColonyRosterStore.seedDefaults();
  }

  Future<void> _hydrate(int startEpoch) async {
    final loaded = await ColonyRosterStore.load();
    if (startEpoch != _epoch) return;
    if (loaded != null && loaded.isNotEmpty) {
      state = [for (final m in loaded) m.copy()];
      return;
    }
    final legacy = await PawnAppearanceStore.load();
    final seeded = ColonyRosterStore.seedDefaults(playerLook: legacy);
    state = seeded;
    await ColonyRosterStore.save(seeded);
  }

  Future<void> _persist() async {
    _epoch++;
    await ColonyRosterStore.save([for (final m in state) m.copy()]);
  }

  ColonyMember? byId(String id) {
    for (final m in state) {
      if (m.id == id) return m;
    }
    return null;
  }

  Future<void> replaceAppearance(String id, PawnAppearance next) async {
    state = [
      for (final m in state)
        if (m.id == id)
          ColonyMember(
            id: m.id,
            isPlayer: m.isPlayer,
            appearance: next.copy(),
          )
        else
          m.copy(),
    ];
    await _persist();
    ColonyMember? player;
    for (final m in state) {
      if (m.isPlayer) {
        player = m;
        break;
      }
    }
    player ??= state.isEmpty ? null : state.first;
    if (player != null && player.id == id) {
      await PawnAppearanceStore.save(player.appearance);
    }
  }

  Future<ColonyMember?> addRandom() async {
    if (state.length >= ColonyRosterStore.maxMembers) return null;
    final rng = math.Random();
    final look = PawnAppearance()..randomize(includeSkin: true, rng: rng);
    look.name = 'Colonista ${state.length + 1}';
    final member = ColonyMember(
      id: 'member_${DateTime.now().millisecondsSinceEpoch}',
      appearance: look,
    );
    state = [...state, member];
    await _persist();
    return member;
  }

  Future<bool> remove(String id) async {
    final target = byId(id);
    if (target == null || target.isPlayer) return false;
    if (state.length <= 1) return false;
    state = [for (final m in state) if (m.id != id) m.copy()];
    await _persist();
    return true;
  }
}

final colonyRosterProvider =
    NotifierProvider<ColonyRosterNotifier, List<ColonyMember>>(
  ColonyRosterNotifier.new,
);
