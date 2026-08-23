import 'package:colony_design_system/colony_design_system.dart';
import 'package:colony_domain/colony_domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/localization/app_strings.dart';
import '../../core/providers/app_providers.dart';
import '../../core/providers/feature_controllers.dart';
import '../../features/chronicle/presentation/chronicle_screen.dart';
import '../../features/colony/presentation/colony_screen.dart';
import '../../features/habitat/application/habitat_chrome_provider.dart';
import '../../features/habitat/presentation/character_create_screen.dart';
import '../../features/habitat/presentation/habitat_screen.dart';
import '../../features/habitat/presentation/widgets/mini_habitat_badge.dart';
import '../../features/inbox/presentation/inbox_screen.dart';
import '../../features/onboarding/presentation/onboarding_screen.dart';
import '../../features/pawn/presentation/daily_review_screen.dart';
import '../../features/pawn/presentation/weekly_review_screen.dart';
import '../../features/pawn/presentation/pawn_screen.dart';
import '../../features/settings/presentation/settings_screen.dart';
import '../../features/tasks/presentation/task_inspect_screen.dart';
import '../../features/work/presentation/schedule_screen.dart';
import '../../features/work/presentation/work_screen.dart';
import '../bootstrap/boot_screen.dart';
import '../../features/projects/presentation/project_detail_screen.dart';
import '../../features/projects/presentation/project_list_screen.dart';
import '../../features/quests/presentation/quest_board_screen.dart';
import '../../features/quests/presentation/quest_detail_screen.dart';
import '../../features/decisions/presentation/decision_list_screen.dart';
import '../../features/research/presentation/research_list_screen.dart';
import '../../features/research/presentation/research_node_detail_screen.dart';
import '../../features/music_atlas/presentation/music_album_screen.dart';
import '../../features/music_atlas/presentation/music_atlas_explore_screen.dart';
import '../../features/music_atlas/presentation/music_atlas_hub_screen.dart';
import '../../features/music_atlas/presentation/music_constellation_screen.dart';
import '../../features/music_atlas/presentation/music_node_inspect_screen.dart';
import '../../features/flashcards/presentation/flashcards_hub_screen.dart';
import '../../features/flashcards/presentation/flashcard_deck_screen.dart';
import '../../features/flashcards/presentation/flashcard_tag_screen.dart';
import '../../features/flashcards/presentation/knowledge_area_screen.dart';
import '../../features/flashcards/presentation/study_session_screen.dart';
import '../../features/finance/presentation/finance_ledger_screen.dart';
import '../../features/health/presentation/health_screen.dart';
import '../../features/inventory/presentation/inventory_screen.dart';
import '../../features/relations/presentation/circle_detail_screen.dart';
import '../../features/relations/presentation/circles_map_screen.dart';
import '../../features/relations/presentation/commitments_screen.dart';
import '../../features/relations/presentation/encounters_chronicle_screen.dart';
import '../../features/relations/presentation/friendship_detail_screen.dart';
import '../../features/relations/presentation/friendships_screen.dart';
import '../../features/relations/presentation/organizations_screen.dart';
import '../../features/relations/presentation/people_screen.dart';
import '../../features/relations/presentation/person_detail_screen.dart';
import '../../features/relations/presentation/relations_hub_screen.dart';
import '../../features/travel/presentation/travel_screen.dart';
import '../../features/home/presentation/home_maintenance_screen.dart';
import '../../features/sync/presentation/sync_status_screen.dart';
import '../../features/integrations/presentation/integrations_screen.dart';
import '../../features/zones/presentation/zones_screen.dart';
import '../../features/activation/presentation/activation_home_screen.dart';
import '../../features/activation/presentation/episode_inspect_screen.dart';
import '../../features/activation/presentation/experiment_inspect_screen.dart';
import '../../features/activation/presentation/mobilization_screen.dart';
import '../../features/activation/presentation/protocol_editor_screen.dart';
import '../../features/activation/presentation/protocol_list_screen.dart';
import '../../features/activation/presentation/environment_screen.dart';
import '../../features/activation/presentation/shield_settings_screen.dart';
import '../../features/activation/presentation/waypoint_editor_screen.dart';
import '../../core/widgets/command_palette.dart';

