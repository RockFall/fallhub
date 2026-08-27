import '../mirror/mirror_signal.dart';

enum HabitatSiteKind {
  home,
  work,
  university,
  gym,
  studio,
  cafe,
  restaurant,
  bar,
  park,
  library,
  hotel,
  airport,
  transport,
  travelDestination,
  friendHome,
  custom,
}

class SiteEnvironmentProfile {
  const SiteEnvironmentProfile({
    this.baseComfort = 0.7,
    this.outdoorBias = 0,
  });

  final double baseComfort;
  final double outdoorBias;
}

/// Larger location context (MD 08 M22).
class HabitatSite {
  const HabitatSite({
    required this.id,
    required this.name,
    required this.kind,
    required this.timezoneId,
    required this.roomIds,
    this.environment = const SiteEnvironmentProfile(),
  });

  final String id;
  final String name;
  final HabitatSiteKind kind;
  final String timezoneId;
  final Set<String> roomIds;
  final SiteEnvironmentProfile environment;
}

/// Navigable / semantic space inside a site (M22).
class HabitatRoom {
  const HabitatRoom({
    required this.id,
    required this.siteId,
    required this.name,
    required this.semanticRole,
    this.contextProfileId,
    this.mapLocationId,
  });

  final String id;
  final String siteId;
  final String name;
  final String semanticRole;
  final String? contextProfileId;

  /// Bridge to existing Flame map id (bedroom/office/…).
  final String? mapLocationId;
}

/// World graph of sites and rooms — not just a single map (M22).
class HabitatWorld {
  HabitatWorld({
    List<HabitatSite>? sites,
    List<HabitatRoom>? rooms,
  })  : sites = {for (final s in sites ?? demoSites) s.id: s},
        rooms = {for (final r in rooms ?? demoRooms) r.id: r};

  final Map<String, HabitatSite> sites;
  final Map<String, HabitatRoom> rooms;

  static final List<HabitatSite> demoSites = [
    const HabitatSite(
      id: 'home_apartment',
      name: 'Demo Home',
      kind: HabitatSiteKind.home,
      timezoneId: 'America/Sao_Paulo',
      roomIds: {
        'home.bedroom',
        'home.office',
        'home.kitchen',
        'home.terrace',
      },
      environment: SiteEnvironmentProfile(baseComfort: 0.82),
    ),
    const HabitatSite(
      id: 'generic_cafe_01',
      name: 'Café da Esquina',
      kind: HabitatSiteKind.cafe,
      timezoneId: 'America/Sao_Paulo',
      roomIds: {'cafe.main'},
      environment: SiteEnvironmentProfile(baseComfort: 0.65),
    ),
  ];

  static final List<HabitatRoom> demoRooms = [
    const HabitatRoom(
      id: 'home.bedroom',
      siteId: 'home_apartment',
      name: 'Quarto',
      semanticRole: 'sleep',
      contextProfileId: 'profile.bedroom',
      mapLocationId: 'bedroom',
    ),
    const HabitatRoom(
      id: 'home.office',
      siteId: 'home_apartment',
      name: 'Escritório',
      semanticRole: 'work',
      contextProfileId: 'profile.office',
      mapLocationId: 'office',
    ),
    const HabitatRoom(
      id: 'home.kitchen',
      siteId: 'home_apartment',
      name: 'Cozinha',
      semanticRole: 'cook',
      contextProfileId: 'profile.kitchen',
      mapLocationId: 'kitchen',
    ),
    const HabitatRoom(
      id: 'home.terrace',
      siteId: 'home_apartment',
      name: 'Terraço',
      semanticRole: 'outdoor',
      contextProfileId: 'profile.terrace',
      mapLocationId: 'terrace',
    ),
    const HabitatRoom(
      id: 'cafe.main',
      siteId: 'generic_cafe_01',
      name: 'Salão',
      semanticRole: 'social',
      contextProfileId: 'profile.cafe',
      mapLocationId: null,
    ),
  ];

  HabitatRoom? roomByMapLocation(String mapId) {
    for (final r in rooms.values) {
      if (r.mapLocationId == mapId) return r;
    }
    return null;
  }

  HabitatSite? siteForMapLocation(String mapId) {
    final room = roomByMapLocation(mapId);
    if (room == null) return null;
    return sites[room.siteId];
  }

  MirrorSignal<String> siteSignal(String siteId) {
    final s = sites[siteId];
    return MirrorSignal<String>(
      id: 'world.site.$siteId',
      value: s?.name ?? siteId,
      source: MirrorSignalSource.simulated,
      observedAt: DateTime.now().toUtc(),
      confidence: 1,
    );
  }
}
