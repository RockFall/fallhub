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

void main() {
  testWidgets('QuestDetailScreen links and shows project', (tester) async {
    tester.view.physicalSize = const Size(800, 1200);
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
        'quest-1',
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

    final project = await repos.projects.create(
      profileId: profile.id,
      title: 'Viagem 2026',
    );
    final quest = await repos.quests.create(
      profileId: profile.id,
      title: 'Organizar documentos',
      purpose: 'Passaporte e seguro',
      status: QuestStatus.active,
    );
    await repos.projects.linkQuest(
      questId: quest.id,
      projectId: project.id,
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
            body: QuestDetailScreen(questId: quest.id.value),
          ),
        ),
      ),
    );
    await settleQuestDetail(tester);

    await tapQuestRelationsTab(tester);

    expect(find.text('Organizar documentos'), findsOneWidget);
    expect(find.text(AppStrings.questLinkedProjects.toUpperCase()), findsOneWidget);
    expect(find.text('Viagem 2026'), findsOneWidget);
    await tearDownQuestDetail(tester, db);
  });
}
