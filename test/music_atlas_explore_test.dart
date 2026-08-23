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
import 'package:fallhub/features/music_atlas/presentation/music_album_screen.dart';
import 'package:fallhub/features/music_atlas/presentation/music_atlas_explore_screen.dart';
import 'package:fallhub/features/music_atlas/presentation/music_atlas_hub_screen.dart';

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

  Future<
      ({
        ColonyRepositories repos,
        ColonyDatabase db,
        String unknownId,
        String heardId,
      })> seed() async {
    final db = ColonyDatabase.inMemory();
    final repos = ColonyRepositories.create(
      db,
      idGenerator: FixedIdGenerator([
        for (var i = 1; i <= 80; i++) 'id-$i',
      ]),
      clock: () => DateTime.utc(2026, 8, 23, 12),
    );
    final profile = await repos.profiles.create(
      colonyName: 'Test',
      displayName: 'Caio',
      timezone: 'UTC',
      locale: 'pt_BR',
      baseCurrency: 'BRL',
    );
    await repos.preferences.save(
      AppPreferences.defaults().copyWith(onboardingCompleted: true),
    );
    final heard = await repos.musicAtlas.createNode(
      nodeType: MusicNodeType.releaseGroup,
      canonicalName: 'Kind of Blue',
      description: 'Miles Davis',
      beginYear: 1959,
    );
    await repos.musicAtlas.recordEncounter(
      profileId: profile.id,
      nodeId: heard.id,
      encounterType: MusicEncounterType.listen,
    );
    final unknown = await repos.musicAtlas.createNode(
      nodeType: MusicNodeType.releaseGroup,
      canonicalName: 'Disco sem ficha',
      description: 'Artista local',
      beginYear: 2024,
    );
    await repos.musicAtlas.recordEncounter(
      profileId: profile.id,
      nodeId: unknown.id,
      encounterType: MusicEncounterType.listen,
    );
    return (repos: repos, db: db, unknownId: unknown.id.value, heardId: heard.id.value);
  }

  testWidgets('hub offers the ramification map', (tester) async {
    tester.view.physicalSize = const Size(800, 1400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final seeded = await seed();
    addTearDown(seeded.db.close);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          databaseProvider.overrideWithValue(seeded.db),
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

    expect(find.text(AppStrings.musicAtlasOpenMap), findsOneWidget);
    expect(find.text('Kind of Blue'), findsWidgets);

    await _flushDisposeTimers(tester);
  });

  testWidgets('explore map shows rivers and blooms heard albums', (tester) async {
    tester.view.physicalSize = const Size(1200, 1800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final seeded = await seed();
    addTearDown(seeded.db.close);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          databaseProvider.overrideWithValue(seeded.db),
          spotifyCatalogPortProvider.overrideWithValue(FakeSpotifyCatalog()),
          spotifyTokenStoreProvider.overrideWithValue(MemorySpotifyTokenStore()),
        ],
        child: MaterialApp(
          theme: ColonyTheme.dark(),
          home: const Scaffold(
            body: MusicAtlasExploreScreen(initialTerritory: 'jazz.modal'),
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));

    expect(find.text('Modal Jazz'), findsWidgets);
    expect(find.text('Kind of Blue'), findsWidgets);
    expect(find.textContaining('já ouvidos neste braço'), findsOneWidget);

    await _flushDisposeTimers(tester);
  });

  testWidgets('album page renders bundled markdown', (tester) async {
    tester.view.physicalSize = const Size(800, 1400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final seeded = await seed();
    addTearDown(seeded.db.close);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          databaseProvider.overrideWithValue(seeded.db),
          spotifyCatalogPortProvider.overrideWithValue(FakeSpotifyCatalog()),
          spotifyTokenStoreProvider.overrideWithValue(MemorySpotifyTokenStore()),
        ],
        child: MaterialApp(
          theme: ColonyTheme.dark(),
          home: Scaffold(body: MusicAlbumScreen(nodeId: seeded.heardId)),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('Kind of Blue'), findsWidgets);
    expect(find.textContaining('So What'), findsOneWidget);
    expect(find.text(AppStrings.musicAtlasGoogleSearch), findsNothing);
    expect(find.text(AppStrings.musicAtlasGoogleSearchMore), findsOneWidget);

    await _flushDisposeTimers(tester);
  });

  testWidgets('album without dossier offers Google search', (tester) async {
    tester.view.physicalSize = const Size(800, 1400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final seeded = await seed();
    addTearDown(seeded.db.close);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          databaseProvider.overrideWithValue(seeded.db),
          spotifyCatalogPortProvider.overrideWithValue(FakeSpotifyCatalog()),
          spotifyTokenStoreProvider.overrideWithValue(MemorySpotifyTokenStore()),
        ],
        child: MaterialApp(
          theme: ColonyTheme.dark(),
          home: Scaffold(body: MusicAlbumScreen(nodeId: seeded.unknownId)),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('Disco sem ficha'), findsWidgets);
    expect(find.text(AppStrings.musicAtlasNoDossier), findsOneWidget);
    expect(find.text(AppStrings.musicAtlasGoogleSearch), findsWidgets);

    await _flushDisposeTimers(tester);
  });
}
