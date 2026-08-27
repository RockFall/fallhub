// Device state + interruptible long activities (MD 08 M33).

enum HabitatDeviceKind {
  phone,
  computer,
  tablet,
  tv,
  speaker,
  headphones,
  console,
}

class HabitatDevice {
  HabitatDevice({
    required this.id,
    required this.kind,
    this.powered = true,
    this.activeMode = 'idle',
    this.currentMediaId,
    this.currentUserPawnId,
  });

  final String id;
  final HabitatDeviceKind kind;
  bool powered;
  String activeMode;
  String? currentMediaId;
  String? currentUserPawnId;

  void power(bool on) {
    powered = on;
    if (!on) {
      activeMode = 'off';
      currentMediaId = null;
      currentUserPawnId = null;
    }
  }

  void use({
    required String mode,
    String? mediaId,
    String? userId,
  }) {
    if (!powered) return;
    activeMode = mode;
    currentMediaId = mediaId;
    currentUserPawnId = userId;
  }

  void release() {
    activeMode = 'idle';
    currentMediaId = null;
    currentUserPawnId = null;
  }
}

enum SustainedActivityPhase {
  active,
  paused,
  interrupted,
  resumable,
  abandoned,
  completed,
}

/// Long activity that can pause and resume (reading, piano, work…).
class SustainedActivity {
  SustainedActivity({
    required this.id,
    required this.kind,
    required this.pawnId,
    this.attentionLoad = 0.4,
    this.naturalBreakIntervalSim = 120,
    this.interruptible = true,
    this.deviceId,
    this.progress = 0,
  });

  final String id;
  final String kind;
  final String pawnId;
  final double attentionLoad;
  final double naturalBreakIntervalSim;
  final bool interruptible;
  final String? deviceId;
  double progress;
  SustainedActivityPhase phase = SustainedActivityPhase.active;
  String? resumeToken;
  double? interruptedAtSim;
}

class ResumeIntentCandidate {
  ResumeIntentCandidate({
    required this.activityId,
    required this.expiresAtSim,
    this.bonus = 0.25,
  });

  final String activityId;
  final double expiresAtSim;
  final double bonus;
}

/// Devices + sustained attention interrupt/resume (M33).
class HabitatDeviceDirector {
  final Map<String, HabitatDevice> devices = {
    'phone': HabitatDevice(id: 'phone', kind: HabitatDeviceKind.phone),
    'computer': HabitatDevice(id: 'computer', kind: HabitatDeviceKind.computer),
    'tv': HabitatDevice(id: 'tv', kind: HabitatDeviceKind.tv),
    'speaker': HabitatDevice(id: 'speaker', kind: HabitatDeviceKind.speaker),
  };

  final Map<String, SustainedActivity> activities = {};
  final List<ResumeIntentCandidate> resumeCandidates = [];
  final List<String> debugLog = [];

  SustainedActivity startReading({
    required String pawnId,
    required String bookItemId,
    double nowSim = 0,
  }) {
    final id = 'read.$pawnId.$nowSim';
    final a = SustainedActivity(
      id: id,
      kind: 'reading',
      pawnId: pawnId,
      attentionLoad: 0.35,
      deviceId: null,
    );
    a.resumeToken = 'bookmark:$bookItemId';
    activities[id] = a;
    debugLog.add('start reading $bookItemId');
    return a;
  }

  SustainedActivity startDeviceUse({
    required String pawnId,
    required String deviceId,
    required String mode,
    String? mediaId,
    double nowSim = 0,
  }) {
    final d = devices[deviceId];
    d?.use(mode: mode, mediaId: mediaId, userId: pawnId);
    final id = 'device.$deviceId.$nowSim';
    final a = SustainedActivity(
      id: id,
      kind: mode,
      pawnId: pawnId,
      deviceId: deviceId,
      attentionLoad: 0.5,
    );
    a.resumeToken = 'device:$deviceId:$mode';
    activities[id] = a;
    debugLog.add('start $mode on $deviceId');
    return a;
  }

  /// Interrupt eligible activities for [pawnId] (visitor / call).
  List<SustainedActivity> interruptFor(
    String pawnId, {
    required double nowSim,
    double resumeWindowSim = 300,
  }) {
    final out = <SustainedActivity>[];
    for (final a in activities.values) {
      if (a.pawnId != pawnId) continue;
      if (a.phase != SustainedActivityPhase.active) continue;
      if (!a.interruptible) continue;
      a.phase = SustainedActivityPhase.interrupted;
      a.interruptedAtSim = nowSim;
      if (a.deviceId != null) {
        devices[a.deviceId!]?.release();
      }
      resumeCandidates.add(
        ResumeIntentCandidate(
          activityId: a.id,
          expiresAtSim: nowSim + resumeWindowSim,
        ),
      );
      a.phase = SustainedActivityPhase.resumable;
      out.add(a);
      debugLog.add('interrupt ${a.kind}');
    }
    return out;
  }

  bool resume(String activityId, {required double nowSim}) {
    final a = activities[activityId];
    if (a == null) return false;
    if (a.phase != SustainedActivityPhase.resumable &&
        a.phase != SustainedActivityPhase.paused) {
      return false;
    }
    resumeCandidates.removeWhere((c) => c.activityId == activityId);
    a.phase = SustainedActivityPhase.active;
    if (a.deviceId != null) {
      final token = a.resumeToken ?? '';
      final parts = token.split(':');
      final mode = parts.length > 2 ? parts[2] : 'active';
      devices[a.deviceId!]?.use(mode: mode, userId: a.pawnId);
    }
    debugLog.add('resume ${a.kind}');
    return true;
  }

  ResumeIntentCandidate? bestResume(String pawnId, double nowSim) {
    ResumeIntentCandidate? best;
    for (final c in resumeCandidates) {
      if (c.expiresAtSim < nowSim) continue;
      final a = activities[c.activityId];
      if (a == null || a.pawnId != pawnId) continue;
      if (best == null || c.bonus > best.bonus) best = c;
    }
    return best;
  }

  void tick(double nowSim) {
    resumeCandidates.removeWhere((c) => c.expiresAtSim < nowSim);
    for (final a in activities.values) {
      if (a.phase == SustainedActivityPhase.active) {
        a.progress = (a.progress + 0.02).clamp(0.0, 1.0);
        if (a.progress >= 1) {
          a.phase = SustainedActivityPhase.completed;
          if (a.deviceId != null) devices[a.deviceId!]?.release();
        }
      }
    }
  }
}
