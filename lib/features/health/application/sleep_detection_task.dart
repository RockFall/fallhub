import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;

import 'package:battery_plus/battery_plus.dart';
import 'package:colony_domain/colony_domain.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:sensors_plus/sensors_plus.dart';

/// Top-level entry for the sleep detection foreground service (ADR-035).
@pragma('vm:entry-point')
void sleepDetectionStartCallback() {
  FlutterForegroundTask.setTaskHandler(SleepDetectionTaskHandler());
}

/// Samples motion in the FG isolate and emits onset/wake events to the UI.
class SleepDetectionTaskHandler extends TaskHandler {
  SleepDetectionEngine _engine = SleepDetectionEngine();
  final Battery _battery = Battery();
  final List<double> _magnitudes = [];
  StreamSubscription<AccelerometerEvent>? _accelSub;
  bool _screenOnHint = false;

  static const _engineKey = 'sleep_engine_state';
  static const _pendingKey = 'sleep_pending_events';

  @override
  Future<void> onStart(DateTime timestamp, TaskStarter starter) async {
    final raw = await FlutterForegroundTask.getData(key: _engineKey);
    if (raw is String && raw.isNotEmpty) {
      try {
        _engine = SleepDetectionEngine.fromJson(
          jsonDecode(raw) as Map<String, dynamic>,
        );
      } catch (_) {
        _engine = SleepDetectionEngine();
      }
    }
    _accelSub = accelerometerEventStream(
      samplingPeriod: SensorInterval.uiInterval,
    ).listen((e) {
      final m = math.sqrt(e.x * e.x + e.y * e.y + e.z * e.z);
      _magnitudes.add(m);
      if (_magnitudes.length > 120) {
        _magnitudes.removeRange(0, _magnitudes.length - 120);
      }
    });
  }

  @override
  void onRepeatEvent(DateTime timestamp) {
    unawaited(_tick(timestamp));
  }

  Future<void> _tick(DateTime timestamp) async {
    final variance = _variance(_magnitudes);
    _magnitudes.clear();

    var charging = false;
    try {
      final state = await _battery.batteryState;
      charging = state == BatteryState.charging || state == BatteryState.full;
    } catch (_) {}

    final sample = SleepSignalSample(
      at: timestamp,
      motionVariance: variance,
      screenOn: _screenOnHint,
      isCharging: charging,
    );
    final event = _engine.ingest(sample);
    await FlutterForegroundTask.saveData(
      key: _engineKey,
      value: jsonEncode(_engine.toJson()),
    );

    String? status;
    if (_engine.phase == SleepDetectorPhase.asleep) {
      status = 'Dormindo…';
    } else if (_engine.phase == SleepDetectorPhase.settling) {
      status = 'Possível início de sono…';
    } else {
      status = 'Monitorando sono';
    }
    await FlutterForegroundTask.updateService(notificationText: status);

    if (event == null) return;

    final payload = switch (event) {
      SleepOnsetDetected(:final onsetAt, :final confidence) => {
          'type': 'onset',
          'onset_at': onsetAt.toUtc().toIso8601String(),
          'confidence': confidence.name,
        },
      SleepWakeDetected(:final onsetAt, :final wakeAt, :final confidence) => {
          'type': 'wake',
          'onset_at': onsetAt.toUtc().toIso8601String(),
          'wake_at': wakeAt.toUtc().toIso8601String(),
          'confidence': confidence.name,
        },
    };

    await _enqueuePending(payload);
    FlutterForegroundTask.sendDataToMain(payload);
  }

  Future<void> _enqueuePending(Map<String, Object?> payload) async {
    final raw = await FlutterForegroundTask.getData(key: _pendingKey);
    final list = <dynamic>[];
    if (raw is String && raw.isNotEmpty) {
      try {
        final decoded = jsonDecode(raw);
        if (decoded is List) list.addAll(decoded);
      } catch (_) {}
    }
    list.add(payload);
    await FlutterForegroundTask.saveData(
      key: _pendingKey,
      value: jsonEncode(list),
    );
  }

  @override
  void onReceiveData(Object data) {
    if (data is Map) {
      final screen = data['screen_on'];
      if (screen is bool) _screenOnHint = screen;
    }
  }

  @override
  Future<void> onDestroy(DateTime timestamp, bool isTimeout) async {
    await _accelSub?.cancel();
    _accelSub = null;
    await FlutterForegroundTask.saveData(
      key: _engineKey,
      value: jsonEncode(_engine.toJson()),
    );
  }

  static double _variance(List<double> values) {
    if (values.length < 2) return 0;
    final mean = values.reduce((a, b) => a + b) / values.length;
    var sum = 0.0;
    for (final v in values) {
      final d = v - mean;
      sum += d * d;
    }
    return sum / values.length;
  }
}
