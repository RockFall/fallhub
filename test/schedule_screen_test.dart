import 'package:colony_database/colony_database.dart';
import 'package:colony_design_system/colony_design_system.dart';
import 'package:colony_domain/colony_domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'package:fallhub/app/localization/app_strings.dart';
import 'package:fallhub/core/providers/app_providers.dart';
import 'package:fallhub/features/work/application/work_controllers.dart';
import 'package:fallhub/features/work/application/work_providers.dart';
import 'package:fallhub/features/work/presentation/schedule_screen.dart';
import 'package:fallhub/features/work/presentation/widgets/schedule_block_sheet.dart';
import 'package:fallhub/features/work/presentation/widgets/schedule_conflict_panel.dart';
import 'package:fallhub/features/work/presentation/widgets/schedule_day_timeline.dart';
import 'package:fallhub/features/work/presentation/widgets/schedule_three_day_view.dart';
import 'package:go_router/go_router.dart';

void main() {
  setUpAll(() async {
    await initializeDateFormatting('pt_BR');
  });

  testWidgets('day navigation buttons change scheduleSelectedDayProvider', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          scheduleSelectedDayProvider.overrideWith(_FixedScheduleSelectedDay.new),
        ],
        child: MaterialApp(
          theme: ColonyTheme.dark(),
          home: Scaffold(body: _DayNavHarness()),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final container = ProviderScope.containerOf(tester.element(find.byType(_DayNavHarness)));
    expect(container.read(scheduleSelectedDayProvider).day, 6);

    await tester.tap(find.byTooltip(AppStrings.scheduleNextDay));
    await tester.pumpAndSettle();
    expect(container.read(scheduleSelectedDayProvider).day, 7);

    await tester.tap(find.byTooltip(AppStrings.schedulePreviousDay));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip(AppStrings.schedulePreviousDay));
    await tester.pumpAndSettle();
    expect(container.read(scheduleSelectedDayProvider).day, 5);
  });

  testWidgets('ScheduleBlockSheet add block persists with chosen times', (tester) async {
    tester.view.physicalSize = const Size(800, 1200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final db = ColonyDatabase.inMemory();
    addTearDown(db.close);

    final repos = ColonyRepositories.create(
      db,
      idGenerator: FixedIdGenerator(['profile-1', 'block-1', 'event-1', 'event-2']),
      clock: () => DateTime.utc(2026, 8, 6, 12),
    );

    final profile = await repos.profiles.create(
      colonyName: 'Test',
      displayName: 'Caio',
      timezone: 'UTC',
      locale: 'pt_BR',
      baseCurrency: 'BRL',
    );
    await repos.preferences.save(AppPreferences.defaults());

    final day = DateTime(2026, 8, 6);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [databaseProvider.overrideWithValue(db)],
        child: MaterialApp(
          theme: ColonyTheme.dark(),
          home: Scaffold(body: ScheduleBlockSheet(day: day)),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text(AppStrings.save));
    await tester.pumpAndSettle();

    final blocks = await repos.schedule.listAll(profile.id);
    expect(blocks, hasLength(1));
    expect(blocks.first.startAt, DateTime(2026, 8, 6, 9).toUtc());
    expect(blocks.first.endAt, DateTime(2026, 8, 6, 10).toUtc());
    expect(blocks.first.mode, ScheduleBlockMode.focus);
  });

  testWidgets('ScheduleBlockSheet edit updates block mode', (tester) async {
    tester.view.physicalSize = const Size(800, 1200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final db = ColonyDatabase.inMemory();
    addTearDown(db.close);

    final repos = ColonyRepositories.create(
      db,
      idGenerator: FixedIdGenerator(['profile-1', 'block-1', 'event-1', 'event-2']),
      clock: () => DateTime.utc(2026, 8, 6, 12),
    );

    final profile = await repos.profiles.create(
      colonyName: 'Test',
      displayName: 'Caio',
      timezone: 'UTC',
      locale: 'pt_BR',
      baseCurrency: 'BRL',
    );

    final day = DateTime(2026, 8, 6);
    final block = await repos.schedule.create(
      profileId: profile.id,
      startAt: DateTime(2026, 8, 6, 9).toUtc(),
      endAt: DateTime(2026, 8, 6, 10).toUtc(),
      mode: ScheduleBlockMode.focus,
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [databaseProvider.overrideWithValue(db)],
        child: MaterialApp(
          theme: ColonyTheme.dark(),
          home: Scaffold(body: ScheduleBlockSheet(day: day, block: block)),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byType(DropdownButtonFormField<ScheduleBlockMode>));
    await tester.pump();
    await tester.tap(
      find.text(AppStrings.scheduleBlockModeLabel(ScheduleBlockMode.meeting)).last,
    );
    await tester.pump();

    await tester.tap(find.text(AppStrings.save));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    final blocks = await repos.schedule.listAll(profile.id);
    expect(blocks.single.mode, ScheduleBlockMode.meeting);
  });

  testWidgets('ScheduleBlockSheet delete removes block', (tester) async {
    tester.view.physicalSize = const Size(800, 1200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final db = ColonyDatabase.inMemory();
    addTearDown(db.close);

    final repos = ColonyRepositories.create(
      db,
      idGenerator: FixedIdGenerator(['profile-1', 'block-1', 'event-1', 'event-2']),
      clock: () => DateTime.utc(2026, 8, 6, 12),
    );

    final profile = await repos.profiles.create(
      colonyName: 'Test',
      displayName: 'Caio',
      timezone: 'UTC',
      locale: 'pt_BR',
      baseCurrency: 'BRL',
    );

    final day = DateTime(2026, 8, 6);
    final block = await repos.schedule.create(
      profileId: profile.id,
      startAt: DateTime(2026, 8, 6, 9).toUtc(),
      endAt: DateTime(2026, 8, 6, 10).toUtc(),
      mode: ScheduleBlockMode.focus,
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [databaseProvider.overrideWithValue(db)],
        child: MaterialApp(
          theme: ColonyTheme.dark(),
          home: Scaffold(body: ScheduleBlockSheet(day: day, block: block)),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text(AppStrings.delete).first);
    await tester.pumpAndSettle();
    await tester.tap(find.text(AppStrings.delete).last);
    await tester.pumpAndSettle();

    final blocks = await repos.schedule.listAll(profile.id);
    expect(blocks, isEmpty);
  });

  testWidgets('invalid time range shows snackbar', (tester) async {
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
    await repos.preferences.save(AppPreferences.defaults());

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          databaseProvider.overrideWithValue(db),
          scheduleDayProvider.overrideWith(_emptyScheduleDay),
          scheduledTasksDayProvider.overrideWith(_emptyScheduledTasksDay),
        ],
        child: MaterialApp(
          theme: ColonyTheme.dark(),
          home: const Scaffold(body: ScheduleScreen()),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final container = ProviderScope.containerOf(
      tester.element(find.byType(ScheduleScreen)),
    );
    await container.read(scheduleControllerProvider.notifier).addBlock(
          day: DateTime(2026, 8, 6),
          startHour: 10,
          startMinute: 0,
          endHour: 9,
          endMinute: 0,
        );
    await tester.pump();

    expect(find.text(AppStrings.scheduleBlockInvalidTime), findsOneWidget);
  });

  testWidgets('timeline renders blocks and shows conflict panel on overlap',
      (tester) async {
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
        'block-1',
        'block-2',
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
    await repos.preferences.save(AppPreferences.defaults());

    await repos.schedule.create(
      profileId: profile.id,
      startAt: DateTime(2026, 8, 6, 9).toUtc(),
      endAt: DateTime(2026, 8, 6, 11).toUtc(),
      mode: ScheduleBlockMode.focus,
    );
    await repos.schedule.create(
      profileId: profile.id,
      startAt: DateTime(2026, 8, 6, 10).toUtc(),
      endAt: DateTime(2026, 8, 6, 12).toUtc(),
      mode: ScheduleBlockMode.meeting,
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          databaseProvider.overrideWithValue(db),
          scheduleSelectedDayProvider.overrideWith(_FixedScheduleSelectedDay.new),
        ],
        child: MaterialApp(
          theme: ColonyTheme.dark(),
          home: const Scaffold(body: ScheduleScreen()),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(ScheduleDayTimeline), findsOneWidget);
    expect(find.byType(DayTimeline), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text(AppStrings.scheduleConflicts.toUpperCase()),
      500,
    );
    expect(
      find.text(AppStrings.scheduleConflicts.toUpperCase()),
      findsOneWidget,
    );
    expect(find.byType(ScheduleConflictPanel), findsOneWidget);
    expect(
      find.textContaining(
        AppStrings.scheduleBlockModeLabel(ScheduleBlockMode.focus),
      ),
      findsWidgets,
    );

    await db.close();
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('timeline shows empty state without conflicts when clean',
      (tester) async {
    tester.view.physicalSize = const Size(800, 1400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final db = ColonyDatabase.inMemory();
    addTearDown(db.close);

    final repos = ColonyRepositories.create(
      db,
      idGenerator: FixedIdGenerator(['profile-1', 'block-1', 'event-1']),
      clock: () => DateTime.utc(2026, 8, 6, 12),
    );

    final profile = await repos.profiles.create(
      colonyName: 'Test',
      displayName: 'Caio',
      timezone: 'UTC',
      locale: 'pt_BR',
      baseCurrency: 'BRL',
    );
    await repos.preferences.save(AppPreferences.defaults());

    await repos.schedule.create(
      profileId: profile.id,
      startAt: DateTime(2026, 8, 6, 9).toUtc(),
      endAt: DateTime(2026, 8, 6, 10).toUtc(),
      mode: ScheduleBlockMode.focus,
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          databaseProvider.overrideWithValue(db),
          scheduleSelectedDayProvider.overrideWith(_FixedScheduleSelectedDay.new),
        ],
        child: MaterialApp(
          theme: ColonyTheme.dark(),
          home: const Scaffold(body: ScheduleScreen()),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(DayTimeline), findsOneWidget);
    expect(
      find.text(AppStrings.scheduleConflicts.toUpperCase()),
      findsNothing,
    );

    await db.close();
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('toggle to 3-day view shows three timeline panels', (tester) async {
    tester.view.physicalSize = const Size(800, 1400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final db = ColonyDatabase.inMemory();
    addTearDown(db.close);

    final repos = ColonyRepositories.create(
      db,
      idGenerator: FixedIdGenerator(['profile-1', 'block-1', 'event-1']),
      clock: () => DateTime.utc(2026, 8, 6, 12),
    );

    await repos.profiles.create(
      colonyName: 'Test',
      displayName: 'Caio',
      timezone: 'UTC',
      locale: 'pt_BR',
      baseCurrency: 'BRL',
    );
    await repos.preferences.save(AppPreferences.defaults());

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          databaseProvider.overrideWithValue(db),
          scheduleSelectedDayProvider.overrideWith(_FixedScheduleSelectedDay.new),
          scheduleDayProvider.overrideWith(_emptyScheduleDay),
          scheduledTasksDayProvider.overrideWith(_emptyScheduledTasksDay),
        ],
        child: MaterialApp(
          theme: ColonyTheme.dark(),
          home: const Scaffold(body: ScheduleScreen()),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.byType(ScheduleDayTimeline), findsOneWidget);
    expect(find.byType(ScheduleThreeDayView), findsNothing);

    await tester.tap(find.text(AppStrings.scheduleViewThreeDays));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.byType(ScheduleThreeDayView), findsOneWidget);
    expect(find.byType(ScheduleDayTimeline), findsNWidgets(3));
    expect(find.byType(ScheduleConflictPanel), findsNWidgets(3));

    await tester.tap(find.text(AppStrings.scheduleViewDay));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.byType(ScheduleDayTimeline), findsOneWidget);
    expect(find.byType(ScheduleThreeDayView), findsNothing);

    await db.close();
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('3-day navigation shifts anchor by one day', (tester) async {
    tester.view.physicalSize = const Size(800, 1400);
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
    await repos.preferences.save(AppPreferences.defaults());

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          databaseProvider.overrideWithValue(db),
          scheduleSelectedDayProvider.overrideWith(_FixedScheduleSelectedDay.new),
          scheduleViewModeProvider.overrideWith(_FixedThreeDayViewMode.new),
          scheduleDayProvider.overrideWith(_emptyScheduleDay),
          scheduledTasksDayProvider.overrideWith(_emptyScheduledTasksDay),
        ],
        child: MaterialApp(
          theme: ColonyTheme.dark(),
          home: const Scaffold(body: ScheduleScreen()),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    final container = ProviderScope.containerOf(
      tester.element(find.byType(ScheduleScreen)),
    );
    expect(container.read(scheduleSelectedDayProvider).day, 6);

    await tester.tap(find.byTooltip(AppStrings.scheduleNextDay));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));
    expect(container.read(scheduleSelectedDayProvider).day, 7);
    expect(find.byType(ScheduleDayTimeline), findsNWidgets(3));

    await db.close();
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('deep link ?date= anchors first day of range', (tester) async {
    tester.view.physicalSize = const Size(800, 1400);
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
    await repos.preferences.save(AppPreferences.defaults());

    late final GoRouter router;
    router = GoRouter(
      routes: [
        GoRoute(
          path: '/work/schedule',
          builder: (context, state) => const Scaffold(body: ScheduleScreen()),
        ),
      ],
      initialLocation: '/work/schedule?date=2026-08-10',
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          databaseProvider.overrideWithValue(db),
          scheduleDayProvider.overrideWith(_emptyScheduleDay),
          scheduledTasksDayProvider.overrideWith(_emptyScheduledTasksDay),
        ],
        child: MaterialApp.router(
          theme: ColonyTheme.dark(),
          routerConfig: router,
        ),
      ),
    );
    await tester.pump();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    final container = ProviderScope.containerOf(
      tester.element(find.byType(ScheduleScreen)),
    );
    final anchor = container.read(scheduleSelectedDayProvider);
    expect(anchor, DateTime(2026, 8, 10));

    await tester.tap(find.text(AppStrings.scheduleViewThreeDays));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    final range = scheduleThreeDayRange(anchor);
    expect(range[0], DateTime(2026, 8, 10));
    expect(range[2], DateTime(2026, 8, 12));

    await db.close();
    await tester.pumpWidget(const SizedBox.shrink());
  });
}

Stream<List<ScheduleBlock>> _emptyScheduleDay(Ref ref, DateTime day) async* {
  yield [];
}

Stream<List<ColonyTask>> _emptyScheduledTasksDay(Ref ref, DateTime day) async* {
  yield [];
}

class _FixedScheduleSelectedDay extends ScheduleSelectedDay {
  @override
  DateTime build() => scheduleCalendarDay(DateTime(2026, 8, 6));
}

class _FixedThreeDayViewMode extends ScheduleViewModeNotifier {
  @override
  ScheduleViewMode build() => ScheduleViewMode.threeDay;
}

class _DayNavHarness extends ConsumerWidget {
  const _DayNavHarness();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedDay = ref.watch(scheduleSelectedDayProvider);

    return Row(
      children: [
        IconButton(
          tooltip: AppStrings.schedulePreviousDay,
          icon: const Icon(Icons.chevron_left),
          onPressed: () {
            ref
                .read(scheduleSelectedDayProvider.notifier)
                .select(selectedDay.subtract(const Duration(days: 1)));
          },
        ),
        Text('${selectedDay.day}'),
        IconButton(
          tooltip: AppStrings.scheduleNextDay,
          icon: const Icon(Icons.chevron_right),
          onPressed: () {
            ref
                .read(scheduleSelectedDayProvider.notifier)
                .select(selectedDay.add(const Duration(days: 1)));
          },
        ),
      ],
    );
  }
}
