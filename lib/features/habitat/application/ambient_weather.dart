import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Cached outdoor conditions for the Habitat ambient HUD.
class AmbientWeather {
  const AmbientWeather({
    required this.temperatureC,
    required this.weatherCode,
    required this.fetchedAt,
    this.latitude,
    this.longitude,
    this.isPlaceholder = false,
  });

  final double? temperatureC;
  final int? weatherCode;
  final DateTime fetchedAt;
  final double? latitude;
  final double? longitude;
  final bool isPlaceholder;

  static AmbientWeather placeholder([DateTime? at]) => AmbientWeather(
        temperatureC: null,
        weatherCode: null,
        fetchedAt: at ?? DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
        isPlaceholder: true,
      );

  Map<String, Object?> toJson() => {
        'temperatureC': temperatureC,
        'weatherCode': weatherCode,
        'fetchedAtMs': fetchedAt.toUtc().millisecondsSinceEpoch,
        'latitude': latitude,
        'longitude': longitude,
        'isPlaceholder': isPlaceholder,
      };

  static AmbientWeather? fromJson(Map<String, Object?> json) {
    final ms = json['fetchedAtMs'];
    if (ms is! int) return null;
    return AmbientWeather(
      temperatureC: (json['temperatureC'] as num?)?.toDouble(),
      weatherCode: json['weatherCode'] as int?,
      fetchedAt: DateTime.fromMillisecondsSinceEpoch(ms, isUtc: true),
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      isPlaceholder: json['isPlaceholder'] as bool? ?? false,
    );
  }
}

/// WMO weather code → short PT label for the HUD.
String ambientWeatherLabel(int? code) {
  if (code == null) return '—';
  if (code == 0) return 'Céu limpo';
  if (code == 1) return 'Principalmente limpo';
  if (code == 2) return 'Parcialmente nublado';
  if (code == 3) return 'Nublado';
  if (code == 45 || code == 48) return 'Neblina';
  if (code >= 51 && code <= 57) return 'Garoa';
  if (code >= 61 && code <= 67) return 'Chuva';
  if (code >= 71 && code <= 77) return 'Neve';
  if (code >= 80 && code <= 82) return 'Pancadas';
  if (code >= 85 && code <= 86) return 'Neve forte';
  if (code == 95) return 'Trovoada';
  if (code == 96 || code == 99) return 'Trovoada com granizo';
  return 'Variável';
}

typedef AmbientHttpGet = Future<String> Function(Uri uri);

/// Persist + refresh outdoor weather (Open-Meteo + IP geolocation).
///
/// Refetches only when the cache is older than [ttl]. On failure returns the
/// last good sample or a placeholder.
abstract final class AmbientWeatherStore {
  static const prefsKey = 'habitat_ambient_weather_v1';
  static const Duration ttl = Duration(minutes: 30);

  /// Override in tests.
  static AmbientHttpGet httpGet = _defaultHttpGet;

  /// Override clock in tests.
  static DateTime Function() now = () => DateTime.now().toUtc();

  static Future<SharedPreferences?> _prefs() async {
    try {
      return await SharedPreferences.getInstance();
    } on PlatformException {
      return null;
    } on MissingPluginException {
      return null;
    } catch (_) {
      return null;
    }
  }

  static Future<AmbientWeather?> loadCached() async {
    final prefs = await _prefs();
    if (prefs == null) return null;
    final raw = prefs.getString(prefsKey);
    if (raw == null || raw.isEmpty) return null;
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map) return null;
      return AmbientWeather.fromJson(Map<String, Object?>.from(decoded));
    } catch (_) {
      return null;
    }
  }

  static Future<void> save(AmbientWeather weather) async {
    final prefs = await _prefs();
    if (prefs == null) return;
    try {
      await prefs.setString(prefsKey, jsonEncode(weather.toJson()));
    } on PlatformException {
      // Hot-restart without native plugin — ignore.
    } on MissingPluginException {
      // Same as PlatformException.
    } catch (_) {
      // Prefs unavailable in some test / desktop edge cases.
    }
  }

  static bool isFresh(AmbientWeather weather, {DateTime? at}) {
    if (weather.isPlaceholder) return false;
    final t = at ?? now();
    return t.difference(weather.fetchedAt) < ttl;
  }

  /// Load cache, fetch if stale, fall back to last/placeholder.
  static Future<AmbientWeather> loadOrRefresh() async {
    final cached = await loadCached();
    if (cached != null && isFresh(cached)) return cached;

    try {
      final fresh = await fetchCurrent();
      await save(fresh);
      return fresh;
    } catch (_) {
      if (cached != null && !cached.isPlaceholder) return cached;
      return AmbientWeather.placeholder(now());
    }
  }

  static Future<AmbientWeather> fetchCurrent() async {
    final loc = await _fetchApproxLocation();
    final uri = Uri.https('api.open-meteo.com', '/v1/forecast', {
      'latitude': loc.$1.toString(),
      'longitude': loc.$2.toString(),
      'current': 'temperature_2m,weather_code',
      'timezone': 'auto',
    });
    final body = await httpGet(uri);
    final json = jsonDecode(body);
    if (json is! Map) throw const FormatException('weather root');
    final current = json['current'];
    if (current is! Map) throw const FormatException('weather current');
    final temp = current['temperature_2m'];
    final code = current['weather_code'];
    return AmbientWeather(
      temperatureC: (temp as num?)?.toDouble(),
      weatherCode: (code as num?)?.toInt(),
      fetchedAt: now(),
      latitude: loc.$1,
      longitude: loc.$2,
    );
  }

  /// Approximate lat/lon from public IP (no device GPS permission).
  static Future<(double, double)> _fetchApproxLocation() async {
    final body = await httpGet(Uri.https('ipwho.is', '/'));
    final json = jsonDecode(body);
    if (json is! Map) throw const FormatException('geo root');
    if (json['success'] == false) {
      throw StateError('geo failed');
    }
    final lat = json['latitude'];
    final lon = json['longitude'];
    if (lat is! num || lon is! num) {
      throw const FormatException('geo coords');
    }
    return (lat.toDouble(), lon.toDouble());
  }

  static Future<String> _defaultHttpGet(Uri uri) async {
    final client = HttpClient();
    try {
      final req = await client.getUrl(uri).timeout(const Duration(seconds: 8));
      req.headers.set(HttpHeaders.acceptHeader, 'application/json');
      final res = await req.close().timeout(const Duration(seconds: 8));
      final body = await res.transform(utf8.decoder).join();
      if (res.statusCode < 200 || res.statusCode >= 300) {
        throw HttpException('HTTP ${res.statusCode}', uri: uri);
      }
      return body;
    } finally {
      client.close(force: true);
    }
  }
}

class AmbientWeatherNotifier extends AsyncNotifier<AmbientWeather> {
  @override
  Future<AmbientWeather> build() => AmbientWeatherStore.loadOrRefresh();

  Future<void> refresh({bool force = false}) async {
    if (!force) {
      final current = state.asData?.value;
      if (current != null && AmbientWeatherStore.isFresh(current)) {
        return;
      }
    }
    state = const AsyncLoading();
    state = await AsyncValue.guard(AmbientWeatherStore.loadOrRefresh);
  }
}

final ambientWeatherProvider =
    AsyncNotifierProvider<AmbientWeatherNotifier, AmbientWeather>(
  AmbientWeatherNotifier.new,
);
