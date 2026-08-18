import 'package:colony_database/colony_database.dart';
import 'package:colony_design_system/colony_design_system.dart';
import 'package:colony_domain/colony_domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:fallhub/app/localization/app_strings.dart';
import 'package:fallhub/core/providers/app_providers.dart';
import 'package:fallhub/features/flashcards/presentation/study_session_screen.dart';

void main() {
  testWidgets('StudySessionScreen reveals and rates a card', (tester) async {
    tester.view.physicalSize = const Size(800, 1400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final db = ColonyDatabase.inMemory();
    addTearDown(db.close);

    final repos = ColonyRepositories.create(
      db,
      idGenerator: FixedIdGenerator([
        for (var i = 1; i <= 40; i++) 'id-$i',
      ]),
      clock: () => DateTime.utc(2026, 8, 17, 12),
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
    final languages = await repos.flashcards.createArea(
      profileId: profile.id,
      title: 'Linguagens',
    );
    final english = await repos.flashcards.createArea(
      profileId: profile.id,
      title: 'Inglês',
      parentId: languages.id,
    );
    final deck = await repos.flashcards.createDeck(
      profileId: profile.id,
      title: 'Básico',
      areaId: english.id,
    );
    await repos.flashcards.createCard(
      profileId: profile.id,
      deckId: deck.id,
      areaId: english.id,
      front: 'Capital da França',
      back: 'Paris',
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          databaseProvider.overrideWithValue(db),
          clockProvider.overrideWithValue(() => DateTime.utc(2026, 8, 17, 12)),
        ],
        child: MaterialApp(
          theme: ColonyTheme.dark(),
          home: const Scaffold(body: StudySessionScreen()),
        ),
      ),
    );
    await tester.pump();
    for (var i = 0; i < 20; i++) {
      await tester.pump(const Duration(milliseconds: 50));
      if (find.text('Capital da França').evaluate().isNotEmpty) break;
    }

    expect(find.text('Capital da França'), findsOneWidget);
    expect(find.text('Linguagens · Inglês'), findsOneWidget);
    expect(find.text(AppStrings.flashcardsReveal), findsOneWidget);
    expect(find.text('Paris'), findsNothing);
    expect(find.text(AppStrings.flashcardsSearchQuestion), findsNothing);

    await tester.tap(find.text('Capital da França'));
    await tester.pump();

    expect(find.text('Paris'), findsOneWidget);
    expect(find.text(AppStrings.flashcardsSearchQuestion), findsOneWidget);
    expect(find.text(AppStrings.flashcardsGood), findsOneWidget);
    expect(find.byType(Semantics), findsWidgets);

    await tester.tap(find.text(AppStrings.flashcardsGood));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text(AppStrings.flashcardsDone), findsOneWidget);

    await tester.pumpWidget(const SizedBox.shrink());
    for (var i = 0; i < 80; i++) {
      await tester.pump(const Duration(milliseconds: 1));
    }
  });

  testWidgets('study menu deletes the current flashcard', (tester) async {
    tester.view.physicalSize = const Size(800, 1400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final db = ColonyDatabase.inMemory();
    addTearDown(db.close);
    final repos = ColonyRepositories.create(
      db,
      idGenerator: FixedIdGenerator([
        for (var i = 1; i <= 40; i++) 'id-$i',
      ]),
      clock: () => DateTime.utc(2026, 8, 17, 12),
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
      title: 'Básico',
    );
    await repos.flashcards.createCard(
      profileId: profile.id,
      deckId: deck.id,
      front: 'Apagar-me',
      back: 'sumiu',
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          databaseProvider.overrideWithValue(db),
          clockProvider.overrideWithValue(() => DateTime.utc(2026, 8, 17, 12)),
        ],
        child: MaterialApp(
          theme: ColonyTheme.dark(),
          home: const Scaffold(body: StudySessionScreen()),
        ),
      ),
    );
    await tester.pump();
    for (var i = 0; i < 20; i++) {
      await tester.pump(const Duration(milliseconds: 50));
      if (find.text('Apagar-me').evaluate().isNotEmpty) break;
    }

    expect(find.text('Apagar-me'), findsOneWidget);
    await tester.tap(find.byKey(const Key('flashcards.more_actions')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    expect(find.text(AppStrings.flashcardsSetPriority), findsOneWidget);
    expect(find.text(AppStrings.flashcardsDelete), findsOneWidget);
    tester
        .widget<PopupMenuButton<String>>(
          find.byKey(const Key('flashcards.more_actions')),
        )
        .onSelected!('delete');
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    expect(find.text(AppStrings.flashcardsDeleteConfirm), findsOneWidget);
    await tester.tap(find.widgetWithText(FilledButton, AppStrings.flashcardsDelete));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text(AppStrings.flashcardsDone), findsOneWidget);
    expect(await repos.flashcards.listCards(profile.id), isEmpty);

    await tester.pumpWidget(const SizedBox.shrink());
    for (var i = 0; i < 80; i++) {
      await tester.pump(const Duration(milliseconds: 1));
    }
  });

  testWidgets('study menu sets priority with a slider', (tester) async {
    tester.view.physicalSize = const Size(800, 1400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final db = ColonyDatabase.inMemory();
    addTearDown(db.close);
    final repos = ColonyRepositories.create(
      db,
      idGenerator: FixedIdGenerator([
        for (var i = 1; i <= 40; i++) 'id-$i',
      ]),
      clock: () => DateTime.utc(2026, 8, 17, 12),
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
      title: 'Básico',
    );
    await repos.flashcards.createCard(
      profileId: profile.id,
      deckId: deck.id,
      front: 'Prioridade',
      back: 'cinco',
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          databaseProvider.overrideWithValue(db),
          clockProvider.overrideWithValue(() => DateTime.utc(2026, 8, 17, 12)),
        ],
        child: MaterialApp(
          theme: ColonyTheme.dark(),
          home: const Scaffold(body: StudySessionScreen()),
        ),
      ),
    );
    await tester.pump();
    for (var i = 0; i < 20; i++) {
      await tester.pump(const Duration(milliseconds: 50));
      if (find.text('Prioridade').evaluate().isNotEmpty) break;
    }

    expect(find.text('Prioridade'), findsOneWidget);
    await tester.tap(find.byKey(const Key('flashcards.more_actions')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    await tester.tap(find.text(AppStrings.flashcardsSetPriority));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    final slider = tester.widget<Slider>(
      find.byKey(const Key('flashcards.priority_slider')),
    );
    expect(slider.value, 5);
    slider.onChanged?.call(1);
    slider.onChangeEnd?.call(1);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    final stored = (await repos.flashcards.listCards(profile.id)).single;
    expect(stored.priority, 1);

    await tester.pumpWidget(const SizedBox.shrink());
    for (var i = 0; i < 80; i++) {
      await tester.pump(const Duration(milliseconds: 1));
    }
  });
}
