enum ConnectivityProfile { offline, poor, normal, fast }

enum NoiseProfile { silent, quiet, normal, busy, loud }

enum PrivacyProfile { private, semiPrivate, shared, public }

enum SocialDensityProfile { empty, sparse, normal, crowded }

/// Functional context of a room/site — not just visuals (MD 08 M24).
class HabitatContextProfile {
  const HabitatContextProfile({
    required this.id,
    required this.capabilities,
    this.unavailableActivityTags = const {},
    this.usefulItemTags = const {},
    this.connectivity = ConnectivityProfile.normal,
    this.noise = NoiseProfile.normal,
    this.privacy = PrivacyProfile.shared,
    this.socialDensity = SocialDensityProfile.normal,
  });

  final String id;
  final Set<String> capabilities;
  final Set<String> unavailableActivityTags;
  final Set<String> usefulItemTags;
  final ConnectivityProfile connectivity;
  final NoiseProfile noise;
  final PrivacyProfile privacy;
  final SocialDensityProfile socialDensity;

  bool allows(String capability) =>
      capabilities.contains(capability) &&
      !unavailableActivityTags.contains(capability);

  /// Soft multiplier for focus / private activities.
  double focusFit() {
    var m = 1.0;
    if (noise == NoiseProfile.silent || noise == NoiseProfile.quiet) m += 0.2;
    if (noise == NoiseProfile.loud || noise == NoiseProfile.busy) m -= 0.25;
    if (privacy == PrivacyProfile.private) m += 0.15;
    if (privacy == PrivacyProfile.public) m -= 0.2;
    return m.clamp(0.4, 1.6);
  }

  /// Soft multiplier for calls (avoid public+loud).
  double callFit() {
    if (privacy == PrivacyProfile.public &&
        (noise == NoiseProfile.loud || noise == NoiseProfile.busy)) {
      return 0.35;
    }
    if (capabilities.contains('privateCall')) return 1.2;
    if (privacy == PrivacyProfile.private) return 1.1;
    return 0.85;
  }
}

abstract final class HabitatContextProfiles {
  static const bedroom = HabitatContextProfile(
    id: 'profile.bedroom',
    capabilities: {
      'sleep',
      'read',
      'privateCall',
      'charging',
      'internet',
    },
    noise: NoiseProfile.quiet,
    privacy: PrivacyProfile.private,
    socialDensity: SocialDensityProfile.sparse,
    connectivity: ConnectivityProfile.normal,
  );

  static const office = HabitatContextProfile(
    id: 'profile.office',
    capabilities: {
      'workDesk',
      'read',
      'internet',
      'privateCall',
      'charging',
    },
    noise: NoiseProfile.quiet,
    privacy: PrivacyProfile.semiPrivate,
    connectivity: ConnectivityProfile.fast,
  );

  static const kitchen = HabitatContextProfile(
    id: 'profile.kitchen',
    capabilities: {'cook', 'groupSocial', 'internet'},
    noise: NoiseProfile.normal,
    privacy: PrivacyProfile.shared,
    usefulItemTags: {'food', 'utensil'},
  );

  static const terrace = HabitatContextProfile(
    id: 'profile.terrace',
    capabilities: {'outdoorWalk', 'groupSocial', 'read'},
    noise: NoiseProfile.normal,
    privacy: PrivacyProfile.semiPrivate,
    socialDensity: SocialDensityProfile.sparse,
  );

  static const cafe = HabitatContextProfile(
    id: 'profile.cafe',
    capabilities: {
      'groupSocial',
      'read',
      'internet',
      'cook',
    },
    unavailableActivityTags: {'sleep', 'shower'},
    noise: NoiseProfile.busy,
    privacy: PrivacyProfile.public,
    socialDensity: SocialDensityProfile.crowded,
    connectivity: ConnectivityProfile.normal,
  );

  static HabitatContextProfile? byId(String? id) => switch (id) {
        'profile.bedroom' => bedroom,
        'profile.office' => office,
        'profile.kitchen' => kitchen,
        'profile.terrace' => terrace,
        'profile.cafe' => cafe,
        _ => null,
      };

  static HabitatContextProfile forMapLocation(String mapId) => switch (mapId) {
        'bedroom' => bedroom,
        'office' => office,
        'kitchen' => kitchen,
        'terrace' => terrace,
        _ => bedroom,
      };
}
