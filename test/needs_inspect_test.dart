import 'package:colony_database/colony_database.dart';
import 'package:colony_design_system/colony_design_system.dart';
import 'package:colony_domain/colony_domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:fallhub/app/localization/app_strings.dart';
import 'package:fallhub/core/providers/app_providers.dart';
import 'package:fallhub/features/pawn/presentation/widgets/needs_inspect_tab.dart';

void main() {
  testWidgets('Needs inspect opens a need chart and Humor returns', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(800, 1400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final db = ColonyDatabase.inMemory();
    addTearDown(db.close);

    final repos = ColonyRepositories.create(
      db,
      idGenerator: FixedIdGenerator([for (var i = 0; i < 80; i++) 'id-$i']),
      clock: () => DateTime.utc(2026, 8, 31, 14, 20),
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
      tension: 0.5,
      focus: 0.5,
      factors: [(label: 'Caminhada', impact: 6, uncertain: false)],
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          databaseProvider.overrideWithValue(db),
          clockProvider.overrideWithValue(
            () => DateTime.utc(2026, 8, 31, 14, 20),
          ),
        ],
        child: MaterialApp(
          theme: ColonyTheme.dark(),
          home: const Scaffold(
            body: NeedsInspectTab(onRecordNeed: _noopRecord),
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.text('SONO'), findsOneWidget);
    expect(find.text('ANSIEDADE'), findsOneWidget);
    expect(find.text('CAMINHADA'), findsOneWidget);

    await tester.tap(find.text('SONO'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.text(AppStrings.needChartTitle('Sono')), findsOneWidget);
    expect(find.text(AppStrings.needRecordToday), findsOneWidget);

    await tester.tap(find.widgetWithText(ColonyButton, AppStrings.mood));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.text(AppStrings.needChartTitle('Sono')), findsNothing);
    expect(find.text('CAMINHADA'), findsOneWidget);

    await tester.pumpWidget(const SizedBox.shrink());
    for (var i = 0; i < 40; i++) {
      await tester.pump(const Duration(milliseconds: 1));
    }
  });
}

void _noopRecord(NeedSnapshot snapshot) {}
