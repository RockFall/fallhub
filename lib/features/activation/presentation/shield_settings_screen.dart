import 'package:colony_design_system/colony_design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/localization/app_strings.dart';
import '../application/activation_controllers.dart';
import '../application/activation_providers.dart';

class ShieldSettingsScreen extends ConsumerWidget {
  const ShieldSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profiles = ref.watch(activationShieldProfilesProvider);
    return Padding(
      padding: const EdgeInsets.all(ColonySpacing.lg),
      child: ListView(
        children: [
          Text(
            AppStrings.activationShield,
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: ColonySpacing.md),
          Text(AppStrings.activationShieldPolicyOnly),
          const SizedBox(height: ColonySpacing.sm),
          Text(AppStrings.activationShieldAllowlist),
          const SizedBox(height: ColonySpacing.lg),
          profiles.when(
            loading: () => const LinearProgressIndicator(),
            error: (_, _) => Text(AppStrings.errorGeneric),
            data: (items) {
              if (items.isEmpty) {
                return Text(AppStrings.activationSensorsOptional);
              }
              return Column(
                children: [
                  for (final profile in items)
                    Card(
                      child: ListTile(
                        title: Text(profile.name),
                        subtitle: Text(
                          '${profile.platformMode.name} · allowlist ${profile.allowlistCategories.join(', ')}',
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
          const SizedBox(height: ColonySpacing.lg),
          OutlinedButton(
            onPressed: () =>
                ref.read(activationControllerProvider.notifier).escapeShield(),
            child: const Text(AppStrings.activationEscape),
          ),
        ],
      ),
    );
  }
}
