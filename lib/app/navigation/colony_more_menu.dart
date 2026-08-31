import 'package:colony_design_system/colony_design_system.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../localization/app_strings.dart';
import '../../core/widgets/command_palette.dart';

/// Overflow of programs (hamburger / tab Mais). Shared so the home header
/// and the shell tab open the same list.
void showColonyMoreMenu(BuildContext context) {
  showColonyFloatMenu(
    context: context,
    title: AppStrings.more,
    items: [
      ColonyFloatMenuItem(
        icon: Icons.search,
        iconName: 'search',
        label: AppStrings.commandPalette,
        onSelected: () => CommandPalette.show(context),
      ),
      ColonyFloatMenuItem(
        icon: Icons.cottage_outlined,
        iconName: 'house',
        label: AppStrings.habitatTitle,
        onSelected: () => context.go('/colony/habitat'),
      ),
      ColonyFloatMenuItem(
        icon: Icons.face_retouching_natural,
        iconName: 'person',
        label: AppStrings.habitatCreateTitle,
        onSelected: () => context.go('/colony/pawn-create'),
      ),
      ColonyFloatMenuItem(
        icon: Icons.directions_walk_outlined,
        iconName: 'activation',
        label: AppStrings.activationTitle,
        onSelected: () => context.go('/activation'),
      ),
      ColonyFloatMenuItem(
        icon: Icons.wb_twilight_outlined,
        iconName: 'sun',
        label: AppStrings.planDayMiniApp,
        onSelected: () => context.go('/today'),
      ),
      ColonyFloatMenuItem(
        icon: Icons.event_available_outlined,
        iconName: 'calendar',
        label: AppStrings.integrationsGoogleCalendar,
        onSelected: () => context.go('/settings/integrations?focus=calendar'),
      ),
      ColonyFloatMenuItem(
        icon: Icons.inbox_outlined,
        iconName: 'inbox',
        label: AppStrings.inbox,
        onSelected: () => context.go('/inbox'),
      ),
      ColonyFloatMenuItem(
        icon: Icons.task_alt_outlined,
        iconName: 'task',
        label: AppStrings.tasksTitle,
        onSelected: () => context.go('/tasks'),
      ),
      ColonyFloatMenuItem(
        icon: Icons.history,
        iconName: 'book',
        label: AppStrings.chronicle,
        onSelected: () => context.go('/chronicle'),
      ),
      ColonyFloatMenuItem(
        icon: Icons.account_balance_outlined,
        iconName: 'coin',
        label: AppStrings.financeLedgerTitle,
        onSelected: () => context.go('/resources/finance'),
      ),
      ColonyFloatMenuItem(
        icon: Icons.favorite_outline,
        iconName: 'heart',
        label: AppStrings.healthTitle,
        onSelected: () => context.go('/resources/health'),
      ),
      ColonyFloatMenuItem(
        icon: Icons.inventory_2_outlined,
        iconName: 'crate',
        label: AppStrings.inventoryTitle,
        onSelected: () => context.go('/resources/inventory'),
      ),
      ColonyFloatMenuItem(
        icon: Icons.luggage_outlined,
        iconName: 'bag',
        label: AppStrings.travelTitle,
        onSelected: () => context.go('/resources/travel'),
      ),
      ColonyFloatMenuItem(
        icon: Icons.home_repair_service_outlined,
        iconName: 'wrench',
        label: AppStrings.homeMaintenanceTitle,
        onSelected: () => context.go('/resources/home'),
      ),
      ColonyFloatMenuItem(
        icon: Icons.place_outlined,
        iconName: 'pin',
        label: AppStrings.zonesTitle,
        onSelected: () => context.go('/resources/zones'),
      ),
      ColonyFloatMenuItem(
        icon: Icons.map_outlined,
        iconName: 'circles',
        label: AppStrings.relationsOpenHub,
        onSelected: () => context.go('/relations'),
      ),
      ColonyFloatMenuItem(
        icon: Icons.people_outline,
        iconName: 'people',
        label: AppStrings.peopleTitle,
        onSelected: () => context.go('/relations/people'),
      ),
      ColonyFloatMenuItem(
        icon: Icons.favorite_outline,
        iconName: 'heart',
        label: AppStrings.friendshipsTitle,
        onSelected: () => context.go('/relations/friendships'),
      ),
      ColonyFloatMenuItem(
        icon: Icons.hub_outlined,
        iconName: 'circles',
        label: AppStrings.relationsCirclesTitle,
        onSelected: () => context.go('/relations/circles'),
      ),
      ColonyFloatMenuItem(
        icon: Icons.event_available_outlined,
        iconName: 'calendar',
        label: AppStrings.relationsEncountersTitle,
        onSelected: () => context.go('/relations/encounters'),
      ),
      ColonyFloatMenuItem(
        icon: Icons.apartment_outlined,
        iconName: 'building',
        label: AppStrings.organizationsTitle,
        onSelected: () => context.go('/relations/organizations'),
      ),
      ColonyFloatMenuItem(
        icon: Icons.handshake_outlined,
        iconName: 'handshake',
        label: AppStrings.commitmentsTitle,
        onSelected: () => context.go('/relations/commitments'),
      ),
      ColonyFloatMenuItem(
        icon: Icons.style_outlined,
        iconName: 'cards',
        label: AppStrings.flashcardsTitle,
        onSelected: () => context.go('/flashcards'),
      ),
      ColonyFloatMenuItem(
        icon: Icons.science_outlined,
        iconName: 'flask',
        label: AppStrings.research,
        onSelected: () => context.go('/research'),
      ),
      ColonyFloatMenuItem(
        icon: Icons.album_outlined,
        iconName: 'album',
        label: AppStrings.musicAtlasTitle,
        onSelected: () => context.go('/research/music-atlas'),
      ),
      ColonyFloatMenuItem(
        icon: Icons.folder_outlined,
        iconName: 'folder',
        label: AppStrings.projects,
        onSelected: () => context.go('/projects'),
      ),
      ColonyFloatMenuItem(
        icon: Icons.gavel_outlined,
        iconName: 'gavel',
        label: AppStrings.decisions,
        onSelected: () => context.go('/decisions'),
      ),
      ColonyFloatMenuItem(
        icon: Icons.sync_outlined,
        iconName: 'sync',
        label: AppStrings.syncTitle,
        onSelected: () => context.go('/settings/sync'),
      ),
      ColonyFloatMenuItem(
        icon: Icons.extension_outlined,
        iconName: 'plug',
        label: AppStrings.integrationsTitle,
        onSelected: () => context.go('/settings/integrations'),
      ),
      ColonyFloatMenuItem(
        icon: Icons.settings_outlined,
        iconName: 'gear',
        label: AppStrings.settings,
        onSelected: () => context.go('/settings'),
      ),
    ],
  );
}
