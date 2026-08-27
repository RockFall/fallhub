import '../../flame/habitat_tint.dart';
import '../world/context_profile.dart';

/// Contextual clothing / visible kit (MD 08 M31).
class HabitatLoadout {
  const HabitatLoadout({
    required this.id,
    required this.label,
    required this.contextTags,
    this.siteTags = const {},
    this.weatherTags = const {},
    this.priority = 0,
    this.apparelTop,
    this.hat,
  });

  final String id;
  final String label;
  final Set<String> contextTags;
  final Set<String> siteTags;
  final Set<String> weatherTags;
  final int priority;
  final String? apparelTop;
  final String? hat;
}

enum LoadoutAutoPolicy { off, suggest, autoSimulated }

/// Resolves loadout from context without touching identity (M31).
class HabitatLoadoutResolver {
  HabitatLoadoutResolver({
    this.policy = LoadoutAutoPolicy.autoSimulated,
  });

  LoadoutAutoPolicy policy;
  final Map<String, String> currentByPawn = {};
  final List<String> debugLog = [];

  static final List<HabitatLoadout> catalog = [
    const HabitatLoadout(
      id: 'home',
      label: 'Casa',
      contextTags: {'home', 'casual'},
      apparelTop: 'shirt_basic',
      priority: 10,
    ),
    const HabitatLoadout(
      id: 'sleep',
      label: 'Sono',
      contextTags: {'sleep', 'night'},
      apparelTop: 'shirt_basic',
      priority: 40,
    ),
    const HabitatLoadout(
      id: 'work',
      label: 'Trabalho',
      contextTags: {'work', 'office'},
      siteTags: {'office', 'work'},
      apparelTop: 'shirt_button',
      hat: 'tuque',
      priority: 30,
    ),
    const HabitatLoadout(
      id: 'study',
      label: 'Estudo',
      contextTags: {'study', 'focus'},
      apparelTop: 'shirt_button',
      priority: 25,
    ),
    const HabitatLoadout(
      id: 'exercise',
      label: 'Exercício',
      contextTags: {'exercise', 'movement'},
      apparelTop: 'shirt_basic',
      priority: 28,
    ),
    const HabitatLoadout(
      id: 'socialCasual',
      label: 'Social',
      contextTags: {'social', 'guests'},
      apparelTop: 'shirt_button',
      priority: 22,
    ),
    const HabitatLoadout(
      id: 'socialFormal',
      label: 'Formal',
      contextTags: {'formal', 'party'},
      apparelTop: 'shirt_button',
      hat: 'cowboy',
      priority: 35,
    ),
    const HabitatLoadout(
      id: 'travel',
      label: 'Viagem',
      contextTags: {'travel', 'away', 'transit'},
      apparelTop: 'jacket',
      hat: 'tuque',
      priority: 32,
    ),
    const HabitatLoadout(
      id: 'outsideCold',
      label: 'Frio',
      contextTags: {'outdoor', 'cold'},
      weatherTags: {'cold'},
      apparelTop: 'jacket',
      hat: 'tuque',
      priority: 33,
    ),
    const HabitatLoadout(
      id: 'outsideHot',
      label: 'Calor',
      contextTags: {'outdoor', 'hot'},
      weatherTags: {'hot'},
      apparelTop: 'shirt_basic',
      priority: 33,
    ),
  ];

  HabitatLoadout? byId(String id) {
    for (final l in catalog) {
      if (l.id == id) return l;
    }
    return null;
  }

  /// Suggest from scene / sleep / outdoor context.
  HabitatLoadout suggest({
    required String mapLocationId,
    required HabitatContextProfile context,
    required bool jobIsSleep,
    required bool isOutdoor,
    String? scenePresetId,
    bool inTransit = false,
  }) {
    final tags = <String>{
      if (jobIsSleep) 'sleep',
      if (isOutdoor) 'outdoor',
      if (inTransit) 'transit',
      if (scenePresetId == 'guests' || scenePresetId == 'party') 'social',
      if (scenePresetId == 'sleepMode') 'sleep',
      if (context.allows('workDesk')) 'work',
      if (context.allows('sleep')) 'home',
      mapLocationId,
    };

    HabitatLoadout best = catalog.first;
    var bestScore = -1;
    for (final l in catalog) {
      var score = l.priority;
      for (final t in l.contextTags) {
        if (tags.contains(t)) score += 20;
      }
      for (final t in l.siteTags) {
        if (tags.contains(t) || t == mapLocationId) score += 15;
      }
      if (score > bestScore) {
        bestScore = score;
        best = l;
      }
    }
    return best;
  }

  /// Apply if policy allows; returns true when appearance should update.
  bool maybeApply({
    required String pawnId,
    required HabitatLoadout loadout,
    required void Function(String apparelTop, String? hat) applyVisual,
    bool force = false,
  }) {
    if (!force && policy == LoadoutAutoPolicy.off) return false;
    if (!force && policy == LoadoutAutoPolicy.suggest) {
      debugLog.add('suggest:${loadout.id}@$pawnId');
      return false;
    }
    final prev = currentByPawn[pawnId];
    if (prev == loadout.id && !force) return false;
    currentByPawn[pawnId] = loadout.id;
    applyVisual(loadout.apparelTop ?? 'shirt_basic', loadout.hat);
    // Keep VisualLoadouts in sync for cosmetics that still use it.
    if (VisualLoadouts.kit(loadout.id).$1 != null ||
        loadout.id == VisualLoadouts.home ||
        loadout.id == VisualLoadouts.work ||
        loadout.id == VisualLoadouts.outdoors) {
      // no-op bridge — appearance mutated via callback
    }
    debugLog.add('apply:${loadout.id}@$pawnId');
    return true;
  }
}
