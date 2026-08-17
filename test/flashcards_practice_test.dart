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
  testWidgets('practice session rates without creating SRS state', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(800, 1400);
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
      title: 'Pontual',
    );
    final cards = await repos.flashcards.createCard(
      profileId: profile.id,
      deckId: deck.id,
      front: 'ODD',
      back: 'Operational Design Domain',
      scheduleMode: FlashcardScheduleMode.unscheduled,
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          databaseProvider.overrideWithValue(db),
          clockProvider.overrideWithValue(() => now),
        ],
        child: MaterialApp(
          theme: ColonyTheme.dark(),
          home: Scaffold(
            body: StudySessionScreen(
              mode: FlashcardStudySessionMode.practice,
              cardId: cards.single.id.value,
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    for (var i = 0; i < 20; i++) {
      await tester.pump(const Duration(milliseconds: 50));
      if (find.text('ODD').evaluate().isNotEmpty) break;
    }

    expect(find.text('ODD'), findsOneWidget);
    expect(find.text(AppStrings.flashcardsPracticeSession), findsOneWidget);
    await tester.tap(find.text('ODD'));
    await tester.pump();
    await tester.tap(find.text(AppStrings.flashcardsGood));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.text(AppStrings.flashcardsPracticeDone), findsOneWidget);
    expect(await repos.flashcards.listSrs(profile.id), isEmpty);
    final logs = await repos.flashcards.listLogs(profile.id);
    expect(logs, hasLength(1));
    expect(logs.single.reviewKind, FlashcardReviewKind.practice);

    await tester.pumpWidget(const SizedBox.shrink());
    for (var i = 0; i < 80; i++) {
      await tester.pump(const Duration(milliseconds: 1));
    }
  });

  testWidgets('practice of a scheduled card does not mutate SRS', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(800, 1400);
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
      title: 'Fila',
    );
    final cards = await repos.flashcards.createCard(
      profileId: profile.id,
      deckId: deck.id,
      front: 'Dominante',
      back: 'V7',
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          databaseProvider.overrideWithValue(db),
          clockProvider.overrideWithValue(() => now),
        ],
        child: MaterialApp(
          theme: ColonyTheme.dark(),
          home: Scaffold(
            body: StudySessionScreen(
              mode: FlashcardStudySessionMode.practice,
              deckId: deck.id.value,
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    for (var i = 0; i < 20; i++) {
      await tester.pump(const Duration(milliseconds: 50));
      if (find.text('Dominante').evaluate().isNotEmpty) break;
    }

    expect(find.text('Dominante'), findsOneWidget);
    await tester.tap(find.text('Dominante'));
    await tester.pump();
    await tester.tap(find.text(AppStrings.flashcardsGood));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.text(AppStrings.flashcardsPracticeDone), findsOneWidget);
    final srs = await repos.flashcards.listSrs(profile.id);
    expect(srs, hasLength(1));
    expect(srs.single.status, FlashcardSrsStatus.newCard);
    expect(srs.single.lastReviewedAt, isNull);
    final logs = await repos.flashcards.listLogs(profile.id);
    expect(logs.single.reviewKind, FlashcardReviewKind.practice);
    expect(cards, hasLength(1));

    await tester.pumpWidget(const SizedBox.shrink());
    for (var i = 0; i < 80; i++) {
      await tester.pump(const Duration(milliseconds: 1));
    }
  });
}
