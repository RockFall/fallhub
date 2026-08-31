import 'package:colony_database/colony_database.dart';
import 'package:colony_design_system/colony_design_system.dart';
import 'package:colony_domain/colony_domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:fallhub/app/localization/app_strings.dart';
import 'package:fallhub/core/providers/app_providers.dart';
import 'package:fallhub/features/pawn/presentation/widgets/check_in_sheet.dart';

void main() {
  testWidgets('Check-in sheet uses inspect rails and saves mood factors', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final db = ColonyDatabase.inMemory();
    addTearDown(db.close);

    var tick = 0;
    DateTime clock() {
      tick += 1;
      return DateTime.utc(2026, 8, 31, 14, 20).add(Duration(seconds: tick));
    }

    final repos = ColonyRepositories.create(
      db,
      idGenerator: FixedIdGenerator([for (var i = 0; i < 200; i++) 'id-$i']),
      clock: clock,
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
    await repos.needs.seedDefaults(profile.id);
    await repos.checkIns.save(
      profileId: profile.id,
      mood: 0.5,
      energy: 0.5,
      tension: 0.25,
      focus: 0.5,
      factors: [(label: 'Caminhada', impact: 6, uncertain: false)],
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          databaseProvider.overrideWithValue(db),
          clockProvider.overrideWithValue(clock),
        ],
        child: MaterialApp(
          theme: ColonyTheme.dark(),
          home: const Scaffold(
            body: SizedBox(height: 1200, child: CheckInSheet()),
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.text('HUMOR'), findsOneWidget);
    expect(find.text('SONO'), findsOneWidget);
    expect(find.text('ANSIEDADE'), findsOneWidget);
    expect(find.text('DESCANSO'), findsOneWidget);
    expect(find.byType(NeedInspectBar), findsNWidgets(13));
    expect(find.byType(NeedInspectSlider), findsOneWidget);
    expect(find.byType(FilterChip), findsNothing);
    expect(find.byType(FilledButton), findsNothing);
    expect(find.text(AppStrings.energy), findsNothing);
    expect(find.text(AppStrings.tension), findsNothing);

    await tester.drag(find.byType(Slider), const Offset(280, 0));
    await tester.pump();

    await tester.ensureVisible(find.text('DESCANSO'));
    await tester.tap(find.text('DESCANSO'));
    await tester.pump();

    await tester.ensureVisible(
      find.widgetWithText(ColonyButton, AppStrings.checkIn),
    );
    await tester.tap(find.widgetWithText(ColonyButton, AppStrings.checkIn));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    final latest = await repos.checkIns.getLatest(profile.id);
    expect(latest, isNotNull);
    expect(latest!.mood, greaterThan(0.5));
    expect(latest.tension, 0.25);
    final factors = await repos.checkIns.getFactors(latest.id);
    expect(factors.map((f) => f.label), contains('Descanso'));

    await tester.pumpWidget(const SizedBox.shrink());
    for (var i = 0; i < 40; i++) {
      await tester.pump(const Duration(milliseconds: 1));
    }
  });
}
