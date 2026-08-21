import 'package:colony_design_system/colony_design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/localization/app_strings.dart';
import '../../core/providers/app_providers.dart';

class BootScreen extends StatelessWidget {
  const BootScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: ColonySpacing.lg),
            Text(AppStrings.loading),
          ],
        ),
      ),
    );
  }
}

class BootErrorScreen extends ConsumerWidget {
  const BootErrorScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(profileProvider);
    final prefs = ref.watch(preferencesProvider);
    final error = profile.error ?? prefs.error ?? AppStrings.errorGeneric;

    return Scaffold(
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: Padding(
            padding: const EdgeInsets.all(ColonySpacing.xl),
            child: ColonyPanel(
              title: AppStrings.bootErrorTitle,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(AppStrings.bootErrorBody),
                  const SizedBox(height: ColonySpacing.md),
                  SelectableText(
                    error.toString(),
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(height: ColonySpacing.xl),
                  FilledButton(
                    onPressed: () {
                      ref.invalidate(profileProvider);
                      ref.invalidate(preferencesProvider);
                    },
                    child: const Text(AppStrings.bootRetry),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
