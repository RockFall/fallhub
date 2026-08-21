import 'package:colony_database/colony_database.dart';
import 'package:colony_domain/colony_domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:fallhub/app/localization/app_strings.dart';
import 'package:fallhub/core/providers/app_providers.dart';
import 'package:fallhub/features/colony/presentation/colony_screen.dart';

Future<void> _flushDisposeTimers(WidgetTester tester) async {
  await tester.pumpWidget(const SizedBox.shrink());
  for (var i = 0; i < 80; i++) {
    await tester.pump(const Duration(milliseconds: 1));
  }
}

void main() {
  testWidgets('colony home shows greeting, mini-programs and operational feed',
      (tester) async {
    tester.view.physicalSize = const Size(1100, 2200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final db = ColonyDatabase.inMemory();
    addTearDown(db.close);

    final repos = ColonyRepositories.create(
      db,
      idGenerator: FixedIdGenerator(List.generate(40, (i) => 'id-$i')),
      clock: () => DateTime.utc(2026, 8, 21, 12),
    );
    await repos.profiles.create(
      colonyName: 'Colônia Nova',
      displayName: 'Caio',
      timezone: 'UTC',
      locale: 'pt_BR',
      baseCurrency: 'BRL',
    );
    await repos.preferences.save(
      AppPreferences.defaults().copyWith(onboardingCompleted: true),
    );

    final router = GoRouter(
      initialLocation: '/colony',
      routes: [
        GoRoute(
          path: '/colony',
          builder: (_, _) => const Scaffold(body: ColonyScreen()),
        ),
        GoRoute(
          path: '/inbox',
          builder: (_, _) => const Scaffold(body: Text('inbox-stub')),
        ),
      ],
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [databaseProvider.overrideWithValue(db)],
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.textContaining('Colônia Nova'), findsWidgets);
    expect(find.textContaining('Caio'), findsWidgets);
    expect(find.text(AppStrings.homeMiniAppsTitle), findsOneWidget);
    expect(find.text(AppStrings.habitatTitle), findsWidgets);
    expect(find.text(AppStrings.financeLedgerTitle), findsWidgets);
    expect(find.text(AppStrings.homeStateTitle), findsOneWidget);
    expect(find.text(AppStrings.homeNext24hTitle), findsOneWidget);
    expect(find.text(AppStrings.colonyActiveQuests), findsOneWidget);
    expect(find.text(AppStrings.homeQuickStudy), findsWidgets);

    await tester.tap(find.text(AppStrings.homeMiniAppsMore));
    await tester.pump();
    expect(find.text(AppStrings.travelTitle), findsOneWidget);
    expect(find.text(AppStrings.settings), findsOneWidget);

    tester.view.physicalSize = const Size(390, 844);
    await tester.pump();
    expect(tester.takeException(), isNull);
    expect(find.text(AppStrings.homeMiniAppsTitle), findsOneWidget);

    await _flushDisposeTimers(tester);
  });
}
