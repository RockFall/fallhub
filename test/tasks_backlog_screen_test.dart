import 'package:colony_database/colony_database.dart';
import 'package:colony_design_system/colony_design_system.dart';
import 'package:colony_domain/colony_domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:fallhub/app/localization/app_strings.dart';
import 'package:fallhub/core/providers/app_providers.dart';
import 'package:fallhub/features/tasks/presentation/tasks_backlog_screen.dart';

Future<void> _drainTimers(WidgetTester tester) async {
  await tester.pumpWidget(const SizedBox.shrink());
  await tester.pump(const Duration(milliseconds: 50));
}

void main() {
  late ColonyDatabase db;
  late ColonyRepositories repos;
  final clock = DateTime.utc(2026, 8, 24, 12);

  Future<void> pumpScreen(WidgetTester tester) async {
    tester.view.physicalSize = const Size(800, 1400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          databaseProvider.overrideWithValue(db),
          repositoriesProvider.overrideWithValue(repos),
          clockProvider.overrideWithValue(() => clock),
        ],
        child: MaterialApp(
          theme: ColonyTheme.dark(),
          home: const Scaffold(body: TasksBacklogScreen()),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    addTearDown(() async {
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump(const Duration(milliseconds: 50));
    });
  }

  setUp(() async {
    db = ColonyDatabase.inMemory();
    repos = ColonyRepositories.create(
      db,
      idGenerator: FixedIdGenerator([
        for (var i = 0; i < 80; i++) 'id-$i',
      ]),
      clock: () => clock,
    );
    await repos.profiles.create(
      colonyName: 'Test',
      displayName: 'Caio',
      timezone: 'UTC',
      locale: 'pt_BR',
      baseCurrency: 'BRL',
    );
    await repos.preferences.save(
      AppPreferences.defaults().copyWith(onboardingCompleted: true),
    );
  });

  tearDown(() async {
    await db.close();
  });

  testWidgets('empty backlog keeps the composer visible', (tester) async {
    await pumpScreen(tester);
    expect(find.text(AppStrings.tasksEmpty), findsOneWidget);
    expect(find.byType(TextField), findsOneWidget);
    await _drainTimers(tester);
  });

  testWidgets('creating with only a name shows the task', (tester) async {
    await pumpScreen(tester);
    await tester.enterText(find.byType(TextField), 'Comprar pão');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    expect(find.text('Comprar pão'), findsOneWidget);
    expect(find.text(AppStrings.tasksEmpty), findsNothing);
    await _drainTimers(tester);
  });

  testWidgets('groups open tasks by project', (tester) async {
    final profile = (await repos.profiles.getActive())!;
    final project = await repos.projects.create(
      profileId: profile.id,
      title: 'Casa',
    );
    final painted = await repos.tasks.createSimple(
      profileId: profile.id,
      title: 'Pintar muro',
    );
    await repos.tasks.save(painted.copyWith(projectId: project.id));
    await repos.tasks.createSimple(
      profileId: profile.id,
      title: 'Ligar para o banco',
    );

    await pumpScreen(tester);
    await tester.tap(find.text(AppStrings.tasksGroupByProject));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(find.text('CASA'), findsOneWidget);
    expect(find.text('SEM PROJETO'), findsOneWidget);
    expect(find.text('Pintar muro'), findsOneWidget);
    expect(find.text('Ligar para o banco'), findsOneWidget);
    await _drainTimers(tester);
  });
}
