import 'package:colony_design_system/colony_design_system.dart';
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
import '../../features/projects/presentation/project_detail_screen.dart';
import '../../features/projects/presentation/project_list_screen.dart';
import '../../features/quests/presentation/quest_board_screen.dart';
import '../../features/quests/presentation/quest_detail_screen.dart';
import '../../features/decisions/presentation/decision_list_screen.dart';
import '../../features/research/presentation/research_list_screen.dart';
import '../../features/research/presentation/research_node_detail_screen.dart';
import '../../features/finance/presentation/finance_ledger_screen.dart';
import '../../features/health/presentation/health_screen.dart';
import '../../features/inventory/presentation/inventory_screen.dart';
import '../../features/relations/presentation/people_screen.dart';
import '../../features/relations/presentation/organizations_screen.dart';
import '../../features/relations/presentation/commitments_screen.dart';
import '../../features/travel/presentation/travel_screen.dart';
import '../../features/home/presentation/home_maintenance_screen.dart';
import '../../features/sync/presentation/sync_status_screen.dart';
import '../../features/integrations/presentation/integrations_screen.dart';
import '../../features/zones/presentation/zones_screen.dart';
import '../../core/widgets/command_palette.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final prefsAsync = ref.watch(preferencesProvider);
  final profileAsync = ref.watch(profileProvider);

  return GoRouter(
    initialLocation: '/colony',
    redirect: (context, state) {
      final onboardingDone = prefsAsync.maybeWhen(
        data: (p) => p.onboardingCompleted,
        orElse: () => false,
      );
      final profileReady = profileAsync.maybeWhen(
        data: (p) => p != null,
        orElse: () => false,
      );
      final onOnboarding = state.matchedLocation == '/onboarding';
      if (!onboardingDone || !profileReady) {
        return onOnboarding ? null : '/onboarding';
      }
      if (onOnboarding) return '/colony';
      return null;
    },
    routes: [
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
                path: ':id',
                builder: (context, state) => ResearchNodeDetailScreen(
                  nodeId: state.pathParameters['id']!,
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
            path: '/relations/people',
            builder: (context, state) => const PeopleScreen(),
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
        ],
      ),
    ],
  );
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
          icon: Icons.people_outline,
          label: AppStrings.peopleTitle,
          onSelected: () => context.go('/relations/people'),
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
          icon: Icons.science_outlined,
          label: AppStrings.research,
          onSelected: () => context.go('/research'),
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
        location.startsWith('/chronicle') ||
        location.startsWith('/projects') ||
        location.startsWith('/decisions') ||
        location.startsWith('/research') ||
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
