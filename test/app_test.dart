import 'package:colony_database/colony_database.dart';
import 'package:colony_design_system/colony_design_system.dart';
import 'package:colony_domain/colony_domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:fallhub/app/bootstrap/colony_app.dart';
import 'package:fallhub/app/localization/app_strings.dart';
import 'package:fallhub/core/providers/app_providers.dart';
import 'package:fallhub/core/providers/feature_controllers.dart';

Future<void> _drainTimers(WidgetTester tester) async {
  await tester.pumpWidget(const SizedBox.shrink());
  for (var i = 0; i < 80; i++) {
    await tester.pump(const Duration(milliseconds: 1));
  }
}

Future<void> _pumpUntilAbsent(WidgetTester tester, Finder finder) async {
  await tester.pump();
  for (var i = 0; i < 40; i++) {
    if (finder.evaluate().isEmpty) return;
    await tester.pump(const Duration(milliseconds: 50));
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  SharedPreferences.setMockInitialValues({});

  testWidgets('shows onboarding when no profile', (tester) async {
    final db = ColonyDatabase.inMemory();
    addTearDown(db.close);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [databaseProvider.overrideWithValue(db)],
        child: const ColonyApp(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('CRIAR COLÔNIA'), findsOneWidget);
    expect(find.text(AppStrings.colony), findsNothing);
    await _drainTimers(tester);
  });

  testWidgets('Iniciar colônia leaves onboarding and opens the colony',
      (tester) async {
    tester.view.physicalSize = const Size(1100, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final db = ColonyDatabase.inMemory();
    addTearDown(db.close);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [databaseProvider.overrideWithValue(db)],
        child: const ColonyApp(),
      ),
    );
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField).first, 'Colônia Nova');
    await tester.enterText(find.byType(TextField).at(1), 'Caio');
    await tester.tap(find.text(AppStrings.startColony));
    await _pumpUntilAbsent(tester, find.text('CRIAR COLÔNIA'));

    expect(find.text('CRIAR COLÔNIA'), findsNothing);
    expect(find.text(AppStrings.startColony), findsNothing);
    expect(find.textContaining('Colônia Nova'), findsWidgets);
    await _drainTimers(tester);
  });

  test('complete finishes onboarding if a profile already exists', () async {
    final db = ColonyDatabase.inMemory();
    addTearDown(db.close);
    final repos = ColonyRepositories.create(
      db,
      idGenerator: FixedIdGenerator(List.generate(20, (i) => 'id-$i')),
      clock: () => DateTime.utc(2026, 8, 20, 12),
    );
    await repos.profiles.create(
      colonyName: 'Já existia',
      displayName: 'Caio',
      timezone: 'UTC',
      locale: 'pt_BR',
      baseCurrency: 'BRL',
    );

    final container = ProviderContainer(
      overrides: [databaseProvider.overrideWithValue(db)],
    );
    addTearDown(container.dispose);

    await container.read(onboardingControllerProvider.notifier).complete(
          colonyName: 'Ignorado',
          displayName: 'Ignorado',
          sectors: const ['trabalho'],
        );

    expect(container.read(onboardingControllerProvider).hasError, isFalse);
    final prefs = await container.read(preferencesProvider.future);
    expect(prefs.onboardingCompleted, isTrue);
    final profile = await container.read(profileProvider.future);
    expect(profile?.colonyName, 'Já existia');
  });

  testWidgets('NeedBar shows unknown label', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: ColonyTheme.dark(),
        home: const Scaffold(
          body: NeedBar(
            data: NeedBarData(label: 'Sono', statusText: 'Desconhecido'),
          ),
        ),
      ),
    );

    expect(find.text('Desconhecido'), findsOneWidget);
  });
}
