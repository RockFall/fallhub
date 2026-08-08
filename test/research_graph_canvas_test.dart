import 'package:colony_database/colony_database.dart';
import 'package:colony_design_system/colony_design_system.dart';
import 'package:colony_domain/colony_domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:fallhub/app/localization/app_strings.dart';
import 'package:fallhub/core/providers/app_providers.dart';
import 'package:fallhub/features/research/application/research_providers.dart';
import 'package:fallhub/features/research/presentation/research_list_screen.dart';
import 'package:fallhub/features/research/presentation/widgets/research_graph_node_tile.dart';

void main() {
  Future<ColonyRepositories> seedRepos(ColonyDatabase db) async {
    final repos = ColonyRepositories.create(
      db,
      idGenerator: FixedIdGenerator([
        'profile-1',
        'node-a',
        'event-1',
        'event-2',
        'evidence-1',
        'event-3',
        'event-4',
        'node-b',
        'event-5',
        'event-6',
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
    var demonstrated = await repos.research.updateStatus(
      base,
      ResearchNodeStatus.inResearch,
    );
    await repos.research.addEvidence(
      profileId: profile.id,
      nodeId: demonstrated.id,
      type: ResearchEvidenceType.summary,
      title: 'Prova',
      body: 'OK',
    );
    demonstrated = await repos.research.updateStatus(
      demonstrated,
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

    return repos;
  }

  testWidgets('ResearchListScreen toggles list and graph views', (tester) async {
    tester.view.physicalSize = const Size(800, 1200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final db = ColonyDatabase.inMemory();
    addTearDown(db.close);
    await seedRepos(db);

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

    expect(find.text(AppStrings.researchHierarchyTitle), findsOneWidget);
    expect(find.text('Base'), findsOneWidget);

    await tester.tap(find.text(AppStrings.researchViewGraph));
    await tester.pumpAndSettle();

    expect(find.text(AppStrings.researchHierarchyTitle), findsNothing);
    expect(find.text('Base'), findsOneWidget);
    expect(find.text('Filho'), findsOneWidget);
    expect(find.text(AppStrings.researchShowDependencies), findsOneWidget);

    await db.close();
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('Research graph node tap navigates to detail', (tester) async {
    tester.view.physicalSize = const Size(800, 1200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final db = ColonyDatabase.inMemory();
    addTearDown(db.close);
    await seedRepos(db);

    final router = GoRouter(
      initialLocation: '/research',
      routes: [
        GoRoute(
          path: '/research',
          builder: (context, state) =>
              const Scaffold(body: ResearchListScreen()),
        ),
        GoRoute(
          path: '/research/:id',
          builder: (context, state) => Scaffold(
            body: Center(child: Text('Detail ${state.pathParameters['id']}')),
          ),
        ),
      ],
    );
    addTearDown(router.dispose);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          databaseProvider.overrideWithValue(db),
          researchViewModeProvider.overrideWith(_FixedGraphViewMode.new),
        ],
        child: MaterialApp.router(
          theme: ColonyTheme.dark(),
          routerConfig: router,
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    final tile = find.byType(ResearchGraphNodeTile);
    expect(tile, findsNWidgets(2));

    await tester.tap(tile.last);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('Detail node-b'), findsOneWidget);

    await db.close();
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('Research graph highlights WIP focus node', (tester) async {
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
      title: 'Em foco agora',
      type: ResearchNodeType.knowledge,
    );
    await repos.research.updateStatus(node, ResearchNodeStatus.inResearch);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          databaseProvider.overrideWithValue(db),
          researchViewModeProvider.overrideWith(_FixedGraphViewMode.new),
        ],
        child: MaterialApp(
          theme: ColonyTheme.dark(),
          home: const Scaffold(body: ResearchListScreen()),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.science), findsOneWidget);
    expect(find.text(AppStrings.researchActiveFocus.toUpperCase()), findsOneWidget);

    await db.close();
    await tester.pumpWidget(const SizedBox.shrink());
  });
}

class _FixedGraphViewMode extends ResearchViewModeNotifier {
  @override
  ResearchViewMode build() => ResearchViewMode.graph;
}
