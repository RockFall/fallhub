import 'package:colony_database/colony_database.dart';
import 'package:colony_design_system/colony_design_system.dart';
import 'package:colony_domain/colony_domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:fallhub/app/localization/app_strings.dart';
import 'package:fallhub/core/providers/app_providers.dart';
import 'package:fallhub/features/travel/presentation/widgets/edit_trip_sheet.dart';

Future<void> _drainTimers(WidgetTester tester) async {
  await tester.pumpWidget(const SizedBox.shrink());
  for (var i = 0; i < 40; i++) {
    await tester.pump(const Duration(milliseconds: 1));
  }
}

void main() {
  testWidgets('EditTripSheet shows packing list section', (tester) async {
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
        'trip-1',
        'event-1',
        'device-1',
        'event-2',
        'op-1',
        'event-3',
        'inv-1',
        'event-4',
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
    final trip = await repos.trips.create(
      profileId: profile.id,
      title: 'Lisboa',
    );
    final item = await repos.inventory.create(
      profileId: profile.id,
      name: 'Mochila',
      category: InventoryCategory.clothing,
    );
    await repos.trips.linkInventoryItem(
      tripId: trip.id,
      inventoryItemId: item.id,
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          databaseProvider.overrideWithValue(db),
          repositoriesProvider.overrideWithValue(repos),
        ],
        child: MaterialApp(
          theme: ColonyTheme.dark(),
          home: Scaffold(
            body: EditTripSheet(trip: trip),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text(AppStrings.tripPackingList.toUpperCase()), findsOneWidget);
    expect(find.text('Mochila'), findsOneWidget);

    await tester.tap(find.byTooltip(AppStrings.tripUnlinkInventoryItem));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(find.text('Mochila'), findsNothing);
    expect(find.text(AppStrings.tripNoPackingItems), findsOneWidget);
    expect(find.text(AppStrings.tripPackingEmptyHint), findsOneWidget);

    final links = await repos.trips.listInventoryLinks(profile.id);
    expect(links, isEmpty);

    await _drainTimers(tester);
  });

  testWidgets('EditTripSheet packing links item from empty state',
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
        'trip-1',
        'event-1',
        'device-1',
        'event-2',
        'op-1',
        'event-3',
        'inv-1',
        'event-4',
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
    final trip = await repos.trips.create(
      profileId: profile.id,
      title: 'Lisboa',
    );
    await repos.inventory.create(
      profileId: profile.id,
      name: 'Adaptador',
      category: InventoryCategory.electronics,
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          databaseProvider.overrideWithValue(db),
          repositoriesProvider.overrideWithValue(repos),
        ],
        child: MaterialApp(
          theme: ColonyTheme.dark(),
          home: Scaffold(
            body: EditTripSheet(trip: trip),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text(AppStrings.tripNoPackingItems), findsOneWidget);

    await tester.tap(find.byTooltip(AppStrings.tripLinkInventoryItem));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Adaptador').last);
    await tester.pumpAndSettle();

    expect(find.text(AppStrings.tripNoPackingItems), findsNothing);
    expect(find.text('Adaptador'), findsOneWidget);

    final links = await repos.trips.listInventoryLinks(profile.id);
    expect(links, hasLength(1));

    await _drainTimers(tester);
  });

  testWidgets('EditTripSheet packing picker empty shows snackbar',
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
        'trip-1',
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
    final trip = await repos.trips.create(
      profileId: profile.id,
      title: 'Lisboa',
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          databaseProvider.overrideWithValue(db),
          repositoriesProvider.overrideWithValue(repos),
        ],
        child: MaterialApp(
          theme: ColonyTheme.dark(),
          home: Scaffold(
            body: EditTripSheet(trip: trip),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip(AppStrings.tripLinkInventoryItem));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(find.text(AppStrings.tripInventoryPickerEmpty), findsOneWidget);

    await _drainTimers(tester);
  });

  testWidgets('EditTripSheet packing empty shows hint', (tester) async {
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
        'trip-1',
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
    final trip = await repos.trips.create(
      profileId: profile.id,
      title: 'Lisboa',
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          databaseProvider.overrideWithValue(db),
          repositoriesProvider.overrideWithValue(repos),
        ],
        child: MaterialApp(
          theme: ColonyTheme.dark(),
          home: Scaffold(
            body: EditTripSheet(trip: trip),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text(AppStrings.tripNoPackingItems), findsOneWidget);
    expect(find.text(AppStrings.tripPackingEmptyHint), findsOneWidget);

    await _drainTimers(tester);
  });
}
