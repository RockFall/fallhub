import 'package:colony_database/colony_database.dart';
import 'package:colony_design_system/colony_design_system.dart';
import 'package:colony_domain/colony_domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:fallhub/app/localization/app_strings.dart';
import 'package:fallhub/core/providers/app_providers.dart';
import 'package:fallhub/features/music_atlas/application/spotify_runtime.dart';
import 'package:fallhub/features/music_atlas/presentation/music_atlas_hub_screen.dart';
import 'package:fallhub/features/music_atlas/presentation/widgets/import_music_atlas_json_sheet.dart';

Future<void> _flushDisposeTimers(WidgetTester tester) async {
  await tester.pumpWidget(const SizedBox.shrink());
  for (var i = 0; i < 80; i++) {
    await tester.pump(const Duration(milliseconds: 1));
  }
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  Future<ColonyRepositories> seed(ColonyDatabase db) async {
    final repos = ColonyRepositories.create(
      db,
      idGenerator: FixedIdGenerator([
        for (var i = 1; i <= 80; i++) 'id-$i',
      ]),
      clock: () => DateTime.utc(2026, 8, 23, 12),
    );
    await repos.profiles.create(
      colonyName: 'Test',
      displayName: 'Caio',
      timezone: 'UTC',
      locale: 'pt_BR',
      baseCurrency: 'BRL',
    );
    await repos.preferences.save(
      AppPreferences.defaults().copyWith(onboardingCompleted: true),
    );
    return repos;
  }

  testWidgets('MusicAtlasHubScreen empty state and create node', (tester) async {
    tester.view.physicalSize = const Size(800, 1400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final db = ColonyDatabase.inMemory();
    addTearDown(db.close);
    await seed(db);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          databaseProvider.overrideWithValue(db),
          spotifyCatalogPortProvider.overrideWithValue(FakeSpotifyCatalog()),
          spotifyTokenStoreProvider.overrideWithValue(MemorySpotifyTokenStore()),
        ],
        child: MaterialApp(
          theme: ColonyTheme.dark(),
          home: const Scaffold(body: MusicAtlasHubScreen()),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text(AppStrings.musicAtlasEmpty), findsOneWidget);
    expect(find.text(AppStrings.musicAtlasCreateNode), findsWidgets);
    expect(find.text(AppStrings.musicAtlasImportJson), findsOneWidget);

    await tester.tap(find.text(AppStrings.musicAtlasCreateNode).first);
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).first, 'Kind of Blue');
    await tester.tap(find.text(AppStrings.musicAtlasCreateNode).last);
    await tester.pumpAndSettle();

    expect(find.text('Kind of Blue'), findsOneWidget);
    expect(find.text(AppStrings.musicAtlasEmpty), findsNothing);

    await _flushDisposeTimers(tester);
  });

  testWidgets('import sheet copies live prompt', (tester) async {
    tester.view.physicalSize = const Size(800, 1400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final db = ColonyDatabase.inMemory();
    addTearDown(db.close);
    await seed(db);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          databaseProvider.overrideWithValue(db),
          spotifyCatalogPortProvider.overrideWithValue(FakeSpotifyCatalog()),
          spotifyTokenStoreProvider.overrideWithValue(MemorySpotifyTokenStore()),
        ],
        child: MaterialApp(
          theme: ColonyTheme.dark(),
          home: const Scaffold(body: ImportMusicAtlasJsonPanel()),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.byKey(const Key('music_atlas.import.prompt')), findsOneWidget);
    expect(find.textContaining('music_atlas'), findsWidgets);
    expect(find.text(AppStrings.musicAtlasCopyPrompt), findsOneWidget);
    expect(find.text(AppStrings.musicAtlasPreview), findsOneWidget);

    await _flushDisposeTimers(tester);
  });
}
