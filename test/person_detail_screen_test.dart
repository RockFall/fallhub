import 'package:colony_database/colony_database.dart';
import 'package:colony_design_system/colony_design_system.dart';
import 'package:colony_domain/colony_domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:fallhub/app/localization/app_strings.dart';
import 'package:fallhub/core/providers/app_providers.dart';
import 'package:fallhub/features/relations/presentation/people_screen.dart';
import 'package:fallhub/features/relations/presentation/person_detail_screen.dart';

Future<void> _flush(WidgetTester tester) async {
  await tester.pumpWidget(const SizedBox.shrink());
  for (var i = 0; i < 40; i++) {
    await tester.pump(const Duration(milliseconds: 1));
  }
}

void main() {
  testWidgets('PersonDetailScreen shows dossier and add-to-friendships',
      (tester) async {
    tester.view.physicalSize = const Size(800, 1400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final db = ColonyDatabase.inMemory();
    final repos = ColonyRepositories.create(
      db,
      idGenerator: FixedIdGenerator(['profile-1', 'person-1', 'event-1']),
      clock: () => DateTime.utc(2026, 8, 23, 12),
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
    final person = await repos.people.create(
      profileId: profile.id,
      displayName: 'Ana Silva',
      preferredName: 'Aninha',
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [databaseProvider.overrideWithValue(db)],
        child: MaterialApp(
          theme: ColonyTheme.dark(),
          home: Scaffold(body: PersonDetailScreen(personId: person.id)),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('Ana Silva'), findsOneWidget);
    expect(find.text('Aninha'), findsOneWidget);
    expect(find.text(AppStrings.personAddToFriendships), findsOneWidget);
    expect(find.text(AppStrings.personInteractionsEmpty), findsOneWidget);

    await _flush(tester);
    await db.close();
  });

  testWidgets('PeopleScreen opens person detail on tap', (tester) async {
    tester.view.physicalSize = const Size(800, 1400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final db = ColonyDatabase.inMemory();
    final repos = ColonyRepositories.create(
      db,
      idGenerator: FixedIdGenerator(['profile-1', 'person-1', 'event-1']),
      clock: () => DateTime.utc(2026, 8, 23, 12),
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
    await repos.people.create(
      profileId: profile.id,
      displayName: 'Ana Silva',
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [databaseProvider.overrideWithValue(db)],
        child: MaterialApp(
          theme: ColonyTheme.dark(),
          home: const Scaffold(body: PeopleScreen()),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    await tester.tap(find.text('Ana Silva'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text(AppStrings.personAddToFriendships), findsOneWidget);

    await _flush(tester);
    await db.close();
  });
}
