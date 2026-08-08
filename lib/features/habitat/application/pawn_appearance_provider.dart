import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../flame/habitat_tint.dart';
import 'pawn_appearance_store.dart';

/// Shared colonist look — create screen writes, Habitat reads, prefs persist.
class PawnAppearanceNotifier extends Notifier<PawnAppearance> {
  /// Bumped on every user write so a late hydrate cannot clobber fresh edits.
  int _epoch = 0;
  var _ready = false;

  bool get isReady => _ready;

  @override
  PawnAppearance build() {
    final startEpoch = _epoch;
    unawaited(_hydrate(startEpoch));
    return PawnAppearance();
  }

  Future<void> _hydrate(int startEpoch) async {
    final loaded = await PawnAppearanceStore.load();
    if (startEpoch != _epoch) {
      _ready = true;
      return;
    }
    if (loaded != null) {
      state = loaded;
    }
    _ready = true;
  }

  Future<void> replace(PawnAppearance next) async {
    _epoch++;
    _ready = true;
    state = next.copy();
    await PawnAppearanceStore.save(state);
  }

  Future<void> update(void Function(PawnAppearance a) fn) async {
    final next = state.copy();
    fn(next);
    await replace(next);
  }
}

final pawnAppearanceProvider =
    NotifierProvider<PawnAppearanceNotifier, PawnAppearance>(
  PawnAppearanceNotifier.new,
);
