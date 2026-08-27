import '../mirror/mirror_signal.dart';

/// Contextual configuration of a site without duplicating the map (MD 08 M30).
class ScenePreset {
  const ScenePreset({
    required this.id,
    required this.label,
    required this.siteId,
    this.propStates = const {},
    this.lightingPreset = 'normal',
    this.ambientAudioPreset,
    this.enabledDecorIds = const {},
    this.affordanceModifiers = const {},
  });

  final String id;
  final String label;
  final String siteId;
  final Map<String, Object?> propStates;
  final String lightingPreset;
  final String? ambientAudioPreset;
  final Set<String> enabledDecorIds;
  final Map<String, double> affordanceModifiers;
}

/// Stateful environment bits that survive activities (M30).
enum HabitatEnvSwitch {
  doorOpen,
  windowOpen,
  lampOn,
  tvOn,
  speakerPlaying,
  computerActive,
  showerOn,
  stoveOn,
  curtainOpen,
}

class HabitatEnvironmentState {
  HabitatEnvironmentState({Map<HabitatEnvSwitch, bool>? switches})
      : switches = {
          for (final s in HabitatEnvSwitch.values) s: false,
          ...?switches,
        };

  final Map<HabitatEnvSwitch, bool> switches;
  final List<String> vestiges = [];

  bool operator [](HabitatEnvSwitch s) => switches[s] ?? false;

  void set(HabitatEnvSwitch s, bool value) => switches[s] = value;

  void addVestige(String note) {
    vestiges.add(note);
    if (vestiges.length > 24) vestiges.removeAt(0);
  }

  HabitatEnvironmentState copy() {
    final next = HabitatEnvironmentState(switches: Map.of(switches));
    next.vestiges.addAll(vestiges);
    return next;
  }
}

/// Applies scene presets and keeps environment state in-session (M30).
class ScenePresetDirector {
  ScenePresetDirector({this.siteId = 'home_apartment'});

  final String siteId;
  HabitatEnvironmentState environment = HabitatEnvironmentState(
    switches: {
      HabitatEnvSwitch.lampOn: true,
      HabitatEnvSwitch.doorOpen: false,
      HabitatEnvSwitch.curtainOpen: true,
    },
  );
  String? activePresetId;
  final List<String> debugLog = [];

  static List<ScenePreset> seedsFor(String siteId) => [
        ScenePreset(
          id: 'normal',
          label: 'Normal',
          siteId: siteId,
          lightingPreset: 'normal',
          propStates: const {'lamp': 'on', 'tv': 'off'},
        ),
        ScenePreset(
          id: 'quietEvening',
          label: 'Noite quieta',
          siteId: siteId,
          lightingPreset: 'dim',
          propStates: const {'lamp': 'on', 'tv': 'off', 'speaker': 'soft'},
          affordanceModifiers: const {'sleep': 0.15, 'listenMusic': 0.1},
        ),
        ScenePreset(
          id: 'movieNight',
          label: 'Noite de filme',
          siteId: siteId,
          lightingPreset: 'cinema',
          propStates: const {'tv': 'on', 'lamp': 'off', 'curtain': 'closed'},
          enabledDecorIds: const {'popcorn_bowl'},
          affordanceModifiers: const {'watchTv': 0.35, 'socialChat': 0.1},
        ),
        ScenePreset(
          id: 'sleepMode',
          label: 'Modo sono',
          siteId: siteId,
          lightingPreset: 'night',
          propStates: const {
            'lamp': 'off',
            'tv': 'off',
            'computer': 'sleep',
            'curtain': 'closed',
          },
          affordanceModifiers: const {'sleep': 0.45, 'watchTv': -0.3},
        ),
        ScenePreset(
          id: 'guests',
          label: 'Visitas',
          siteId: siteId,
          lightingPreset: 'bright',
          propStates: const {'lamp': 'on', 'speaker': 'on'},
          affordanceModifiers: const {'socialChat': 0.3, 'goToTable': 0.2},
        ),
        ScenePreset(
          id: 'morning',
          label: 'Manhã',
          siteId: siteId,
          lightingPreset: 'morning',
          propStates: const {'curtain': 'open', 'lamp': 'off'},
          affordanceModifiers: const {'stretch': 0.15, 'goToTable': 0.1},
        ),
      ];

  List<ScenePreset> get presets => seedsFor(siteId);

  ScenePreset? get active {
    final id = activePresetId;
    if (id == null) return null;
    for (final p in presets) {
      if (p.id == id) return p;
    }
    return null;
  }

  /// Apply preset — mutates lights/screens/decor flags, keeps vestiges.
  void apply(String presetId, {double nowSim = 0}) {
    ScenePreset? preset;
    for (final p in presets) {
      if (p.id == presetId) preset = p;
    }
    if (preset == null) return;
    activePresetId = presetId;

    final ps = preset.propStates;
    if (ps['lamp'] == 'on') environment.set(HabitatEnvSwitch.lampOn, true);
    if (ps['lamp'] == 'off') environment.set(HabitatEnvSwitch.lampOn, false);
    if (ps['tv'] == 'on') environment.set(HabitatEnvSwitch.tvOn, true);
    if (ps['tv'] == 'off') environment.set(HabitatEnvSwitch.tvOn, false);
    if (ps['speaker'] != null) {
      environment.set(
        HabitatEnvSwitch.speakerPlaying,
        ps['speaker'] != 'off',
      );
    }
    if (ps['computer'] == 'sleep') {
      environment.set(HabitatEnvSwitch.computerActive, false);
    }
    if (ps['computer'] == 'active') {
      environment.set(HabitatEnvSwitch.computerActive, true);
    }
    if (ps['curtain'] == 'closed') {
      environment.set(HabitatEnvSwitch.curtainOpen, false);
    }
    if (ps['curtain'] == 'open') {
      environment.set(HabitatEnvSwitch.curtainOpen, true);
    }

    debugLog.add('[${nowSim.toStringAsFixed(0)}s] preset:${preset.id}');
  }

  /// Aftermath of an activity — do not wipe environment (M30 vestiges).
  void markAftermath(String activityKind) {
    switch (activityKind) {
      case 'movie':
      case 'watchTv':
        environment.set(HabitatEnvSwitch.tvOn, true);
        environment.addVestige('xícaras na mesa');
      case 'dinner':
        environment.addVestige('pratos na mesa');
      case 'listenMusic':
        environment.set(HabitatEnvSwitch.speakerPlaying, true);
      default:
        environment.addVestige('vestígio:$activityKind');
    }
  }

  double affordanceBoost(String affordanceId) {
    final p = active;
    if (p == null) return 0;
    return p.affordanceModifiers[affordanceId] ?? 0;
  }

  MirrorSignal<String> lightingSignal() {
    return MirrorSignal<String>(
      id: 'scene.lighting',
      value: active?.lightingPreset ?? 'normal',
      source: MirrorSignalSource.simulated,
      observedAt: DateTime.now().toUtc(),
      confidence: 1,
    );
  }
}
