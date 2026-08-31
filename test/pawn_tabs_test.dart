import 'package:colony_database/colony_database.dart';
import 'package:colony_design_system/colony_design_system.dart';
import 'package:colony_domain/colony_domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:fallhub/app/localization/app_strings.dart';
import 'package:fallhub/core/providers/app_providers.dart';
import 'package:fallhub/features/pawn/presentation/widgets/pawn_mind_tab.dart';
import 'package:fallhub/features/pawn/presentation/widgets/pawn_mobilization_tab.dart';
import 'package:fallhub/features/pawn/presentation/widgets/pawn_summary_tab.dart';

void main() {
  test('sitrep explains mood, needs and open route', () {
    expect(
      AppStrings.pawnSitrepLine(
        hasCheckIn: false,
        checkInIsToday: false,
        moodLabel: null,
        hasNeedReadings: false,
        attentionCount: 0,
        openRoute: false,
      ),
      contains(AppStrings.pawnSitrepNoCheckIn),
    );
    expect(
      AppStrings.pawnSitrepLine(
        hasCheckIn: true,
        checkInIsToday: true,
        moodLabel: 'Neutro',
        hasNeedReadings: true,
        attentionCount: 2,
        openRoute: true,
      ),
      allOf(
        contains('Humor Neutro'),
        contains('2 necessidades'),
        contains(AppStrings.pawnSitrepOpenRoute),
      ),
    );
  });

  testWidgets('Summary tab is a briefing, not a need catalog', (tester) async {
    tester.view.physicalSize = const Size(800, 1400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final env = await _seed(tester);
    var openedNeeds = 0;

    await tester.pumpWidget(
      _scope(
        env,
        PawnSummaryTab(
          onOpenNeeds: () => openedNeeds++,
          onOpenActivation: () {},
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.text('SITUAÇÃO'), findsOneWidget);
    expect(find.text('PRÓXIMO'), findsOneWidget);
    expect(find.text(AppStrings.pawnReviewPending.toUpperCase()), findsWidgets);
    expect(find.byType(NeedBar), findsNothing);
    expect(find.byType(LinearProgressIndicator), findsNothing);
    expect(find.byType(FilledButton), findsNothing);
    expect(find.text('SONO'), findsOneWidget);

    await tester.tap(find.text('SONO'));
    await tester.pump();
    expect(openedNeeds, 1);

    await _drain(tester);
  });

  testWidgets('Mind tab shows declared mood ledger and prompts', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(800, 1400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final env = await _seed(tester);
    await tester.pumpWidget(_scope(env, const PawnMindTab()));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.text('NEUTRO'), findsOneWidget);
    expect(find.text('CAMINHADA'), findsOneWidget);
    expect(find.text(AppStrings.pawnMindLift.toUpperCase()), findsOneWidget);
    expect(find.text(CheckInPrompts.daily.first.toUpperCase()), findsOneWidget);
    expect(find.byType(NeedInspectBar), findsNothing);
    expect(find.byType(FilterChip), findsNothing);

    await _drain(tester);
  });

  testWidgets('Mobilization tab is a single order well', (tester) async {
    tester.view.physicalSize = const Size(800, 1400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final env = await _seed(tester);
    await tester.pumpWidget(_scope(env, const PawnMobilizationTab()));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.text('ORDEM ATUAL'), findsOneWidget);
    expect(
      find.text(AppStrings.activationAvailable.toUpperCase()),
      findsOneWidget,
    );
    expect(
      find.widgetWithText(ColonyButton, AppStrings.activationStuckNow),
      findsOneWidget,
    );
    expect(find.byType(FilledButton), findsNothing);
    expect(find.byType(ListTile), findsNothing);
    expect(find.byType(NeedInspectBar), findsNothing);

    await _drain(tester);
  });
}

class _Env {
  const _Env({required this.db, required this.clock});

  final ColonyDatabase db;
  final DateTime Function() clock;
}

Future<_Env> _seed(WidgetTester tester) async {
  final db = ColonyDatabase.inMemory();
  addTearDown(db.close);

  var tick = 0;
  DateTime clock() {
    tick += 1;
    return DateTime.utc(2026, 8, 31, 14, 20).add(Duration(seconds: tick));
  }

  final repos = ColonyRepositories.create(
    db,
    idGenerator: FixedIdGenerator([for (var i = 0; i < 240; i++) 'id-$i']),
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
  final snapshots = await repos.needs.buildSnapshots(profile.id);
  final sono = snapshots.firstWhere((s) => s.definition.slug == 'sono');
  await repos.needs.recordReading(
    needId: sono.definition.id,
    normalizedValue: 0.1,
  );
  await repos.checkIns.save(
    profileId: profile.id,
    mood: 0.5,
    energy: 0.5,
    tension: 0.5,
    focus: 0.5,
    factors: [(label: 'Caminhada', impact: 6, uncertain: false)],
  );
  return _Env(db: db, clock: clock);
}

Widget _scope(_Env env, Widget body) {
  return ProviderScope(
    overrides: [
      databaseProvider.overrideWithValue(env.db),
      clockProvider.overrideWithValue(env.clock),
    ],
    child: MaterialApp(
      theme: ColonyTheme.dark(),
      home: Scaffold(body: body),
    ),
  );
}

Future<void> _drain(WidgetTester tester) async {
  await tester.pumpWidget(const SizedBox.shrink());
  for (var i = 0; i < 40; i++) {
    await tester.pump(const Duration(milliseconds: 1));
  }
}
