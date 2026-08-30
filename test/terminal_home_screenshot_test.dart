import 'dart:io';
import 'dart:ui' as ui;

import 'package:colony_database/colony_database.dart';
import 'package:colony_design_system/colony_design_system.dart';
import 'package:colony_domain/colony_domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:fallhub/core/providers/app_providers.dart';
import 'package:fallhub/features/colony/presentation/widgets/colony_terminal_home.dart';

/// Local visual dump used to iterate against the designer reference.
/// Run:
///   flutter test test/terminal_home_screenshot_test.dart
void main() {
  testWidgets('dumps terminal home screenshot', (tester) async {
    tester.view.physicalSize = const Size(390, 1180);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final db = ColonyDatabase.inMemory();
    addTearDown(db.close);
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
    await repos.tasks.capture(profileId: profile.id, title: 'Inbox a');
    await repos.tasks.capture(profileId: profile.id, title: 'Inbox b');
    await repos.tasks.capture(profileId: profile.id, title: 'Inbox c');
    await repos.tasks.capture(profileId: profile.id, title: 'Inbox d');

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
                child: RepaintBoundary(
                  child: ColonyTerminalHome(profile: profile),
                ),
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

    expect(find.textContaining('CAIO'), findsWidgets);
    expect(find.text('SONO'), findsOneWidget);
    expect(find.text('NOW'), findsOneWidget);

    final boundary = tester.renderObject<RenderRepaintBoundary>(
      find.byType(RepaintBoundary).first,
    );
    final image = await tester.runAsync(() => boundary.toImage(pixelRatio: 2));
    if (image == null) return;
    final bytes = await tester.runAsync(
      () async => (await image.toByteData(
        format: ui.ImageByteFormat.png,
      ))!.buffer.asUint8List(),
    );
    if (bytes == null) return;
    final out = File('/opt/cursor/artifacts/terminal_home_v1.png');
    out.parent.createSync(recursive: true);
    await out.writeAsBytes(bytes);
    await File('/tmp/terminal_home_v1.png').writeAsBytes(bytes);
  });
}
