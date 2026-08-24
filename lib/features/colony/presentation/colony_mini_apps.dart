import 'package:colony_design_system/colony_design_system.dart';
import 'package:flutter/material.dart';

import '../../../app/localization/app_strings.dart';

/// Catalog of home mini-programs — routes + original iconography (ADR-044).
class ColonyMiniApp {
  const ColonyMiniApp({
    required this.id,
    required this.label,
    required this.route,
    required this.icon,
    required this.color,
    this.assetPath,
    this.pinned = false,
  });

  final String id;
  final String label;
  final String route;
  final IconData icon;
  final Color color;
  final String? assetPath;
  final bool pinned;
}

abstract final class ColonyMiniAppAssets {
  static const habitat = 'assets/mini_apps/mini_app_habitat.png';
  static const pawn = 'assets/mini_apps/mini_app_pawn.png';
  static const work = 'assets/mini_apps/mini_app_work.png';
  static const quests = 'assets/mini_apps/mini_app_quests.png';
  static const flashcards = 'assets/mini_apps/mini_app_flashcards.png';
  static const research = 'assets/mini_apps/mini_app_research.png';
  static const finance = 'assets/mini_apps/mini_app_finance.png';
  static const health = 'assets/mini_apps/mini_app_health.png';
  static const inventory = 'assets/mini_apps/mini_app_inventory.png';
  static const travel = 'assets/mini_apps/mini_app_travel.png';
  static const home = 'assets/mini_apps/mini_app_home.png';
  static const zones = 'assets/mini_apps/mini_app_zones.png';
  static const people = 'assets/mini_apps/mini_app_people.png';
  static const friendships = 'assets/mini_apps/mini_app_friendships.png';
  static const circles = 'assets/mini_apps/mini_app_circles.png';
  static const encounters = 'assets/mini_apps/mini_app_encounters.png';
  static const organizations = 'assets/mini_apps/mini_app_organizations.png';
  static const commitments = 'assets/mini_apps/mini_app_commitments.png';
  static const inbox = 'assets/mini_apps/mini_app_inbox.png';
  static const chronicle = 'assets/mini_apps/mini_app_chronicle.png';
  static const projects = 'assets/mini_apps/mini_app_projects.png';
  static const decisions = 'assets/mini_apps/mini_app_decisions.png';
  static const schedule = 'assets/mini_apps/mini_app_schedule.png';
  static const sync = 'assets/mini_apps/mini_app_sync.png';
  static const integrations = 'assets/mini_apps/mini_app_integrations.png';
  static const settings = 'assets/mini_apps/mini_app_settings.png';
  static const pawnCreate = 'assets/mini_apps/mini_app_pawn_create.png';
}

