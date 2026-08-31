import 'dart:convert';
import 'dart:typed_data';

import 'package:colony_database/colony_database.dart';
import 'package:colony_design_system/colony_design_system.dart';
import 'package:colony_domain/colony_domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:fallhub/app/localization/app_strings.dart';
import 'package:fallhub/core/providers/app_providers.dart';
import 'package:fallhub/core/providers/feature_controllers.dart';
import 'package:fallhub/features/settings/presentation/settings_screen.dart';
import 'package:fallhub/features/settings/presentation/widgets/restore_preview_sheet.dart';
import 'package:fallhub/features/settings/presentation/widgets/sqlite_restore_preview_sheet.dart';

void main() {
  testWidgets('RestorePreviewSheet shows counts and confirms', (tester) async {
    tester.view.physicalSize = const Size(800, 1200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final snapshot = ExportSnapshot(
      exportedAt: DateTime.utc(2026, 8, 6, 12),
      version: 4,
      profile: ColonyProfile.create(
        id: EntityId('profile-1'),
        colonyName: 'Test',
        displayName: 'Caio',
        timezone: 'UTC',
        locale: 'pt_BR',
        baseCurrency: 'BRL',
        createdAt: DateTime.utc(2026, 8, 1),
      ),
      preferences: AppPreferences.defaults(),
      tasks: [
        ColonyTask.capture(
          id: EntityId('task-1'),
          profileId: EntityId('profile-1'),
          title: 'Tarefa',
          createdAt: DateTime.utc(2026, 8, 6),
        ),
      ],
      events: const [],
      quests: const [],
    );

    await tester.pumpWidget(
      MaterialApp(
        theme: ColonyTheme.dark(),
        localizationsDelegates: const [
          DefaultMaterialLocalizations.delegate,
          DefaultWidgetsLocalizations.delegate,
        ],
        home: Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: FilledButton(
                onPressed: () => RestorePreviewSheet.show(
                  context,
                  snapshot: snapshot,
                ),
                child: const Text('open'),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    expect(find.text(AppStrings.restorePreviewTitle), findsOneWidget);
    expect(find.textContaining('v4'), findsOneWidget);
    expect(find.textContaining('Tarefas: 1'), findsOneWidget);

    await tester.tap(find.text(AppStrings.restoreCancel));
    await tester.pumpAndSettle();
    expect(find.text(AppStrings.restorePreviewTitle), findsNothing);
  });

  testWidgets('RestorePreviewSheet shows pawn entity labels for v6 counts', (tester) async {
    tester.view.physicalSize = const Size(800, 1200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final snapshot = ExportSnapshot(
      exportedAt: DateTime.utc(2026, 8, 6, 12),
      version: 6,
      profile: ColonyProfile.create(
        id: EntityId('profile-1'),
        colonyName: 'Test',
        displayName: 'Caio',
        timezone: 'UTC',
        locale: 'pt_BR',
        baseCurrency: 'BRL',
        createdAt: DateTime.utc(2026, 8, 1),
      ),
      preferences: AppPreferences.defaults(),
      tasks: const [],
      events: const [],
      dailyReviews: [
        DailyReview(
          id: EntityId('review-1'),
          profileId: EntityId('profile-1'),
          reviewDate: DateTime.utc(2026, 8, 5),
          createdAt: DateTime.utc(2026, 8, 5, 22),
        ),
      ],
      moodFactors: [
        MoodFactor(
          id: EntityId('factor-1'),
          checkInId: EntityId('checkin-1'),
          label: 'Descanso',
          kind: MoodFactorKind.userConfirmed,
        ),
      ],
    );

    await tester.pumpWidget(
      MaterialApp(
        theme: ColonyTheme.dark(),
        localizationsDelegates: const [
          DefaultMaterialLocalizations.delegate,
          DefaultWidgetsLocalizations.delegate,
        ],
        home: Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: FilledButton(
                onPressed: () => RestorePreviewSheet.show(
                  context,
                  snapshot: snapshot,
                ),
                child: const Text('open'),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    expect(find.textContaining('Revisões diárias: 1'), findsOneWidget);
    expect(find.textContaining('Fatores de humor: 1'), findsOneWidget);
  });

  testWidgets('RestorePreviewSheet shows weekly review label for v7 counts', (tester) async {
    tester.view.physicalSize = const Size(800, 1200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final snapshot = ExportSnapshot(
      exportedAt: DateTime.utc(2026, 8, 6, 12),
      version: 7,
      profile: ColonyProfile.create(
        id: EntityId('profile-1'),
        colonyName: 'Test',
        displayName: 'Caio',
        timezone: 'UTC',
        locale: 'pt_BR',
        baseCurrency: 'BRL',
        createdAt: DateTime.utc(2026, 8, 1),
      ),
      preferences: AppPreferences.defaults(),
      tasks: const [],
      events: const [],
      weeklyReviews: [
        WeeklyReview(
          id: EntityId('weekly-1'),
          profileId: EntityId('profile-1'),
          weekStartDate: DateTime.utc(2026, 8, 4),
          createdAt: DateTime.utc(2026, 8, 10, 20),
          wins: 'Semana produtiva',
        ),
      ],
    );

    await tester.pumpWidget(
      MaterialApp(
        theme: ColonyTheme.dark(),
        localizationsDelegates: const [
          DefaultMaterialLocalizations.delegate,
          DefaultWidgetsLocalizations.delegate,
        ],
        home: Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: FilledButton(
                onPressed: () => RestorePreviewSheet.show(
                  context,
                  snapshot: snapshot,
                ),
                child: const Text('open'),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    expect(find.textContaining('Revisões semanais: 1'), findsOneWidget);
  });

  testWidgets('RestoreController restore replaces profile data', (tester) async {
    final db = ColonyDatabase.inMemory();
    addTearDown(db.close);

    final repos = ColonyRepositories.create(
      db,
      idGenerator: FixedIdGenerator(['profile-old', 'restore-event-1']),
      clock: () => DateTime.utc(2026, 8, 6, 14),
    );

    await repos.profiles.create(
      colonyName: 'Old Colony',
      displayName: 'Old',
      timezone: 'UTC',
      locale: 'pt_BR',
      baseCurrency: 'BRL',
    );

    final snapshot = ExportSnapshot(
      exportedAt: DateTime.utc(2026, 8, 6, 12),
      version: 1,
      profile: ColonyProfile.create(
        id: EntityId('profile-new'),
        colonyName: 'New Colony',
        displayName: 'New',
        timezone: 'UTC',
        locale: 'pt_BR',
        baseCurrency: 'BRL',
        createdAt: DateTime.utc(2026, 8, 1),
      ),
      preferences: AppPreferences.defaults().copyWith(onboardingCompleted: true),
      tasks: const [],
      events: const [],
    );

    late ProviderContainer container;
    await tester.pumpWidget(
      ProviderScope(
        overrides: [databaseProvider.overrideWithValue(db)],
        child: Builder(
          builder: (context) {
            container = ProviderScope.containerOf(context);
            return const SizedBox.shrink();
          },
        ),
      ),
    );

    await container.read(restoreControllerProvider.notifier).restore(snapshot);

    final profile = await repos.profiles.getActive();
    expect(profile!.colonyName, 'New Colony');
    await db.close();
  });

  testWidgets('SqliteRestorePreviewSheet shows schema and size', (tester) async {
    tester.view.physicalSize = const Size(800, 1200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final sqlite = Uint8List(200);
    sqlite.setRange(0, 15, ascii.encode('SQLite format 3'));
    final backup = ColonySqliteBackup(
      manifest: ColonySqliteBackupManifest(
        schemaVersion: 45,
        exportedAt: DateTime.utc(2026, 8, 31, 12),
      ),
      sqlite: sqlite,
    );

    await tester.pumpWidget(
      MaterialApp(
        theme: ColonyTheme.dark(),
        localizationsDelegates: const [
          DefaultMaterialLocalizations.delegate,
          DefaultWidgetsLocalizations.delegate,
        ],
        home: Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: FilledButton(
                onPressed: () => SqliteRestorePreviewSheet.show(
                  context,
                  backup: backup,
                ),
                child: const Text('open'),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    expect(find.text(AppStrings.sqliteBackupPreviewTitle), findsOneWidget);
    expect(find.textContaining('v45'), findsOneWidget);
    expect(
      find.textContaining(AppStrings.sqliteBackupSizeValue(200)),
      findsOneWidget,
    );

    await tester.tap(find.text(AppStrings.restoreCancel));
    await tester.pumpAndSettle();
    expect(find.text(AppStrings.sqliteBackupPreviewTitle), findsNothing);
  });

  testWidgets('SettingsScreen offers sqlite backup and JSON export', (tester) async {
    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final db = ColonyDatabase.inMemory();
    addTearDown(db.close);
    final repos = ColonyRepositories.create(
      db,
      idGenerator: FixedIdGenerator([
        for (var i = 1; i <= 20; i++) 'id-$i',
      ]),
      clock: () => DateTime.utc(2026, 8, 31, 12),
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
          home: const Scaffold(body: SettingsScreen()),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.text(AppStrings.sqliteBackupExport), findsOneWidget);
    expect(find.text(AppStrings.restoreData), findsOneWidget);
    expect(find.text(AppStrings.exportData), findsOneWidget);
    expect(find.text(AppStrings.sqliteBackupHint), findsOneWidget);
  });
}
