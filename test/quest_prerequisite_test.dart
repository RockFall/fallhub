import 'package:colony_database/colony_database.dart';
import 'package:colony_design_system/colony_design_system.dart';
import 'package:colony_domain/colony_domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:fallhub/app/localization/app_strings.dart';
import 'package:fallhub/core/providers/app_providers.dart';
import 'package:fallhub/features/quests/presentation/quest_board_screen.dart';
import 'package:fallhub/features/quests/presentation/quest_detail_screen.dart';
import 'quest_detail_test_helpers.dart';

void main() {
  testWidgets('QuestDetailScreen shows prerequisites and blocks activate', (tester) async {
    tester.view.physicalSize = const Size(800, 1400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final db = ColonyDatabase.inMemory();

    final repos = ColonyRepositories.create(
      db,
      idGenerator: FixedIdGenerator([
        'profile-1',
        'quest-prereq',
        'event-1',
        'quest-main',
        'event-2',
      ]),
      clock: () => DateTime.utc(2026, 8, 6, 12),
    );

    final profile = await repos.profiles.create(
      colonyName: 'Test',
      displayName: 'Caio',
      timezone: 'UTC',
      locale: 'pt_BR',
      baseCurrency: 'BRL',
    );
    await repos.preferences.save(AppPreferences.defaults().copyWith(
      onboardingCompleted: true,
    ));

    final prereq = await repos.quests.create(
      profileId: profile.id,
      title: 'Documentos',
      purpose: 'Passaporte',
      status: QuestStatus.draft,
    );
    final main = await repos.quests.create(
      profileId: profile.id,
      title: 'Reservas',
      purpose: 'Hotéis',
      status: QuestStatus.draft,
    );
    await repos.quests.linkPrerequisite(
      questId: main.id,
      prerequisiteQuestId: prereq.id,
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          databaseProvider.overrideWithValue(db),
          repositoriesProvider.overrideWithValue(repos),
        ],
        child: MaterialApp(
          theme: ColonyTheme.dark(),
          home: Scaffold(
            body: QuestDetailScreen(questId: main.id.value),
          ),
        ),
      ),
    );
    await settleQuestDetail(tester);
    await waitForQuestDetailStreams(tester);

    await tester.ensureVisible(
      find.widgetWithText(FilledButton, AppStrings.questAcceptAndActivate),
    );
    await tester.tap(
      find.widgetWithText(FilledButton, AppStrings.questAcceptAndActivate),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text(AppStrings.questActivateBlockedPrerequisites), findsOneWidget);
    expect(find.text(AppStrings.questAcceptTitle), findsNothing);

    await tapQuestRelationsTab(tester);

    expect(find.text('Documentos'), findsWidgets);

    await tearDownQuestDetail(tester, db);
  });

  testWidgets('QuestBoardScreen shows waiting badge', (tester) async {
    tester.view.physicalSize = const Size(800, 1200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final db = ColonyDatabase.inMemory();

    final repos = ColonyRepositories.create(
      db,
      idGenerator: FixedIdGenerator([
        'profile-1',
        'quest-prereq',
        'event-1',
        'quest-main',
        'event-2',
      ]),
      clock: () => DateTime.utc(2026, 8, 6, 12),
    );

    final profile = await repos.profiles.create(
      colonyName: 'Test',
      displayName: 'Caio',
      timezone: 'UTC',
      locale: 'pt_BR',
      baseCurrency: 'BRL',
    );
    await repos.preferences.save(AppPreferences.defaults().copyWith(
      onboardingCompleted: true,
    ));

    final prereq = await repos.quests.create(
      profileId: profile.id,
      title: 'Documentos',
      purpose: 'Passaporte',
      status: QuestStatus.active,
    );
    final main = await repos.quests.create(
      profileId: profile.id,
      title: 'Reservas',
      purpose: 'Hotéis',
      status: QuestStatus.draft,
    );
    await repos.quests.linkPrerequisite(
      questId: main.id,
      prerequisiteQuestId: prereq.id,
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [databaseProvider.overrideWithValue(db)],
        child: MaterialApp(
          theme: ColonyTheme.dark(),
          home: const Scaffold(
            body: QuestBoardScreen(),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Reservas'), findsOneWidget);
    expect(find.text(AppStrings.questWaitingBadge), findsOneWidget);

    await db.close();
    await tester.pumpWidget(const SizedBox.shrink());
  });
}
