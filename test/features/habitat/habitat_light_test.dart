import 'package:fallhub/features/habitat/flame/habitat_light.dart';
import 'package:fallhub/features/habitat/flame/habitat_locations.dart';
import 'package:fallhub/features/habitat/flame/habitat_map.dart';
import 'package:fallhub/features/habitat/flame/habitat_prop_catalog.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('HabitatLightField V9.11', () {
    test('indoor night is near pitch black without lamps', () {
      final d = HabitatLightField.ambientDarkness(0.85, outdoor: false);
      expect(d, greaterThan(0.85));
    });

    test('outdoor night stays penumbra not full black', () {
      final d = HabitatLightField.ambientDarkness(0.85, outdoor: true);
      expect(d, inInclusiveRange(0.35, 0.52));
      // Penumbra must never trigger "Escuro demais."
      expect(d, lessThan(HabitatLightField.tooDarkThreshold));
    });

    test('tooDarkThreshold sits between outdoor penumbra and indoor night', () {
      final outdoor = HabitatLightField.ambientDarkness(0.9, outdoor: true);
      final indoor = HabitatLightField.ambientDarkness(0.9, outdoor: false);
      expect(outdoor, lessThan(HabitatLightField.tooDarkThreshold));
      expect(indoor, greaterThan(HabitatLightField.tooDarkThreshold));
    });

    test('daytime darkness is low', () {
      final d = HabitatLightField.ambientDarkness(0.45, outdoor: false);
      expect(d, lessThan(0.1));
    });

    test('lamp reduces darkness at nearby cells', () {
      final map = HabitatMap(
        width: 16,
        height: 12,
        floors: List.filled(16 * 12, HabitatFloor.wood),
        props: [
          HabitatPropCatalog.spawn(HabitatPropKinds.lamp, (3, 3)),
        ],
      );
      final field = HabitatLightField.compute(
        map,
        phase: 0.85,
        locationId: HabitatLocationIds.bedroom,
      );
      final atLamp = HabitatLightField.at(field, map, 3, 3);
      final mid = HabitatLightField.at(field, map, 7, 3);
      final far = HabitatLightField.at(field, map, 14, 10);
      expect(atLamp, lessThan(mid));
      expect(mid, lessThan(far));
      expect(atLamp, lessThan(0.35));
      expect(HabitatLightField.lampRadius, greaterThanOrEqualTo(7));
    });

    test('lamp illumination falloff is smooth (no hard step at mid radius)', () {
      const r = HabitatLightField.lampRadius;
      final a = HabitatLightField.lampIllumination(r * 0.4, r, 0);
      final b = HabitatLightField.lampIllumination(r * 0.41, r, 0);
      expect((a - b).abs(), lessThan(0.08));
      expect(HabitatLightField.lampIllumination(r, r, 0), 0);
    });
  });
}
