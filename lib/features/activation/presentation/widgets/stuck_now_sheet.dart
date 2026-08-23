import 'package:colony_design_system/colony_design_system.dart';
import 'package:colony_domain/colony_domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/localization/app_strings.dart';
import '../../../../core/providers/app_providers.dart';
import '../../application/activation_controllers.dart';
import '../../application/activation_providers.dart';

class StuckNowSheet extends ConsumerWidget {
  const StuckNowSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (_) => const StuckNowSheet(),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final schedule = ref.watch(activationScheduleContextProvider).asData?.value;
    final choices = ActivationStuckNowPolicy.choices(
      now: ref.watch(clockProvider)(),
      hasUpcomingFocus: schedule?.hasUpcomingFocus ?? false,
    );
    return Padding(
      padding: const EdgeInsets.all(ColonySpacing.lg),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            AppStrings.activationStuckNow,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: ColonySpacing.sm),
          Text(
            AppStrings.activationDisclaimer,
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: ColonySpacing.lg),
          for (final choice in choices.take(2))
            Padding(
              padding: const EdgeInsets.only(bottom: ColonySpacing.sm),
              child: FilledButton(
                onPressed: () async {
                  final episode = await ref
                      .read(activationControllerProvider.notifier)
                      .startPreferred(type: choice.protocolType);
                  if (!context.mounted) return;
                  Navigator.of(context).pop();
                  if (episode != null) {
                    context.go('/activation/episodes/${episode.id.value}');
                  }
                },
                child: Text(choice.label),
              ),
            ),
        ],
      ),
    );
  }
}
