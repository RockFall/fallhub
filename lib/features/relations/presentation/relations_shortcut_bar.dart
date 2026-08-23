import 'package:colony_design_system/colony_design_system.dart';
import 'package:flutter/material.dart';

import '../../../app/localization/app_strings.dart';
import '../../colony/presentation/colony_mini_apps.dart';
import 'relations_assets.dart';
import 'relations_navigation.dart';

enum RelationsDoor {
  hub,
  people,
  friendships,
  circles,
  encounters,
  organizations,
  commitments,
}

class RelationsShortcutBar extends StatelessWidget {
  const RelationsShortcutBar({super.key, this.current});

  final RelationsDoor? current;

  @override
  Widget build(BuildContext context) {
    final items = <_Door>[
      _Door(
        door: RelationsDoor.hub,
        label: AppStrings.relationsNavHub,
        asset: RelationsAssets.heroConstellation,
        path: '/relations',
      ),
      _Door(
        door: RelationsDoor.people,
        label: AppStrings.relationsNavPeople,
        asset: ColonyMiniAppAssets.people,
        path: '/relations/people',
      ),
      _Door(
        door: RelationsDoor.friendships,
        label: AppStrings.relationsNavFriendships,
        asset: ColonyMiniAppAssets.friendships,
        path: '/relations/friendships',
      ),
      _Door(
        door: RelationsDoor.circles,
        label: AppStrings.relationsNavCircles,
        asset: ColonyMiniAppAssets.circles,
        path: '/relations/circles',
      ),
      _Door(
        door: RelationsDoor.encounters,
        label: AppStrings.relationsNavEncounters,
        asset: ColonyMiniAppAssets.encounters,
        path: '/relations/encounters',
      ),
      _Door(
        door: RelationsDoor.organizations,
        label: AppStrings.relationsNavOrganizations,
        asset: ColonyMiniAppAssets.organizations,
        path: '/relations/organizations',
      ),
      _Door(
        door: RelationsDoor.commitments,
        label: AppStrings.relationsOpenCommitments,
        asset: ColonyMiniAppAssets.commitments,
        path: '/relations/commitments',
      ),
    ];
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (final item in items)
            Padding(
              padding: const EdgeInsets.only(right: ColonySpacing.sm),
              child: FilterChip(
                selected: current == item.door,
                avatar: ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: Image.asset(
                    item.asset,
                    width: 18,
                    height: 18,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stack) =>
                        const Icon(Icons.circle, size: 12),
                  ),
                ),
                label: Text(item.label),
                onSelected: (_) => goRelations(context, item.path),
              ),
            ),
        ],
      ),
    );
  }
}

class _Door {
  const _Door({
    required this.door,
    required this.label,
    required this.asset,
    required this.path,
  });

  final RelationsDoor door;
  final String label;
  final String asset;
  final String path;
}
