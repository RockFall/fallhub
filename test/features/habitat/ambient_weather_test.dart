import 'package:fallhub/features/habitat/application/ambient_weather.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    AmbientWeatherStore.httpGet = (_) async => throw StateError('no net');
    AmbientWeatherStore.now = () => DateTime.utc(2026, 8, 7, 18, 0);
  });

  group('AmbientWeatherStore', () {
    test('isFresh respects 30 minute TTL', () {
      final fresh = AmbientWeather(
        temperatureC: 22,
        weatherCode: 0,
        fetchedAt: DateTime.utc(2026, 8, 7, 17, 45),
      );
      final stale = AmbientWeather(
        temperatureC: 22,
        weatherCode: 0,
        fetchedAt: DateTime.utc(2026, 8, 7, 17, 20),
      );
      expect(AmbientWeatherStore.isFresh(fresh), isTrue);
      expect(AmbientWeatherStore.isFresh(stale), isFalse);
      expect(
        AmbientWeatherStore.isFresh(AmbientWeather.placeholder()),
        isFalse,
      );
    });

    test('loadOrRefresh uses cache when fresh (no HTTP)', () async {
      final cached = AmbientWeather(
        temperatureC: 19.4,
        weatherCode: 2,
        fetchedAt: DateTime.utc(2026, 8, 7, 17, 50),
        latitude: -23.5,
        longitude: -46.6,
      );
      await AmbientWeatherStore.save(cached);

      var calls = 0;
      AmbientWeatherStore.httpGet = (_) async {
        calls++;
        throw StateError('should not fetch');
      };

      final got = await AmbientWeatherStore.loadOrRefresh();
      expect(calls, 0);
      expect(got.temperatureC, 19.4);
      expect(got.weatherCode, 2);
      expect(got.isPlaceholder, isFalse);
    });

    test('stale cache refetches; failure keeps last sample', () async {
      final cached = AmbientWeather(
        temperatureC: 11,
        weatherCode: 61,
        fetchedAt: DateTime.utc(2026, 8, 7, 16, 0),
      );
      await AmbientWeatherStore.save(cached);

      AmbientWeatherStore.httpGet = (_) async => throw StateError('offline');

      final got = await AmbientWeatherStore.loadOrRefresh();
      expect(got.temperatureC, 11);
      expect(got.weatherCode, 61);
      expect(got.isPlaceholder, isFalse);
    });

    test('no cache + failed fetch → placeholder', () async {
      AmbientWeatherStore.httpGet = (_) async => throw StateError('offline');
      final got = await AmbientWeatherStore.loadOrRefresh();
      expect(got.isPlaceholder, isTrue);
      expect(got.temperatureC, isNull);
      expect(ambientWeatherLabel(got.weatherCode), '—');
    });

    test('successful fetch parses geo + open-meteo and persists', () async {
      AmbientWeatherStore.httpGet = (uri) async {
        if (uri.host.contains('ipwho')) {
          return '{"success":true,"latitude":-23.55,"longitude":-46.63}';
        }
        if (uri.host.contains('open-meteo')) {
          return '{"current":{"temperature_2m":27.2,"weather_code":3}}';
        }
        throw StateError(uri.toString());
      };

      final got = await AmbientWeatherStore.loadOrRefresh();
      expect(got.temperatureC, 27.2);
      expect(got.weatherCode, 3);
      expect(got.latitude, closeTo(-23.55, 0.01));
      expect(got.isPlaceholder, isFalse);

      final reloaded = await AmbientWeatherStore.loadCached();
      expect(reloaded?.temperatureC, 27.2);
      expect(ambientWeatherLabel(3), 'Nublado');
    });

    test('fresh cache skips refetch after a prior save', () async {
      AmbientWeatherStore.httpGet = (uri) async {
        if (uri.host.contains('ipwho')) {
          return '{"success":true,"latitude":1.0,"longitude":2.0}';
        }
        return '{"current":{"temperature_2m":10,"weather_code":0}}';
      };
      await AmbientWeatherStore.loadOrRefresh();

      var calls = 0;
      AmbientWeatherStore.httpGet = (_) async {
        calls++;
        return '{}';
      };
      final again = await AmbientWeatherStore.loadOrRefresh();
      expect(calls, 0);
      expect(again.temperatureC, 10);
    });
  });
}
