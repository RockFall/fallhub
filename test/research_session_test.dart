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
  testWidgets('ResearchNodeDetailScreen logs learning session', (tester) async {
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
        'node-1',
        'session-1',
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
      title: 'Flutter',
      type: ResearchNodeType.knowledge,
    );
    await repos.research.updateStatus(node, ResearchNodeStatus.inResearch);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [databaseProvider.overrideWithValue(db)],
        child: MaterialApp(
          theme: ColonyTheme.dark(),
          home: Scaffold(
            body: ResearchNodeDetailScreen(nodeId: node.id.value),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text(AppStrings.researchLogSession));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField).first, '45');
    await tester.tap(find.text(AppStrings.save));
    await tester.pumpAndSettle();

    expect(find.text(AppStrings.researchNoSessions), findsNothing);
    expect(find.text('1 sessão · 45 min · 0 evidências'), findsOneWidget);
    expect(find.text(AppStrings.researchNodeActivitySummary.toUpperCase()), findsOneWidget);

    await db.close();
    await tester.pumpWidget(const SizedBox.shrink());
  });
}
