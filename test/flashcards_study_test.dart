import 'package:colony_database/colony_database.dart';
import 'package:colony_design_system/colony_design_system.dart';
import 'package:colony_domain/colony_domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

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
    final deck = await repos.flashcards.createDeck(
      profileId: profile.id,
      title: 'Básico',
    );
    await repos.flashcards.createCard(
      profileId: profile.id,
      deckId: deck.id,
      front: 'Capital da França',
      back: 'Paris',
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [databaseProvider.overrideWithValue(db)],
        child: MaterialApp.router(
          theme: ColonyTheme.dark(),
          routerConfig: GoRouter(
            initialLocation: '/flashcards/study',
            routes: [
              GoRoute(
                path: '/flashcards',
                builder: (_, __) => const Scaffold(body: Text('hub')),
              ),
              GoRoute(
                path: '/flashcards/study',
                builder: (_, __) => const Scaffold(body: StudySessionScreen()),
              ),
            ],
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Capital da França'), findsOneWidget);
    expect(find.text(AppStrings.flashcardsReveal), findsOneWidget);
    expect(find.text('Paris'), findsNothing);

    await tester.tap(find.text('Capital da França'));
    await tester.pumpAndSettle();

    expect(find.text('Paris'), findsOneWidget);
    expect(find.text(AppStrings.flashcardsGood), findsOneWidget);

    await tester.tap(find.text(AppStrings.flashcardsGood));
    await tester.pumpAndSettle();

    expect(find.text(AppStrings.flashcardsDone), findsOneWidget);

    await tester.pumpWidget(const SizedBox.shrink());
  });
}
