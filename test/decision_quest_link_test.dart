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
  testWidgets('QuestDetailScreen links and shows decision', (tester) async {
    tester.view.physicalSize = const Size(800, 1200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final db = ColonyDatabase.inMemory();

    final repos = ColonyRepositories.create(
      db,
      idGenerator: FixedIdGenerator([
        'profile-1',
        'decision-1',
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

    final quest = await repos.quests.create(
      profileId: profile.id,
      title: 'Mudança de emprego',
      purpose: 'Avaliar oferta',
      status: QuestStatus.active,
    );
    final decision = await repos.decisions.create(
      profileId: profile.id,
      title: 'Aceitar oferta',
      context: 'Proposta remota',
      decision: 'Aceitar com prazo de 30 dias',
      reversibility: DecisionReversibility.hard,
    );
    await repos.decisions.linkQuest(
      questId: quest.id,
      decisionId: decision.id,
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

    expect(find.text('Mudança de emprego'), findsOneWidget);
    expect(find.text(AppStrings.questLinkedDecisions.toUpperCase()), findsOneWidget);
    expect(find.text('Aceitar oferta'), findsOneWidget);
    expect(find.text('Aceitar com prazo de 30 dias'), findsOneWidget);
    expect(find.text(AppStrings.decisionReversibilityLabel(DecisionReversibility.hard)), findsOneWidget);

    await tearDownQuestDetail(tester, db);
  });

  testWidgets('deleting linked decision removes it from quest detail', (tester) async {
    tester.view.physicalSize = const Size(800, 1200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final db = ColonyDatabase.inMemory();

    final repos = ColonyRepositories.create(
      db,
      idGenerator: FixedIdGenerator([
        'profile-1',
        'decision-1',
        'event-1',
        'quest-1',
        'event-2',
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

    final quest = await repos.quests.create(
      profileId: profile.id,
      title: 'Missão delete',
      purpose: 'Testar delete',
      status: QuestStatus.active,
    );
    final decision = await repos.decisions.create(
      profileId: profile.id,
      title: 'Decisão efêmera',
      context: 'Ctx',
      decision: 'Sim',
      assumptions: ['Premissa'],
      expectedOutcomes: ['Outcome'],
    );
    await repos.decisions.linkQuest(
      questId: quest.id,
      decisionId: decision.id,
    );

    await repos.decisions.delete(decision.id);

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

    expect(find.text('Decisão efêmera'), findsNothing);
    expect(find.text(AppStrings.questNoLinkedDecisions), findsOneWidget);

    await tearDownQuestDetail(tester, db);
  });
}
