/// Wall-clock of the device. Never accelerates (MD 08 M2).
class HabitatRealClock {
  HabitatRealClock({DateTime Function()? now}) : _now = now ?? DateTime.now;

  final DateTime Function() _now;

  DateTime now() => _now();
}

/// Perceived scene time — drives lighting / day phase.
///
/// Advances only via [tick] (Flame dt) or explicit [skip]/[setSceneHour].
/// Does **not** call `DateTime.now()` for progression (injectable [realNow]).
class HabitatSceneClock {
  HabitatSceneClock({
    DateTime? initial,
    DateTime Function()? realNow,
    String? siteTimezoneId,
  })  : _realNow = realNow ?? DateTime.now,
        _sceneNow = initial ?? (realNow ?? DateTime.now)(),
        siteTimezoneId = siteTimezoneId ?? 'local';

  DateTime Function() _realNow;

  /// Shared with [HabitatClockBundle.siteTimezoneId].
  String siteTimezoneId;

  DateTime _sceneNow;
  double _speed = 1;
  bool _frozen = false;

  double get speed => _speed;
  bool get isFrozen => _frozen;

  /// Bind to the bundle's real clock (tests / injection).
  void attachRealNow(DateTime Function() realNow) {
    _realNow = realNow;
  }

  /// Fraction of local day `0..1` (midnight → midnight).
  double get phase {
    final t = now();
    final secs =
        t.hour * 3600 + t.minute * 60 + t.second + t.millisecond / 1000;
    return (secs / 86400.0) % 1.0;
  }

  DateTime now() => _sceneNow;

  /// Advance scene by real frame dt × [speed].
  void tick(double realDtSeconds) {
    if (_frozen || realDtSeconds <= 0 || _speed <= 0) return;
    final micros = (realDtSeconds * _speed * 1e6).round();
    if (micros == 0) return;
    _sceneNow = _sceneNow.add(Duration(microseconds: micros));
  }

  void setSpeed(double speed) {
    _speed = speed.clamp(0.0, 120.0);
  }

  void freeze([DateTime? at]) {
    if (at != null) _sceneNow = at;
    _frozen = true;
  }

  void unfreeze() {
    _frozen = false;
  }

  void skip(Duration delta) {
    _sceneNow = _sceneNow.add(delta);
  }

  /// Set local scene hour in `0..24` (keeps date).
  void setSceneHour(double hour) {
    final h = hour % 24.0;
    final whole = h.floor();
    final frac = h - whole;
    final mins = (frac * 60).floor();
    final secs = (((frac * 60) - mins) * 60).round();
    _sceneNow = DateTime(
      _sceneNow.year,
      _sceneNow.month,
      _sceneNow.day,
      whole,
      mins,
      secs,
    );
  }

  /// Re-sync scene to real clock reading (default follow mode).
  void followReal([DateTime? realNow]) {
    _frozen = false;
    _speed = 1;
    _sceneNow = realNow ?? _realNow();
  }
}

/// Simulation time for needs, cooldowns, episodes, background sim.
class HabitatSimulationClock {
  HabitatSimulationClock({double initialElapsed = 0})
      : elapsedSeconds = initialElapsed;

  double elapsedSeconds;
  double speedMultiplier = 1;

  void tick(double realDtSeconds) {
    if (realDtSeconds <= 0) return;
    elapsedSeconds += realDtSeconds * speedMultiplier;
  }

  void setSpeed(double multiplier) {
    speedMultiplier = multiplier.clamp(0.0, 120.0);
  }

  void skip(Duration delta) {
    elapsedSeconds += delta.inMicroseconds / 1e6;
  }
}

/// Bundle of Habitat clocks + site timezone helper (MD 08 M2).
class HabitatClockBundle {
  HabitatClockBundle({
    HabitatRealClock? real,
    HabitatSceneClock? scene,
    HabitatSimulationClock? simulation,
    String siteTimezoneId = 'local',
  })  : real = real ?? HabitatRealClock(),
        scene = scene ??
            HabitatSceneClock(
              realNow: (real ?? HabitatRealClock()).now,
              siteTimezoneId: siteTimezoneId,
            ),
        simulation = simulation ?? HabitatSimulationClock(),
        siteTimezoneId = siteTimezoneId {
    this.scene.attachRealNow(this.real.now);
    this.scene.siteTimezoneId = siteTimezoneId;
  }

  final HabitatRealClock real;
  final HabitatSceneClock scene;
  final HabitatSimulationClock simulation;

  String siteTimezoneId;

  void tick(double realDtSeconds) {
    scene.tick(realDtSeconds);
    simulation.tick(realDtSeconds);
  }

  void setDebugSpeed(double speed) {
    scene.setSpeed(speed);
    simulation.setSpeed(speed);
  }

  void skipOneHour() {
    const hour = Duration(hours: 1);
    scene.skip(hour);
    simulation.skip(hour);
  }

  DateTime toSiteLocal(DateTime utc) {
    if (siteTimezoneId == 'local') return utc.toLocal();
    return utc.toUtc();
  }

  String debugSummary() {
    final s = scene.now();
    final hour = (scene.phase * 24).toStringAsFixed(1);
    return 'scene ${s.hour.toString().padLeft(2, '0')}:'
        '${s.minute.toString().padLeft(2, '0')} '
        '(${hour}h) ×${scene.speed.toStringAsFixed(0)} | '
        'sim ${simulation.elapsedSeconds.toStringAsFixed(1)}s '
        '×${simulation.speedMultiplier.toStringAsFixed(0)} | '
        'tz=$siteTimezoneId';
  }
}
