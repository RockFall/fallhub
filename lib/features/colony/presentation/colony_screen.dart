import 'package:colony_design_system/colony_design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/localization/app_strings.dart';
import '../../../core/providers/app_providers.dart';
import 'widgets/colony_home_digest.dart';
import 'widgets/colony_terminal_home.dart';

class ColonyScreen extends ConsumerWidget {
  const ColonyScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(profileProvider);

    return profile.when(
      loading: () => const Center(
        child: CircularProgressIndicator(color: ColonyColors.accentCyan),
      ),
      error: (e, _) => Center(child: Text(AppStrings.errorGeneric)),
      data: (p) {
        if (p == null) return const SizedBox.shrink();
        return Semantics(
          container: true,
          identifier: 'colony.home',
          label: AppStrings.colony,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final wide = constraints.maxWidth > 900;
              final terminal = ColonyTerminalHome(profile: p);
              if (!wide) return terminal;
              return Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SizedBox(width: 420, child: terminal),
                  const SizedBox(width: ColonySpacing.lg),
                  const Expanded(
                    child: SingleChildScrollView(
                      padding: EdgeInsets.fromLTRB(
                        0,
                        ColonySpacing.sm,
                        ColonySpacing.page,
                        ColonySpacing.lg,
                      ),
                      child: ColonyHomeDigest(),
                    ),
                  ),
                ],
              );
            },
          ),
        );
      },
    );
  }
}