abstract final class ColonyMiniApps {
  static const all = <ColonyMiniApp>[
    ColonyMiniApp(
      id: 'plan_day',
      label: AppStrings.planDayMiniApp,
      route: '/today',
      icon: Icons.wb_twilight_outlined,
      color: ColonyMiniAppColors.planDay,
      pinned: true,
    ),
    ColonyMiniApp(
      id: 'habitat',
      label: AppStrings.habitatTitle,
      route: '/colony/habitat',
      icon: Icons.cottage_outlined,
      color: ColonyMiniAppColors.habitat,
      assetPath: ColonyMiniAppAssets.habitat,
      pinned: true,
    ),
    ColonyMiniApp(
      id: 'pawn',
      label: AppStrings.pawn,
      route: '/pawn',
      icon: Icons.person_outline,
      color: ColonyMiniAppColors.pawn,
      assetPath: ColonyMiniAppAssets.pawn,
      pinned: true,
    ),
    ColonyMiniApp(
      id: 'work',
      label: AppStrings.work,
      route: '/work',
      icon: Icons.grid_on_outlined,
      color: ColonyMiniAppColors.work,
      assetPath: ColonyMiniAppAssets.work,
      pinned: true,
    ),
    ColonyMiniApp(
      id: 'quests',
      label: AppStrings.quests,
      route: '/quests',
      icon: Icons.flag_outlined,
      color: ColonyMiniAppColors.quests,
      assetPath: ColonyMiniAppAssets.quests,
      pinned: true,
    ),
    ColonyMiniApp(
      id: 'flashcards',
      label: AppStrings.flashcardsTitle,
      route: '/flashcards',
      icon: Icons.style_outlined,
      color: ColonyMiniAppColors.flashcards,
      assetPath: ColonyMiniAppAssets.flashcards,
      pinned: true,
    ),
    ColonyMiniApp(
      id: 'music_atlas',
      label: AppStrings.musicAtlasTitle,
      route: '/research/music-atlas/explore',
      icon: Icons.album_outlined,
      color: ColonyMiniAppColors.musicAtlas,
      pinned: true,
    ),
    ColonyMiniApp(
      id: 'finance',
      label: AppStrings.financeLedgerTitle,
      route: '/resources/finance',
      icon: Icons.account_balance_wallet_outlined,
      color: ColonyMiniAppColors.finance,
      assetPath: ColonyMiniAppAssets.finance,
      pinned: true,
    ),
    ColonyMiniApp(
      id: 'health',
      label: AppStrings.healthTitle,
      route: '/resources/health',
      icon: Icons.favorite_outline,
      color: ColonyMiniAppColors.health,
      assetPath: ColonyMiniAppAssets.health,
      pinned: true,
    ),
    ColonyMiniApp(
      id: 'activation',
      label: AppStrings.activationTitle,
      route: '/activation',
      icon: Icons.directions_walk_outlined,
      color: ColonyMiniAppColors.activation,
      pinned: true,
    ),
    ColonyMiniApp(
      id: 'inbox',
      label: AppStrings.inbox,
      route: '/inbox',
      icon: Icons.inbox_outlined,
      color: ColonyMiniAppColors.inbox,
      assetPath: ColonyMiniAppAssets.inbox,
      pinned: true,
    ),
    ColonyMiniApp(
      id: 'tasks',
      label: AppStrings.tasksMiniApp,
      route: '/tasks',
      icon: Icons.task_alt_outlined,
      color: ColonyMiniAppColors.tasks,
      pinned: true,
    ),
    ColonyMiniApp(
      id: 'research',
      label: AppStrings.research,
      route: '/research',
      icon: Icons.science_outlined,
      color: ColonyMiniAppColors.research,
      assetPath: ColonyMiniAppAssets.research,
    ),
    ColonyMiniApp(
      id: 'schedule',
      label: AppStrings.schedule,
      route: '/work/schedule',
      icon: Icons.calendar_today_outlined,
      color: ColonyMiniAppColors.schedule,
      assetPath: ColonyMiniAppAssets.schedule,
    ),
    ColonyMiniApp(
      id: 'inventory',
      label: AppStrings.inventoryTitle,
      route: '/resources/inventory',
      icon: Icons.inventory_2_outlined,
      color: ColonyMiniAppColors.inventory,
      assetPath: ColonyMiniAppAssets.inventory,
    ),
    ColonyMiniApp(
      id: 'travel',
      label: AppStrings.travelTitle,
      route: '/resources/travel',
      icon: Icons.luggage_outlined,
      color: ColonyMiniAppColors.travel,
      assetPath: ColonyMiniAppAssets.travel,
    ),
    ColonyMiniApp(
      id: 'home',
      label: AppStrings.homeMaintenanceTitle,
      route: '/resources/home',
      icon: Icons.home_repair_service_outlined,
      color: ColonyMiniAppColors.home,
      assetPath: ColonyMiniAppAssets.home,
    ),
    ColonyMiniApp(
      id: 'zones',
      label: AppStrings.zonesTitle,
      route: '/resources/zones',
      icon: Icons.place_outlined,
      color: ColonyMiniAppColors.zones,
      assetPath: ColonyMiniAppAssets.zones,
    ),
    ColonyMiniApp(
      id: 'relations_hub',
      label: AppStrings.relationsOpenHub,
      route: '/relations',
      icon: Icons.map_outlined,
      color: const Color(0xFF7B5EA7),
      assetPath: ColonyMiniAppAssets.circles,
    ),
    ColonyMiniApp(
      id: 'people',
      label: AppStrings.peopleTitle,
      route: '/relations/people',
      icon: Icons.people_outline,
      color: ColonyMiniAppColors.people,
      assetPath: ColonyMiniAppAssets.people,
    ),
    ColonyMiniApp(
      id: 'friendships',
      label: AppStrings.friendshipsTitle,
      route: '/relations/friendships',
      icon: Icons.favorite_outline,
      color: ColonyMiniAppColors.friendships,
      assetPath: ColonyMiniAppAssets.friendships,
    ),
    ColonyMiniApp(
      id: 'circles',
      label: AppStrings.relationsCirclesTitle,
      route: '/relations/circles',
      icon: Icons.hub_outlined,
      color: const Color(0xFF7B5EA7),
      assetPath: ColonyMiniAppAssets.circles,
    ),
    ColonyMiniApp(
      id: 'encounters',
      label: AppStrings.relationsEncountersTitle,
      route: '/relations/encounters',
      icon: Icons.event_available_outlined,
      color: const Color(0xFF2BB7C4),
      assetPath: ColonyMiniAppAssets.encounters,
    ),
    ColonyMiniApp(
      id: 'organizations',
      label: AppStrings.organizationsTitle,
      route: '/relations/organizations',
      icon: Icons.apartment_outlined,
      color: ColonyMiniAppColors.organizations,
      assetPath: ColonyMiniAppAssets.organizations,
    ),
    ColonyMiniApp(
      id: 'commitments',
      label: AppStrings.commitmentsTitle,
      route: '/relations/commitments',
      icon: Icons.handshake_outlined,
      color: ColonyMiniAppColors.commitments,
      assetPath: ColonyMiniAppAssets.commitments,
    ),
    ColonyMiniApp(
      id: 'chronicle',
      label: AppStrings.chronicle,
      route: '/chronicle',
      icon: Icons.history,
      color: ColonyMiniAppColors.chronicle,
      assetPath: ColonyMiniAppAssets.chronicle,
    ),
    ColonyMiniApp(
      id: 'projects',
      label: AppStrings.projects,
      route: '/projects',
      icon: Icons.folder_outlined,
      color: ColonyMiniAppColors.projects,
      assetPath: ColonyMiniAppAssets.projects,
    ),
    ColonyMiniApp(
      id: 'decisions',
      label: AppStrings.decisions,
      route: '/decisions',
      icon: Icons.gavel_outlined,
      color: ColonyMiniAppColors.decisions,
      assetPath: ColonyMiniAppAssets.decisions,
    ),
    ColonyMiniApp(
      id: 'daily_review',
      label: AppStrings.dailyReview,
      route: '/pawn/review',
      icon: Icons.rate_review_outlined,
      color: ColonyMiniAppColors.pawn,
    ),
    ColonyMiniApp(
      id: 'pawn_create',
      label: AppStrings.habitatCreateTitle,
      route: '/colony/pawn-create',
      icon: Icons.face_retouching_natural,
      color: ColonyMiniAppColors.pawn,
      assetPath: ColonyMiniAppAssets.pawnCreate,
    ),
    ColonyMiniApp(
      id: 'sync',
      label: AppStrings.syncTitle,
      route: '/settings/sync',
      icon: Icons.sync_outlined,
      color: ColonyMiniAppColors.sync,
      assetPath: ColonyMiniAppAssets.sync,
    ),
    ColonyMiniApp(
      id: 'integrations',
      label: AppStrings.integrationsTitle,
      route: '/settings/integrations',
      icon: Icons.extension_outlined,
      color: ColonyMiniAppColors.integrations,
      assetPath: ColonyMiniAppAssets.integrations,
    ),
    ColonyMiniApp(
      id: 'settings',
      label: AppStrings.settings,
      route: '/settings',
      icon: Icons.settings_outlined,
      color: ColonyMiniAppColors.settings,
      assetPath: ColonyMiniAppAssets.settings,
    ),
  ];

  static List<ColonyMiniApp> get pinned =>
      all.where((app) => app.pinned).toList();

  static List<ColonyMiniApp> get overflow =>
      all.where((app) => !app.pinned).toList();
}
