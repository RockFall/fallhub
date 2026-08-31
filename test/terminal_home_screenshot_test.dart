import 'package:colony_database/colony_database.dart';
import 'package:colony_design_system/colony_design_system.dart';
import 'package:colony_domain/colony_domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:fallhub/app/localization/app_strings.dart';
import 'package:fallhub/core/providers/app_providers.dart';
import 'package:fallhub/features/colony/presentation/widgets/colony_terminal_home.dart';

Future<ColonyProfile> _seed(ColonyDatabase db) async {
  final repos = ColonyRepositories.create(
    db,
    idGenerator: FixedIdGenerator(List.generate(80, (i) => 'id-$i')),
    clock: () => DateTime.utc(2026, 5, 19, 12, 4),
  );
  final profile = await repos.profiles.create(
    colonyName: 'Colônia Nova',
    displayName: 'Caio',
    timezone: 'UTC',
    locale: 'pt_BR',
    baseCurrency: 'BRL',
  );
  await repos.preferences.save(
    AppPreferences.defaults().copyWith(onboardingCompleted: true),
  );
  await repos.schedule.create(
    profileId: profile.id,
    startAt: DateTime.utc(2026, 5, 19, 0),
    endAt: DateTime.utc(2026, 5, 19, 7, 30),
    mode: ScheduleBlockMode.sleep,
  );
  await repos.schedule.create(
    profileId: profile.id,
    startAt: DateTime.utc(2026, 5, 19, 7, 30),
    endAt: DateTime.utc(2026, 5, 19, 12),
    mode: ScheduleBlockMode.focus,
  );
  await repos.schedule.create(
    profileId: profile.id,
    startAt: DateTime.utc(2026, 5, 19, 14, 30),
    endAt: DateTime.utc(2026, 5, 19, 16),
    mode: ScheduleBlockMode.meeting,
  );
  await repos.schedule.create(
    profileId: profile.id,
    startAt: DateTime.utc(2026, 5, 19, 19),
    endAt: DateTime.utc(2026, 5, 19, 20),
    mode: ScheduleBlockMode.recreation,
  );
  await repos.tasks.createSimple(
    profileId: profile.id,
    title: 'Ensaio cap. 3',
  );
  for (final title in ['Inbox a', 'Inbox b', 'Inbox c', 'Inbox d']) {
    await repos.tasks.capture(profileId: profile.id, title: title);
  }
  return profile;
}

void main() {
  testWidgets('terminal home matches mockup content (date, agenda, work, nav)',
      (tester) async {
    tester.view.physicalSize = const Size(390, 1400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final db = ColonyDatabase.inMemory();
    addTearDown(db.close);
    final profile = await _seed(db);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          databaseProvider.overrideWithValue(db),
          clockProvider.overrideWithValue(
            () => DateTime.utc(2026, 5, 19, 12, 4),
          ),
        ],
        child: MaterialApp(
          theme: ColonyTheme.dark(),
          home: Scaffold(
            backgroundColor: ColonyColors.void_,
            body: ColonyVoidBackdrop(
              child: SafeArea(
                child: ColonyTerminalHome(profile: profile),
              ),
            ),
            bottomNavigationBar: ColonyMainTabBar(
              height: 64,
              currentRoute: '/colony',
              onSelect: (_) {},
              tabs: const [
                ColonyMainTab(
                  label: 'Colônia',
                  icon: Icons.groups,
                  route: '/colony',
                  iconName: 'people',
                ),
                ColonyMainTab(
                  label: 'Perfil',
                  icon: Icons.person,
                  route: '/pawn',
                  iconName: 'person',
                ),
                ColonyMainTab(
                  label: 'Trabalho',
                  icon: Icons.work,
                  route: '/work',
                  iconName: 'briefcase',
                ),
                ColonyMainTab(
                  label: 'Missões',
                  icon: Icons.flag,
                  route: '/quests',
                  iconName: 'flag',
                ),
                ColonyMainTab(
                  label: 'Mais',
                  icon: Icons.more_horiz,
                  route: '/more',
                  iconName: 'more',
                ),
              ],
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(tester.takeException(), isNull);
    expect(find.textContaining('CAIO'), findsWidgets);
    expect(find.textContaining('19 DE MAIO'), findsOneWidget);
    expect(find.text('SONO'), findsOneWidget);
    expect(find.text('FOCO'), findsOneWidget);
    expect(find.text('AULA'), findsOneWidget);
    expect(find.text('JANTAR'), findsOneWidget);
    expect(find.text('NOW'), findsOneWidget);
    expect(find.text('Ensaio cap. 3'), findsOneWidget);
    expect(find.text(AppStrings.homeSleepCheckIn), findsOneWidget);
    expect(find.text(AppStrings.homeInboxCount(4)), findsOneWidget);
    expect(find.text(AppStrings.pawn.toUpperCase()), findsWidgets);
    expect(find.text(AppStrings.habitatTitle.toUpperCase()), findsWidgets);
    expect(find.text(AppStrings.homeActionOpen.toUpperCase()), findsOneWidget);

    await tester.pumpWidget(const SizedBox.shrink());
    for (var i = 0; i < 80; i++) {
      await tester.pump(const Duration(milliseconds: 1));
    }
  });
}
