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
  await tester.pump(const Duration(seconds: 7));
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
    addTearDown(() async {
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump(const Duration(seconds: 7));
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

  testWidgets('empty state keeps the composer visible', (tester) async {
    await pumpScreen(tester);
    expect(find.text(AppStrings.planDayEmpty), findsOneWidget);
    expect(find.byType(TextField), findsOneWidget);
    await _drainTimers(tester);
  });

  testWidgets('adds an ad-hoc item from the composer', (tester) async {
    await pumpScreen(tester);
    await tester.enterText(find.byType(TextField), 'Comprar pão');
    await tester.tap(find.byTooltip(AppStrings.planDayComposerSubmit));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    expect(find.text('Comprar pão'), findsWidgets);
    expect(find.byType(Checkbox), findsOneWidget);
    await _drainTimers(tester);
  });

  testWidgets('enter always creates an ad-hoc item, even with a matching task',
      (tester) async {
    final profile = (await repos.profiles.getActive())!;
    await repos.tasks.capture(profileId: profile.id, title: 'Revisar PR');
    await pumpScreen(tester);
    await tester.enterText(find.byType(TextField), 'Revisar PR');
    await tester.tap(find.byTooltip(AppStrings.planDayComposerSubmit));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    expect(find.byIcon(Icons.link), findsNothing);
    expect(find.text('Revisar PR'), findsWidgets);
    await _drainTimers(tester);
  });

  testWidgets('pulls a matching inbox task from suggestions', (tester) async {
    final profile = (await repos.profiles.getActive())!;
    await repos.tasks.capture(profileId: profile.id, title: 'Revisar PR');
    await pumpScreen(tester);
    await tester.enterText(find.byType(TextField), 'Revis');
    await tester.pump();
    expect(find.text('Revisar PR'), findsWidgets);
    await tester.tap(find.text('Revisar PR').last);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    expect(find.byIcon(Icons.link), findsOneWidget);
    await _drainTimers(tester);
  });

  testWidgets('completing an ad-hoc item moves it to completed', (tester) async {
    final profile = (await repos.profiles.getActive())!;
    final plan = await repos.dayPlan.getOrCreateForDate(profile.id, '2026-08-24');
    await repos.dayPlan.addAdHoc(dayPlanId: plan.plan.id, title: 'Leite');
    await pumpScreen(tester);
    expect(find.text('Leite'), findsOneWidget);
    await tester.tap(find.byType(Checkbox));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    final loaded = await repos.dayPlan.getForDate(profile.id, '2026-08-24');
    expect(loaded!.items.single.isDone, isTrue);
    expect(find.text(AppStrings.planDayAllDone), findsOneWidget);
    await _drainTimers(tester);
  });

  testWidgets('completing a linked item marks the global task done', (tester) async {
    final profile = (await repos.profiles.getActive())!;
    var task = await repos.tasks.capture(profileId: profile.id, title: 'PR');
    task = await repos.tasks.updateStatus(task, TaskStatus.next);
    final plan = await repos.dayPlan.getOrCreateForDate(profile.id, '2026-08-24');
    await repos.dayPlan.pullTask(dayPlanId: plan.plan.id, task: task);
    await pumpScreen(tester);
    await tester.tap(find.byType(Checkbox));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect((await repos.tasks.getById(task.id))!.status, TaskStatus.done);
    await _drainTimers(tester);
  });

  testWidgets('carry-over banner brings yesterday items', (tester) async {
    final profile = (await repos.profiles.getActive())!;
    final yesterday =
        await repos.dayPlan.getOrCreateForDate(profile.id, '2026-08-23');
    await repos.dayPlan.addAdHoc(dayPlanId: yesterday.plan.id, title: 'Ontem');
    await pumpScreen(tester);
    expect(find.text(AppStrings.planDayCarryOverBanner(1)), findsOneWidget);
    await tester.tap(find.text(AppStrings.planDayCarryOverAddAll(1)));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    expect(find.text('Ontem'), findsOneWidget);
    await _drainTimers(tester);
  });

  testWidgets('home card shows empty prompt and composer', (tester) async {
    await pumpScreen(tester, home: const PlanDayHomeCard());
    expect(find.text(AppStrings.planDayTitle), findsOneWidget);
    expect(find.text(AppStrings.planDayHomeEmpty), findsOneWidget);
    expect(find.text(AppStrings.planDayHomeCta), findsOneWidget);
    await _drainTimers(tester);
  });
}
