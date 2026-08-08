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

Future<void> _flush(WidgetTester tester) async {
  await tester.pumpWidget(const SizedBox.shrink());
  for (var i = 0; i < 40; i++) {
    await tester.pump(const Duration(milliseconds: 1));
  }
}

void main() {
  test('parseEvidenceEventIds splits and trims', () {
    expect(ChronicleScreen.parseEvidenceEventIds(null), isEmpty);
    expect(ChronicleScreen.parseEvidenceEventIds(''), isEmpty);
    expect(
      ChronicleScreen.parseEvidenceEventIds('a, b,,c'),
      ['a', 'b', 'c'],
    );
  });

  testWidgets('ChronicleScreen filters and clears evidence deep-link',
      (tester) async {
    tester.view.physicalSize = const Size(800, 1200);
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
        'task-2',
        'event-2',
        'task-3',
        'event-3',
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
      title: 'Alpha',
    );
    await repos.tasks.capture(
      profileId: profile.id,
      title: 'Beta',
    );
    await repos.tasks.capture(
      profileId: profile.id,
      title: 'Gamma',
    );

    final events = await repos.events.listTimeline();
    final keep = events
        .where((e) => e.eventType == EventType.captureCreated)
        .toList();
    expect(keep, hasLength(3));
    final id1 = keep[0].id.value;
    final id2 = keep[1].id.value;

    final router = GoRouter(
      routes: [
        GoRoute(
          path: '/chronicle',
          builder: (context, state) {
            final eventIdsRaw = state.uri.queryParameters['eventIds'];
            final highlight = state.uri.queryParameters['highlight'];
            return Scaffold(
              body: ChronicleScreen(
                evidenceEventIds: ChronicleScreen.parseEvidenceEventIds(
                  eventIdsRaw,
                ),
                highlightEventId: highlight,
              ),
            );
          },
        ),
      ],
      initialLocation: '/chronicle?eventIds=$id1,$id2&highlight=$id2',
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          databaseProvider.overrideWithValue(db),
          repositoriesProvider.overrideWithValue(repos),
        ],
        child: MaterialApp.router(
          theme: ColonyTheme.dark(),
          routerConfig: router,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.text(AppStrings.chronicleEvidenceFilterActive(2)),
      findsOneWidget,
    );
    expect(find.text('Alpha'), findsOneWidget);
    expect(find.text('Beta'), findsOneWidget);
    expect(find.text('Gamma'), findsNothing);

    final highlighted = tester.widget<TimelineLetter>(
      find.byKey(ValueKey('chronicle-event-$id2')),
    );
    expect(highlighted.highlighted, isTrue);

    await tester.tap(find.text(AppStrings.chronicleClearEvidenceFilter));
    await tester.pumpAndSettle();

    expect(find.text('Gamma'), findsOneWidget);
    expect(
      find.text(AppStrings.chronicleEvidenceFilterActive(2)),
      findsNothing,
    );

    await _flush(tester);
  });
}
