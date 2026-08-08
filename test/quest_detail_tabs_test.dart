import 'package:colony_database/colony_database.dart';
import 'package:colony_design_system/colony_design_system.dart';
import 'package:colony_domain/colony_domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:fallhub/app/localization/app_strings.dart';
import 'package:fallhub/core/providers/app_providers.dart';
import 'package:fallhub/features/quests/presentation/quest_detail_screen.dart';
import 'quest_detail_test_helpers.dart';

Future<void> _pumpQuestDetail(
  WidgetTester tester,
  ColonyDatabase db,
  ColonyRepositories repos,
  String questId,
) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        databaseProvider.overrideWithValue(db),
        repositoriesProvider.overrideWithValue(repos),
      ],
      child: MaterialApp(
        theme: ColonyTheme.dark(),
        home: Scaffold(
          body: QuestDetailScreen(questId: questId),
        ),
      ),
    ),
  );
  await settleQuestDetail(tester);
}

void main() {
  testWidgets('QuestDetailScreen shows content tab by default', (tester) async {
    tester.view.physicalSize = const Size(800, 1400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final db = ColonyDatabase.inMemory();

    final repos = ColonyRepositories.create(
      db,
      idGenerator: FixedIdGenerator([
        'profile-1',
        'quest-1',
        'event-1',
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

    final quest = await repos.quests.create(
      profileId: profile.id,
      title: 'Viagem Europa',
      purpose: 'Organizar documentos',
      status: QuestStatus.draft,
      successCriteria: ['Passaporte válido'],
    );

    await _pumpQuestDetail(tester, db, repos, quest.id.value);

    expect(find.text(AppStrings.questDetailTabContent), findsOneWidget);
    expect(find.text(AppStrings.questDetailTabRelations), findsOneWidget);
    expect(find.text(AppStrings.questPurpose.toUpperCase()), findsOneWidget);
    expect(find.text('Organizar documentos'), findsOneWidget);
    await tester.ensureVisible(find.text(AppStrings.questAcceptAndActivate));
    expect(find.text(AppStrings.questAcceptAndActivate), findsOneWidget);
    expect(find.text(AppStrings.questLinkedProjects.toUpperCase()), findsNothing);

    await tearDownQuestDetail(tester, db);
  });

  testWidgets('QuestDetailScreen relations tab shows linked sections', (tester) async {
    tester.view.physicalSize = const Size(800, 1400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final db = ColonyDatabase.inMemory();

    final repos = ColonyRepositories.create(
      db,
      idGenerator: FixedIdGenerator([
        'profile-1',
        'project-1',
        'event-1',
        'quest-prereq',
        'event-2',
        'quest-main',
        'event-3',
        'decision-1',
        'event-4',
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

    final project = await repos.projects.create(
      profileId: profile.id,
      title: 'Viagem 2026',
    );
    final prereq = await repos.quests.create(
      profileId: profile.id,
      title: 'Documentos',
      purpose: 'Passaporte',
      status: QuestStatus.completed,
    );
    final quest = await repos.quests.create(
      profileId: profile.id,
      title: 'Reservas',
      purpose: 'Hotéis',
      status: QuestStatus.draft,
    );
    await repos.projects.linkQuest(questId: quest.id, projectId: project.id);
    await repos.quests.linkPrerequisite(
      questId: quest.id,
      prerequisiteQuestId: prereq.id,
    );
    final decision = await repos.decisions.create(
      profileId: profile.id,
      title: 'Escolher hotel',
      context: 'Centro vs aeroporto',
      decision: 'Centro',
      reversibility: DecisionReversibility.easy,
    );
    await repos.decisions.linkQuest(questId: quest.id, decisionId: decision.id);

    await _pumpQuestDetail(tester, db, repos, quest.id.value);
    await tapQuestRelationsTab(tester);

    expect(find.text(AppStrings.questLinkedProjects.toUpperCase()), findsOneWidget);
    expect(find.text('Viagem 2026'), findsOneWidget);
    expect(find.text(AppStrings.questLinkedPrerequisites.toUpperCase()), findsOneWidget);
    expect(find.text('Documentos'), findsWidgets);
    expect(find.text(AppStrings.questLinkedDecisions.toUpperCase()), findsOneWidget);
    expect(find.text('Escolher hotel'), findsOneWidget);
    expect(find.text(AppStrings.questPurpose.toUpperCase()), findsNothing);

    await tearDownQuestDetail(tester, db);
  });
}
