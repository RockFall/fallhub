/// Data-driven content registry (MD 08 M42).

class HabitatPropDefinition {
  const HabitatPropDefinition({
    required this.id,
    required this.label,
    required this.tags,
    this.affordances = const [],
    this.interestTags = const {},
    this.assetKey,
  });

  final String id;
  final String label;
  final Set<String> tags;
  final List<String> affordances;
  final Set<String> interestTags;
  final String? assetKey;
}

class HabitatItemDefinition {
  const HabitatItemDefinition({
    required this.id,
    required this.label,
    required this.tags,
  });

  final String id;
  final String label;
  final Set<String> tags;
}

class HabitatActivityDefinition {
  const HabitatActivityDefinition({
    required this.id,
    required this.label,
    required this.targetTags,
    this.durationSim = 30,
    this.minParticipants = 1,
    this.maxParticipants = 1,
    this.needEffects = const {},
    this.interestTags = const {},
  });

  final String id;
  final String label;
  final Set<String> targetTags;
  final double durationSim;
  final int minParticipants;
  final int maxParticipants;
  final Map<String, double> needEffects;
  final Set<String> interestTags;
}

class ContentValidationIssue {
  const ContentValidationIssue(this.message);
  final String message;
}

/// Registry of definitions used by editor + sim (M42).
class HabitatContentRegistry {
  HabitatContentRegistry() {
    _seed();
  }

  final Map<String, HabitatPropDefinition> props = {};
  final Map<String, HabitatItemDefinition> items = {};
  final Map<String, HabitatActivityDefinition> activities = {};
  final Set<String> knownAffordanceIds = {
    'sleep',
    'sit',
    'goToTable',
    'wander',
    'listenMusic',
    'creativeShort',
    'practiceInstrument',
    'performMusic',
    'watchTv',
    'socialChat',
  };

  void _seed() {
    registerProp(
      const HabitatPropDefinition(
        id: 'prop.piano',
        label: 'Piano',
        tags: {'music', 'instrument', 'piano'},
        affordances: ['practiceInstrument', 'performMusic'],
        interestTags: {'music'},
        assetKey: 'piano',
      ),
    );
    registerProp(
      const HabitatPropDefinition(
        id: 'prop.saxophone_alto',
        label: 'Sax alto',
        tags: {'music', 'instrument', 'saxophone'},
        affordances: ['practiceInstrument', 'performMusic'],
        interestTags: {'music', 'music.jazz'},
        assetKey: 'saxophone',
      ),
    );
    registerItem(
      const HabitatItemDefinition(
        id: 'item.vinyl',
        label: 'Vinil',
        tags: {'album', 'media', 'vinyl'},
      ),
    );
    registerActivity(
      const HabitatActivityDefinition(
        id: 'act.listen_vinyl',
        label: 'Ouvir vinil',
        targetTags: {'recordPlayer', 'vinyl'},
        durationSim: 45,
        maxParticipants: 4,
        needEffects: {'recreation': 0.3, 'creativeExpression': 0.1},
        interestTags: {'music'},
      ),
    );
  }

  void registerProp(HabitatPropDefinition def) => props[def.id] = def;
  void registerItem(HabitatItemDefinition def) => items[def.id] = def;
  void registerActivity(HabitatActivityDefinition def) =>
      activities[def.id] = def;

  HabitatPropDefinition? getPropDefinition(String id) => props[id];

  List<HabitatPropDefinition> getAffordancesForTags(Set<String> tags) {
    return props.values
        .where((p) => p.tags.intersection(tags).isNotEmpty)
        .toList();
  }

  HabitatActivityDefinition? getActivityDefinition(String id) =>
      activities[id];

  List<ContentValidationIssue> validate() {
    final issues = <ContentValidationIssue>[];
    final propIds = <String>{};
    for (final p in props.values) {
      if (!propIds.add(p.id)) {
        issues.add(ContentValidationIssue('duplicate prop ${p.id}'));
      }
      for (final a in p.affordances) {
        if (!knownAffordanceIds.contains(a)) {
          issues.add(
            ContentValidationIssue('prop ${p.id} unknown affordance $a'),
          );
        }
      }
    }
    for (final a in activities.values) {
      if (a.durationSim <= 0) {
        issues.add(ContentValidationIssue('activity ${a.id} invalid duration'));
      }
      if (a.minParticipants > a.maxParticipants) {
        issues.add(ContentValidationIssue('activity ${a.id} bad participants'));
      }
    }
    return issues;
  }
}
