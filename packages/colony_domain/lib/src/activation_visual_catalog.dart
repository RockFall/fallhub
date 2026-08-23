import 'activation_enums.dart';
import 'activation_models.dart';

enum ActivationDaypart { morning, day, evening, night }

class ActivationRouteStation {
  const ActivationRouteStation({
    required this.key,
    required this.label,
    this.waypointSeedKey,
  });

  final String key;
  final String label;
  final String? waypointSeedKey;
}

class ActivationVisualSpec {
  const ActivationVisualSpec({
    required this.seedKey,
    required this.artAsset,
    required this.daypart,
    required this.journeyLabel,
    required this.stations,
    this.protocolType,
  });

  final String seedKey;
  final String artAsset;
  final ActivationDaypart daypart;
  final String journeyLabel;
  final List<ActivationRouteStation> stations;
  final ActivationProtocolType? protocolType;
}

/// Artes e estações canônicas das rotas de ignição (originais, sem HUD).
abstract final class ActivationArtAssets {
  static const hero = 'assets/activation/ignition_hero.png';
  static const morning = 'assets/activation/ignition_morning.png';
  static const desk = 'assets/activation/ignition_desk.png';
  static const study = 'assets/activation/ignition_study.png';
  static const night = 'assets/activation/ignition_night.png';
  static const walk = 'assets/activation/ignition_walk.png';
  static const map = 'assets/activation/ignition_map.png';
  static const scroll = 'assets/activation/ignition_scroll.png';
  static const piano = 'assets/activation/ignition_piano.png';
  static const shower = 'assets/activation/ignition_shower.png';
}

abstract final class ActivationVisualCatalog {
  static const catalog = <ActivationVisualSpec>[
    ActivationVisualSpec(
      seedKey: 'morning_launch_standard',
      artAsset: ActivationArtAssets.morning,
      daypart: ActivationDaypart.morning,
      journeyLabel: 'Cama → primeira ação',
      protocolType: ActivationProtocolType.wakeUp,
      stations: [
        ActivationRouteStation(
          key: 'bed',
          label: 'Cama',
          waypointSeedKey: 'bed',
        ),
        ActivationRouteStation(
          key: 'bathroom_dock',
          label: 'Banheiro',
          waypointSeedKey: 'bathroom_dock',
        ),
        ActivationRouteStation(key: 'shower', label: 'Chuveiro'),
        ActivationRouteStation(key: 'clothes', label: 'Roupa'),
        ActivationRouteStation(
          key: 'water',
          label: 'Água',
          waypointSeedKey: 'kitchen_light',
        ),
        ActivationRouteStation(
          key: 'desk',
          label: 'Mesa',
          waypointSeedKey: 'desk_dock',
        ),
        ActivationRouteStation(key: 'first_action', label: 'Primeira ação'),
      ],
    ),
    ActivationVisualSpec(
      seedKey: 'morning_launch_minimal',
      artAsset: ActivationArtAssets.morning,
      daypart: ActivationDaypart.morning,
      journeyLabel: 'Cama → em pé',
      protocolType: ActivationProtocolType.wakeUp,
      stations: [
        ActivationRouteStation(key: 'bed', label: 'Beira da cama'),
        ActivationRouteStation(key: 'water', label: 'Água'),
        ActivationRouteStation(
          key: 'bathroom',
          label: 'Banheiro',
          waypointSeedKey: 'bathroom_dock',
        ),
        ActivationRouteStation(key: 'hygiene', label: 'Higiene'),
        ActivationRouteStation(key: 'clothes', label: 'Roupa'),
        ActivationRouteStation(key: 'reassess', label: 'Próximo movimento'),
      ],
    ),
    ActivationVisualSpec(
      seedKey: 'code_ignition',
      artAsset: ActivationArtAssets.desk,
      daypart: ActivationDaypart.day,
      journeyLabel: 'Dock → primeira mudança',
      protocolType: ActivationProtocolType.workStart,
      stations: [
        ActivationRouteStation(
          key: 'desk_dock',
          label: 'Dock',
          waypointSeedKey: 'desk_dock',
        ),
        ActivationRouteStation(key: 'workspace', label: 'Workspace'),
        ActivationRouteStation(key: 'issue', label: 'Issue'),
        ActivationRouteStation(key: 'restart_note', label: 'Nota'),
        ActivationRouteStation(key: 'first_action', label: 'Primeira mudança'),
      ],
    ),
    ActivationVisualSpec(
      seedKey: 'study_ignition',
      artAsset: ActivationArtAssets.study,
      daypart: ActivationDaypart.day,
      journeyLabel: 'Mesa → cinco minutos',
      protocolType: ActivationProtocolType.studyStart,
      stations: [
        ActivationRouteStation(
          key: 'desk',
          label: 'Mesa',
          waypointSeedKey: 'desk_dock',
        ),
        ActivationRouteStation(key: 'material', label: 'Material'),
        ActivationRouteStation(key: 'prompt', label: 'Enunciado'),
        ActivationRouteStation(key: 'question', label: 'Escrita'),
        ActivationRouteStation(key: 'study_contact', label: 'Cinco minutos'),
      ],
    ),
    ActivationVisualSpec(
      seedKey: 'piano_ignition',
      artAsset: ActivationArtAssets.piano,
      daypart: ActivationDaypart.day,
      journeyLabel: 'Banco → oito compassos',
      protocolType: ActivationProtocolType.creativeStart,
      stations: [
        ActivationRouteStation(
          key: 'piano_bench',
          label: 'Banco',
          waypointSeedKey: 'piano_bench',
        ),
        ActivationRouteStation(key: 'piano', label: 'Instrumento'),
        ActivationRouteStation(key: 'scale', label: 'Escala'),
        ActivationRouteStation(key: 'piece', label: 'Oito compassos'),
      ],
    ),
    ActivationVisualSpec(
      seedKey: 'music_expedition_walk',
      artAsset: ActivationArtAssets.walk,
      daypart: ActivationDaypart.evening,
      journeyLabel: 'Tênis → rua',
      protocolType: ActivationProtocolType.exerciseStart,
      stations: [
        ActivationRouteStation(
          key: 'shoes',
          label: 'Tênis',
          waypointSeedKey: 'exercise_mat',
        ),
        ActivationRouteStation(
          key: 'front_door',
          label: 'Porta',
          waypointSeedKey: 'front_door',
        ),
        ActivationRouteStation(key: 'atlas_encounter', label: 'Atlas'),
        ActivationRouteStation(key: 'walk', label: 'Caminhada'),
      ],
    ),
    ActivationVisualSpec(
      seedKey: 'shower_reset',
      artAsset: ActivationArtAssets.shower,
      daypart: ActivationDaypart.morning,
      journeyLabel: 'Dock → chuveiro',
      protocolType: ActivationProtocolType.hygiene,
      stations: [
        ActivationRouteStation(
          key: 'bathroom_dock',
          label: 'Dock',
          waypointSeedKey: 'bathroom_dock',
        ),
        ActivationRouteStation(key: 'playlist', label: 'Som'),
        ActivationRouteStation(key: 'shower', label: 'Chuveiro'),
      ],
    ),
    ActivationVisualSpec(
      seedKey: 'leave_home',
      artAsset: ActivationArtAssets.walk,
      daypart: ActivationDaypart.day,
      journeyLabel: 'Roupa → porta',
      protocolType: ActivationProtocolType.departure,
      stations: [
        ActivationRouteStation(key: 'clothes', label: 'Roupa'),
        ActivationRouteStation(key: 'loadout', label: 'Loadout'),
        ActivationRouteStation(
          key: 'front_door',
          label: 'Porta',
          waypointSeedKey: 'front_door',
        ),
        ActivationRouteStation(key: 'outside', label: 'Fora'),
      ],
    ),
    ActivationVisualSpec(
      seedKey: 'night_runway',
      artAsset: ActivationArtAssets.night,
      daypart: ActivationDaypart.night,
      journeyLabel: 'Roupa → nota de amanhã',
      protocolType: ActivationProtocolType.sleepPreparation,
      stations: [
        ActivationRouteStation(key: 'clothes', label: 'Roupa'),
        ActivationRouteStation(
          key: 'water',
          label: 'Água',
          waypointSeedKey: 'kitchen_light',
        ),
        ActivationRouteStation(key: 'first_action', label: 'Nota de amanhã'),
      ],
    ),
    ActivationVisualSpec(
      seedKey: 'anti_scroll',
      artAsset: ActivationArtAssets.scroll,
      daypart: ActivationDaypart.night,
      journeyLabel: 'Tela → três passos',
      protocolType: ActivationProtocolType.antiScroll,
      stations: [
        ActivationRouteStation(key: 'phone', label: 'Travar'),
        ActivationRouteStation(key: 'surface', label: 'Virar'),
        ActivationRouteStation(key: 'steps', label: 'Três passos'),
      ],
    ),
  ];

