import 'package:colony_database/colony_database.dart';
import 'package:colony_design_system/colony_design_system.dart';
import 'package:colony_domain/colony_domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:fallhub/app/localization/app_strings.dart';
import 'package:fallhub/core/providers/app_providers.dart';
import 'package:fallhub/features/chronicle/presentation/chronicle_screen.dart';
import 'package:fallhub/features/storyteller/presentation/narrative_digest_sheet.dart';

Future<void> _flush(WidgetTester tester) async {
  await tester.pumpWidget(const SizedBox.shrink());
  for (var i = 0; i < 40; i++) {
    await tester.pump(const Duration(milliseconds: 1));
  }
}

void main() {
  testWidgets('NarrativeDigestSheet shows rules disclaimer and bullets',
      (tester) async {
    tester.view.physicalSize = const Size(800, 1200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final db = ColonyDatabase.inMemory();
    final repos = ColonyRepositories.create(
      db,
      idGenerator: FixedIdGenerator([
        'profile-1',
        'event-1',
      ]),
      clock: () => DateTime.utc(2026, 8, 7, 12),
    );

    await repos.profiles.create(
      colonyName: 'Test',
      displayName: 'Caio',
      timezone: 'UTC',
      locale: 'pt_BR',
      baseCurrency: 'BRL',
    );
    await repos.preferences.save(AppPreferences.defaults().copyWith(
      onboardingCompleted: true,
    ));

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          databaseProvider.overrideWithValue(db),
          repositoriesProvider.overrideWithValue(repos),
          clockProvider.overrideWithValue(() => DateTime.utc(2026, 8, 7, 12)),
        ],
        child: MaterialApp(
          theme: ColonyTheme.dark(),
          home: const Scaffold(body: NarrativeDigestSheet()),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text(AppStrings.narrativeDigestTitle), findsOneWidget);
    expect(find.text(AppStrings.narrativeDigestDisclaimer), findsOneWidget);
    expect(find.textContaining('Gerador: rules_v1'), findsOneWidget);
    expect(find.textContaining('Período:'), findsOneWidget);
    expect(find.text(AppStrings.narrativeDigestSignals), findsOneWidget);
    expect(find.byType(Chip), findsWidgets);
    expect(find.byType(Semantics), findsWidgets);

    await _flush(tester);
    await db.close();
  });

  testWidgets('NarrativeDigestSheet evidence tap navigates to chronicle',
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
        'task-1',
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
    await repos.preferences.save(AppPreferences.defaults().copyWith(
      onboardingCompleted: true,
    ));
    await repos.tasks.capture(
      profileId: profile.id,
      title: 'Evidência digest',
    );

    final router = GoRouter(
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) => Scaffold(
            body: Builder(
              builder: (context) => TextButton(
                onPressed: () => showNarrativeDigestSheet(context),
                child: const Text('open-digest'),
              ),
            ),
          ),
        ),
        GoRoute(
          path: '/chronicle',
          builder: (context, state) {
            final eventIdsRaw = state.uri.queryParameters['eventIds'];
            return Scaffold(
              body: ChronicleScreen(
                evidenceEventIds: ChronicleScreen.parseEvidenceEventIds(
                  eventIdsRaw,
                ),
                highlightEventId: state.uri.queryParameters['highlight'],
              ),
            );
          },
        ),
      ],
      initialLocation: '/',
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          databaseProvider.overrideWithValue(db),
          repositoriesProvider.overrideWithValue(repos),
          clockProvider.overrideWithValue(() => DateTime.utc(2026, 8, 7, 12)),
        ],
        child: MaterialApp.router(
          theme: ColonyTheme.dark(),
          routerConfig: router,
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('open-digest'));
    await tester.pumpAndSettle();

    expect(find.text(AppStrings.narrativeDigestTitle), findsOneWidget);
    expect(find.byIcon(Icons.open_in_new), findsWidgets);

    await tester.tap(find.byIcon(Icons.open_in_new).first);
    await tester.pumpAndSettle();

    expect(router.state.uri.path, '/chronicle');
    expect(router.state.uri.queryParameters['eventIds'], isNotEmpty);
    expect(
      find.text(AppStrings.chronicleClearEvidenceFilter),
      findsOneWidget,
    );

    await _flush(tester);
  });
}
