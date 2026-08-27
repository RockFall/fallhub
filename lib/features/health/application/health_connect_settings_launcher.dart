import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Opens system screens and reads sleep via native Health Connect (ADR-035).
class HealthConnectSettingsLauncher {
  static const _channel = MethodChannel('com.fallhub.fallhub/health_connect');

  static Future<bool> openHealthConnectSettings() async {
    if (kIsWeb || !Platform.isAndroid) return false;
    try {
      final ok = await _channel.invokeMethod<bool>('openHealthConnectSettings');
      return ok ?? false;
    } catch (_) {
      return false;
    }
  }

  static Future<bool> openSamsungHealth() async {
    if (kIsWeb || !Platform.isAndroid) return false;
    try {
      final ok = await _channel.invokeMethod<bool>('openSamsungHealth');
      return ok ?? false;
    } catch (_) {
      return false;
    }
  }

  static Future<Map<String, dynamic>?> diagnoseSleep({int days = 730}) async {
    if (kIsWeb || !Platform.isAndroid) return null;
    try {
      final raw = await _channel.invokeMethod<dynamic>('diagnoseSleep', {
        'days': days,
      });
      if (raw is Map) {
        return Map<String, dynamic>.from(raw);
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  /// Native SleepSessionRecord rows: `{start, end, origin, stages}`.
  static Future<List<Map<String, dynamic>>> readSleepSessions({
    int days = 730,
  }) async {
    if (kIsWeb || !Platform.isAndroid) return const [];
    try {
      final raw = await _channel.invokeMethod<dynamic>('readSleepSessions', {
        'days': days,
      });
      if (raw is! List) return const [];
      return raw
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
    } catch (_) {
      return const [];
    }
  }
}
