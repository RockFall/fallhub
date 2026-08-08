import 'package:fallhub/features/habitat/application/pawn_appearance_store.dart';
import 'package:fallhub/features/habitat/flame/habitat_tint.dart';
import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('PawnAppearanceStore round-trips JSON fields', () {
    final original = PawnAppearance(
      name: 'Ada',
      bodyType: 'thin',
      hairStyle: 'mohawk',
      beardStyle: 'goatee',
      apparelTop: 'jacket',
      hat: 'cowboy',
      loadoutId: VisualLoadouts.outdoors,
      skin: PawnPalettes.skinDeep,
      hair: const Color(0xFF3D6FBF),
      apparelTint: StuffPalettes.clothRed,
      bio: 'Engenheira da colônia',
    );
    final restored = PawnAppearanceStore.fromJson(
      PawnAppearanceStore.toJson(original),
    );
    expect(restored.name, 'Ada');
    expect(restored.bodyType, 'thin');
    expect(restored.hairStyle, 'mohawk');
    expect(restored.beardStyle, 'goatee');
    expect(restored.apparelTop, 'jacket');
    expect(restored.hat, 'cowboy');
    expect(restored.loadoutId, VisualLoadouts.outdoors);
    expect(restored.skin.toARGB32(), original.skin.toARGB32());
    expect(restored.hair.toARGB32(), original.hair.toARGB32());
    expect(restored.apparelTint.toARGB32(), original.apparelTint.toARGB32());
    expect(restored.bio, 'Engenheira da colônia');
  });
}

