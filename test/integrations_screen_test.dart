import 'package:colony_database/colony_database.dart';
import 'package:colony_design_system/colony_design_system.dart';
import 'package:colony_domain/colony_domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:fallhub/app/localization/app_strings.dart';
import 'package:fallhub/core/providers/app_providers.dart';
import 'package:fallhub/features/integrations/application/integrations_providers.dart';
import 'package:fallhub/features/integrations/application/notification_capture_platform.dart';
import 'package:fallhub/features/integrations/presentation/integrations_screen.dart';

Future<void> _drainTimers(WidgetTester tester) async {
  await tester.pumpWidget(const SizedBox.shrink());
  for (var i = 0; i < 80; i++) {
    await tester.pump(const Duration(milliseconds: 1));
  }
}

void main() {
  testWidgets('IntegrationsScreen shows disclaimer and empty events',
      (tester) async {
    tester.view.physicalSize = const Size(800, 1800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final db = ColonyDatabase.inMemory();
    addTearDown(db.close);
    final repos = ColonyRepositories.create(
      db,
      idGenerator: FixedIdGenerator(List.generate(20, (i) => 'id-$i')),
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
          notificationCapturePlatformProvider.overrideWithValue(
            FakeNotificationCapturePlatform(android: true),
          ),
        ],
        child: MaterialApp(
          theme: ColonyTheme.dark(),
          home: const Scaffold(body: IntegrationsScreen()),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text(AppStrings.integrationsTitle), findsOneWidget);
    expect(find.text(AppStrings.integrationsDisclaimer), findsOneWidget);
    expect(
      find.text(AppStrings.integrationsNotificationsWarning),
      findsOneWidget,
    );
    expect(find.text(AppStrings.integrationsEmpty), findsOneWidget);
    expect(find.text(AppStrings.musicAtlasSpotifyOpenGuide), findsOneWidget);
    expect(find.text(AppStrings.musicAtlasSpotifyNotLinked), findsOneWidget);
    expect(find.byType(Semantics), findsWidgets);

    await _drainTimers(tester);
  });

  testWidgets('IntegrationsScreen shows numbered notification setup',
      (tester) async {
    tester.view.physicalSize = const Size(800, 1800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final db = ColonyDatabase.inMemory();
    addTearDown(db.close);
    final repos = ColonyRepositories.create(
      db,
      idGenerator: FixedIdGenerator(List.generate(20, (i) => 'setup-$i')),
      clock: () => DateTime.utc(2026, 8, 20, 12),
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
          notificationCapturePlatformProvider.overrideWithValue(
            FakeNotificationCapturePlatform(android: true),
          ),
        ],
        child: MaterialApp(
          theme: ColonyTheme.dark(),
          home: const Scaffold(body: IntegrationsScreen()),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(
      find.text(AppStrings.integrationsNotificationsWarning),
      findsOneWidget,
    );
    expect(
      find.text(AppStrings.integrationsNotificationsStep1Title),
      findsOneWidget,
    );
    expect(
      find.text(AppStrings.integrationsNotificationsStep2Title),
      findsOneWidget,
    );
    expect(
      find.text(AppStrings.integrationsNotificationsOpenAndroid),
      findsOneWidget,
    );
    expect(
      find.text(AppStrings.integrationsNotificationsNotReady),
      findsOneWidget,
    );

    await _drainTimers(tester);
  });
}
