import 'package:colony_database/colony_database.dart';
import 'package:colony_design_system/colony_design_system.dart';
import 'package:colony_domain/colony_domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:fallhub/app/localization/app_locale.dart';
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
  testWidgets('IntegrationsScreen shows disclaimer and empty events', (
    tester,
  ) async {
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
    await repos.preferences.save(
      AppPreferences.defaults().copyWith(onboardingCompleted: true),
    );

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
    expect(
      find.text(AppStrings.integrationsGoogleCalendar.toUpperCase()),
      findsOneWidget,
    );
    expect(
      find.text(AppStrings.integrationsGoogleCalendarSaveAndSync),
      findsOneWidget,
    );
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

  testWidgets('IntegrationsScreen shows numbered notification setup', (
    tester,
  ) async {
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
    await repos.preferences.save(
      AppPreferences.defaults().copyWith(onboardingCompleted: true),
    );

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

  testWidgets('IntegrationsScreen filters captures by an inclusive day range', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(800, 8000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final db = ColonyDatabase.inMemory();
    addTearDown(db.close);
    final posted = DateTime(2026, 10, 30, 18, 5);
    final repos = ColonyRepositories.create(
      db,
      idGenerator: FixedIdGenerator(List.generate(40, (i) => 'range-$i')),
      clock: () => DateTime.utc(2026, 10, 31, 12),
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
    await repos.integrations.setConsentEnabled(
      profileId: profile.id,
      kind: IntegrationKind.notificationListener,
      enabled: true,
    );
    const body = 'texto completo da notificação de 30/10';
    await repos.integrations.ingestCapturedNotification(
      profileId: profile.id,
      payload: NotificationCapturePayload(
        nativeKey: 'oct-30',
        packageName: 'com.whatsapp',
        title: 'Aviso de 30/10',
        text: body,
        postedAt: posted.toUtc(),
      ),
    );
    await repos.integrations.ingestCapturedNotification(
      profileId: profile.id,
      payload: NotificationCapturePayload(
        nativeKey: 'oct-28',
        packageName: 'com.whatsapp',
        title: 'Aviso de 28/10',
        text: 'fora da faixa',
        postedAt: DateTime(2026, 10, 28, 11).toUtc(),
      ),
    );

    final dayLabel = AppLocale.date('dd/MM/yyyy').format(posted);
    final whenLabel = AppLocale.date('dd/MM/yyyy HH:mm')
        .format(posted.toUtc().toLocal());

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          databaseProvider.overrideWithValue(db),
          repositoriesProvider.overrideWithValue(repos),
          clockProvider.overrideWithValue(() => DateTime(2026, 10, 31, 15)),
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

    expect(find.text('Aviso de 30/10'), findsOneWidget);
    expect(find.text('Aviso de 28/10'), findsOneWidget);

    await tester.tap(
      find.widgetWithText(
        OutlinedButton,
        AppStrings.integrationsNotificationsRangeFrom,
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(DatePickerDialog), findsOneWidget);
    await tester.tap(find.text('30').last);
    await tester.pump();
    await tester.tap(find.text('OK'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('De: $dayLabel'), findsOneWidget);
    expect(find.text('Até: $dayLabel'), findsOneWidget);
    expect(find.text('Aviso de 30/10'), findsOneWidget);
    expect(find.text('Aviso de 28/10'), findsNothing);
    expect(
      find.text(AppStrings.integrationsNotificationsRangeCount(1)),
      findsOneWidget,
    );

    await tester.tap(find.text('Aviso de 30/10'));
    await tester.pumpAndSettle();
    expect(find.byType(SelectableText), findsOneWidget);
    expect(find.text(body), findsWidgets);
    expect(find.text(whenLabel), findsWidgets);

    await tester.tap(find.text(AppStrings.close));
    await tester.pumpAndSettle();

    await tester.tap(find.text(AppStrings.integrationsNotificationsRangeClear));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('Aviso de 28/10'), findsOneWidget);
    expect(find.text('Aviso de 30/10'), findsOneWidget);

    await _drainTimers(tester);
  });
}
