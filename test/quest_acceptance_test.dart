import 'package:colony_database/colony_database.dart';

import 'package:colony_design_system/colony_design_system.dart';

import 'package:colony_domain/colony_domain.dart';

import 'package:flutter/material.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:flutter_test/flutter_test.dart';



import 'package:fallhub/app/localization/app_strings.dart';

import 'package:fallhub/core/providers/app_providers.dart';

import 'package:fallhub/features/quests/presentation/quest_detail_screen.dart';

import 'quest_detail_test_helpers.dart';

import 'package:fallhub/features/quests/presentation/widgets/accept_quest_sheet.dart';

import 'package:fallhub/features/quests/presentation/widgets/create_quest_sheet.dart';



void main() {

  testWidgets('AcceptQuestSheet cancel does not activate quest', (tester) async {

    tester.view.physicalSize = const Size(800, 1200);

    tester.view.devicePixelRatio = 1.0;

    addTearDown(tester.view.resetPhysicalSize);

    addTearDown(tester.view.resetDevicePixelRatio);



    await tester.pumpWidget(

      MaterialApp(

        theme: ColonyTheme.dark(),

        home: Scaffold(

          body: Builder(

            builder: (context) => FilledButton(

              onPressed: () => AcceptQuestSheet.show(

                context,

                initialPurpose: 'Propósito inicial',

              ),

              child: const Text('open'),

            ),

          ),

        ),

      ),

    );

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));



    await tester.tap(find.text('open'));

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));



    expect(find.text(AppStrings.questAcceptTitle), findsOneWidget);

    expect(find.text('Propósito inicial'), findsOneWidget);



    await tester.tap(find.text(AppStrings.questAcceptCancel));

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));



    expect(find.text(AppStrings.questAcceptTitle), findsNothing);

  });



  testWidgets('QuestDetailScreen accept flow activates quest with assumptions',

      (tester) async {

    tester.view.physicalSize = const Size(800, 1400);

    tester.view.devicePixelRatio = 1.0;

    addTearDown(tester.view.resetPhysicalSize);

    addTearDown(tester.view.resetDevicePixelRatio);



    final db = ColonyDatabase.inMemory();

    final repos = ColonyRepositories.create(

      db,

      idGenerator: FixedIdGenerator([

        'profile-1',

        'quest-main',

        'event-1',

        'event-2',

      ]),

      clock: () => DateTime.utc(2026, 8, 6, 12),

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

      title: 'Viagem',

      purpose: 'Organizar documentos',

      status: QuestStatus.draft,

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

            body: QuestDetailScreen(questId: quest.id.value),

          ),

        ),

      ),

    );

    await settleQuestDetail(tester);
    await waitForQuestDetailStreams(tester);

    await tester.ensureVisible(
      find.widgetWithText(FilledButton, AppStrings.questAcceptAndActivate),
    );
    await tester.tap(
      find.widgetWithText(FilledButton, AppStrings.questAcceptAndActivate),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text(AppStrings.questAcceptTitle), findsOneWidget);



    await tester.enterText(

      find.byType(TextField).first,

      'Tenho tempo esta semana',

    );

    await tester.tap(find.text(AppStrings.questAcceptConfirm));

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));



    expect(find.text(AppStrings.questAcceptedAt.toUpperCase()), findsOneWidget);

    expect(find.text('Tenho tempo esta semana'), findsWidgets);



    final loaded = await repos.quests.getById(quest.id);

    expect(loaded!.status, QuestStatus.active);

    expect(loaded.acceptedAt, DateTime.utc(2026, 8, 6, 12));

    expect(loaded.acceptanceAssumptions, ['Tenho tempo esta semana']);

    await tearDownQuestDetail(tester, db);

  });



  testWidgets('CreateQuestSheet create and activate passes through acceptance sheet',

      (tester) async {

    tester.view.physicalSize = const Size(800, 1400);

    tester.view.devicePixelRatio = 1.0;

    addTearDown(tester.view.resetPhysicalSize);

    addTearDown(tester.view.resetDevicePixelRatio);



    final db = ColonyDatabase.inMemory();

    final repos = ColonyRepositories.create(

      db,

      idGenerator: FixedIdGenerator([

        'profile-1',

        'quest-1',

        'event-1',

        'event-2',

      ]),

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

        overrides: [
          databaseProvider.overrideWithValue(db),
          repositoriesProvider.overrideWithValue(repos),
        ],

        child: MaterialApp(

          theme: ColonyTheme.dark(),

          home: const Scaffold(body: CreateQuestSheet()),

        ),

      ),

    );

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));



    await tester.enterText(find.byType(TextField).at(0), 'Nova missão');

    await tester.enterText(find.byType(TextField).at(1), 'Propósito claro');



    await tester.ensureVisible(find.text(AppStrings.questCreateAndActivate));

    await tester.tap(find.text(AppStrings.questCreateAndActivate));

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));



    expect(find.text(AppStrings.questAcceptTitle), findsOneWidget);



    await tester.tap(find.text(AppStrings.questAcceptConfirm));

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));



    final quests = await repos.quests.listAll(profile.id);

    expect(quests, hasLength(1));

    expect(quests.first.status, QuestStatus.active);

    expect(quests.first.acceptanceAssumptions, ['Propósito claro']);

    await tester.pumpWidget(const SizedBox.shrink());
    await db.close();
  });

  testWidgets('QuestDetailScreen paused resume skips accept sheet', (tester) async {
    tester.view.physicalSize = const Size(800, 1400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final db = ColonyDatabase.inMemory();

    final repos = ColonyRepositories.create(
      db,
      idGenerator: FixedIdGenerator([
        'profile-1',
        'quest-main',
        'event-1',
        'event-2',
        'event-3',
      ]),
      clock: () => DateTime.utc(2026, 8, 6, 12),
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

    var quest = await repos.quests.create(
      profileId: profile.id,
      title: 'Pausada',
      purpose: 'Retomar sem aceite',
      status: QuestStatus.draft,
    );
    quest = await repos.quests.acceptAndActivate(
      quest,
      acceptanceAssumptions: ['Premissa original'],
    );
    quest = await repos.quests.updateStatus(
      quest,
      QuestStatus.paused,
      pauseReason: 'Férias',
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
            body: QuestDetailScreen(questId: quest.id.value),
          ),
        ),
      ),
    );
    await settleQuestDetail(tester);

    await tester.ensureVisible(find.text(AppStrings.questResume));
    await tester.tap(find.text(AppStrings.questResume));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text(AppStrings.questAcceptTitle), findsNothing);
    expect(find.text(AppStrings.questStatusLabel(QuestStatus.active)), findsWidgets);

    final loaded = await repos.quests.getById(quest.id);
    expect(loaded!.status, QuestStatus.active);

    await tearDownQuestDetail(tester, db);
  });

}

