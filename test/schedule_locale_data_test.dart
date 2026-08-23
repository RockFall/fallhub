import 'package:colony_database/colony_database.dart';
import 'package:colony_design_system/colony_design_system.dart';
import 'package:colony_domain/colony_domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:fallhub/app/localization/app_strings.dart';
import 'package:fallhub/core/providers/app_providers.dart';
import 'package:fallhub/features/work/presentation/schedule_screen.dart';

/// Regression: opening Agenda used `DateFormat(..., 'pt_BR')` without
/// `initializeDateFormatting`, which throws LocaleDataException on device.
/// This file deliberately does **not** call initializeDateFormatting.
void main() {
  testWidgets('ScheduleScreen opens with pt_BR profile without LocaleDataException',
      (tester) async {
    tester.view.physicalSize = const Size(800, 1200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final db = ColonyDatabase.inMemory();
    addTearDown(db.close);

    final repos = ColonyRepositories.create(
      db,
      idGenerator: FixedIdGenerator(['profile-1']),
      clock: () => DateTime.utc(2026, 8, 23, 12),
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
        overrides: [databaseProvider.overrideWithValue(db)],
        child: MaterialApp(
          theme: ColonyTheme.dark(),
          home: const Scaffold(body: ScheduleScreen()),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(tester.takeException(), isNull);
    expect(find.text(AppStrings.schedule), findsOneWidget);
  });
}
