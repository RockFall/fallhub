import 'package:colony_design_system/colony_design_system.dart';
import 'package:colony_domain/colony_domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/localization/app_strings.dart';
import '../application/activation_providers.dart';

class ProtocolListScreen extends ConsumerWidget {
  const ProtocolListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final protocols = ref.watch(activationProtocolsProvider);
    return Padding(
      padding: const EdgeInsets.all(ColonySpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            AppStrings.activationProtocols,
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: ColonySpacing.sm),
          Text(
            AppStrings.activationSubtitle,
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: ColonySpacing.lg),
          Expanded(
            child: protocols.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (_, _) => Center(child: Text(AppStrings.errorGeneric)),
              data: (items) {
                if (items.isEmpty) {
                  return Center(child: Text(AppStrings.activationEmpty));
                }
                return ListView.builder(
                  itemCount: items.length,
                  itemBuilder: (context, index) {
                    final protocol = items[index];
                    final spec = ActivationVisualCatalog.forProtocol(protocol);
                    return Padding(
                      padding: const EdgeInsets.only(bottom: ColonySpacing.sm),
                      child: ColonyJourneyCard(
                        assetPath: spec.artAsset,
                        eyebrow: AppStrings.activationProtocolTypeLabel(
                          protocol.protocolType,
                        ),
                        title: protocol.name,
                        subtitle:
                            '${spec.journeyLabel} · ${protocol.originState.label} → ${protocol.targetState.label}',
                        height: 128,
                        onTap: () => context.go(
                          '/activation/protocols/${protocol.id.value}',
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
