import 'package:colony_database/colony_database.dart';
import 'package:colony_design_system/colony_design_system.dart';
import 'package:colony_domain/colony_domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:fallhub/app/localization/app_strings.dart';
import 'package:fallhub/core/providers/app_providers.dart';
import 'package:fallhub/features/relations/presentation/widgets/edit_commitment_sheet.dart';

Future<void> _drainTimers(WidgetTester tester) async {
  await tester.pumpWidget(const SizedBox.shrink());
  for (var i = 0; i < 40; i++) {
    await tester.pump(const Duration(milliseconds: 1));
  }
}

void main() {
  testWidgets('EditCommitmentSheet clears linked quest on save',
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
        'quest-1',
        'event-q',
        'cmt-1',
        'event-c',
        'device-1',
        'event-d',
        'op-1',
        'event-o',
        'event-save',
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
    final quest = await repos.quests.create(
      profileId: profile.id,
      title: 'Missão Alpha',
      purpose: 'Propósito',
    );
    final commitment = await repos.commitments.create(
      profileId: profile.id,
      description: 'Enviar PDF',
      madeToLabel: 'Ana',
      linkedQuestId: quest.id,
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
            body: EditCommitmentSheet(commitment: commitment),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text(AppStrings.commitmentLinkedQuestHint), findsOneWidget);

    await tester.tap(find.byType(DropdownButtonFormField<String?>));
    await tester.pumpAndSettle();
    await tester.tap(find.text(AppStrings.commitmentNoQuestLink).last);
    await tester.pumpAndSettle();

    await tester.tap(find.text(AppStrings.save));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    final saved = (await repos.commitments.listAll(profile.id)).single;
    expect(saved.linkedQuestId, isNull);

    await _drainTimers(tester);
  });
}
