import 'package:colony_database/colony_database.dart';
import 'package:colony_design_system/colony_design_system.dart';
import 'package:colony_domain/colony_domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:fallhub/app/localization/app_strings.dart';
import 'package:fallhub/core/providers/app_providers.dart';
import 'package:fallhub/features/research/presentation/research_list_screen.dart';

void main() {
  testWidgets('ResearchListScreen empty state and create sheet', (tester) async {
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
        'research-1',
        'event-1',
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

    await tester.pumpWidget(
      ProviderScope(
        overrides: [databaseProvider.overrideWithValue(db)],
        child: MaterialApp(
          theme: ColonyTheme.dark(),
          home: const Scaffold(body: ResearchListScreen()),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text(AppStrings.researchListEmpty), findsOneWidget);

    await tester.tap(find.text(AppStrings.newResearchNode));
    await tester.pumpAndSettle();

    expect(find.text(AppStrings.researchTitle), findsOneWidget);

    await tester.enterText(find.byType(TextField).first, 'Flutter avançado');
    await tester.tap(find.text(AppStrings.save));
    await tester.pumpAndSettle();

    expect(find.text('Flutter avançado'), findsOneWidget);
    expect(find.text(AppStrings.researchHierarchyTitle), findsOneWidget);
    expect(find.text(AppStrings.researchProgressSummary.toUpperCase()), findsOneWidget);

    await db.close();
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('Research hierarchy indents dependent node', (tester) async {
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
        'node-base',
        'event-1',
        'event-2',
        'evidence-1',
        'event-3',
        'event-4',
        'node-child',
        'event-5',
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

    final base = await repos.research.create(
      profileId: profile.id,
      title: 'Base',
      type: ResearchNodeType.knowledge,
    );
    var baseUpdated = await repos.research.updateStatus(
      base,
      ResearchNodeStatus.inResearch,
    );
    await repos.research.addEvidence(
      profileId: profile.id,
      nodeId: baseUpdated.id,
      type: ResearchEvidenceType.summary,
      title: 'Prova',
      body: 'OK',
    );
    baseUpdated = await repos.research.updateStatus(
      baseUpdated,
      ResearchNodeStatus.demonstrated,
    );
    final child = await repos.research.create(
      profileId: profile.id,
      title: 'Filho',
      type: ResearchNodeType.skill,
    );
    await repos.research.linkPrerequisite(
      nodeId: child.id,
      prerequisiteNodeId: base.id,
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [databaseProvider.overrideWithValue(db)],
        child: MaterialApp(
          theme: ColonyTheme.dark(),
          home: const Scaffold(body: ResearchListScreen()),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Base'), findsOneWidget);
    expect(find.text('Filho'), findsOneWidget);

    await db.close();
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('ResearchListScreen filters hierarchy by search query', (tester) async {
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
        'node-a',
        'event-1',
        'node-b',
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

    await repos.research.create(
      profileId: profile.id,
      title: 'Flutter avançado',
      type: ResearchNodeType.knowledge,
      description: 'Widgets e layout',
    );
    await repos.research.create(
      profileId: profile.id,
      title: 'Finanças pessoais',
      type: ResearchNodeType.knowledge,
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [databaseProvider.overrideWithValue(db)],
        child: MaterialApp(
          theme: ColonyTheme.dark(),
          home: const Scaffold(body: ResearchListScreen()),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Flutter avançado'), findsOneWidget);
    expect(find.text('Finanças pessoais'), findsOneWidget);

    await tester.enterText(find.byType(TextField).first, 'flutter');
    await tester.pumpAndSettle();

    expect(find.text('Flutter avançado'), findsOneWidget);
    expect(find.text('Finanças pessoais'), findsNothing);

    await db.close();
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('ResearchListScreen shows empty search state', (tester) async {
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
        'node-a',
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

    await repos.research.create(
      profileId: profile.id,
      title: 'Kotlin',
      type: ResearchNodeType.skill,
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [databaseProvider.overrideWithValue(db)],
        child: MaterialApp(
          theme: ColonyTheme.dark(),
          home: const Scaffold(body: ResearchListScreen()),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField).first, 'dart');
    await tester.pumpAndSettle();

    expect(find.text(AppStrings.researchSearchNoResults), findsOneWidget);
    expect(find.text('Kotlin'), findsNothing);

    await tester.enterText(find.byType(TextField).first, '');
    await tester.pumpAndSettle();

    expect(find.text('Kotlin'), findsOneWidget);

    await db.close();
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('ResearchListScreen search works in graph mode', (tester) async {
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
        'node-a',
        'event-1',
        'node-b',
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

    await repos.research.create(
      profileId: profile.id,
      title: 'Flutter avançado',
      type: ResearchNodeType.knowledge,
    );
    await repos.research.create(
      profileId: profile.id,
      title: 'Finanças pessoais',
      type: ResearchNodeType.knowledge,
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [databaseProvider.overrideWithValue(db)],
        child: MaterialApp(
          theme: ColonyTheme.dark(),
          home: const Scaffold(body: ResearchListScreen()),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text(AppStrings.researchViewGraph));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField).first, 'flutter');
    await tester.pumpAndSettle();

    expect(find.text('Flutter avançado'), findsOneWidget);
    expect(find.text('Finanças pessoais'), findsOneWidget);
    expect(find.text(AppStrings.researchSearchNoResults), findsNothing);

    await db.close();
    await tester.pumpWidget(const SizedBox.shrink());
  });
}
