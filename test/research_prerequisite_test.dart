import 'package:colony_database/colony_database.dart';
import 'package:colony_design_system/colony_design_system.dart';
import 'package:colony_domain/colony_domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:fallhub/app/localization/app_strings.dart';
import 'package:fallhub/core/providers/app_providers.dart';
import 'package:fallhub/features/research/presentation/research_node_detail_screen.dart';

void main() {
  testWidgets('Research detail blocks focus when prerequisites incomplete', (tester) async {
    tester.view.physicalSize = const Size(800, 1400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final db = ColonyDatabase.inMemory();
    addTearDown(db.close);

    final repos = ColonyRepositories.create(
      db,
      idGenerator: FixedIdGenerator([
        'profile-1',
        'node-prereq',
        'event-1',
        'node-main',
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

    final prereq = await repos.research.create(
      profileId: profile.id,
      title: 'Fundamentos',
      type: ResearchNodeType.knowledge,
    );
    final main = await repos.research.create(
      profileId: profile.id,
      title: 'Avançado',
      type: ResearchNodeType.skill,
    );
    await repos.research.linkPrerequisite(
      nodeId: main.id,
      prerequisiteNodeId: prereq.id,
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [databaseProvider.overrideWithValue(db)],
        child: MaterialApp(
          theme: ColonyTheme.dark(),
          home: Scaffold(
            body: ResearchNodeDetailScreen(nodeId: main.id.value),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Avançado'), findsOneWidget);
    expect(find.text(AppStrings.researchStartFocus), findsOneWidget);

    await tester.tap(find.text(AppStrings.researchStartFocus));
    await tester.pumpAndSettle();

    expect(find.text(AppStrings.researchBlockedPrerequisites), findsOneWidget);

    var sawPrerequisite = false;
    for (var i = 0; i < 12; i++) {
      if (find.text('Fundamentos').evaluate().isNotEmpty) {
        sawPrerequisite = true;
        break;
      }
      await tester.drag(find.byType(ListView), const Offset(0, -400));
      await tester.pump();
    }
    expect(sawPrerequisite, isTrue);
    await tester.pumpAndSettle();

    expect(find.text(AppStrings.researchBlockedPrerequisites), findsOneWidget);

    await db.close();
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('Research detail blocks second WIP focus', (tester) async {
    tester.view.physicalSize = const Size(800, 1400);
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
        'node-b',
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

    final a = await repos.research.create(
      profileId: profile.id,
      title: 'Foco A',
      type: ResearchNodeType.knowledge,
    );
    await repos.research.updateStatus(a, ResearchNodeStatus.inResearch);

    final b = await repos.research.create(
      profileId: profile.id,
      title: 'Foco B',
      type: ResearchNodeType.skill,
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [databaseProvider.overrideWithValue(db)],
        child: MaterialApp(
          theme: ColonyTheme.dark(),
          home: Scaffold(
            body: ResearchNodeDetailScreen(nodeId: b.id.value),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text(AppStrings.researchStartFocus));
    await tester.pumpAndSettle();

    expect(find.text(AppStrings.researchWipBlocked), findsOneWidget);

    await db.close();
    await tester.pumpWidget(const SizedBox.shrink());
  });
}
