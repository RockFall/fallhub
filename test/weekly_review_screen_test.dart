import 'package:colony_database/colony_database.dart';

import 'package:colony_design_system/colony_design_system.dart';

import 'package:colony_domain/colony_domain.dart';

import 'package:flutter/material.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:flutter_test/flutter_test.dart';



import 'package:fallhub/app/localization/app_strings.dart';

import 'package:fallhub/core/providers/app_providers.dart';

import 'package:fallhub/features/pawn/presentation/weekly_review_screen.dart';



void main() {

  testWidgets('WeeklyReviewScreen loads existing review and saves', (tester) async {

    tester.view.physicalSize = const Size(800, 1200);

    tester.view.devicePixelRatio = 1.0;

    addTearDown(tester.view.resetPhysicalSize);

    addTearDown(tester.view.resetDevicePixelRatio);



    final db = ColonyDatabase.inMemory();

    addTearDown(db.close);



    final repos = ColonyRepositories.create(

      db,

      idGenerator: FixedIdGenerator(['profile-1', 'weekly-1', 'event-1', 'event-2']),

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

      weekStartsOnMonday: true,

    ));

    await repos.weeklyReviews.save(

      profileId: profile.id,

      weekStartDate: DateTime.utc(2026, 8, 3),

      facts: 'Conteúdo existente',

    );



    await tester.pumpWidget(

      ProviderScope(

        overrides: [databaseProvider.overrideWithValue(db)],

        child: MaterialApp(

          theme: ColonyTheme.dark(),

          home: Builder(

            builder: (context) => Scaffold(

              body: FilledButton(

                onPressed: () => Navigator.of(context).push(

                  MaterialPageRoute<void>(

                    builder: (_) => const WeeklyReviewScreen(),

                  ),

                ),

                child: const Text('open'),

              ),

            ),

          ),

        ),

      ),

    );

    await tester.tap(find.text('open'));

    await tester.pumpAndSettle();



    expect(find.text(AppStrings.weeklyReview), findsOneWidget);

    expect(find.text('Conteúdo existente'), findsOneWidget);



    await tester.enterText(find.byType(TextField).at(1), 'Vitória da semana');

    await tester.tap(find.text(AppStrings.save));

    await tester.pumpAndSettle();



    final saved = await repos.weeklyReviews.getForWeek(

      profile.id,

      DateTime.utc(2026, 8, 3),

    );

    expect(saved!.wins, 'Vitória da semana');

  });



  testWidgets('WeeklyReviewScreen shows empty form for new week', (tester) async {

    tester.view.physicalSize = const Size(800, 1200);

    tester.view.devicePixelRatio = 1.0;

    addTearDown(tester.view.resetPhysicalSize);

    addTearDown(tester.view.resetDevicePixelRatio);



    final db = ColonyDatabase.inMemory();

    addTearDown(db.close);



    final repos = ColonyRepositories.create(

      db,

      idGenerator: FixedIdGenerator(['profile-1', 'weekly-1', 'event-1', 'event-2']),

      clock: () => DateTime.utc(2026, 8, 6, 12),

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

        overrides: [databaseProvider.overrideWithValue(db)],

        child: MaterialApp(

          theme: ColonyTheme.dark(),

          home: const WeeklyReviewScreen(),

        ),

      ),

    );

    await tester.pumpAndSettle();



    expect(find.text(AppStrings.weeklyReviewIntro), findsOneWidget);

    expect(find.text(AppStrings.reviewFacts), findsOneWidget);

    expect(find.text(AppStrings.reviewNextWeek), findsOneWidget);

  });

}


