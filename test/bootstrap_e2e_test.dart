import 'package:colony_database/colony_database.dart';
import 'package:colony_design_system/colony_design_system.dart';
import 'package:colony_domain/colony_domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:fallhub/app/localization/app_strings.dart';
import 'package:fallhub/core/providers/app_providers.dart';
import 'package:fallhub/features/colony/presentation/colony_screen.dart';
import 'package:fallhub/features/finance/presentation/finance_ledger_screen.dart';
import 'package:fallhub/features/health/presentation/health_screen.dart';
import 'package:fallhub/features/inventory/presentation/inventory_screen.dart';
import 'package:fallhub/features/quests/presentation/quest_board_screen.dart';
import 'package:fallhub/features/relations/presentation/people_screen.dart';
import 'package:fallhub/features/relations/presentation/organizations_screen.dart';
import 'package:fallhub/features/relations/presentation/commitments_screen.dart';
import 'package:fallhub/features/flashcards/presentation/flashcards_hub_screen.dart';
import 'package:fallhub/features/research/presentation/research_list_screen.dart';
import 'package:fallhub/features/music_atlas/presentation/music_atlas_hub_screen.dart';
import 'package:fallhub/features/travel/presentation/travel_screen.dart';
import 'package:fallhub/features/home/presentation/home_maintenance_screen.dart';
import 'package:fallhub/features/zones/presentation/zones_screen.dart';
import 'package:fallhub/features/integrations/application/integrations_providers.dart';
import 'package:fallhub/features/integrations/application/notification_capture_platform.dart';
import 'package:fallhub/features/integrations/presentation/integrations_screen.dart';
import 'package:fallhub/features/music_atlas/application/spotify_runtime.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<void> _flushDisposeTimers(WidgetTester tester) async {
  await tester.pumpWidget(const SizedBox.shrink());
  for (var i = 0; i < 80; i++) {
    await tester.pump(const Duration(milliseconds: 1));
  }
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets(
      'bootstrap: DB + routing opens colony, finance, health, inventory, travel, home, zones, people, organizations, commitments, integrations, research, quests, flashcards, music atlas',
      (tester) async {
    tester.view.physicalSize = const Size(1100, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final db = ColonyDatabase.inMemory();

    final repos = ColonyRepositories.create(
      db,
      idGenerator: FixedIdGenerator(List.generate(30, (i) => 'id-$i')),
      clock: () => DateTime.utc(2026, 8, 7, 12),
    );

    await repos.profiles.create(
      colonyName: 'Colônia E2E',
      displayName: 'Caio',
      timezone: 'UTC',
      locale: 'pt_BR',
      baseCurrency: 'BRL',
    );
    await repos.preferences.save(
      AppPreferences.defaults().copyWith(onboardingCompleted: true),
    );

    late final GoRouter router;
    router = GoRouter(
      initialLocation: '/colony',
      routes: [
        GoRoute(
          path: '/colony',
          builder: (_, __) => const Scaffold(body: ColonyScreen()),
        ),
        GoRoute(
          path: '/resources/finance',
          builder: (_, __) => const Scaffold(body: FinanceLedgerScreen()),
        ),
        GoRoute(
          path: '/resources/health',
          builder: (_, __) => const Scaffold(body: HealthScreen()),
        ),
        GoRoute(
          path: '/resources/inventory',
          builder: (_, __) => const Scaffold(body: InventoryScreen()),
        ),
        GoRoute(
          path: '/resources/travel',
          builder: (_, __) => const Scaffold(body: TravelScreen()),
        ),
        GoRoute(
          path: '/resources/home',
          builder: (_, __) => const Scaffold(body: HomeMaintenanceScreen()),
        ),
        GoRoute(
          path: '/resources/zones',
          builder: (_, __) => const Scaffold(body: ZonesScreen()),
        ),
        GoRoute(
          path: '/relations/people',
          builder: (_, __) => const Scaffold(body: PeopleScreen()),
        ),
        GoRoute(
          path: '/relations/organizations',
          builder: (_, __) => const Scaffold(body: OrganizationsScreen()),
        ),
        GoRoute(
          path: '/relations/commitments',
          builder: (_, __) => const Scaffold(body: CommitmentsScreen()),
        ),
        GoRoute(
          path: '/settings/integrations',
          builder: (_, __) => const Scaffold(body: IntegrationsScreen()),
        ),
        GoRoute(
          path: '/research',
          builder: (_, __) => const Scaffold(body: ResearchListScreen()),
        ),
        GoRoute(
          path: '/quests',
          builder: (_, __) => const Scaffold(body: QuestBoardScreen()),
        ),
        GoRoute(
          path: '/flashcards',
          builder: (_, __) => const Scaffold(body: FlashcardsHubScreen()),
        ),
        GoRoute(
          path: '/research/music-atlas',
          builder: (_, __) => const Scaffold(body: MusicAtlasHubScreen()),
        ),
      ],
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          databaseProvider.overrideWithValue(db),
          notificationCapturePlatformProvider.overrideWithValue(
            FakeNotificationCapturePlatform(android: false),
          ),
          spotifyCatalogPortProvider.overrideWithValue(FakeSpotifyCatalog()),
          spotifyTokenStoreProvider.overrideWithValue(MemorySpotifyTokenStore()),
        ],
        child: MaterialApp.router(
          theme: ColonyTheme.dark(),
          routerConfig: router,
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.textContaining('Colônia E2E'), findsOneWidget);
    expect(find.text(AppStrings.homeMiniAppsTitle), findsOneWidget);
    expect(find.text(AppStrings.habitatTitle), findsWidgets);

    router.go('/resources/finance');
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.text(AppStrings.financeLedgerTitle), findsOneWidget);
    expect(find.text(AppStrings.financeDisclaimer), findsOneWidget);

    router.go('/resources/health');
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.text(AppStrings.healthTitle), findsOneWidget);
    expect(find.text(AppStrings.healthDisclaimer), findsOneWidget);
    expect(find.text(AppStrings.healthEmpty), findsOneWidget);

    router.go('/resources/inventory');
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.text(AppStrings.inventoryTitle), findsOneWidget);
    expect(find.text(AppStrings.inventoryEmpty), findsOneWidget);

    router.go('/resources/travel');
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.text(AppStrings.timelineHubTitle), findsOneWidget);
    expect(find.text(AppStrings.travelDisclaimer), findsOneWidget);
    expect(find.text(AppStrings.travelEmpty), findsOneWidget);

    router.go('/resources/home');
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.text(AppStrings.homeMaintenanceTitle), findsOneWidget);
    expect(find.text(AppStrings.homeMaintenanceDisclaimer), findsOneWidget);
    expect(find.text(AppStrings.homeMaintenanceEmpty), findsOneWidget);

    router.go('/resources/zones');
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.text(AppStrings.zonesTitle), findsOneWidget);
    expect(find.text(AppStrings.zonesDisclaimer), findsOneWidget);
    expect(find.text(AppStrings.zonesEmpty), findsOneWidget);

    router.go('/relations/people');
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.text(AppStrings.peopleTitle), findsOneWidget);
    expect(find.text(AppStrings.peopleDisclaimer), findsOneWidget);
    expect(find.text(AppStrings.peopleEmpty), findsOneWidget);

    router.go('/relations/organizations');
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.text(AppStrings.organizationsTitle), findsOneWidget);
    expect(find.text(AppStrings.organizationsDisclaimer), findsOneWidget);
    expect(find.text(AppStrings.organizationsEmpty), findsOneWidget);

    router.go('/relations/commitments');
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.text(AppStrings.commitmentsTitle), findsOneWidget);
    expect(find.text(AppStrings.commitmentsDisclaimer), findsOneWidget);
    expect(find.text(AppStrings.commitmentsEmpty), findsOneWidget);

    router.go('/settings/integrations');
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.text(AppStrings.integrationsTitle), findsOneWidget);
    expect(find.text(AppStrings.integrationsDisclaimer), findsOneWidget);
    expect(find.text(AppStrings.integrationsEmpty), findsOneWidget);

    router.go('/research');
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.text(AppStrings.researchListEmpty), findsOneWidget);

    router.go('/quests');
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.text(AppStrings.questBoardEmpty), findsOneWidget);

    router.go('/flashcards');
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.text(AppStrings.flashcardsEmpty), findsOneWidget);
    expect(find.text(AppStrings.flashcardsStudyNow), findsOneWidget);

    router.go('/research/music-atlas');
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.text(AppStrings.musicAtlasTitle), findsWidgets);
    expect(find.text(AppStrings.musicAtlasEmpty), findsOneWidget);

    await _flushDisposeTimers(tester);
    await db.close();
  });
}
