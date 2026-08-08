import 'package:colony_database/colony_database.dart';
import 'package:colony_design_system/colony_design_system.dart';
import 'package:colony_domain/colony_domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:fallhub/app/localization/app_strings.dart';
import 'package:fallhub/core/providers/app_providers.dart';
import 'package:fallhub/features/quests/presentation/quest_board_screen.dart';

void main() {
  testWidgets('create=1 deep link opens sheet twice after close', (tester) async {
    tester.view.physicalSize = const Size(800, 1200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final db = ColonyDatabase.inMemory();
    addTearDown(db.close);

    final repos = ColonyRepositories.create(
      db,
      idGenerator: FixedIdGenerator([
        'profile-1',
        'quest-1',
        'event-1',
        'quest-2',
        'event-2',
      ]),
      clock: () => DateTime.utc(2026, 8, 6, 12),
    );

    await repos.profiles.create(
      colonyName: 'Test',
      displayName: 'Caio',
      timezone: 'UTC',
      locale: 'pt_BR',
      baseCurrency: 'BRL',
    );
    await repos.preferences.save(AppPreferences.defaults().copyWith(
      onboardingCompleted: true,
    ));

    late final GoRouter router;
    router = GoRouter(
      routes: [
        GoRoute(
          path: '/quests',
          builder: (context, state) => const Scaffold(
            body: QuestBoardScreen(),
          ),
        ),
      ],
      initialLocation: '/quests?create=1',
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [databaseProvider.overrideWithValue(db)],
        child: MaterialApp.router(
          theme: ColonyTheme.dark(),
          routerConfig: router,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(TextField), findsWidgets);

    await tester.enterText(find.byType(TextField).at(0), 'Primeira missão');
    await tester.enterText(find.byType(TextField).at(1), 'Propósito');
    await tester.tap(find.text(AppStrings.questSaveDraft));
    await tester.pumpAndSettle();

    expect(find.byType(TextField), findsNothing);

    router.go('/quests');
    await tester.pumpAndSettle();

    router.go('/quests?create=1&retry=1');
    await tester.pump();
    await tester.pumpAndSettle();

    expect(find.byType(TextField), findsWidgets);

    await db.close();
    await tester.pumpWidget(const SizedBox.shrink());
  });
}
