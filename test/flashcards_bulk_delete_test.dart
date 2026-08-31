import 'package:colony_database/colony_database.dart';
import 'package:colony_design_system/colony_design_system.dart';
import 'package:colony_domain/colony_domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:fallhub/app/localization/app_strings.dart';
import 'package:fallhub/core/providers/app_providers.dart';
import 'package:fallhub/features/flashcards/presentation/flashcard_tag_screen.dart';
import 'package:fallhub/features/flashcards/presentation/knowledge_area_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<void> _flush(WidgetTester tester) async {
  await tester.pumpWidget(const SizedBox.shrink());
  for (var i = 0; i < 80; i++) {
    await tester.pump(const Duration(milliseconds: 1));
  }
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('tag screen bulk-deletes cards and keeps the tag', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final now = DateTime.utc(2026, 8, 31, 12);
    final db = ColonyDatabase.inMemory();
    addTearDown(db.close);
    final repos = ColonyRepositories.create(
      db,
      idGenerator: FixedIdGenerator([for (var i = 1; i <= 80; i++) 'id-$i']),
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
      title: 'Deck',
    );
    final tag = await repos.flashcards.createTag(
      profileId: profile.id,
      title: 'Jazz',
    );
    await repos.flashcards.createCard(
      profileId: profile.id,
      deckId: deck.id,
      front: 'ii-V-I',
      back: 'Progressão',
      tags: const ['Jazz'],
    );
    await repos.flashcards.createCard(
      profileId: profile.id,
      deckId: deck.id,
      front: 'keep',
      back: 'ficar',
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          databaseProvider.overrideWithValue(db),
          clockProvider.overrideWithValue(() => now),
        ],
        child: MaterialApp(
          theme: ColonyTheme.dark(),
          home: Scaffold(body: FlashcardTagScreen(tagId: tag.id.value)),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text(AppStrings.flashcardsDeleteTagCards(1)), findsOneWidget);
    await tester.tap(find.text(AppStrings.flashcardsDeleteTagCards(1)));
    await tester.pumpAndSettle();
    await tester.tap(find.text(AppStrings.flashcardsDeleteTagCards(1)).last);
    await tester.pumpAndSettle();
    await tester.tap(find.text(AppStrings.delete));
    await tester.pumpAndSettle();

    expect(
      find.text(AppStrings.flashcardsDeleteCategoryDone(1)),
      findsOneWidget,
    );
    expect(await repos.flashcards.listCards(profile.id), hasLength(1));
    expect((await repos.flashcards.listCards(profile.id)).single.front, 'keep');
    expect(await repos.flashcards.listTags(profile.id), hasLength(1));

    await _flush(tester);
  });

  testWidgets('area screen bulk-deletes cards in the area only', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(800, 1800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final now = DateTime.utc(2026, 8, 31, 12);
    final db = ColonyDatabase.inMemory();
    addTearDown(db.close);
    final repos = ColonyRepositories.create(
      db,
      idGenerator: FixedIdGenerator([for (var i = 1; i <= 80; i++) 'id-$i']),
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
    final french = await repos.flashcards.createArea(
      profileId: profile.id,
      title: 'Francês',
    );
    final other = await repos.flashcards.createArea(
      profileId: profile.id,
      title: 'Outra',
    );
    final deck = await repos.flashcards.createDeck(
      profileId: profile.id,
      title: 'Deck FR',
      areaId: french.id,
    );
    final otherDeck = await repos.flashcards.createDeck(
      profileId: profile.id,
      title: 'Deck OT',
      areaId: other.id,
    );
    await repos.flashcards.createCard(
      profileId: profile.id,
      deckId: deck.id,
      areaId: french.id,
      front: 'bonjour',
      back: 'oi',
    );
    await repos.flashcards.createCard(
      profileId: profile.id,
      deckId: otherDeck.id,
      areaId: other.id,
      front: 'keep',
      back: 'ficar',
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          databaseProvider.overrideWithValue(db),
          clockProvider.overrideWithValue(() => now),
        ],
        child: MaterialApp(
          theme: ColonyTheme.dark(),
          home: Scaffold(body: KnowledgeAreaScreen(areaId: french.id.value)),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text(AppStrings.flashcardsDeleteAreaCards(1)), findsOneWidget);
    await tester.ensureVisible(
      find.text(AppStrings.flashcardsDeleteAreaCards(1)),
    );
    await tester.tap(find.text(AppStrings.flashcardsDeleteAreaCards(1)));
    await tester.pumpAndSettle();
    await tester.tap(find.text(AppStrings.flashcardsDeleteAreaCards(1)).last);
    await tester.pumpAndSettle();
    await tester.tap(find.text(AppStrings.delete));
    await tester.pumpAndSettle();

    expect(
      find.text(AppStrings.flashcardsDeleteCategoryDone(1)),
      findsOneWidget,
    );
    final remaining = await repos.flashcards.listCards(profile.id);
    expect(remaining, hasLength(1));
    expect(remaining.single.front, 'keep');
    expect(
      (await repos.flashcards.listAreas(profile.id)).map((a) => a.title),
      containsAll(['Francês', 'Outra']),
    );

    await _flush(tester);
  });
}