class _GoRouterRefresh extends ChangeNotifier {
  void ping() => notifyListeners();
}

final routerProvider = Provider<GoRouter>((ref) {
  final refresh = _GoRouterRefresh();
  ref.onDispose(refresh.dispose);

  final router = GoRouter(
    initialLocation: '/boot',
    refreshListenable: refresh,
    redirect: (context, state) {
      final prefsAsync = ref.read(preferencesProvider);
      final profileAsync = ref.read(profileProvider);
      final location = state.matchedLocation;
      final onBoot = location == '/boot';
      final onBootError = location == '/boot-error';
      final onOnboarding = location == '/onboarding';

      if (prefsAsync.isLoading || profileAsync.isLoading) {
        return onBoot ? null : '/boot';
      }
      if (prefsAsync.hasError || profileAsync.hasError) {
        return onBootError ? null : '/boot-error';
      }
      final onboardingDone = prefsAsync.maybeWhen(
        data: (p) => p.onboardingCompleted,
        orElse: () => false,
      );
      final profileReady = profileAsync.maybeWhen(
        data: (p) => p != null,
        orElse: () => false,
      );
      if (!onboardingDone || !profileReady) {
        return onOnboarding ? null : '/onboarding';
      }
      if (onOnboarding || onBoot || onBootError) return '/colony';
      return null;
    },
    routes: [
      GoRoute(
        path: '/boot',
        builder: (context, state) => const BootScreen(),
      ),
      GoRoute(
        path: '/boot-error',
        builder: (context, state) => const BootErrorScreen(),
      ),
      GoRoute(
        path: '/onboarding',
        builder: (context, state) => const OnboardingScreen(),
      ),
      ShellRoute(
        builder: (context, state, child) => AppShell(child: child),
        routes: [
          GoRoute(
            path: '/colony',
            builder: (context, state) => const ColonyScreen(),
          ),
          GoRoute(
            path: '/colony/habitat',
            builder: (context, state) => const HabitatScreen(),
          ),
          GoRoute(
            path: '/colony/pawn-create',
            builder: (context, state) => CharacterCreateScreen(
              memberId: state.uri.queryParameters['memberId'],
            ),
          ),
          GoRoute(
            path: '/pawn',
            builder: (context, state) => const PawnScreen(),
            routes: [
              GoRoute(
                path: 'review',
                builder: (context, state) => const DailyReviewScreen(),
                routes: [
                  GoRoute(
                    path: 'weekly',
                    builder: (context, state) => const WeeklyReviewScreen(),
                  ),
                ],
              ),
            ],
          ),
          GoRoute(
            path: '/work',
            builder: (context, state) => const WorkScreen(),
            routes: [
              GoRoute(
                path: 'schedule',
                builder: (context, state) => const ScheduleScreen(),
              ),
            ],
          ),
          GoRoute(
            path: '/projects',
            builder: (context, state) => const ProjectListScreen(),
            routes: [
              GoRoute(
                path: ':id',
                builder: (context, state) => ProjectDetailScreen(
                  projectId: state.pathParameters['id']!,
                ),
              ),
            ],
          ),
          GoRoute(
            path: '/quests',
            builder: (context, state) => const QuestBoardScreen(),
            routes: [
              GoRoute(
                path: ':id',
                builder: (context, state) => QuestDetailScreen(
                  questId: state.pathParameters['id']!,
                ),
              ),
            ],
          ),
          GoRoute(
            path: '/inbox',
            builder: (context, state) => const InboxScreen(),
          ),
          GoRoute(
            path: '/chronicle',
            builder: (context, state) {
              final eventIdsRaw = state.uri.queryParameters['eventIds'];
              final highlight = state.uri.queryParameters['highlight'];
              return ChronicleScreen(
                evidenceEventIds: ChronicleScreen.parseEvidenceEventIds(
                  eventIdsRaw,
                ),
                highlightEventId: highlight,
              );
            },
          ),
          GoRoute(
            path: '/settings',
            builder: (context, state) => const SettingsScreen(),
          ),
          GoRoute(
            path: '/settings/sync',
            builder: (context, state) => const SyncStatusScreen(),
          ),
          GoRoute(
            path: '/settings/integrations',
            builder: (context, state) => const IntegrationsScreen(),
          ),
          GoRoute(
            path: '/decisions',
            builder: (context, state) => const DecisionListScreen(),
          ),
          GoRoute(
            path: '/research',
            builder: (context, state) => const ResearchListScreen(),
            routes: [
              GoRoute(
                path: 'music-atlas',
                builder: (context, state) => MusicAtlasHubScreen(
                  openImport:
                      state.uri.queryParameters['source'] == 'json' ||
                      state.uri.queryParameters['import'] == '1',
                  importSource: state.uri.queryParameters['source'],
                ),
                routes: [
                  GoRoute(
                    path: 'import',
                    builder: (context, state) => MusicAtlasHubScreen(
                      openImport: true,
                      importSource: state.uri.queryParameters['source'],
                    ),
                  ),
                  GoRoute(
                    path: 'constellation',
                    builder: (context, state) =>
                        const MusicConstellationScreen(),
                  ),
                  GoRoute(
                    path: 'explore',
                    builder: (context, state) => MusicAtlasExploreScreen(
                      initialTerritory: state.uri.queryParameters['t'],
                    ),
                  ),
                  GoRoute(
                    path: 'albums/:nodeId',
                    builder: (context, state) => MusicAlbumScreen(
                      nodeId: state.pathParameters['nodeId']!,
                    ),
                  ),
                  GoRoute(
                    path: 'nodes/:nodeId',
                    builder: (context, state) => MusicNodeInspectScreen(
                      nodeId: state.pathParameters['nodeId']!,
                    ),
                  ),
                ],
              ),
              GoRoute(
                path: ':id',
                builder: (context, state) => ResearchNodeDetailScreen(
                  nodeId: state.pathParameters['id']!,
                ),
              ),
            ],
          ),
          GoRoute(
            path: '/flashcards',
            builder: (context, state) => FlashcardsHubScreen(
              openCapture: state.uri.queryParameters['capture'] == '1',
              openImport: state.uri.queryParameters['import'] == '1',
              openTags: state.uri.queryParameters['tab'] == 'tags',
            ),
            routes: [
              GoRoute(
                path: 'study',
                builder: (context, state) => StudySessionScreen(
                  deckId: state.uri.queryParameters['deckId'],
                  areaId: state.uri.queryParameters['areaId'],
                  tagId: state.uri.queryParameters['tagId'],
                  cardId: state.uri.queryParameters['cardId'],
                  researchId: state.uri.queryParameters['researchId'],
                  mode: state.uri.queryParameters['mode'] == 'practice'
                      ? FlashcardStudySessionMode.practice
                      : FlashcardStudySessionMode.scheduled,
                  savedOnly: state.uri.queryParameters['saved'] == '1',
                  laterOnly: state.uri.queryParameters['later'] == '1',
                  minutes: int.tryParse(
                    state.uri.queryParameters['minutes'] ?? '',
                  ),
                ),
              ),
              GoRoute(
                path: 'areas/:id',
                builder: (context, state) => KnowledgeAreaScreen(
                  areaId: state.pathParameters['id']!,
                  viaAreaId: state.uri.queryParameters['via'],
                ),
              ),
              GoRoute(
                path: 'decks/:id',
                builder: (context, state) => FlashcardDeckScreen(
                  deckId: state.pathParameters['id']!,
                ),
              ),
              GoRoute(
                path: 'tags/:id',
                builder: (context, state) => FlashcardTagScreen(
                  tagId: state.pathParameters['id']!,
                ),
              ),
            ],
          ),
          GoRoute(
            path: '/resources/finance',
            builder: (context, state) => const FinanceLedgerScreen(),
          ),
          GoRoute(
            path: '/resources/health',
            builder: (context, state) => const HealthScreen(),
          ),
          GoRoute(
            path: '/resources/inventory',
            builder: (context, state) => const InventoryScreen(),
          ),
          GoRoute(
            path: '/resources/travel',
            builder: (context, state) => const TravelScreen(),
          ),
          GoRoute(
            path: '/resources/home',
            builder: (context, state) => const HomeMaintenanceScreen(),
          ),
          GoRoute(
            path: '/resources/zones',
            builder: (context, state) => const ZonesScreen(),
          ),
          GoRoute(
            path: '/relations',
            builder: (context, state) => const RelationsHubScreen(),
          ),
          GoRoute(
            path: '/relations/people',
            builder: (context, state) => const PeopleScreen(),
          ),
          GoRoute(
            path: '/relations/people/:personId',
            builder: (context, state) => PersonDetailScreen(
              personId: EntityId(state.pathParameters['personId']!),
            ),
          ),
          GoRoute(
            path: '/relations/friendships',
            builder: (context, state) => const FriendshipsScreen(),
          ),
          GoRoute(
            path: '/relations/friendships/:friendshipId',
            builder: (context, state) => FriendshipDetailScreen(
              friendshipId: EntityId(state.pathParameters['friendshipId']!),
            ),
          ),
          GoRoute(
            path: '/relations/circles',
            builder: (context, state) => const CirclesMapScreen(),
          ),
          GoRoute(
            path: '/relations/circles/:circleId',
            builder: (context, state) => CircleDetailScreen(
              circleId: EntityId(state.pathParameters['circleId']!),
            ),
          ),
          GoRoute(
            path: '/relations/encounters',
            builder: (context, state) => const EncountersChronicleScreen(),
          ),
          GoRoute(
            path: '/relations/organizations',
            builder: (context, state) => const OrganizationsScreen(),
          ),
          GoRoute(
            path: '/relations/commitments',
            builder: (context, state) => const CommitmentsScreen(),
          ),
          GoRoute(
            path: '/tasks/:id',
            builder: (context, state) => TaskInspectScreen(
              taskId: state.pathParameters['id']!,
            ),
          ),
          GoRoute(
            path: '/activation',
            builder: (context, state) => const ActivationHomeScreen(),
            routes: [
              GoRoute(
                path: 'start',
                builder: (context, state) => MobilizationScreen(
                  episodeId: null,
                  protocolId: state.uri.queryParameters['protocol'],
                ),
              ),
              GoRoute(
                path: 'episodes/:episodeId',
                builder: (context, state) {
                  final inspect = state.uri.queryParameters['inspect'] == '1';
                  final id = state.pathParameters['episodeId']!;
                  if (inspect) {
                    return EpisodeInspectScreen(episodeId: id);
                  }
                  return MobilizationScreen(episodeId: id);
                },
              ),
              GoRoute(
                path: 'protocols',
                builder: (context, state) => const ProtocolListScreen(),
                routes: [
                  GoRoute(
                    path: ':protocolId',
                    builder: (context, state) => ProtocolEditorScreen(
                      protocolId: state.pathParameters['protocolId']!,
                    ),
                  ),
                ],
              ),
              GoRoute(
                path: 'waypoints',
                builder: (context, state) => WaypointEditorScreen(
                  initialToken: state.uri.queryParameters['token'],
                ),
                routes: [
                  GoRoute(
                    path: 'reach',
                    builder: (context, state) => WaypointEditorScreen(
                      initialToken: state.uri.queryParameters['token'],
                    ),
                  ),
                ],
              ),
              GoRoute(
                path: 'shield',
                builder: (context, state) => const ShieldSettingsScreen(),
              ),
              GoRoute(
                path: 'experiments',
                builder: (context, state) => const ExperimentInspectScreen(),
              ),
              GoRoute(
                path: 'environment',
                builder: (context, state) => const EnvironmentScreen(),
              ),
            ],
          ),
          GoRoute(
            path: '/pawn/me/activation',
            builder: (context, state) => const ActivationHomeScreen(),
          ),
        ],
      ),
    ],
  );
  ref.listen(preferencesProvider, (previous, next) => refresh.ping(), fireImmediately: true);
  ref.listen(profileProvider, (previous, next) => refresh.ping(), fireImmediately: true);
  ref.onDispose(router.dispose);
  return router;
});

