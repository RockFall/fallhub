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
  testWidgets('QuestChainPanel renders ordered chain with current highlight', (tester) async {
    tester.view.physicalSize = const Size(800, 1400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final db = ColonyDatabase.inMemory();

    final repos = ColonyRepositories.create(
      db,
      idGenerator: FixedIdGenerator([
        'profile-1',
        'quest-a',
        'event-1',
        'quest-b',
        'event-2',
        'quest-c',
        'event-3',
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

    final a = await repos.quests.create(
      profileId: profile.id,
      title: 'Documentos',
      purpose: 'Passaporte',
      status: QuestStatus.completed,
    );
    final b = await repos.quests.create(
      profileId: profile.id,
      title: 'Seguro',
      purpose: 'Viagem',
      status: QuestStatus.active,
    );
    final c = await repos.quests.create(
      profileId: profile.id,
      title: 'Reservas',
      purpose: 'Hotéis',
      status: QuestStatus.draft,
    );
    await repos.quests.linkPrerequisite(questId: b.id, prerequisiteQuestId: a.id);
    await repos.quests.linkPrerequisite(questId: c.id, prerequisiteQuestId: b.id);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          databaseProvider.overrideWithValue(db),
          repositoriesProvider.overrideWithValue(repos),
        ],
        child: MaterialApp(
          theme: ColonyTheme.dark(),
          home: Scaffold(
            body: QuestDetailScreen(questId: c.id.value),
          ),
        ),
      ),
    );
    await settleQuestDetail(tester);

    await tapQuestRelationsTab(tester);

    expect(find.text(AppStrings.questChainTitle.toUpperCase()), findsOneWidget);
    expect(find.text('Documentos'), findsWidgets);
    expect(find.text('Seguro'), findsWidgets);
    expect(find.text('Reservas'), findsWidgets);
    expect(find.byIcon(Icons.flag), findsOneWidget);

    await tearDownQuestDetail(tester, db);
  });
}
