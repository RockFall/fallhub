import 'package:colony_database/colony_database.dart';
import 'package:colony_design_system/colony_design_system.dart';
import 'package:colony_domain/colony_domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:fallhub/app/localization/app_strings.dart';
import 'package:fallhub/core/providers/app_providers.dart';
import 'package:fallhub/features/flashcards/presentation/flashcards_hub_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

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

  testWidgets('FlashcardsHubScreen empty state', (tester) async {
    tester.view.physicalSize = const Size(800, 1400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final db = ColonyDatabase.inMemory();
    addTearDown(db.close);

    final repos = ColonyRepositories.create(
      db,
      idGenerator: FixedIdGenerator([
        for (var i = 1; i <= 20; i++) 'id-$i',
      ]),
      clock: () => DateTime.utc(2026, 8, 17, 12),
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

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          databaseProvider.overrideWithValue(db),
          clockProvider.overrideWithValue(() => DateTime.utc(2026, 8, 17, 12)),
        ],
        child: MaterialApp(
          theme: ColonyTheme.dark(),
          home: const Scaffold(body: FlashcardsHubScreen()),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text(AppStrings.flashcardsEmpty), findsOneWidget);
    expect(find.text(AppStrings.flashcardsEmptyHint), findsOneWidget);
    expect(find.text(AppStrings.flashcardsStudyNow), findsOneWidget);
    expect(find.text(AppStrings.flashcardsDueTodayZero), findsOneWidget);
    expect(find.text(AppStrings.flashcardsSeedMap), findsWidgets);
    expect(find.text(AppStrings.flashcardsNewDeck), findsOneWidget);
    expect(find.text(AppStrings.flashcardsDisclaimer), findsOneWidget);
    expect(find.text(AppStrings.flashcardsNewCard), findsOneWidget);
    expect(find.byType(Semantics), findsWidgets);
    expect(find.text(AppStrings.flashcardsImportJson), findsWidgets);
    expect(find.textContaining('areaPath'), findsWidgets);
    expect(find.textContaining('ainda não há categorias'), findsOneWidget);

    await _flushDisposeTimers(tester);
  });

  testWidgets('FlashcardsHubScreen hero shows capped session count', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final now = DateTime.utc(2026, 8, 17, 12);
    final db = ColonyDatabase.inMemory();
    addTearDown(db.close);
    final repos = ColonyRepositories.create(
      db,
      idGenerator: FixedIdGenerator([
        for (var i = 1; i <= 40; i++) 'id-$i',
      ]),
      clock: () => now,
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
    final deck = await repos.flashcards.createDeck(
      profileId: profile.id,
      title: 'Limite',
      newLimitPerDay: 1,
    );
    await repos.flashcards.createCard(
      profileId: profile.id,
      deckId: deck.id,
      front: 'Um',
      back: '1',
    );
    await repos.flashcards.createCard(
      profileId: profile.id,
      deckId: deck.id,
      front: 'Dois',
      back: '2',
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          databaseProvider.overrideWithValue(db),
          clockProvider.overrideWithValue(() => now),
        ],
        child: MaterialApp(
          theme: ColonyTheme.dark(),
          home: const Scaffold(body: FlashcardsHubScreen()),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text(AppStrings.flashcardsHeroStudyCount(1)), findsOneWidget);
    expect(find.text(AppStrings.flashcardsMinutes(1)), findsOneWidget);
    expect(
      find.text(
        AppStrings.flashcardsSessionBuckets(learning: 0, review: 0, news: 1),
      ),
      findsOneWidget,
    );

    await _flushDisposeTimers(tester);
  });

  testWidgets('import prompt lists live shelves and JSON upload creates cards', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(800, 1800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final now = DateTime.utc(2026, 8, 17, 12);
    final db = ColonyDatabase.inMemory();
    addTearDown(db.close);
    final repos = ColonyRepositories.create(
      db,
      idGenerator: FixedIdGenerator([
        for (var i = 1; i <= 120; i++) 'id-$i',
      ]),
      clock: () => now,
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
    await repos.flashcards.seedCatalog(
      profileId: profile.id,
      keys: const ['arts.music.tropicalismo'],
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          databaseProvider.overrideWithValue(db),
          clockProvider.overrideWithValue(() => now),
        ],
        child: MaterialApp(
          theme: ColonyTheme.dark(),
          home: const Scaffold(body: FlashcardsHubScreen()),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.textContaining('Tropicalismo'), findsWidgets);
    expect(find.textContaining('CATEGORIAS JÁ EXISTENTES'), findsWidgets);
    expect(find.textContaining('inventar ramos novos'), findsWidgets);

    await tester.enterText(
      find.byKey(const Key('flashcards.import.json')),
      '''
{"cards":[{"front":"ODD","back":"Operational Design Domain","deck":"AV","areaPath":["Engenharia","ODD"]}]}
''',
    );
    await tester.tap(find.text(AppStrings.flashcardsImportPreview));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text(AppStrings.flashcardsImportConfirm), findsOneWidget);
    await tester.tap(find.text(AppStrings.flashcardsImportConfirm));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 800));

    expect(find.textContaining(AppStrings.flashcardsImportDone), findsWidgets);
    expect(await repos.flashcards.listCards(profile.id), hasLength(1));
    expect(
      (await repos.flashcards.listDecks(profile.id)).map((d) => d.title),
      contains('AV'),
    );

    await _flushDisposeTimers(tester);
  });
}
