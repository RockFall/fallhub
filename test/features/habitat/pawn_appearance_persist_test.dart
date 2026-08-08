import 'package:fallhub/features/habitat/application/pawn_appearance_provider.dart';
import 'package:fallhub/features/habitat/application/pawn_appearance_store.dart';
import 'package:fallhub/features/habitat/flame/habitat_tint.dart';
import 'package:flutter/painting.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
  });

  test('replace persists and hydrate restores after new container', () async {
    final edited = PawnAppearance(
      name: 'Ada',
      hairStyle: 'mohawk',
      skin: PawnPalettes.skinDeep,
      hair: const Color(0xFF3D6FBF),
      bio: 'salva',
    );

    final container = ProviderContainer();
    addTearDown(container.dispose);
    await container.read(pawnAppearanceProvider.notifier).replace(edited);

    final raw = await PawnAppearanceStore.load();
    expect(raw?.name, 'Ada');
    expect(raw?.hairStyle, 'mohawk');

    final next = ProviderContainer();
    addTearDown(next.dispose);
    // Trigger build + hydrate.
    expect(next.read(pawnAppearanceProvider).name, 'Colonista');
    await Future<void>.delayed(Duration.zero);
    await Future<void>.delayed(const Duration(milliseconds: 50));
    expect(next.read(pawnAppearanceProvider).name, 'Ada');
    expect(next.read(pawnAppearanceProvider).hairStyle, 'mohawk');
  });

  test('late hydrate does not overwrite a newer replace', () async {
    SharedPreferences.setMockInitialValues({
      PawnAppearanceStore.prefsKey:
          '{"name":"Velho","hairStyle":"bob","skin":1,"hair":2,"bio":""}',
    });

    final container = ProviderContainer();
    addTearDown(container.dispose);
    container.read(pawnAppearanceProvider); // start hydrate of "Velho"

    await container.read(pawnAppearanceProvider.notifier).replace(
          PawnAppearance(name: 'Novo', hairStyle: 'spikes'),
        );

    await Future<void>.delayed(const Duration(milliseconds: 50));
    expect(container.read(pawnAppearanceProvider).name, 'Novo');
    expect(container.read(pawnAppearanceProvider).hairStyle, 'spikes');
  });
}
