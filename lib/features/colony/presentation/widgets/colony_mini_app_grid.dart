import 'package:colony_design_system/colony_design_system.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/localization/app_strings.dart';
import '../colony_mini_apps.dart';

class ColonyMiniAppGrid extends StatefulWidget {
  const ColonyMiniAppGrid({
    super.key,
    this.inboxBadge = 0,
  });

  final int inboxBadge;

  @override
  State<ColonyMiniAppGrid> createState() => _ColonyMiniAppGridState();
}

class _ColonyMiniAppGridState extends State<ColonyMiniAppGrid> {
  var _expanded = false;

  @override
  Widget build(BuildContext context) {
    final apps = [
      ...ColonyMiniApps.pinned,
      if (_expanded) ...ColonyMiniApps.overflow,
    ];

    return Semantics(
      container: true,
      identifier: 'colony.home.mini_apps',
      label: AppStrings.homeMiniAppsTitle,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            AppStrings.homeMiniAppsTitle,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(height: ColonySpacing.sm),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: apps.length + 1,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 4,
              mainAxisSpacing: ColonySpacing.sm,
              crossAxisSpacing: ColonySpacing.xs,
              childAspectRatio: 0.78,
            ),
            itemBuilder: (context, index) {
              if (index == apps.length) {
                return ColonyMiniAppTile(
                  label: _expanded
                      ? AppStrings.homeMiniAppsLess
                      : AppStrings.homeMiniAppsMore,
                  icon: _expanded ? Icons.expand_less : Icons.apps,
                  backgroundColor: ColonyMiniAppColors.more,
                  onPressed: () => setState(() => _expanded = !_expanded),
                );
              }
              final app = apps[index];
              return ColonyMiniAppTile(
                label: app.label,
                icon: app.icon,
                iconAsset: app.assetPath,
                backgroundColor: app.color,
                badgeCount: app.id == 'inbox' ? widget.inboxBadge : null,
                onPressed: () => context.go(app.route),
              );
            },
          ),
        ],
      ),
    );
  }
}
