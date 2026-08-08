import 'package:colony_database/colony_database.dart';
import 'package:colony_design_system/colony_design_system.dart';
import 'package:colony_domain/colony_domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:fallhub/app/localization/app_strings.dart';
import 'package:fallhub/core/providers/app_providers.dart';
import 'package:fallhub/features/quests/presentation/widgets/create_quest_sheet.dart';

void main() {
  testWidgets('CreateQuestSheet saves quest with criteria', (tester) async {
    tester.view.physicalSize = const Size(800, 1200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final db = ColonyDatabase.inMemory();
    addTearDown(db.close);

    final repos = ColonyRepositories.create(
      db,
      idGenerator: FixedIdGenerator(['profile-1', 'quest-1', 'event-1']),
      clock: () => DateTime.utc(2026, 8, 6, 12),
    );

    final profile = await repos.profiles.create(
      colonyName: 'Test',
      displayName: 'Caio',
      timezone: 'UTC',
      locale: 'pt_BR',
      baseCurrency: 'BRL',
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [databaseProvider.overrideWithValue(db)],
        child: MaterialApp(
          theme: ColonyTheme.dark(),
          home: const Scaffold(body: CreateQuestSheet()),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byType(TextField).at(0),
      'Viagem internacional',
    );
    await tester.enterText(
      find.byType(TextField).at(1),
      'Organizar documentação',
    );
    await tester.enterText(
      find.byType(TextField).at(2),
      'Passaporte válido',
    );

    await tester.ensureVisible(find.text(AppStrings.questSaveDraft));
    await tester.tap(find.text(AppStrings.questSaveDraft));
    await tester.pumpAndSettle();

    final quests = await repos.quests.listAll(profile.id);
    expect(quests, hasLength(1));
    expect(quests.first.title, 'Viagem internacional');
    expect(quests.first.purpose, 'Organizar documentação');
    expect(quests.first.successCriteria, ['Passaporte válido']);
    expect(quests.first.risks, isEmpty);
    expect(quests.first.status, QuestStatus.draft);
  });
}
