import 'package:colony_database/colony_database.dart';
import 'package:colony_design_system/colony_design_system.dart';
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
  testWidgets('colony terminal home shows pawn, agenda, work and nav grid',
      (tester) async {
    tester.view.physicalSize = const Size(390, 1200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final db = ColonyDatabase.inMemory();
    addTearDown(db.close);

    final repos = ColonyRepositories.create(
      db,
      idGenerator: FixedIdGenerator(List.generate(80, (i) => 'id-$i')),
      clock: () => DateTime.utc(2026, 5, 19, 12, 4),
    );
    final profile = await repos.profiles.create(
      colonyName: 'Colônia Nova',
      displayName: 'Caio',
      timezone: 'UTC',
      locale: 'pt_BR',
      baseCurrency: 'BRL',
    );
    await repos.preferences.save(
      AppPreferences.defaults().copyWith(onboardingCompleted: true),
    );
    await repos.schedule.create(
      profileId: profile.id,
      startAt: DateTime.utc(2026, 5, 19, 0),
      endAt: DateTime.utc(2026, 5, 19, 7, 30),
      mode: ScheduleBlockMode.sleep,
    );
    await repos.schedule.create(
      profileId: profile.id,
      startAt: DateTime.utc(2026, 5, 19, 7, 30),
      endAt: DateTime.utc(2026, 5, 19, 12),
      mode: ScheduleBlockMode.focus,
    );
    await repos.tasks.createSimple(
      profileId: profile.id,
      title: 'Ensaio cap. 3',
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
        GoRoute(
          path: '/pawn',
          builder: (_, _) => const Scaffold(body: Text('pawn-stub')),
        ),
      ],
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          databaseProvider.overrideWithValue(db),
          clockProvider.overrideWithValue(() => DateTime.utc(2026, 5, 19, 12, 4)),
        ],
        child: MaterialApp.router(
          theme: ColonyTheme.dark(),
          routerConfig: router,
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.textContaining('CAIO'), findsWidgets);
    expect(find.textContaining(AppStrings.homeAgendaTitle.toUpperCase()), findsOneWidget);
    expect(
      find.textContaining(AppStrings.homeTodayWorkTitle.toUpperCase()),
      findsOneWidget,
    );
    expect(find.text(AppStrings.pawn.toUpperCase()), findsWidgets);
    expect(find.text(AppStrings.habitatTitle.toUpperCase()), findsWidgets);
    expect(find.text(AppStrings.financeLedgerTitle.toUpperCase()), findsWidgets);
    expect(find.text('SONO'), findsOneWidget);
    expect(find.text('FOCO'), findsOneWidget);
    expect(find.text('Ensaio cap. 3'), findsOneWidget);
    expect(find.text(AppStrings.homeSleepCheckIn), findsOneWidget);

    tester.view.physicalSize = const Size(1100, 1600);
    await tester.pump();
    expect(tester.takeException(), isNull);
    expect(find.textContaining('CAIO'), findsWidgets);

    await _flushDisposeTimers(tester);
  });
}
