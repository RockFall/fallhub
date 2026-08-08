import 'package:colony_database/colony_database.dart';
import 'package:colony_design_system/colony_design_system.dart';
import 'package:colony_domain/colony_domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:fallhub/app/localization/app_strings.dart';
import 'package:fallhub/core/providers/app_providers.dart';
import 'package:fallhub/features/projects/presentation/project_detail_screen.dart';
import 'package:fallhub/features/projects/presentation/widgets/edit_project_sheet.dart';

void main() {
  testWidgets('edit project saves title and purpose', (tester) async {
    tester.view.physicalSize = const Size(800, 1200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final db = ColonyDatabase.inMemory();
    addTearDown(() async {
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpAndSettle();
      await db.close();
    });

    final repos = ColonyRepositories.create(
      db,
      idGenerator: FixedIdGenerator(['profile-1', 'project-1', 'event-1', 'event-2']),
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

    final project = await repos.projects.create(
      profileId: profile.id,
      title: 'Viagem 2026',
      purpose: 'Planejamento',
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [databaseProvider.overrideWithValue(db)],
        child: MaterialApp(
          theme: ColonyTheme.dark(),
          home: Scaffold(
            body: ProjectDetailScreen(projectId: project.id.value),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text(AppStrings.projectEdit));
    await tester.pumpAndSettle();

    expect(find.byType(EditProjectSheet), findsOneWidget);

    await tester.enterText(find.widgetWithText(TextField, AppStrings.projectTitle), 'Viagem revisada');
    await tester.enterText(
      find.widgetWithText(TextField, AppStrings.projectPurposeOptional),
      'Novo propósito',
    );
    await tester.tap(find.text(AppStrings.save));
    await tester.pumpAndSettle();

    final updated = await repos.projects.getById(project.id);
    expect(updated?.title, 'Viagem revisada');
    expect(updated?.purpose, 'Novo propósito');

    await db.close();
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('complete transitions status and hides edit', (tester) async {
    tester.view.physicalSize = const Size(800, 1200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final db = ColonyDatabase.inMemory();
    addTearDown(() async {
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpAndSettle();
      await db.close();
    });

    final repos = ColonyRepositories.create(
      db,
      idGenerator: FixedIdGenerator(['profile-1', 'project-1', 'event-1', 'event-2']),
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

    final project = await repos.projects.create(
      profileId: profile.id,
      title: 'Viagem 2026',
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [databaseProvider.overrideWithValue(db)],
        child: MaterialApp(
          theme: ColonyTheme.dark(),
          home: Scaffold(
            body: ProjectDetailScreen(projectId: project.id.value),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text(AppStrings.projectEdit), findsOneWidget);

    await tester.tap(find.text(AppStrings.projectComplete));
    await tester.pumpAndSettle();
    await tester.tap(find.text(AppStrings.projectComplete).last);
    await tester.pumpAndSettle();

    expect(find.text(AppStrings.projectStatusLabel(ProjectStatus.completed)), findsOneWidget);
    expect(find.text(AppStrings.projectEdit), findsNothing);
    expect(find.text(AppStrings.projectArchive), findsOneWidget);

    final updated = await repos.projects.getById(project.id);
    expect(updated?.status, ProjectStatus.completed);

    await db.close();
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('archive after complete transitions to archived', (tester) async {
    tester.view.physicalSize = const Size(800, 1200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final db = ColonyDatabase.inMemory();
    addTearDown(() async {
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpAndSettle();
      await db.close();
    });

    final repos = ColonyRepositories.create(
      db,
      idGenerator: FixedIdGenerator([
        'profile-1',
        'project-1',
        'event-1',
        'event-2',
        'event-3',
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

    final project = await repos.projects.create(
      profileId: profile.id,
      title: 'Arquivável',
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [databaseProvider.overrideWithValue(db)],
        child: MaterialApp(
          theme: ColonyTheme.dark(),
          home: Scaffold(
            body: ProjectDetailScreen(projectId: project.id.value),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text(AppStrings.projectComplete));
    await tester.pumpAndSettle();
    await tester.tap(find.text(AppStrings.projectComplete).last);
    await tester.pumpAndSettle();

    await tester.tap(find.text(AppStrings.projectArchive));
    await tester.pumpAndSettle();
    await tester.tap(find.text(AppStrings.projectArchive).last);
    await tester.pumpAndSettle();

    final updated = await repos.projects.getById(project.id);
    expect(updated?.status, ProjectStatus.archived);
    expect(find.text(AppStrings.projectStatusLabel(ProjectStatus.archived)), findsOneWidget);

    await db.close();
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('archived project hides edit actions', (tester) async {
    tester.view.physicalSize = const Size(800, 1200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final db = ColonyDatabase.inMemory();
    addTearDown(() async {
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpAndSettle();
      await db.close();
    });

    final repos = ColonyRepositories.create(
      db,
      idGenerator: FixedIdGenerator(['profile-1', 'project-1', 'event-1']),
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

    final project = await repos.projects.create(
      profileId: profile.id,
      title: 'Legado',
      status: ProjectStatus.archived,
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [databaseProvider.overrideWithValue(db)],
        child: MaterialApp(
          theme: ColonyTheme.dark(),
          home: Scaffold(
            body: ProjectDetailScreen(projectId: project.id.value),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text(AppStrings.projectEdit), findsNothing);
    expect(find.text(AppStrings.projectComplete), findsNothing);
    expect(find.text(AppStrings.projectArchive), findsNothing);

    await db.close();
    await tester.pumpWidget(const SizedBox.shrink());
  });
}
