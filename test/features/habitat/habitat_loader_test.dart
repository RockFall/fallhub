import 'package:fallhub/features/habitat/flame/habitat_asset_loader.dart';
import 'package:fallhub/features/habitat/flame/habitat_map.dart';
import 'package:flame/cache.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:living_habitat_assets/living_habitat_assets.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('loadHabitatAssets fills Images cache', () async {
    final images = Images(prefix: '');
    final map = HabitatMap.demoRoom();
    await loadHabitatAssets(images, map);
    expect(images.containsKey(HabitatAssets.woodFloor), isTrue);
    expect(images.containsKey(HabitatAssets.body('south')), isTrue);
  });
}
