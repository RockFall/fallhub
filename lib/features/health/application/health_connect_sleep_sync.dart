import 'dart:io' show Platform;

import 'package:colony_database/colony_database.dart';
import 'package:colony_domain/colony_domain.dart';
import 'package:flutter/foundation.dart';
import 'package:health/health.dart';
import 'package:logging/logging.dart';

import 'health_connect_settings_launcher.dart';

/// Result of a Health Connect sleep pull (ADR-035).
class HealthConnectSleepSyncResult {
  const HealthConnectSleepSyncResult({
    required this.imported,
    required this.rawPoints,
    this.message,
  });

  final int imported;
  final int rawPoints;
  final String? message;

  bool get isEmpty => imported == 0 && rawPoints == 0;
}

/// Reads sleep sessions from Health Connect / HealthKit (ADR-035).
class HealthConnectSleepSync {
  HealthConnectSleepSync({Health? health}) : _health = health ?? Health();

  final Health _health;
  final _log = Logger('HealthConnectSleepSync');
  bool _configured = false;

  static List<HealthDataType> get _sleepReadTypes {
    if (kIsWeb) return const [];
    if (Platform.isIOS) {
      return const [
        HealthDataType.SLEEP_ASLEEP,
        HealthDataType.SLEEP_IN_BED,
        HealthDataType.SLEEP_AWAKE,
        HealthDataType.SLEEP_DEEP,
        HealthDataType.SLEEP_LIGHT,
        HealthDataType.SLEEP_REM,
      ];
    }
    return const [HealthDataType.SLEEP_SESSION];
  }

  Future<void> _ensureConfigured() async {
    if (_configured) return;
    await _health.configure();
    _configured = true;
  }

  Future<bool> requestAuthorization() async {
    if (kIsWeb) return false;
    await _ensureConfigured();
    final types = _sleepReadTypes;
    if (types.isEmpty) return false;
    // Also ask steps so diagnostics can tell "HC works but sleep empty".
    final authTypes = Platform.isAndroid
        ? <HealthDataType>[
            ...types,
            HealthDataType.STEPS,
          ]
        : types;
    final permissions =
        authTypes.map((_) => HealthDataAccess.READ).toList(growable: false);
    try {
      if (Platform.isAndroid) {
        final status = await _health.getHealthConnectSdkStatus();
        if (status != null && status != HealthConnectSdkStatus.sdkAvailable) {
          _log.warning('Health Connect SDK status: $status');
          return false;
        }
      }
      final granted = await _health.requestAuthorization(
        authTypes,
        permissions: permissions,
      );
      if (!granted) return false;

      if (Platform.isAndroid) {
        try {
          final historyOk = await _health.isHealthDataHistoryAuthorized();
          if (historyOk != true) {
            await _health.requestHealthDataHistoryAuthorization();
          }
        } catch (e, st) {
          _log.warning('History authorization failed', e, st);
        }
      }
      return true;
    } catch (e, st) {
      _log.warning('requestAuthorization failed', e, st);
      return false;
    }
  }

  Future<HealthConnectSleepSyncResult> sync({
    required ColonyRepositories repos,
    required EntityId profileId,
    int lookbackDays = 730,
  }) async {
    if (kIsWeb) {
      return const HealthConnectSleepSyncResult(
        imported: 0,
        rawPoints: 0,
        message: 'Health Connect indisponível nesta plataforma.',
      );
    }
    await _ensureConfigured();

    if (Platform.isAndroid) {
      await _ensureHistoryPermission();
      return _syncAndroidNative(
        repos: repos,
        profileId: profileId,
        lookbackDays: lookbackDays,
      );
    }

    return _syncViaPlugin(
      repos: repos,
      profileId: profileId,
      lookbackDays: lookbackDays,
    );
  }

  /// HC only exposes ~30 days before first grant unless history is authorized.
  Future<void> _ensureHistoryPermission() async {
    try {
      final ok = await _health.isHealthDataHistoryAuthorized();
      if (ok == true) return;
      _log.info('Requesting Health Connect history permission…');
      await _health.requestHealthDataHistoryAuthorization();
    } catch (e, st) {
      _log.warning('History permission request failed', e, st);
    }
  }

