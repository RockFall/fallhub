import 'package:colony_database/colony_database.dart';
import 'package:colony_design_system/colony_design_system.dart';
import 'package:colony_domain/colony_domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:fallhub/app/localization/app_strings.dart';
import 'package:fallhub/core/providers/app_providers.dart';
import 'package:fallhub/features/health/presentation/health_screen.dart';

Future<void> _flush(WidgetTester tester) async {
  await tester.pumpWidget(const SizedBox.shrink());
  for (var i = 0; i < 40; i++) {
    await tester.pump(const Duration(milliseconds: 1));
  }
}

void main() {
  testWidgets('HealthScreen shows disclaimer and empty state', (tester) async {
    tester.view.physicalSize = const Size(800, 1200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final db = ColonyDatabase.inMemory();
    final repos = ColonyRepositories.create(
      db,
      idGenerator: FixedIdGenerator(['profile-1']),
      clock: () => DateTime.utc(2026, 8, 7, 12),
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

    await tester.pumpWidget(
      ProviderScope(
        overrides: [databaseProvider.overrideWithValue(db)],
        child: MaterialApp(
          theme: ColonyTheme.dark(),
          home: const Scaffold(body: HealthScreen()),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text(AppStrings.healthDisclaimer), findsOneWidget);
    expect(find.text(AppStrings.healthEmpty), findsOneWidget);
    expect(find.text(AppStrings.healthNewCondition), findsOneWidget);

    await _flush(tester);
    await db.close();
  });

  testWidgets('HealthScreen lists created condition', (tester) async {
    tester.view.physicalSize = const Size(800, 1200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final db = ColonyDatabase.inMemory();
    final repos = ColonyRepositories.create(
      db,
      idGenerator: FixedIdGenerator([
        'profile-1',
        'health-1',
        'event-1',
      ]),
      clock: () => DateTime.utc(2026, 8, 7, 12),
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
    await repos.health.create(
      profileId: profile.id,
      title: 'Enxaqueca',
      type: HealthConditionType.symptom,
      severityUserReported: 3,
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [databaseProvider.overrideWithValue(db)],
        child: MaterialApp(
          theme: ColonyTheme.dark(),
          home: const Scaffold(body: HealthScreen()),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('Enxaqueca'), findsOneWidget);
    expect(find.textContaining('Sintoma'), findsOneWidget);

    await _flush(tester);
    await db.close();
  });

  testWidgets('HealthScreen edit sheet updates title and status', (tester) async {
    tester.view.physicalSize = const Size(800, 1400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final db = ColonyDatabase.inMemory();
    final repos = ColonyRepositories.create(
      db,
      idGenerator: FixedIdGenerator([
        'profile-1',
        'health-1',
        'event-1',
        'event-2',
      ]),
      clock: () => DateTime.utc(2026, 8, 7, 12),
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
    await repos.health.create(
      profileId: profile.id,
      title: 'Enxaqueca',
      type: HealthConditionType.symptom,
      severityUserReported: 3,
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [databaseProvider.overrideWithValue(db)],
        child: MaterialApp(
          theme: ColonyTheme.dark(),
          home: const Scaffold(body: HealthScreen()),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    await tester.tap(find.text('Enxaqueca'));
    await tester.pumpAndSettle();

    expect(find.text(AppStrings.healthEditCondition), findsOneWidget);

    await tester.enterText(
      find.widgetWithText(TextField, AppStrings.healthConditionTitle),
      'Enxaqueca leve',
    );

    await tester.tap(find.text(AppStrings.healthConditionStatusLabel(
      HealthConditionStatus.active,
    )));
    await tester.pumpAndSettle();
    await tester.tap(
      find.text(
        AppStrings.healthConditionStatusLabel(HealthConditionStatus.monitoring),
      ).last,
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text(AppStrings.save));
    await tester.pumpAndSettle();

    expect(find.text('Enxaqueca leve'), findsOneWidget);
    expect(
      find.textContaining(
        AppStrings.healthConditionStatusLabel(
          HealthConditionStatus.monitoring,
        ),
      ),
      findsOneWidget,
    );

    final saved = await repos.health.listAll(profile.id);
    expect(saved.single.title, 'Enxaqueca leve');
    expect(saved.single.status, HealthConditionStatus.monitoring);

    await _flush(tester);
    await db.close();
  });

  testWidgets('HealthScreen logs symptom entry on condition', (tester) async {
    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final db = ColonyDatabase.inMemory();
    final repos = ColonyRepositories.create(
      db,
      idGenerator: FixedIdGenerator([
        'profile-1',
        'health-1',
        'event-1',
        'sym-1',
        'event-2',
      ]),
      clock: () => DateTime.utc(2026, 8, 7, 12),
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
    await repos.health.create(
      profileId: profile.id,
      title: 'Enxaqueca',
      type: HealthConditionType.symptom,
      severityUserReported: 3,
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [databaseProvider.overrideWithValue(db)],
        child: MaterialApp(
          theme: ColonyTheme.dark(),
          home: const Scaffold(body: HealthScreen()),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    await tester.tap(find.text('Enxaqueca'));
    await tester.pumpAndSettle();

    expect(find.text(AppStrings.healthSymptomTimeline.toUpperCase()), findsOneWidget);
    expect(find.text(AppStrings.healthSymptomEmpty), findsOneWidget);

    await tester.tap(find.byTooltip(AppStrings.healthLogSymptom));
    await tester.pumpAndSettle();

    expect(find.text(AppStrings.healthLogSymptom), findsWidgets);
    await tester.tap(find.text(AppStrings.save).last);
    await tester.pumpAndSettle();

    expect(find.text(AppStrings.healthSymptomEmpty), findsNothing);
    expect(find.textContaining('Intensidade 3'), findsWidgets);

    final entries = await repos.health.listAllSymptomEntries(profile.id);
    expect(entries, hasLength(1));
    expect(entries.single.intensity, 3);

    await _flush(tester);
    await db.close();
  });

  testWidgets('HealthScreen appointments empty when only cancelled',
      (tester) async {
    tester.view.physicalSize = const Size(800, 1400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final db = ColonyDatabase.inMemory();
    final repos = ColonyRepositories.create(
      db,
      idGenerator: FixedIdGenerator([
        'profile-1',
        'appt-1',
        'event-1',
        'event-2',
      ]),
      clock: () => DateTime.utc(2026, 8, 7, 12),
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
    final appt = await repos.health.createAppointment(
      profileId: profile.id,
      title: 'Cancelada prévia',
      scheduledAt: DateTime.utc(2026, 9, 3, 10),
    );
    await repos.health.saveAppointment(
      appt.copyWith(status: HealthAppointmentStatus.cancelled),
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          databaseProvider.overrideWithValue(db),
          repositoriesProvider.overrideWithValue(repos),
        ],
        child: MaterialApp(
          theme: ColonyTheme.dark(),
          home: const Scaffold(body: HealthScreen()),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('Cancelada prévia'), findsNothing);
    expect(find.text(AppStrings.healthAppointmentsEmpty), findsOneWidget);

    await _flush(tester);
    await db.close();
  });

  testWidgets('HealthScreen mark appointment done hides tile', (tester) async {
    tester.view.physicalSize = const Size(800, 1400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final db = ColonyDatabase.inMemory();
    final repos = ColonyRepositories.create(
      db,
      idGenerator: FixedIdGenerator([
        'profile-1',
        'appt-1',
        'event-1',
        'event-2',
      ]),
      clock: () => DateTime.utc(2026, 8, 7, 12),
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
    await repos.health.createAppointment(
      profileId: profile.id,
      title: 'Check-up',
      scheduledAt: DateTime.utc(2026, 9, 2, 10),
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          databaseProvider.overrideWithValue(db),
          repositoriesProvider.overrideWithValue(repos),
        ],
        child: MaterialApp(
          theme: ColonyTheme.dark(),
          home: const Scaffold(body: HealthScreen()),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('Check-up'), findsOneWidget);

    await tester.tap(find.byTooltip(AppStrings.healthAppointmentMarkDone));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(find.text('Check-up'), findsNothing);
    expect(find.text(AppStrings.healthAppointmentsEmpty), findsOneWidget);

    final appts = await repos.health.listAppointments(profile.id);
    expect(appts.single.status, HealthAppointmentStatus.done);

    await _flush(tester);
    await db.close();
  });

  testWidgets('HealthScreen mark appointment cancelled hides tile',
      (tester) async {
    tester.view.physicalSize = const Size(800, 1400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final db = ColonyDatabase.inMemory();
    final repos = ColonyRepositories.create(
      db,
      idGenerator: FixedIdGenerator([
        'profile-1',
        'appt-1',
        'event-1',
        'event-2',
      ]),
      clock: () => DateTime.utc(2026, 8, 7, 12),
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
    await repos.health.createAppointment(
      profileId: profile.id,
      title: 'Dentista',
      scheduledAt: DateTime.utc(2026, 9, 1, 10),
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          databaseProvider.overrideWithValue(db),
          repositoriesProvider.overrideWithValue(repos),
        ],
        child: MaterialApp(
          theme: ColonyTheme.dark(),
          home: const Scaffold(body: HealthScreen()),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('Dentista'), findsOneWidget);

    await tester.tap(find.byTooltip(AppStrings.healthAppointmentMarkCancelled));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(find.text('Dentista'), findsNothing);
    expect(find.text(AppStrings.healthAppointmentsEmpty), findsOneWidget);

    final appts = await repos.health.listAppointments(profile.id);
    expect(appts.single.status, HealthAppointmentStatus.cancelled);

    await _flush(tester);
    await db.close();
  });

  testWidgets('HealthScreen edits appointment title', (tester) async {
    tester.view.physicalSize = const Size(800, 1400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final db = ColonyDatabase.inMemory();
    final repos = ColonyRepositories.create(
      db,
      idGenerator: FixedIdGenerator([
        'profile-1',
        'appt-1',
        'event-1',
        'event-2',
      ]),
      clock: () => DateTime.utc(2026, 8, 7, 12),
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
    await repos.health.createAppointment(
      profileId: profile.id,
      title: 'Clínico',
      scheduledAt: DateTime.utc(2026, 9, 5, 14),
      locationLabel: 'Clínica A',
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          databaseProvider.overrideWithValue(db),
          repositoriesProvider.overrideWithValue(repos),
        ],
        child: MaterialApp(
          theme: ColonyTheme.dark(),
          home: const Scaffold(body: HealthScreen()),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('Clínico'), findsOneWidget);

    await tester.tap(find.byTooltip(AppStrings.healthEditAppointment));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(find.text(AppStrings.healthEditAppointment), findsWidgets);

    await tester.enterText(
      find.widgetWithText(TextField, AppStrings.healthAppointmentTitle),
      'Clínico geral',
    );
    // Bottom sheet content can sit past the viewport hit box; invoke save directly.
    final saveButton = find.widgetWithText(FilledButton, AppStrings.save);
    tester.widget<FilledButton>(saveButton).onPressed!();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    final appts = await repos.health.listAppointments(profile.id);
    expect(appts.single.title, 'Clínico geral');
    expect(find.text('Clínico geral'), findsWidgets);

    await _flush(tester);
    await db.close();
  });
}
