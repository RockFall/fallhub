import 'package:colony_design_system/colony_design_system.dart';
import 'package:colony_domain/colony_domain.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/localization/app_strings.dart';
import '../application/activation_controllers.dart';
import '../application/activation_providers.dart';

class EnvironmentScreen extends ConsumerStatefulWidget {
  const EnvironmentScreen({super.key});

  @override
  ConsumerState<EnvironmentScreen> createState() => _EnvironmentScreenState();
}

class _EnvironmentScreenState extends ConsumerState<EnvironmentScreen> {
  final _contact = TextEditingController();
  final _message = TextEditingController();
  String? _dryRun;

  @override
  void dispose() {
    _contact.dispose();
    _message.dispose();
    super.dispose();
  }

  ActivationPlatformCapability get _capability {
    return switch (defaultTargetPlatform) {
      TargetPlatform.android => ActivationPlatformCapability.androidConservative,
      TargetPlatform.iOS => ActivationPlatformCapability.iosConservative,
      _ => ActivationPlatformCapability.desktop,
    };
  }

  @override
  Widget build(BuildContext context) {
    final contracts = ref.watch(activationRescueContractsProvider);
    final scenes = ref.watch(activationScenesProvider);
    final capability = _capability;
    return Padding(
      padding: const EdgeInsets.all(ColonySpacing.lg),
      child: ListView(
        children: [
          Text(
            AppStrings.activationEnvironment,
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: ColonySpacing.md),
          Text(
            AppStrings.activationCapabilityTitle,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          Text(
            '${capability.platform} · alarm ${capability.canExactAlarm} · '
            'passos ${capability.canSteps} · shield ${capability.canAppShield} · '
            'NFC ${capability.canNfc} · watch ${capability.watchCommands}',
          ),
          const SizedBox(height: ColonySpacing.sm),
          Text(AppStrings.activationWatchDeferred),
          const SizedBox(height: ColonySpacing.lg),
          Text(
            AppStrings.activationRescue,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          Text(AppStrings.activationRescueHint),
          TextField(
            controller: _contact,
            decoration: const InputDecoration(
              labelText: AppStrings.activationRescueContact,
            ),
          ),
          TextField(
            controller: _message,
            decoration: const InputDecoration(
              labelText: AppStrings.activationRescueMessage,
            ),
          ),
          const SizedBox(height: ColonySpacing.sm),
          FilledButton(
            onPressed: () async {
              if (_contact.text.trim().isEmpty) return;
              await ref.read(activationControllerProvider.notifier).saveRescue(
                    contactLabel: _contact.text.trim(),
                    messageTemplate: _message.text.trim().isEmpty
                        ? 'Estou travado. Sem detalhes.'
                        : _message.text.trim(),
                  );
              _contact.clear();
              _message.clear();
            },
            child: const Text(AppStrings.activationRescueArm),
          ),
          contracts.when(
            loading: () => const SizedBox.shrink(),
            error: (_, _) => Text(AppStrings.errorGeneric),
            data: (items) => Column(
              children: [
                for (final contract in items)
                  ListTile(
                    title: Text(contract.contactLabel),
                    subtitle: Text(
                      '${contract.status.name} · ${AppStrings.activationRescueHint}',
                    ),
                    trailing: TextButton(
                      onPressed: () => ref
                          .read(activationControllerProvider.notifier)
                          .requestRescueSend(contract),
                      child: const Text(AppStrings.activationRescueRequest),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: ColonySpacing.lg),
          Text(
            AppStrings.activationHaDryRun,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          scenes.when(
            loading: () => const SizedBox.shrink(),
            error: (_, _) => const SizedBox.shrink(),
            data: (items) => Text(
              items.isEmpty
                  ? AppStrings.activationSensorsOptional
                  : items.map((s) => s.name).join(', '),
            ),
          ),
          OutlinedButton(
            onPressed: () async {
              final result = await ref
                  .read(activationControllerProvider.notifier)
                  .dryRunFirstScene();
              setState(() {
                _dryRun = result == null
                    ? AppStrings.activationSensorsOptional
                    : '${result.action} · reversível ${result.reversible}';
              });
            },
            child: const Text(AppStrings.activationHaDryRun),
          ),
          if (_dryRun != null) Text(_dryRun!),
        ],
      ),
    );
  }
}
