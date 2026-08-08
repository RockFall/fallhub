import 'package:colony_database/colony_database.dart';
import 'package:colony_design_system/colony_design_system.dart';
import 'package:colony_domain/colony_domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:fallhub/app/localization/app_strings.dart';
import 'package:fallhub/core/providers/app_providers.dart';
import 'package:fallhub/features/zones/presentation/zones_screen.dart';

void main() {
  testWidgets('ZonesScreen shows empty state and disclaimer', (tester) async {
    tester.view.physicalSize = const Size(800, 1200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final db = ColonyDatabase.inMemory();
    final repos = ColonyRepositories.create(
      db,
      idGenerator: FixedIdGenerator(['profile-1']),
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
        ],
        child: MaterialApp(
          theme: ColonyTheme.dark(),
          home: const Scaffold(body: ZonesScreen()),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text(AppStrings.zonesTitle), findsOneWidget);
    expect(find.text(AppStrings.zonesDisclaimer), findsOneWidget);
    expect(find.text(AppStrings.zonesEmpty), findsOneWidget);

    await db.close();
  });

  testWidgets('ZonesScreen subtitle shows unavailable work types',
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
        'zone-1',
        'event-1',
        'device-1',
        'event-2',
        'op-1',
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
    await repos.contextZones.create(
      profileId: profile.id,
      name: 'Avião',
      capabilities: const ['leitura'],
      unavailableWorkTypes: const ['restRecreation'],
      connectivity: ZoneConnectivity.limited,
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          databaseProvider.overrideWithValue(db),
          repositoriesProvider.overrideWithValue(repos),
        ],
        child: MaterialApp(
          theme: ColonyTheme.dark(),
          home: const Scaffold(body: ZonesScreen()),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Avião'), findsOneWidget);
    expect(
      find.textContaining(
        AppStrings.zoneUnavailableWorkTypesLabel(['restRecreation']),
      ),
      findsOneWidget,
    );
    expect(find.textContaining('leitura'), findsOneWidget);

    await db.close();
  });

  testWidgets('ZonesScreen combines capabilities and unavailable in subtitle',
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
        'zone-1',
        'event-1',
        'device-1',
        'event-2',
        'op-1',
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
    await repos.contextZones.create(
      profileId: profile.id,
      name: 'Trem',
      capabilities: const ['notas', 'leitura'],
      unavailableWorkTypes: const ['exercise', 'music'],
      connectivity: ZoneConnectivity.online,
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          databaseProvider.overrideWithValue(db),
          repositoriesProvider.overrideWithValue(repos),
        ],
        child: MaterialApp(
          theme: ColonyTheme.dark(),
          home: const Scaffold(body: ZonesScreen()),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.textContaining('notas, leitura'),
      findsOneWidget,
    );
    expect(
      find.textContaining(
        AppStrings.zoneUnavailableWorkTypesLabel(['exercise', 'music']),
      ),
      findsOneWidget,
    );

    await db.close();
  });
}
