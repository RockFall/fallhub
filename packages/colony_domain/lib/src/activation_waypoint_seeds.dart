import 'activation_enums.dart';

class ActivationWaypointSeedSpec {
  const ActivationWaypointSeedSpec({
    required this.key,
    required this.name,
    required this.waypointType,
    required this.mapX,
    required this.mapY,
    this.relatedProtocolKeys = const [],
  });

  final String key;
  final String name;
  final ActivationWaypointType waypointType;
  final double mapX;
  final double mapY;
  final List<String> relatedProtocolKeys;

  String get token => key;

  Map<String, Object?> settings() => {
        'seed_key': key,
        'map_x': mapX,
        'map_y': mapY,
        'related_protocols': relatedProtocolKeys,
      };
}

/// Waypoints canônicos da casa — âncoras de prova, não rastreamento.
abstract final class ActivationWaypointSeeds {
  static const catalog = <ActivationWaypointSeedSpec>[
    ActivationWaypointSeedSpec(
      key: 'bed',
      name: 'Cama',
      waypointType: ActivationWaypointType.manual,
      mapX: 0.18,
      mapY: 0.22,
      relatedProtocolKeys: [
        'morning_launch_standard',
        'morning_launch_minimal',
        'night_runway',
      ],
    ),
    ActivationWaypointSeedSpec(
      key: 'bathroom_dock',
      name: 'Dock do banheiro',
      waypointType: ActivationWaypointType.qr,
      mapX: 0.36,
      mapY: 0.28,
      relatedProtocolKeys: [
        'morning_launch_standard',
        'morning_launch_minimal',
        'shower_reset',
      ],
    ),
    ActivationWaypointSeedSpec(
      key: 'kitchen_light',
      name: 'Luz da cozinha',
      waypointType: ActivationWaypointType.manual,
      mapX: 0.56,
      mapY: 0.36,
      relatedProtocolKeys: [
        'morning_launch_standard',
        'night_runway',
      ],
    ),
    ActivationWaypointSeedSpec(
      key: 'desk_dock',
      name: 'Dock da mesa',
      waypointType: ActivationWaypointType.qr,
      mapX: 0.74,
      mapY: 0.46,
      relatedProtocolKeys: [
        'code_ignition',
        'study_ignition',
        'morning_launch_standard',
      ],
    ),
    ActivationWaypointSeedSpec(
      key: 'piano_bench',
      name: 'Banco do piano',
      waypointType: ActivationWaypointType.manual,
      mapX: 0.42,
      mapY: 0.62,
      relatedProtocolKeys: ['piano_ignition'],
    ),
    ActivationWaypointSeedSpec(
      key: 'exercise_mat',
      name: 'Tapete',
      waypointType: ActivationWaypointType.manual,
      mapX: 0.26,
      mapY: 0.70,
      relatedProtocolKeys: ['music_expedition_walk'],
    ),
    ActivationWaypointSeedSpec(
      key: 'front_door',
      name: 'Porta da frente',
      waypointType: ActivationWaypointType.qr,
      mapX: 0.84,
      mapY: 0.74,
      relatedProtocolKeys: [
        'leave_home',
        'music_expedition_walk',
      ],
    ),
  ];

  static ActivationWaypointSeedSpec? byKey(String key) {
    for (final spec in catalog) {
      if (spec.key == key) return spec;
    }
    return null;
  }
}
