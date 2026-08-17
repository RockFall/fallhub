import 'package:colony_design_system/colony_design_system.dart';
import 'package:flutter/material.dart';

import '../../../../app/localization/app_strings.dart';
import '../../../../core/sideload_build_info.dart';

class SideloadBuildPanel extends StatelessWidget {
  const SideloadBuildPanel({super.key});

  @override
  Widget build(BuildContext context) {
    final body = SideloadBuildInfo.isCiBuild
        ? [
            '${AppStrings.sideloadBuildCommit} ${SideloadBuildInfo.shortSha}',
            if (SideloadBuildInfo.gitRef.isNotEmpty)
              '${AppStrings.sideloadBuildRef} ${SideloadBuildInfo.gitRef}',
            if (SideloadBuildInfo.builtAt.isNotEmpty)
              '${AppStrings.sideloadBuildTime} ${SideloadBuildInfo.builtAt}',
          ].join('\n')
        : AppStrings.sideloadBuildLocal;

    return ColonyPanel(
      title: AppStrings.sideloadBuildTitle,
      child: Text(body),
    );
  }
}
