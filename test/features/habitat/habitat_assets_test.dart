import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:living_habitat_assets/living_habitat_assets.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('V6 package assets resolve via rootBundle', () async {
    final paths = [
      HabitatAssets.woodFloor,
      HabitatAssets.body('south'),
      HabitatAssets.body('south', bodyType: 'female'),
      HabitatAssets.body('east', bodyType: 'hulk'),
      HabitatAssets.head('south'),
      HabitatAssets.head('south', bodyType: 'female'),
      HabitatAssets.hair('south'),
      HabitatAssets.hair('south', style: 'afro'),
      HabitatAssets.apparel('shirt_basic', 'male', 'south'),
      HabitatAssets.apparel('jacket', 'thin', 'east'),
      HabitatAssets.hat('tuque', 'north'),
      HabitatAssets.beard('full', 'south'),
      HabitatAssets.beard('goatee', 'north'), // falls back to south file
      HabitatAssets.bedSouth,
    ];
    for (final rel in paths) {
      final key = 'packages/${HabitatAssets.package}/$rel';
      final data = await rootBundle.load(key);
      expect(data.lengthInBytes, greaterThan(0), reason: key);
    }
  });
}
