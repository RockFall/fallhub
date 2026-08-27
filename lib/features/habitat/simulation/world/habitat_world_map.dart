import 'habitat_world.dart';

/// Minimal abstract place without a bespoke map (MD 08 M41).
class AbstractSiteKind {
  const AbstractSiteKind({
    required this.id,
    required this.label,
    required this.siteKind,
    required this.contextProfileId,
    this.timezoneId = 'America/Sao_Paulo',
  });

  final String id;
  final String label;
  final HabitatSiteKind siteKind;
  final String contextProfileId;
  final String timezoneId;
}

/// World map tree + site factory (M41).
class HabitatWorldMap {
  static const kinds = <AbstractSiteKind>[
    AbstractSiteKind(
      id: 'abstract.cafe',
      label: 'Café genérico',
      siteKind: HabitatSiteKind.cafe,
      contextProfileId: 'profile.cafe',
    ),
    AbstractSiteKind(
      id: 'abstract.restaurant',
      label: 'Restaurante',
      siteKind: HabitatSiteKind.restaurant,
      contextProfileId: 'profile.cafe',
    ),
    AbstractSiteKind(
      id: 'abstract.office',
      label: 'Escritório',
      siteKind: HabitatSiteKind.work,
      contextProfileId: 'profile.office',
    ),
    AbstractSiteKind(
      id: 'abstract.classroom',
      label: 'Sala de aula',
      siteKind: HabitatSiteKind.university,
      contextProfileId: 'profile.office',
    ),
    AbstractSiteKind(
      id: 'abstract.hotel',
      label: 'Hotel',
      siteKind: HabitatSiteKind.hotel,
      contextProfileId: 'profile.bedroom',
      timezoneId: 'Asia/Tokyo',
    ),
    AbstractSiteKind(
      id: 'abstract.train',
      label: 'Trem',
      siteKind: HabitatSiteKind.transport,
      contextProfileId: 'profile.cafe',
    ),
    AbstractSiteKind(
      id: 'abstract.airport',
      label: 'Lounge aeroporto',
      siteKind: HabitatSiteKind.airport,
      contextProfileId: 'profile.cafe',
    ),
  ];

  /// Diegetic navigation tree (not geographic).
  static const tree = <String, List<String>>{
    'HOME': ['WORK', 'UNIVERSITY', 'GYM', 'CAFÉ', 'PARK', 'OTHER'],
    'OTHER': ['HOTEL', 'TRAIN', 'AIRPORT', 'RESTAURANT'],
  };

  static AbstractSiteKind? kindByNavLabel(String label) {
    final key = label.toUpperCase();
    switch (key) {
      case 'CAFÉ':
      case 'CAFE':
        return kinds.firstWhere((k) => k.id == 'abstract.cafe');
      case 'WORK':
        return kinds.firstWhere((k) => k.id == 'abstract.office');
      case 'UNIVERSITY':
        return kinds.firstWhere((k) => k.id == 'abstract.classroom');
      case 'HOTEL':
        return kinds.firstWhere((k) => k.id == 'abstract.hotel');
      case 'TRAIN':
        return kinds.firstWhere((k) => k.id == 'abstract.train');
      case 'AIRPORT':
        return kinds.firstWhere((k) => k.id == 'abstract.airport');
      case 'RESTAURANT':
        return kinds.firstWhere((k) => k.id == 'abstract.restaurant');
      default:
        return null;
    }
  }

  /// Materialize abstract kind into [world] if missing; returns site id.
  static String materialize(HabitatWorld world, AbstractSiteKind kind) {
    final siteId = 'abs.${kind.siteKind.name}.01';
    if (world.sites.containsKey(siteId)) return siteId;
    final roomId = '$siteId.main';
    world.sites[siteId] = HabitatSite(
      id: siteId,
      name: kind.label,
      kind: kind.siteKind,
      timezoneId: kind.timezoneId,
      roomIds: {roomId},
      environment: SiteEnvironmentProfile(
        baseComfort: kind.siteKind == HabitatSiteKind.hotel ? 0.7 : 0.6,
      ),
    );
    world.rooms[roomId] = HabitatRoom(
      id: roomId,
      siteId: siteId,
      name: 'Principal',
      semanticRole: kind.siteKind.name,
      contextProfileId: kind.contextProfileId,
      mapLocationId: null,
    );
    return siteId;
  }

  /// Promote abstract site to custom saved id.
  static String promoteCustom(HabitatWorld world, String abstractSiteId) {
    final src = world.sites[abstractSiteId];
    if (src == null) return abstractSiteId;
    final customId = 'custom.${src.kind.name}.${src.id.hashCode.abs()}';
    if (world.sites.containsKey(customId)) return customId;
    world.sites[customId] = HabitatSite(
      id: customId,
      name: '${src.name} (salvo)',
      kind: HabitatSiteKind.custom,
      timezoneId: src.timezoneId,
      roomIds: src.roomIds,
      environment: src.environment,
    );
    return customId;
  }
}
