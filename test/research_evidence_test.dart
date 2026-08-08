import 'package:colony_database/colony_database.dart';
import 'package:colony_design_system/colony_design_system.dart';
import 'package:colony_domain/colony_domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:fallhub/app/localization/app_strings.dart';
import 'package:fallhub/core/providers/app_providers.dart';
import 'package:fallhub/features/research/presentation/research_node_detail_screen.dart';

Future<void> _settleResearchDetail(WidgetTester tester) async {
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
  testWidgets('ResearchNodeDetailScreen adds evidence and demonstrate gate',
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
        'node-1',
        'evidence-1',
        'event-1',
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

    final node = await repos.research.create(
      profileId: profile.id,
      title: 'Rust',
      type: ResearchNodeType.skill,
    );
    await repos.research.updateStatus(node, ResearchNodeStatus.inResearch);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          databaseProvider.overrideWithValue(db),
          repositoriesProvider.overrideWithValue(repos),
        ],
        child: MaterialApp(
          theme: ColonyTheme.dark(),
          home: Scaffold(
            body: ResearchNodeDetailScreen(nodeId: node.id.value),
          ),
        ),
      ),
    );
    await _settleResearchDetail(tester);

    await tester.tap(find.text(AppStrings.researchDemonstrate));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    await tester.tap(find.text(AppStrings.save).last);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text(AppStrings.researchDemonstrateBlocked), findsOneWidget);

    await tester.tap(find.text(AppStrings.researchAddEvidence));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    await tester.enterText(find.byType(TextField).at(0), 'Prova prática');
    await tester.enterText(find.byType(TextField).at(1), 'Implementei um exemplo');
    await tester.tap(find.text(AppStrings.save));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('Prova prática'), findsOneWidget);
    expect(find.text(AppStrings.researchNoEvidence), findsNothing);

    await _tearDown(tester, db);
  });

  testWidgets('ResearchEvidencePanel hides delete on last demonstrated evidence',
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
        'node-1',
        'event-1',
        'event-2',
        'evidence-1',
        'event-3',
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

    var node = await repos.research.create(
      profileId: profile.id,
      title: 'Rust',
      type: ResearchNodeType.skill,
    );
    node = await repos.research.updateStatus(node, ResearchNodeStatus.inResearch);
    await repos.research.addEvidence(
      profileId: profile.id,
      nodeId: node.id,
      type: ResearchEvidenceType.note,
      title: 'Única evidência',
      body: 'Corpo',
    );
    node = await repos.research.updateStatus(
      node,
      ResearchNodeStatus.demonstrated,
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
            body: ResearchNodeDetailScreen(nodeId: node.id.value),
          ),
        ),
      ),
    );
    await _settleResearchDetail(tester);

    expect(find.text('Única evidência'), findsOneWidget);
    expect(find.byIcon(Icons.delete_outline), findsNothing);

    await _tearDown(tester, db);
  });

  testWidgets('skill detail shows suggested rubric level', (tester) async {
    tester.view.physicalSize = const Size(800, 1400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final db = ColonyDatabase.inMemory();
    final repos = ColonyRepositories.create(
      db,
      idGenerator: FixedIdGenerator([
        'profile-1',
        'node-1',
        'event-1',
        'evidence-1',
        'event-2',
      ]),
      clock: () => DateTime.utc(2026, 8, 7, 12),
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
      title: 'Dart',
      type: ResearchNodeType.skill,
    );
    await repos.research.addEvidence(
      profileId: profile.id,
      nodeId: node.id,
      type: ResearchEvidenceType.practiceLog,
      title: 'Kata',
      body: 'Prática',
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          databaseProvider.overrideWithValue(db),
          repositoriesProvider.overrideWithValue(repos),
          clockProvider.overrideWithValue(() => DateTime.utc(2026, 8, 7, 12)),
        ],
        child: MaterialApp(
          theme: ColonyTheme.dark(),
          home: Scaffold(
            body: ResearchNodeDetailScreen(nodeId: node.id.value),
          ),
        ),
      ),
    );
    await _settleResearchDetail(tester);

    expect(
      find.text(AppStrings.researchSkillRubricTitle.toUpperCase()),
      findsOneWidget,
    );
    expect(find.text(AppStrings.researchSkillRubricLevel(2)), findsOneWidget);
    expect(find.text(AppStrings.researchSkillRubricHint), findsOneWidget);

    await _tearDown(tester, db);
  });
}
