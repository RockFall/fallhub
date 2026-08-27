import 'dart:convert';

import 'package:colony_database/colony_database.dart';
import 'package:colony_domain/colony_domain.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:permission_handler/permission_handler.dart';

import 'sleep_detection_task.dart';

/// Bridges FG-task sleep events into the local DB (ADR-035).
class SleepDetectionCoordinator with WidgetsBindingObserver {
  SleepDetectionCoordinator._();
  static final SleepDetectionCoordinator instance =
      SleepDetectionCoordinator._();

  ColonyDatabase? _database;
  bool _listening = false;

  static const _profileKey = 'sleep_profile_id';
  static const _pendingKey = 'sleep_pending_events';
  static const _enabledKey = 'sleep_detection_enabled';

  void attachDatabase(ColonyDatabase database) {
    _database = database;
  }

  Future<void> init() async {
    if (kIsWeb) return;
    FlutterForegroundTask.initCommunicationPort();
    FlutterForegroundTask.init(
      androidNotificationOptions: AndroidNotificationOptions(
        channelId: 'colony_sleep_detection',
        channelName: 'Detecção de sono',
        channelDescription:
            'Monitora movimento e quietude para registrar início e fim do sono.',
        onlyAlertOnce: true,
      ),
      iosNotificationOptions: const IOSNotificationOptions(
        showNotification: true,
        playSound: false,
      ),
      foregroundTaskOptions: ForegroundTaskOptions(
        eventAction: ForegroundTaskEventAction.repeat(60 * 1000),
        autoRunOnBoot: true,
        autoRunOnMyPackageReplaced: true,
        allowWakeLock: true,
        allowWifiLock: false,
      ),
    );
    if (!_listening) {
      FlutterForegroundTask.addTaskDataCallback(_onTaskData);
      WidgetsBinding.instance.addObserver(this);
      _listening = true;
    }
    await flushPendingEvents();
    final enabled = await FlutterForegroundTask.getData(key: _enabledKey);
    if (enabled == true || enabled == 'true') {
      await ensureServiceRunning();
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final screenOn = state == AppLifecycleState.resumed;
    FlutterForegroundTask.sendDataToTask({'screen_on': screenOn});
    if (state == AppLifecycleState.resumed) {
      unawaitedFlush();
    }
  }

  void unawaitedFlush() {
    flushPendingEvents();
  }

  Future<void> dispose() async {
    if (_listening) {
      FlutterForegroundTask.removeTaskDataCallback(_onTaskData);
      WidgetsBinding.instance.removeObserver(this);
      _listening = false;
    }
  }

  Future<bool> enable({required String profileId}) async {
    await FlutterForegroundTask.saveData(key: _profileKey, value: profileId);
    await FlutterForegroundTask.saveData(key: _enabledKey, value: true);

    final notif = await FlutterForegroundTask.checkNotificationPermission();
    if (notif != NotificationPermission.granted) {
      await FlutterForegroundTask.requestNotificationPermission();
    }
    if (defaultTargetPlatform == TargetPlatform.android) {
      final activity = await Permission.activityRecognition.request();
      if (!activity.isGranted && !activity.isLimited) {
        // Continue — motion still works via accelerometer.
      }
      if (!await FlutterForegroundTask.isIgnoringBatteryOptimizations) {
        await FlutterForegroundTask.requestIgnoreBatteryOptimization();
      }
    }
    return ensureServiceRunning();
  }

  Future<void> disable() async {
    await FlutterForegroundTask.saveData(key: _enabledKey, value: false);
    if (await FlutterForegroundTask.isRunningService) {
      await FlutterForegroundTask.stopService();
    }
  }

  Future<bool> ensureServiceRunning() async {
    if (kIsWeb) return false;
    if (await FlutterForegroundTask.isRunningService) {
      return true;
    }
    final result = await FlutterForegroundTask.startService(
      serviceId: 35035,
      notificationTitle: 'Detecção de sono ativa',
      notificationText: 'Monitorando automaticamente — sem abrir o app.',
      callback: sleepDetectionStartCallback,
      serviceTypes: const [
        ForegroundServiceTypes.health,
        ForegroundServiceTypes.dataSync,
      ],
    );
    return result is ServiceRequestSuccess;
  }

  Future<bool> get isRunning async =>
      !kIsWeb && await FlutterForegroundTask.isRunningService;

  void _onTaskData(Object data) {
    if (data is Map) {
      final map = Map<String, dynamic>.from(data);
      _applyEvent(map);
    }
  }

  Future<void> flushPendingEvents() async {
    final raw = await FlutterForegroundTask.getData(key: _pendingKey);
    if (raw is! String || raw.isEmpty) return;
    List<dynamic> list;
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return;
      list = decoded;
    } catch (_) {
      return;
    }
    for (final item in list) {
      if (item is Map) {
        await _applyEvent(Map<String, dynamic>.from(item));
      }
    }
    await FlutterForegroundTask.saveData(key: _pendingKey, value: '[]');
  }

  Future<void> _applyEvent(Map<String, dynamic> map) async {
    final db = _database;
    if (db == null) return;
    final profileRaw = await FlutterForegroundTask.getData(key: _profileKey);
    if (profileRaw is! String || profileRaw.isEmpty) return;

    final repos = ColonyRepositories.create(db);
    final type = map['type'] as String?;
    final confidenceName = map['confidence'] as String? ?? 'medium';
    final confidence = ConfidenceLevel.values.byName(confidenceName);

    if (type == 'onset') {
      final onset = DateTime.parse(map['onset_at'] as String);
      await repos.health.openDetectedSleep(
        profileId: EntityId(profileRaw),
        startedAt: onset,
        confidence: confidence,
      );
    } else if (type == 'wake') {
      final onset = DateTime.parse(map['onset_at'] as String);
      final wake = DateTime.parse(map['wake_at'] as String);
      final existing = await repos.health.listSleepSessions(EntityId(profileRaw));
      const merge = SleepSessionMergePolicy();
      final candidate = SleepSession.create(
        id: EntityId('pending'),
        profileId: EntityId(profileRaw),
        startedAt: onset,
        endedAt: wake,
        source: SleepSessionSource.detected,
        confidence: confidence,
        createdAt: DateTime.now().toUtc(),
      );
      if (merge.isSupersededByExisting(
        candidate: candidate,
        existing: existing,
      )) {
        // Drop open detected session if HC already covers the night.
        final open = await repos.health.findOpenSleepSession(EntityId(profileRaw));
        if (open != null && open.source == SleepSessionSource.detected) {
          await repos.health.upsertSleepSession(
            open.copyWith(endedAt: wake, updatedAt: DateTime.now().toUtc()),
          );
        }
        return;
      }
      await repos.health.closeDetectedSleep(
        profileId: EntityId(profileRaw),
        startedAt: onset,
        endedAt: wake,
        confidence: confidence,
      );
    }
  }
}
