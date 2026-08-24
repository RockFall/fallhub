import 'package:colony_database/colony_database.dart';
import 'package:colony_design_system/colony_design_system.dart';
import 'package:colony_domain/colony_domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:fallhub/app/localization/app_strings.dart';
import 'package:fallhub/core/providers/app_providers.dart';
import 'package:fallhub/features/tasks/presentation/task_detail_screen.dart';
import 'package:fallhub/features/tasks/presentation/widgets/task_composer.dart';

Future<void> _drainTimers(WidgetTester tester) async {
  await tester.pumpWidget(const SizedBox.shrink());
  await tester.pump(const Duration(milliseconds: 50));
}

void main() {
  late ColonyDatabase db;
  late ColonyRepositories repos;
  late ColonyTask task;
  final clock = DateTime.utc(2026, 8, 24, 12);

  Future<void> pumpScreen(WidgetTester tester) async {
    tester.view.physicalSize = const Size(800, 1600);
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
          home: Scaffold(body: TaskDetailScreen(taskId: task.id.value)),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 80));
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
    final profile = await repos.profiles.create(
      colonyName: 'Test',
      displayName: 'Caio',
      timezone: 'UTC',
      locale: 'pt_BR',
      baseCurrency: 'BRL',
    );
    await repos.preferences.save(
      AppPreferences.defaults().copyWith(onboardingCompleted: true),
    );
    task = await repos.tasks.createSimple(
      profileId: profile.id,
      title: 'Revisar PR',
    );
  });

  tearDown(() async {
    await db.close();
  });

  testWidgets('task page shows title and optional fields', (tester) async {
    await pumpScreen(tester);
    expect(find.text('Revisar PR'), findsWidgets);
    expect(find.text(AppStrings.taskPriority), findsOneWidget);
    expect(find.text(AppStrings.taskDeadline), findsOneWidget);
    expect(find.text(AppStrings.taskForDate), findsOneWidget);
    expect(find.text(AppStrings.taskSubtasks), findsOneWidget);
    expect(find.text(AppStrings.taskProject), findsOneWidget);
    await _drainTimers(tester);
  });

  testWidgets('shows a subtask created under the parent', (tester) async {
    await repos.tasks.createSimple(
      profileId: task.profileId,
      title: 'Abrir o diff',
      parentTaskId: task.id,
    );
    await pumpScreen(tester);
    expect(find.text('Abrir o diff'), findsOneWidget);
    expect(find.byType(TaskComposer), findsOneWidget);
    await _drainTimers(tester);
  });

  testWidgets('sets qualitative priority', (tester) async {
    await pumpScreen(tester);
    await tester.tap(find.text(AppStrings.taskPriorityLabel(TaskPriority.now)));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 80));
    final loaded = await repos.tasks.getById(task.id);
    expect(loaded!.priority, TaskPriority.now);
    await _drainTimers(tester);
  });

  testWidgets('marcar para hoje writes scheduledStart for today', (tester) async {
    await pumpScreen(tester);
    await tester.ensureVisible(find.text(AppStrings.planDayAddToToday));
    await tester.tap(find.text(AppStrings.planDayAddToToday));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 80));

    final loaded = await repos.tasks.getById(task.id);
    expect(loaded!.scheduledStart, isNotNull);
    expect(
      TaskCapabilityPolicy.isScheduledOn(
        loaded,
        dayPlanLocalDateKey(clock),
      ),
      isTrue,
    );
    await _drainTimers(tester);
  });
}