  static ActivationVisualSpec? bySeedKey(String? key) {
    if (key == null) return null;
    for (final spec in catalog) {
      if (spec.seedKey == key) return spec;
    }
    return null;
  }

  static ActivationVisualSpec forProtocol(ActivationProtocol protocol) {
    return bySeedKey(protocol.seedKey) ??
        forType(protocol.protocolType);
  }

  static ActivationVisualSpec forType(ActivationProtocolType type) {
    for (final spec in catalog) {
      if (spec.protocolType == type) return spec;
    }
    return catalog.first;
  }

  static String artForProtocol(ActivationProtocol? protocol) {
    if (protocol == null) return ActivationArtAssets.hero;
    return forProtocol(protocol).artAsset;
  }

  static List<ActivationRouteStation> stationsFor(ActivationProtocol? protocol) {
    if (protocol == null) return const [];
    return forProtocol(protocol).stations;
  }

  static List<ActivationVisualSpec> byDaypart(ActivationDaypart daypart) {
    return [
      for (final spec in catalog)
        if (spec.daypart == daypart) spec,
    ];
  }

  static int stationIndex({
    required ActivationVisualSpec spec,
    String? destinationRef,
    String? objectRef,
    int runIndex = 0,
    int runCount = 1,
  }) {
    final refs = [destinationRef, objectRef];
    for (final ref in refs) {
      if (ref == null) continue;
      final match = spec.stations.indexWhere(
        (station) =>
            station.key == ref || station.waypointSeedKey == ref,
      );
      if (match >= 0) return match;
    }
    if (spec.stations.isEmpty || runCount <= 0) return 0;
    final ratio = runIndex / runCount;
    return (ratio * (spec.stations.length - 1))
        .round()
        .clamp(0, spec.stations.length - 1);
  }
}
