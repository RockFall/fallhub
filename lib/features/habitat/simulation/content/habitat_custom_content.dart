import 'habitat_content_registry.dart';

/// User-composed content from registered primitives (MD 08 M43) — no scripting.
class CustomContentDraft {
  CustomContentDraft({
    required this.kind,
    required this.name,
    this.tags = const {},
    this.affordances = const [],
    this.interestTags = const {},
    this.durationSim = 30,
    this.needEffects = const {},
    this.tintHex,
  });

  final String kind; // prop | activity
  String name;
  Set<String> tags;
  List<String> affordances;
  Set<String> interestTags;
  double durationSim;
  Map<String, double> needEffects;
  String? tintHex;
}

class CustomContentResult {
  const CustomContentResult.ok(this.id) : error = null;
  const CustomContentResult.err(this.error) : id = null;

  final String? id;
  final String? error;
  bool get isOk => error == null && id != null;
}

/// Safe custom prop/activity creator (M43).
class HabitatCustomContentCreator {
  HabitatCustomContentCreator(this.registry);

  final HabitatContentRegistry registry;
  final Map<String, Object> saved = {};
  final List<String> debugLog = [];

  CustomContentResult createProp(CustomContentDraft draft) {
    if (draft.name.trim().isEmpty) {
      return const CustomContentResult.err('nome vazio');
    }
    if (draft.affordances.isEmpty) {
      return const CustomContentResult.err('sem affordance');
    }
    for (final a in draft.affordances) {
      if (!registry.knownAffordanceIds.contains(a)) {
        return CustomContentResult.err('affordance inválida: $a');
      }
    }
    final id = 'custom.prop.${draft.name.hashCode.abs()}';
    final def = HabitatPropDefinition(
      id: id,
      label: draft.name,
      tags: {...draft.tags, 'custom', 'personal'},
      affordances: draft.affordances,
      interestTags: draft.interestTags,
      assetKey: draft.tintHex,
    );
    registry.registerProp(def);
    saved[id] = def;
    debugLog.add('created prop $id');
    return CustomContentResult.ok(id);
  }

  CustomContentResult createActivity(CustomContentDraft draft) {
    if (draft.name.trim().isEmpty) {
      return const CustomContentResult.err('nome vazio');
    }
    if (draft.durationSim <= 0 || draft.durationSim > 600) {
      return const CustomContentResult.err('duração inválida');
    }
    for (final e in draft.needEffects.entries) {
      if (e.value.abs() > 1) {
        return CustomContentResult.err('efeito fora de range: ${e.key}');
      }
    }
    if (draft.tags.isEmpty) {
      return const CustomContentResult.err('missing target tags');
    }
    final id = 'custom.act.${draft.name.hashCode.abs()}';
    final def = HabitatActivityDefinition(
      id: id,
      label: draft.name,
      targetTags: draft.tags,
      durationSim: draft.durationSim,
      maxParticipants: 4,
      needEffects: draft.needEffects,
      interestTags: draft.interestTags,
    );
    registry.registerActivity(def);
    saved[id] = def;
    debugLog.add('created activity $id');
    return CustomContentResult.ok(id);
  }

  /// Simulate restart: re-register saved definitions.
  void restoreInto(HabitatContentRegistry target) {
    for (final v in saved.values) {
      if (v is HabitatPropDefinition) target.registerProp(v);
      if (v is HabitatActivityDefinition) target.registerActivity(v);
    }
  }
}
