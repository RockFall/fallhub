import 'package:colony_database/colony_database.dart';
import 'package:colony_design_system/colony_design_system.dart';
import 'package:colony_domain/colony_domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:fallhub/app/localization/app_strings.dart';
import 'package:fallhub/core/providers/app_providers.dart';
import 'package:fallhub/features/decisions/presentation/decision_list_screen.dart';
import 'package:fallhub/features/decisions/presentation/widgets/edit_decision_sheet.dart';

void main() {
  testWidgets('DecisionListScreen shows empty state', (tester) async {
    tester.view.physicalSize = const Size(800, 1200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final db = ColonyDatabase.inMemory();
    addTearDown(db.close);

    final repos = ColonyRepositories.create(
      db,
      idGenerator: FixedIdGenerator(['profile-1']),
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
          localizationsDelegates: const [
            DefaultMaterialLocalizations.delegate,
            DefaultWidgetsLocalizations.delegate,
          ],
          home: const Scaffold(body: DecisionListScreen()),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text(AppStrings.decisionListEmpty), findsOneWidget);
    await db.close();
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('DecisionListScreen lists decision and opens edit', (tester) async {
    tester.view.physicalSize = const Size(800, 1200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final db = ColonyDatabase.inMemory();
    addTearDown(db.close);

    final repos = ColonyRepositories.create(
      db,
      idGenerator: FixedIdGenerator(['profile-1', 'decision-1', 'event-1']),
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
    await repos.decisions.create(
      profileId: profile.id,
      title: 'Escolha estratégica',
      context: 'Contexto',
      decision: 'Opção A',
      assumptions: ['Premissa X'],
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [databaseProvider.overrideWithValue(db)],
        child: MaterialApp(
          theme: ColonyTheme.dark(),
          localizationsDelegates: const [
            DefaultMaterialLocalizations.delegate,
            DefaultWidgetsLocalizations.delegate,
          ],
          home: const Scaffold(body: DecisionListScreen()),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Escolha estratégica'), findsOneWidget);

    await tester.tap(find.text('Escolha estratégica'));
    await tester.pumpAndSettle();

    expect(find.byType(EditDecisionSheet), findsOneWidget);
    await db.close();
    await tester.pumpWidget(const SizedBox.shrink());
  });
}
