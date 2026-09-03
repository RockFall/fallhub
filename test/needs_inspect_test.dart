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
      tension: 0.5,
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
          home: const Scaffold(body: NeedsInspectTab()),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.text('SONO'), findsOneWidget);
    expect(find.text('ANSIEDADE'), findsOneWidget);
    expect(find.text('CAMINHADA'), findsOneWidget);

    final sono = tester.widget<Text>(find.text('SONO'));
    final anxiety = tester.widget<Text>(find.text('ANSIEDADE'));
    expect(sono.style!.fontSize, greaterThan(anxiety.style!.fontSize!));

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

    await tester.tap(find.text('HUMOR'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(
      find.text(AppStrings.needChartTitle(AppStrings.mood)),
      findsOneWidget,
    );
    expect(find.text(AppStrings.needRecordToday), findsOneWidget);
    expect(find.byType(NeedInspectSlider), findsOneWidget);
    expect(find.byType(Slider), findsOneWidget);

    await tester.drag(find.byType(Slider), const Offset(280, 0));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    final after = await repos.checkIns.getLatest(profile.id);
    expect(after, isNotNull);
    expect(after!.mood, greaterThan(0.5));
    final factors = await repos.checkIns.getFactors(after.id);
    expect(factors.map((f) => f.label), contains('Caminhada'));

    await tester.pumpWidget(const SizedBox.shrink());
    for (var i = 0; i < 40; i++) {
      await tester.pump(const Duration(milliseconds: 1));
    }
  });

  testWidgets('Humor chart keeps two check-ins on the same local day', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(800, 1400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final db = ColonyDatabase.inMemory();
    addTearDown(db.close);

    var now = DateTime.utc(2026, 8, 31, 8, 5);
    DateTime clock() => now;

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
      mood: 0.25,
      energy: 0.5,
      tension: 0.5,
      focus: 0.5,
    );
    now = DateTime.utc(2026, 8, 31, 20, 15);
    await repos.checkIns.save(
      profileId: profile.id,
      mood: 0.75,
      energy: 0.5,
      tension: 0.5,
      focus: 0.5,
    );

    final stored = await repos.checkIns.listAll(profile.id);
    expect(stored, hasLength(2));

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          databaseProvider.overrideWithValue(db),
          clockProvider.overrideWithValue(clock),
        ],
        child: MaterialApp(
          theme: ColonyTheme.dark(),
          home: const Scaffold(body: NeedsInspectTab()),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    await tester.tap(find.text('HUMOR'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.byType(NeedSparkline), findsOneWidget);
    expect(
      find.text(
        AppStrings.needSampleHeadline(
          DateTime.utc(2026, 8, 31, 20, 15),
          AppStrings.scaleFiveLabel(0.75),
        ),
      ),
      findsOneWidget,
    );

    await tester.pumpWidget(const SizedBox.shrink());
    for (var i = 0; i < 40; i++) {
      await tester.pump(const Duration(milliseconds: 1));
    }
  });
}
