import '../identity/identity.dart';
import 'habitat_rng.dart';
import 'posture_transition.dart';

/// Block F — sleep, routine and day transitions (MD 10 R59–R69).

enum SleepBodySignal {
  none,
  yawn,
  slowBlink,
  stretch,
  heavyLids,
  nodOff,
}

abstract final class SleepBodySignals {
  static SleepBodySignal forPressure(double sleepPressure) {
    if (sleepPressure < 0.35) return SleepBodySignal.none;
    if (sleepPressure < 0.5) return SleepBodySignal.yawn;
    if (sleepPressure < 0.65) return SleepBodySignal.slowBlink;
    if (sleepPressure < 0.78) return SleepBodySignal.stretch;
    if (sleepPressure < 0.9) return SleepBodySignal.heavyLids;
    return SleepBodySignal.nodOff;
  }
}

enum WindDownAction { dimLights, putDownDevice, stretch, brushTeethStub }

abstract final class WindDownRoutine {
  static List<WindDownAction> plan({
    required double sleepPressure,
    required String pawnId,
  }) {
    final actions = <WindDownAction>[];
    if (sleepPressure > 0.45) actions.add(WindDownAction.putDownDevice);
    if (sleepPressure > 0.55) actions.add(WindDownAction.dimLights);
    if (HabitatRng.unit(pawnId, 'wind') > 0.4) {
      actions.add(WindDownAction.stretch);
    }
    if (sleepPressure > 0.7) actions.add(WindDownAction.brushTeethStub);
    return actions;
  }
}

enum BedEntryPhase {
  approach,
  sitEdge,
  lieDown,
  settle,
  asleep,
  stir,
  sitUp,
  stand,
}

class BedChoreography {
  BedChoreography();

  BedEntryPhase phase = BedEntryPhase.approach;
  double phaseEndsAt = 0;
  bool isNap = false;

  void beginEnter({required double now, required bool nap}) {
    isNap = nap;
    phase = BedEntryPhase.approach;
    phaseEndsAt = now + 0.2;
  }

  void beginExit(double now) {
    phase = BedEntryPhase.stir;
    phaseEndsAt = now + (isNap ? 0.25 : 0.45);
  }

  bool tick(double now) {
    if (now < phaseEndsAt) return false;
    phase = switch (phase) {
      BedEntryPhase.approach => BedEntryPhase.sitEdge,
      BedEntryPhase.sitEdge => BedEntryPhase.lieDown,
      BedEntryPhase.lieDown => BedEntryPhase.settle,
      BedEntryPhase.settle => BedEntryPhase.asleep,
      BedEntryPhase.stir => BedEntryPhase.sitUp,
      BedEntryPhase.sitUp => BedEntryPhase.stand,
      BedEntryPhase.asleep || BedEntryPhase.stand => phase,
    };
    phaseEndsAt = now + switch (phase) {
          BedEntryPhase.sitEdge => 0.28,
          BedEntryPhase.lieDown => PostureTimings.liePrep,
          BedEntryPhase.settle => isNap ? 0.2 : 0.4,
          BedEntryPhase.sitUp => 0.3,
          BedEntryPhase.stand => PostureTimings.risePrep,
          _ => 0.15,
        };
    return phase == BedEntryPhase.asleep || phase == BedEntryPhase.stand;
  }
}

enum SleepPoseVariant { sideLeft, sideRight, back, curled }

abstract final class SleepPoseVariants {
  static SleepPoseVariant pick(String pawnId, double now) {
    final i = (HabitatRng.unit(pawnId, 'sleepPose', now.floor()) * 4)
        .floor()
        .clamp(0, 3);
    return SleepPoseVariant.values[i];
  }

  static double nextChangeAt(String pawnId, double now) =>
      now + HabitatRng.range(90, 240, a: pawnId, b: 'poseChange');
}

class WakeInertia {
  WakeInertia({required this.startedAt, this.duration = 12});

  final double startedAt;
  final double duration;
  double speedMul = 0.82;
  double focusMul = 0.7;

  bool isActive(double now) => now - startedAt < duration;

  void tick(double now) {
    if (!isActive(now)) {
      speedMul = 1;
      focusMul = 1;
      return;
    }
    final t = ((now - startedAt) / duration).clamp(0.0, 1.0);
    speedMul = 0.82 + 0.18 * t;
    focusMul = 0.7 + 0.3 * t;
  }
}

abstract final class NapPolicy {
  static bool isNap({
    required double sceneHour,
    required double intendedDurationMinutes,
  }) {
    final day = sceneHour >= 9 && sceneHour <= 18;
    return day && intendedDurationMinutes <= 45;
  }

  static double recoverMultiplier({required bool nap}) => nap ? 0.55 : 1.0;
}

abstract final class QuietHoursBehavior {
  static bool isQuiet(double sceneHour) =>
      sceneHour >= 22 || sceneHour < 6.5;

  static double speechChanceMultiplier(double sceneHour) =>
      isQuiet(sceneHour) ? 0.25 : 1.0;

  static double musicVolumeMul(double sceneHour) =>
      isQuiet(sceneHour) ? 0.35 : 1.0;
}

enum MorningMicroStep { stretch, water, openCurtain, checkPhone, breakfastStub }

abstract final class MorningMicroRoutine {
  static List<MorningMicroStep> plan(String pawnId, BehaviorProfile? profile) {
    final steps = <MorningMicroStep>[
      MorningMicroStep.stretch,
      MorningMicroStep.openCurtain,
    ];
    if ((profile?.conscientiousness ?? 0.5) > 0.55) {
      steps.add(MorningMicroStep.water);
    }
    if (HabitatRng.unit(pawnId, 'morning') > 0.45) {
      steps.add(MorningMicroStep.checkPhone);
    }
    if ((profile?.openness ?? 0.5) > 0.4) {
      steps.add(MorningMicroStep.breakfastStub);
    }
    return steps;
  }
}

abstract final class LastCheckBeforeLeave {
  static List<String> checklist({
    required bool lightsOn,
    required bool windowOpen,
    required bool stoveOn,
    required bool bagReady,
  }) {
    final out = <String>[];
    if (lightsOn) out.add('lights');
    if (windowOpen) out.add('window');
    if (stoveOn) out.add('stove');
    if (!bagReady) out.add('bag');
    return out;
  }
}

class ArrivalDecompression {
  ArrivalDecompression({required this.startedAt, this.duration = 8});

  final double startedAt;
  final double duration;
  bool done = false;

  bool tick(double now) {
    if (done) return true;
    if (now - startedAt >= duration) {
      done = true;
      return true;
    }
    return false;
  }

  String get preferredAction => 'sit_or_water';
}

class AppointmentWaitBehavior {
  AppointmentWaitBehavior({
    required this.appointmentId,
    required this.readyAt,
  });

  final String appointmentId;
  final double readyAt;
  bool pacing = true;

  bool shouldPace(double now) => pacing && now < readyAt;

  void stopPacing() => pacing = false;
}
