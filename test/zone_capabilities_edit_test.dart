import 'package:colony_database/colony_database.dart';
import 'package:colony_design_system/colony_design_system.dart';
import 'package:colony_domain/colony_domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:fallhub/app/localization/app_strings.dart';
import 'package:fallhub/core/providers/app_providers.dart';
import 'package:fallhub/features/zones/presentation/widgets/edit_zone_sheet.dart';

Future<void> _drainTimers(WidgetTester tester) async {
  await tester.pumpWidget(const SizedBox.shrink());
  for (var i = 0; i < 40; i++) {
    await tester.pump(const Duration(milliseconds: 1));
  }
}

void main() {
  testWidgets('EditZoneSheet saves capabilities and unavailable work types',
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
        'zone-1',
        'event-1',
        'device-1',
        'event-2',
        'op-1',
        'event-3',
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
    final zone = await repos.contextZones.create(
      profileId: profile.id,
      name: 'Avião',
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
          home: Scaffold(
            body: EditZoneSheet(zone: zone),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text(AppStrings.zoneCapabilitiesHint), findsOneWidget);
    expect(find.text(AppStrings.zoneUnavailableWorkTypesHint), findsOneWidget);

    final fields = find.byType(TextField);
    // name, location, capabilities, unavailable, notes
    await tester.enterText(fields.at(2), 'leitura, notas');
    await tester.enterText(fields.at(3), 'restRecreation');
    await tester.tap(find.text(AppStrings.save));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    final saved = (await repos.contextZones.listAll(profile.id)).single;
    expect(saved.capabilities, ['leitura', 'notas']);
    expect(saved.unavailableWorkTypes, ['restRecreation']);

    await _drainTimers(tester);
  });
}
