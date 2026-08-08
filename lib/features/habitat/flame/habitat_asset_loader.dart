import 'package:flame/cache.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';
import 'package:flutter/services.dart';
import 'package:living_habitat_assets/living_habitat_assets.dart';

import 'habitat_map.dart';
import 'habitat_prop_catalog.dart';

/// Loads habitat sprites via Flutter's package asset keys (no Flame prefix).
///
/// Missing files are skipped (stale APK / hot-restart without asset rebuild).
/// Core V0 paths still throw if absent so the errorBuilder can surface them.
Future<void> loadHabitatAssets(Images images, HabitatMap map) async {
  final required = <String>{
    HabitatAssets.woodFloor,
    HabitatAssets.carpet,
    HabitatAssets.concrete,
    for (final kind in HabitatPropKinds.furniture) ...[
      if (HabitatPropCatalog.assetPath(kind) !=
          HabitatPropCatalog.proceduralAsset)
        HabitatPropCatalog.assetPath(kind),
    ],
    for (final dir in HabitatAssets.directions) ...[
      HabitatAssets.body(dir, bodyType: 'male'),
      HabitatAssets.head(dir, bodyType: 'male'),
      HabitatAssets.hair(dir, style: 'bob'),
    ],
    for (final p in map.props)
      if (p.assetPath != HabitatPropCatalog.proceduralAsset) p.assetPath,
  };

  final optional = <String>{
    for (final dir in HabitatAssets.directions) ...[
      for (final body in HabitatAssets.bodyTypes)
        if (body != 'male') ...[
          HabitatAssets.body(dir, bodyType: body),
          HabitatAssets.head(dir, bodyType: body),
        ],
      for (final body in HabitatAssets.bodyTypes)
        for (final top in HabitatAssets.apparelTops)
          HabitatAssets.apparel(top, body, dir),
      for (final style in HabitatAssets.hairStyles)
        if (style != 'bob') HabitatAssets.hair(dir, style: style),
      for (final h in HabitatAssets.hats) HabitatAssets.hat(h, dir),
    ],
    for (final style in HabitatAssets.beardStyles) ...[
      HabitatAssets.beard(style, 'south'),
      HabitatAssets.beard(style, 'east'),
    ],
  };

  for (final path in required) {
    await _loadOne(images, path, required: true);
  }
  for (final path in optional) {
    await _loadOne(images, path, required: false);
  }
}

Future<void> _loadOne(
  Images images,
  String path, {
  required bool required,
}) async {
  if (images.containsKey(path)) return;
  final key = 'packages/${HabitatAssets.package}/$path';
  try {
    final data = await rootBundle.load(key);
    final image = await decodeImageFromList(data.buffer.asUint8List());
    images.add(path, image);
  } catch (e) {
    if (required) rethrow;
    assert(() {
      debugPrint('Habitat asset skipped (rebuild app to include): $key');
      return true;
    }());
  }
}
