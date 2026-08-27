import '../../flame/habitat_map.dart' show HabitatFloor;
import 'habitat_rng.dart';

/// Block G — environment, audio and atmosphere (MD 10 R70–R81).

enum FootstepMaterial { wood, carpet, concrete, outdoor }

abstract final class Footsteps {
  static FootstepMaterial fromFloor(HabitatFloor floor) => switch (floor) {
        HabitatFloor.wood => FootstepMaterial.wood,
        HabitatFloor.carpet => FootstepMaterial.carpet,
        HabitatFloor.concrete => FootstepMaterial.concrete,
      };

  static double volumeMul(FootstepMaterial m) => switch (m) {
        FootstepMaterial.carpet => 0.45,
        FootstepMaterial.wood => 0.8,
        FootstepMaterial.concrete => 1.0,
        FootstepMaterial.outdoor => 0.7,
      };

  static String stubId(FootstepMaterial m) => 'footstep.${m.name}';
}

class SpatialAudioSample {
  const SpatialAudioSample({
    required this.id,
    required this.cell,
    required this.baseVolume,
  });

  final String id;
  final (int, int) cell;
  final double baseVolume;
}

abstract final class SpatialAudio {
  static double hear({
    required SpatialAudioSample sample,
    required (int, int) listener,
    required bool sameRoom,
    required bool doorClosed,
  }) {
    final d = (sample.cell.$1 - listener.$1).abs() +
        (sample.cell.$2 - listener.$2).abs();
    var v = sample.baseVolume * (1.0 - (d / 12).clamp(0.0, 1.0));
    if (!sameRoom) v *= 0.4;
    if (doorClosed) v *= 0.25;
    return v.clamp(0.0, 1.0);
  }
}

class AmbientSoundZone {
  const AmbientSoundZone({
    required this.id,
    required this.cells,
    required this.loopId,
    this.gain = 0.4,
  });

  final String id;
  final Set<(int, int)> cells;
  final String loopId;
  final double gain;

  bool contains((int, int) cell) => cells.contains(cell);
}

abstract final class ContextualLights {
  static bool shouldToggleOn({
    required double darkness,
    required double sceneHour,
    required bool pawnPresent,
  }) {
    if (!pawnPresent) return false;
    if (darkness < 0.55) return false;
    return sceneHour >= 17.5 || sceneHour < 7;
  }

  static bool shouldDimForSleep(bool windDown) => windDown;
}

abstract final class CurtainWindowProps {
  static bool preferOpen({
    required double sceneHour,
    required bool raining,
    required bool privacyNeed,
  }) {
    if (privacyNeed) return false;
    if (raining) return false;
    return sceneHour >= 7 && sceneHour <= 19;
  }
}

enum ClimateReaction { none, shiver, wipeBrow, seekShade, seekWarmth }

abstract final class ClimateReactionVariants {
  static ClimateReaction forPawn({
    required String pawnId,
    required double tempDelta,
    required double coldTolerance,
    required double heatTolerance,
  }) {
    if (tempDelta < -coldTolerance) {
      return HabitatRng.unit(pawnId, 'cold') > 0.5
          ? ClimateReaction.shiver
          : ClimateReaction.seekWarmth;
    }
    if (tempDelta > heatTolerance) {
      return HabitatRng.unit(pawnId, 'hot') > 0.5
          ? ClimateReaction.wipeBrow
          : ClimateReaction.seekShade;
    }
    return ClimateReaction.none;
  }
}

enum EnvMicroAnim { steamRise, curtainSway, lampFlicker, plantBob }

abstract final class EnvironmentalMicroAnims {
  static Set<EnvMicroAnim> active({
    required bool kettleHot,
    required bool windowOpen,
    required bool lampOn,
    required bool windy,
  }) {
    final out = <EnvMicroAnim>{};
    if (kettleHot) out.add(EnvMicroAnim.steamRise);
    if (windowOpen && windy) out.add(EnvMicroAnim.curtainSway);
    if (lampOn && HabitatRng.unit('lamp', 'flicker') > 0.92) {
      out.add(EnvMicroAnim.lampFlicker);
    }
    if (windy) out.add(EnvMicroAnim.plantBob);
    return out;
  }
}

enum DaypartAtmosphere { dawn, morning, afternoon, evening, night }

abstract final class AtmospherePresets {
  static DaypartAtmosphere fromHour(double hour) {
    if (hour < 6) return DaypartAtmosphere.night;
    if (hour < 9) return DaypartAtmosphere.dawn;
    if (hour < 12) return DaypartAtmosphere.morning;
    if (hour < 17) return DaypartAtmosphere.afternoon;
    if (hour < 21) return DaypartAtmosphere.evening;
    return DaypartAtmosphere.night;
  }

  static double ambientBias(DaypartAtmosphere a) => switch (a) {
        DaypartAtmosphere.dawn => 0.15,
        DaypartAtmosphere.morning => 0.0,
        DaypartAtmosphere.afternoon => 0.05,
        DaypartAtmosphere.evening => 0.25,
        DaypartAtmosphere.night => 0.55,
      };
}

abstract final class MicroEventPropagation {
  static List<String> whoNotices({
    required String sourcePawnId,
    required List<String> nearbyIds,
    required int maxPropagate,
  }) {
    final out = <String>[];
    for (final id in nearbyIds) {
      if (id == sourcePawnId) continue;
      if (out.length >= maxPropagate) break;
      if (HabitatRng.unit(id, 'notice') < 0.65) out.add(id);
    }
    return out;
  }
}

enum LivedInMarker {
  chairAskew,
  mugOut,
  blanketMessy,
  bookOpen,
  shoesByDoor,
}

abstract final class LivedInMarkers {
  static Set<LivedInMarker> forRoom({
    required int recentActivityCount,
    required bool morning,
  }) {
    final out = <LivedInMarker>{};
    if (recentActivityCount > 0) out.add(LivedInMarker.chairAskew);
    if (recentActivityCount > 2) out.add(LivedInMarker.mugOut);
    if (morning) out.add(LivedInMarker.blanketMessy);
    if (recentActivityCount > 1) out.add(LivedInMarker.bookOpen);
    return out;
  }
}

class QuietnessController {
  QuietnessController({this.target = 0.5});

  double target;
  double current = 0.5;

  void setDaypart(DaypartAtmosphere a) {
    target = switch (a) {
      DaypartAtmosphere.night => 0.85,
      DaypartAtmosphere.evening => 0.65,
      DaypartAtmosphere.dawn => 0.7,
      DaypartAtmosphere.morning => 0.4,
      DaypartAtmosphere.afternoon => 0.35,
    };
  }

  void tick(double dt) {
    current += (target - current) * (dt * 0.15).clamp(0.0, 1.0);
  }

  double get speechMul => (1.2 - current).clamp(0.2, 1.0);
  double get musicMul => (1.1 - current * 0.8).clamp(0.2, 1.0);
}