class AppShell extends ConsumerStatefulWidget {
  const AppShell({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<AppShell> createState() => _AppShellState();
}

class _AppShellState extends ConsumerState<AppShell> {
  final _destinations = const [
    ColonyDestination(
      label: AppStrings.colony,
      icon: Icons.home_work_outlined,
      route: '/colony',
    ),
    ColonyDestination(
      label: AppStrings.pawn,
      icon: Icons.person_outline,
      route: '/pawn',
    ),
    ColonyDestination(
      label: AppStrings.work,
      icon: Icons.grid_on_outlined,
      route: '/work',
    ),
    ColonyDestination(
      label: AppStrings.quests,
      icon: Icons.flag_outlined,
      route: '/quests',
    ),
    ColonyDestination(
      label: AppStrings.more,
      icon: Icons.more_horiz,
      route: '/more',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).uri.toString();
    if (GoRouterState.of(context).uri.path.startsWith('/flashcards/study')) {
      return Scaffold(body: widget.child);
    }
    final undo = ref.watch(undoControllerProvider);
    final compact = _isCompact(context);

    final chrome = ref.watch(habitatChromeProvider);
    final mini = MiniHabitatBadge(
      locationId: chrome.locationId,
      phaseLabel: chrome.phaseLabel,
    );

    final topActions = <Widget>[
      mini,
      IconButton(
        tooltip: AppStrings.commandPalette,
        icon: const Icon(Icons.search),
        onPressed: () => CommandPalette.show(context),
      ),
      if (undo != null)
        TextButton(
          onPressed: () =>
              ref.read(captureControllerProvider.notifier).undoLast(),
          child: const Text(AppStrings.undo),
        ),
    ];

    return ColonyShell(
      destinations: _destinations,
      currentRoute: _matchRoute(location),
      compact: compact,
      onNavigate: (route) {
        if (route == '/more') {
          _showMoreMenu(context);
          return;
        }
        context.go(route);
      },
      showCaptureFab: false,
      appBarTitle: compact ? AppStrings.appName : null,
      appBarActions: compact ? topActions : const [],
      desktopTopBar: compact
          ? null
          : Row(
              children: [
                Expanded(
                  child: Text(
                    AppStrings.appName,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                mini,
                const SizedBox(width: ColonySpacing.md),
                Text(
                  AppStrings.offlineReady,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: ColonyColors.textMuted,
                      ),
                ),
                const SizedBox(width: ColonySpacing.md),
                ...topActions.skip(1),
              ],
            ),
      body: widget.child,
    );
  }

  bool _isCompact(BuildContext context) =>
      MediaQuery.sizeOf(context).width < 840;

  void _showMoreMenu(BuildContext context) {
    showColonyFloatMenu(
      context: context,
      title: AppStrings.more,
      items: [
        ColonyFloatMenuItem(
          icon: Icons.cottage_outlined,
          label: AppStrings.habitatTitle,
          onSelected: () => context.go('/colony/habitat'),
        ),
        ColonyFloatMenuItem(
          icon: Icons.face_retouching_natural,
          label: AppStrings.habitatCreateTitle,
          onSelected: () => context.go('/colony/pawn-create'),
        ),
        ColonyFloatMenuItem(
          icon: Icons.directions_walk_outlined,
          label: AppStrings.activationTitle,
          onSelected: () => context.go('/activation'),
        ),
        ColonyFloatMenuItem(
          icon: Icons.inbox_outlined,
          label: AppStrings.inbox,
          onSelected: () => context.go('/inbox'),
        ),
        ColonyFloatMenuItem(
          icon: Icons.history,
          label: AppStrings.chronicle,
          onSelected: () => context.go('/chronicle'),
        ),
        ColonyFloatMenuItem(
          icon: Icons.account_balance_outlined,
          label: AppStrings.financeLedgerTitle,
          onSelected: () => context.go('/resources/finance'),
        ),
        ColonyFloatMenuItem(
          icon: Icons.favorite_outline,
          label: AppStrings.healthTitle,
          onSelected: () => context.go('/resources/health'),
        ),
        ColonyFloatMenuItem(
          icon: Icons.inventory_2_outlined,
          label: AppStrings.inventoryTitle,
          onSelected: () => context.go('/resources/inventory'),
        ),
        ColonyFloatMenuItem(
          icon: Icons.luggage_outlined,
          label: AppStrings.travelTitle,
          onSelected: () => context.go('/resources/travel'),
        ),
        ColonyFloatMenuItem(
          icon: Icons.home_repair_service_outlined,
          label: AppStrings.homeMaintenanceTitle,
          onSelected: () => context.go('/resources/home'),
        ),
        ColonyFloatMenuItem(
          icon: Icons.place_outlined,
          label: AppStrings.zonesTitle,
          onSelected: () => context.go('/resources/zones'),
        ),
        ColonyFloatMenuItem(
          icon: Icons.map_outlined,
          label: AppStrings.relationsOpenHub,
          onSelected: () => context.go('/relations'),
        ),
        ColonyFloatMenuItem(
          icon: Icons.people_outline,
          label: AppStrings.peopleTitle,
          onSelected: () => context.go('/relations/people'),
        ),
        ColonyFloatMenuItem(
          icon: Icons.favorite_outline,
          label: AppStrings.friendshipsTitle,
          onSelected: () => context.go('/relations/friendships'),
        ),
        ColonyFloatMenuItem(
          icon: Icons.hub_outlined,
          label: AppStrings.relationsCirclesTitle,
          onSelected: () => context.go('/relations/circles'),
        ),
        ColonyFloatMenuItem(
          icon: Icons.event_available_outlined,
          label: AppStrings.relationsEncountersTitle,
          onSelected: () => context.go('/relations/encounters'),
        ),
        ColonyFloatMenuItem(
          icon: Icons.apartment_outlined,
          label: AppStrings.organizationsTitle,
          onSelected: () => context.go('/relations/organizations'),
        ),
        ColonyFloatMenuItem(
          icon: Icons.handshake_outlined,
          label: AppStrings.commitmentsTitle,
          onSelected: () => context.go('/relations/commitments'),
        ),
        ColonyFloatMenuItem(
          icon: Icons.style_outlined,
          label: AppStrings.flashcardsTitle,
          onSelected: () => context.go('/flashcards'),
        ),
        ColonyFloatMenuItem(
          icon: Icons.science_outlined,
          label: AppStrings.research,
          onSelected: () => context.go('/research'),
        ),
        ColonyFloatMenuItem(
          icon: Icons.album_outlined,
          label: AppStrings.musicAtlasTitle,
          onSelected: () => context.go('/research/music-atlas'),
        ),
        ColonyFloatMenuItem(
          icon: Icons.folder_outlined,
          label: AppStrings.projects,
          onSelected: () => context.go('/projects'),
        ),
        ColonyFloatMenuItem(
          icon: Icons.gavel_outlined,
          label: AppStrings.decisions,
          onSelected: () => context.go('/decisions'),
        ),
        ColonyFloatMenuItem(
          icon: Icons.sync_outlined,
          label: AppStrings.syncTitle,
          onSelected: () => context.go('/settings/sync'),
        ),
        ColonyFloatMenuItem(
          icon: Icons.extension_outlined,
          label: AppStrings.integrationsTitle,
          onSelected: () => context.go('/settings/integrations'),
        ),
        ColonyFloatMenuItem(
          icon: Icons.settings_outlined,
          label: AppStrings.settings,
          onSelected: () => context.go('/settings'),
        ),
      ],
    );
  }

  String _matchRoute(String location) {
    // Habitat lives under /colony/* but is opened from Mais.
    if (location.startsWith('/colony/habitat') ||
        location.startsWith('/colony/pawn-create')) {
      return '/more';
    }
    for (final d in _destinations) {
      if (d.route != '/more' && location.startsWith(d.route)) return d.route;
    }
    // Secondary destinations highlight "More" in the main tab strip.
    if (location.startsWith('/inbox') ||
        location.startsWith('/activation') ||
        location.startsWith('/chronicle') ||
        location.startsWith('/projects') ||
        location.startsWith('/decisions') ||
        location.startsWith('/research') ||
        location.startsWith('/flashcards') ||
        location.startsWith('/resources') ||
        location.startsWith('/settings') ||
        location.startsWith('/relations')) {
      return '/more';
    }
    return '/colony';
  }
}

class PlaceholderScreen extends StatelessWidget {
  const PlaceholderScreen({super.key, required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(title, style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: ColonySpacing.md),
          Text(AppStrings.comingSoon, style: Theme.of(context).textTheme.bodyMedium),
        ],
      ),
    );
  }
}
