import 'package:colony_database/colony_database.dart';
import 'package:colony_design_system/colony_design_system.dart';
import 'package:colony_domain/colony_domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:fallhub/app/localization/app_strings.dart';
import 'package:fallhub/core/providers/app_providers.dart';
import 'package:fallhub/features/plan_day/presentation/plan_day_screen.dart';
import 'package:fallhub/features/plan_day/presentation/widgets/plan_day_home_card.dart';

Future<void> _drainTimers(WidgetTester tester) async {
  await tester.pumpWidget(const SizedBox.shrink());
  await tester.pump(const Duration(milliseconds: 50));
}

void main() {
  late ColonyDatabase db;
  late ColonyRepositories repos;
  final clock = DateTime(2026, 8, 24, 12);

  Future<void> pumpScreen(WidgetTester tester, {Widget? home}) async {
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
          home: Scaffold(body: home ?? const PlanDayScreen()),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
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

  testWidgets('empty state keeps the composer visible', (tester) async {
    await pumpScreen(tester);
    expect(find.text(AppStrings.planDayEmpty), findsOneWidget);
    expect(find.byType(TextField), findsOneWidget);
    await _drainTimers(tester);
  });

  testWidgets('composer creates an undated ColonyTask visible on Hoje',
      (tester) async {
    await pumpScreen(tester);
    await tester.enterText(find.byType(TextField), 'Comprar pão');
    await tester.tap(find.byTooltip(AppStrings.tasksComposerSubmit));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(find.text('Comprar pão'), findsOneWidget);
    expect(find.text('SEM DATA'), findsOneWidget);
    expect(find.text('NESTE DIA'), findsNothing);
    expect(find.byType(Checkbox), findsOneWidget);
    expect(find.textContaining('concluídas'), findsNothing);

    final profile = (await repos.profiles.getActive())!;
    final tasks = await repos.tasks.listAll(profile.id);
    expect(tasks, hasLength(1));
    expect(tasks.single.title, 'Comprar pão');
    expect(tasks.single.scheduledStart, isNull);
    expect(tasks.single.status, TaskStatus.next);
    await _drainTimers(tester);
  });

  testWidgets('undated tasks stay visible on other days; dated ones do not',
      (tester) async {
    final profile = (await repos.profiles.getActive())!;
    await repos.tasks.createSimple(
      profileId: profile.id,
      title: 'Sempre ativa',
    );
    final tomorrow = await repos.tasks.createSimple(
      profileId: profile.id,
      title: 'Só amanhã',
    );
    await repos.tasks.save(
      tomorrow.copyWith(scheduledStart: DateTime(2026, 8, 25)),
    );
    final todayOnly = await repos.tasks.createSimple(
      profileId: profile.id,
      title: 'Só hoje',
    );
    await repos.tasks.save(
      todayOnly.copyWith(scheduledStart: DateTime(2026, 8, 24)),
    );

    await pumpScreen(tester);
    expect(find.text('Sempre ativa'), findsOneWidget);
    expect(find.text('Só hoje'), findsOneWidget);
    expect(find.text('Só amanhã'), findsNothing);
    expect(find.text('NESTE DIA'), findsOneWidget);
    expect(find.text('SEM DATA'), findsOneWidget);
    expect(find.text(AppStrings.planDayProgress(0, 1)), findsOneWidget);

    await tester.tap(find.byTooltip(AppStrings.planDayNextDay));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(find.text('Sempre ativa'), findsOneWidget);
    expect(find.text('Só amanhã'), findsOneWidget);
    expect(find.text('Só hoje'), findsNothing);
    expect(
      find.text(
        AppStrings.planDayComposerOtherDayHint(
          AppStrings.planDayDateHeading('2026-08-25', isToday: false),
        ),
      ),
      findsOneWidget,
    );
    await _drainTimers(tester);
  });

  testWidgets('inbox capture stays off Hoje until it becomes next',
      (tester) async {
    final profile = (await repos.profiles.getActive())!;
    await repos.tasks.capture(
      profileId: profile.id,
      title: 'Rascunho inbox',
    );

    await pumpScreen(tester);
    expect(find.text('Rascunho inbox'), findsNothing);
    expect(find.text(AppStrings.planDayEmpty), findsOneWidget);
    await _drainTimers(tester);
  });

  testWidgets('deadline-only tasks still appear every day', (tester) async {
    final profile = (await repos.profiles.getActive())!;
    final task = await repos.tasks.createSimple(
      profileId: profile.id,
      title: 'Pagar conta',
    );
    await repos.tasks.save(
      task.copyWith(dueAt: DateTime(2026, 8, 30)),
    );

    await pumpScreen(tester);
    expect(find.text('Pagar conta'), findsOneWidget);

    await tester.tap(find.byTooltip(AppStrings.planDayNextDay));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    expect(find.text('Pagar conta'), findsOneWidget);
    await _drainTimers(tester);
  });

  testWidgets('subtasks stay off the day list', (tester) async {
    final profile = (await repos.profiles.getActive())!;
    final parent = await repos.tasks.createSimple(
      profileId: profile.id,
      title: 'Pai',
    );
    await repos.tasks.createSimple(
      profileId: profile.id,
      title: 'Filho',
      parentTaskId: parent.id,
    );

    await pumpScreen(tester);
    expect(find.text('Pai'), findsOneWidget);
    expect(find.text('Filho'), findsNothing);
    await _drainTimers(tester);
  });

  testWidgets('completing a task marks the ColonyTask done', (tester) async {
    final profile = (await repos.profiles.getActive())!;
    final task = await repos.tasks.createSimple(
      profileId: profile.id,
      title: 'Leite',
    );

    await pumpScreen(tester);
    expect(find.text('Leite'), findsOneWidget);
    await tester.tap(find.byType(Checkbox));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect((await repos.tasks.getById(task.id))!.status, TaskStatus.done);
    expect(find.text(AppStrings.planDayAllDone), findsOneWidget);
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

    expect(find.text('SEM DATA'), findsOneWidget);
    expect(find.text('CASA'), findsOneWidget);
    expect(find.text('SEM PROJETO'), findsOneWidget);
    expect(find.text('Pintar muro'), findsOneWidget);
    expect(find.text('Ligar para o banco'), findsOneWidget);
    await _drainTimers(tester);
  });

  testWidgets('home card shows empty prompt and composer', (tester) async {
    await pumpScreen(tester, home: const PlanDayHomeCard());
    expect(find.text(AppStrings.planDayTitle), findsOneWidget);
    expect(find.text(AppStrings.planDayHomeEmpty), findsOneWidget);
    expect(find.text(AppStrings.planDayHomeCta), findsOneWidget);
    await _drainTimers(tester);
  });

  testWidgets('home card composer also creates an undated task', (tester) async {
    await pumpScreen(tester, home: const PlanDayHomeCard());
    await tester.enterText(find.byType(TextField), 'Do card');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    final profile = (await repos.profiles.getActive())!;
    final tasks = await repos.tasks.listAll(profile.id);
    expect(tasks.single.title, 'Do card');
    expect(tasks.single.scheduledStart, isNull);
    expect(find.text('Do card'), findsOneWidget);
    await _drainTimers(tester);
  });
}
