import 'package:colony_database/colony_database.dart';
import 'package:colony_design_system/colony_design_system.dart';
import 'package:colony_domain/colony_domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:fallhub/core/providers/app_providers.dart';
import 'package:fallhub/features/colony/presentation/widgets/colony_terminal_home.dart';

/// Phone-framed preview of the Colônia terminal home (designer reference).
///
///   flutter run -d linux -t tool/preview_terminal_home.dart
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  var n = 0;
  final db = ColonyDatabase.inMemory();
  final repos = ColonyRepositories.create(
    db,
    idGenerator: UuidIdGenerator(() => 'id-${++n}'),
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

  runApp(
    ProviderScope(
      overrides: [
        databaseProvider.overrideWithValue(db),
        clockProvider.overrideWithValue(() => DateTime.utc(2026, 5, 19, 12, 4)),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: ColonyTheme.dark(),
        home: ColoredBox(
          color: const Color(0xFF050608),
          child: Center(
            child: SizedBox(
              width: 390,
              height: 844,
              child: Scaffold(
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
        ),
      ),
    ),
  );
}