  Future<HealthConnectSleepSyncResult> _syncAndroidNative({
    required ColonyRepositories repos,
    required EntityId profileId,
    required int lookbackDays,
  }) async {
    await _ensureHistoryPermission();

    var diag = await HealthConnectSettingsLauncher.diagnoseSleep(
      days: lookbackDays,
    );
    _log.info('HC diagnose: $diag');

    final hasSleep = diag?['hasSleepReadPermission'] == true;
    if (!hasSleep) {
      final ok = await requestAuthorization();
      if (!ok) {
        return const HealthConnectSleepSyncResult(
          imported: 0,
          rawPoints: 0,
          message:
              'Permissão de LEITURA de Sono ausente no Health Connect. Ative de novo o opt-in.',
        );
      }
      await _ensureHistoryPermission();
      diag = await HealthConnectSettingsLauncher.diagnoseSleep(
        days: lookbackDays,
      );
    }

    final native = await HealthConnectSettingsLauncher.readSleepSessions(
      days: lookbackDays,
    );
    _log.info('Native sleep rows: ${native.length}');

    // Re-check after read (history may have been granted mid-flow).
    diag = await HealthConnectSettingsLauncher.diagnoseSleep(
      days: lookbackDays,
    );
    final historyGranted = diag?['hasHistoryPermission'] == true;
    final effectiveDays = diag?['effectiveDays'];

    if (native.isEmpty) {
      final message = diag?['message'] as String? ??
          '0 sessões de sono no Health Connect.';
      return HealthConnectSleepSyncResult(
        imported: 0,
        rawPoints: 0,
        message: message,
      );
    }

    final existing = await repos.health.listSleepSessions(profileId);
    const merge = SleepSessionMergePolicy();
    var upserted = 0;
    final seen = <String>{};

    for (final row in native) {
      final startMs = row['start'];
      final endMs = row['end'];
      if (startMs is! int || endMs is! int) continue;
      final from =
          DateTime.fromMillisecondsSinceEpoch(startMs, isUtc: true);
      final to = DateTime.fromMillisecondsSinceEpoch(endMs, isUtc: true);
      if (!to.isAfter(from)) continue;
      if (to.difference(from) < const Duration(minutes: 20)) continue;

      final origin = (row['origin'] as String?) ?? 'unknown';
      final externalId = 'hc:native:$origin:$startMs:$endMs';
      if (!seen.add(externalId)) continue;

      final candidate = SleepSession.create(
        id: EntityId(externalId),
        profileId: profileId,
        startedAt: from,
        endedAt: to,
        source: SleepSessionSource.healthConnect,
        confidence: ConfidenceLevel.high,
        externalId: externalId,
        notes: 'origin=$origin',
        createdAt: DateTime.now().toUtc(),
      );

      if (merge.isSupersededByExisting(
        candidate: candidate,
        existing: existing,
      )) {
        continue;
      }

      await repos.health.upsertSleepSession(candidate);
      upserted++;
      existing.add(candidate);
    }

    return HealthConnectSleepSyncResult(
      imported: upserted,
      rawPoints: native.length,
      message: upserted == 0
          ? 'HC tem ${native.length} sessão(ões), mas nenhuma nova para importar.'
          : (!historyGranted
              ? '$upserted importada(s). Histórico ainda off — janela ~${effectiveDays ?? 30} dias; ative “Acessar dados anteriores” para o Colônia.'
              : null),
    );
  }

  Future<HealthConnectSleepSyncResult> _syncViaPlugin({
    required ColonyRepositories repos,
    required EntityId profileId,
    required int lookbackDays,
  }) async {
    final types = _sleepReadTypes;
    final end = DateTime.now();
    final start = DateTime(end.year, end.month, end.day)
        .subtract(Duration(days: lookbackDays));

    List<HealthDataPoint> points;
    try {
      points = await _health.getHealthDataFromTypes(
        types: types,
        startTime: start,
        endTime: end,
      );
    } catch (e, st) {
      _log.warning('plugin sleep read failed', e, st);
      return HealthConnectSleepSyncResult(
        imported: 0,
        rawPoints: 0,
        message: 'Falha ao ler sono: $e',
      );
    }

    if (points.isEmpty) {
      return const HealthConnectSleepSyncResult(
        imported: 0,
        rawPoints: 0,
        message: 'Nenhuma sessão de sono no HealthKit.',
      );
    }

    final existing = await repos.health.listSleepSessions(profileId);
    const merge = SleepSessionMergePolicy();
    var upserted = 0;
    final seen = <String>{};

    for (final point in points) {
      final from = point.dateFrom.toUtc();
      final to = point.dateTo.toUtc();
      if (!to.isAfter(from)) continue;
      if (to.difference(from) < const Duration(minutes: 20)) continue;
      final externalId =
          'hc:${point.type.name}:${from.millisecondsSinceEpoch}:${to.millisecondsSinceEpoch}';
      if (!seen.add(externalId)) continue;
      final candidate = SleepSession.create(
        id: EntityId(externalId),
        profileId: profileId,
        startedAt: from,
        endedAt: to,
        source: SleepSessionSource.healthConnect,
        confidence: ConfidenceLevel.high,
        externalId: externalId,
        createdAt: DateTime.now().toUtc(),
      );
      if (merge.isSupersededByExisting(
        candidate: candidate,
        existing: existing,
      )) {
        continue;
      }
      await repos.health.upsertSleepSession(candidate);
      upserted++;
      existing.add(candidate);
    }

    return HealthConnectSleepSyncResult(
      imported: upserted,
      rawPoints: points.length,
    );
  }
}
