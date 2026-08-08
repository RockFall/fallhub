import 'package:colony_database/colony_database.dart';
import 'package:colony_design_system/colony_design_system.dart';
import 'package:colony_domain/colony_domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:fallhub/app/localization/app_strings.dart';
import 'package:fallhub/core/providers/app_providers.dart';
import 'package:fallhub/features/relations/presentation/widgets/edit_organization_sheet.dart';

void main() {
  testWidgets('EditOrganizationSheet shows membership section', (tester) async {
    tester.view.physicalSize = const Size(800, 1200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final db = ColonyDatabase.inMemory();
    final repos = ColonyRepositories.create(
      db,
      idGenerator: FixedIdGenerator([
        'profile-1',
        'person-1',
        'event-1',
        'org-1',
        'event-2',
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
    final person = await repos.people.create(
      profileId: profile.id,
      displayName: 'Ana',
    );
    final org = await repos.organizations.create(
      profileId: profile.id,
      name: 'Acme',
      kind: OrganizationKind.company,
    );
    await repos.organizations.linkPerson(
      personId: person.id,
      organizationId: org.id,
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
            body: EditOrganizationSheet(organization: org),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text(AppStrings.organizationEdit), findsOneWidget);
    expect(
      find.text(AppStrings.organizationMembers.toUpperCase()),
      findsOneWidget,
    );
    expect(find.text('Ana'), findsOneWidget);

    await db.close();
  });
}
