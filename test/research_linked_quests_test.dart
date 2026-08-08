import 'package:colony_database/colony_database.dart';
import 'package:colony_design_system/colony_design_system.dart';
import 'package:colony_domain/colony_domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:fallhub/app/localization/app_strings.dart';
import 'package:fallhub/core/providers/app_providers.dart';
import 'package:fallhub/features/research/presentation/widgets/research_linked_quests_panel.dart';

Future<void> _settle(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 500));
  for (var i = 0; i < 20; i++) {
    await tester.pump(const Duration(milliseconds: 50));
  }
}

Future<void> _tearDown(WidgetTester tester, ColonyDatabase db) async {
  await tester.pumpWidget(const SizedBox.shrink());
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 100));
  await db.close();
}

void main() {
  testWidgets('ResearchLinkedQuestsPanel shows linked quest reverse view',
      (tester) async {
    tester.view.physicalSize = const Size(800, 1200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final db = ColonyDatabase.inMemory();

    final repos = ColonyRepositories.create(
      db,
      idGenerator: FixedIdGenerator([
        'profile-1',
        'research-1',
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

    final node = await repos.research.create(
      profileId: profile.id,
      title: 'Flutter avançado',
      type: ResearchNodeType.knowledge,
    );
    final quest = await repos.quests.create(
      profileId: profile.id,
      title: 'Estudar UI',
      purpose: 'Widgets e estado',
      status: QuestStatus.active,
    );
    await repos.research.linkQuest(
      questId: quest.id,
      researchNodeId: node.id,
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
            body: ResearchLinkedQuestsPanel(node: node),
          ),
        ),
      ),
    );
    await _settle(tester);

    expect(
      find.text(AppStrings.researchLinkedQuests.toUpperCase()),
      findsOneWidget,
    );
    expect(find.text('Estudar UI'), findsOneWidget);

    await _tearDown(tester, db);
  });
}
