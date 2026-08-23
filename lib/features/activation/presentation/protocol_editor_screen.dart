import 'package:colony_design_system/colony_design_system.dart';
import 'package:colony_domain/colony_domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/localization/app_strings.dart';
import '../../../core/providers/app_providers.dart';
import '../application/activation_controllers.dart';

class ProtocolEditorScreen extends ConsumerStatefulWidget {
  const ProtocolEditorScreen({super.key, required this.protocolId});

  final String protocolId;

  @override
  ConsumerState<ProtocolEditorScreen> createState() =>
      _ProtocolEditorScreenState();
}

class _ProtocolEditorScreenState extends ConsumerState<ProtocolEditorScreen> {
  ActivationProtocolBundle? _bundle;
  var _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final bundle = await ref.read(repositoriesProvider).activation.getBundle(
          EntityId(widget.protocolId),
        );
    if (!mounted) return;
    setState(() {
      _bundle = bundle;
      _loading = false;
      _error = bundle == null ? AppStrings.activationEmpty : null;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    final bundle = _bundle;
    if (bundle == null) {
      return Center(child: Text(_error ?? AppStrings.activationEmpty));
    }
    return Padding(
      padding: const EdgeInsets.all(ColonySpacing.lg),
      child: ListView(
        children: [
          Text(
            bundle.protocol.name,
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: ColonySpacing.sm),
          Text(bundle.protocol.description ?? ''),
          Text(
            'v${bundle.protocol.activeVersion} · '
            '${bundle.protocol.maturity.name}',
          ),
          const SizedBox(height: ColonySpacing.md),
          SwitchListTile(
            title: const Text(AppStrings.activationEnabled),
            value: bundle.protocol.isEnabled,
            onChanged: (value) async {
              await ref.read(activationControllerProvider.notifier).saveProtocol(
                    bundle.protocol.copyWith(isEnabled: value),
                  );
              await _load();
            },
          ),
          const SizedBox(height: ColonySpacing.md),
          Text(AppStrings.activationTriggerRelease),
          const SizedBox(height: ColonySpacing.sm),
          for (var i = 0; i < bundle.orderedCommands.length; i++)
            _CommandCard(
              command: bundle.orderedCommands[i],
              onChanged: (updated) {
                final commands = [...bundle.orderedCommands];
                commands[i] = updated;
                setState(() {
                  _bundle = ActivationProtocolBundle(
                    protocol: bundle.protocol,
                    version: bundle.version,
                    commands: commands,
                  );
                });
              },
            ),
          const SizedBox(height: ColonySpacing.md),
          OutlinedButton(
            onPressed: () {
              final next = bundle.orderedCommands.length + 1;
              setState(() {
                _bundle = ActivationProtocolBundle(
                  protocol: bundle.protocol,
                  version: bundle.version,
                  commands: [
                    ...bundle.orderedCommands,
                    ActivationCommandTemplate(
                      id: EntityId(ref.read(idGeneratorProvider).newId()),
                      protocolId: bundle.protocol.id,
                      protocolVersion: bundle.version.version,
                      sequenceKey: next.toString().padLeft(2, '0'),
                      instruction: 'Dê três passos para frente.',
                      actionVerb: 'Dê',
                    ),
                  ],
                );
              });
            },
            child: const Text(AppStrings.activationAddCommand),
          ),
          const SizedBox(height: ColonySpacing.sm),
          FilledButton(
            onPressed: () async {
              await ref
                  .read(activationControllerProvider.notifier)
                  .publishProtocol(_bundle!);
              if (!mounted) return;
              await _load();
            },
            child: const Text(AppStrings.activationSaveVersion),
          ),
          const SizedBox(height: ColonySpacing.sm),
          FilledButton.tonal(
            onPressed: () => context.go(
              '/activation/start?protocol=${bundle.protocol.id.value}',
            ),
            child: const Text(AppStrings.activationMobilize),
          ),
        ],
      ),
    );
  }
}

class _CommandCard extends StatefulWidget {
  const _CommandCard({required this.command, required this.onChanged});

  final ActivationCommandTemplate command;
  final ValueChanged<ActivationCommandTemplate> onChanged;

  @override
  State<_CommandCard> createState() => _CommandCardState();
}

class _CommandCardState extends State<_CommandCard> {
  late final TextEditingController _instruction;

  @override
  void initState() {
    super.initState();
    _instruction = TextEditingController(text: widget.command.instruction);
  }

  @override
  void didUpdateWidget(covariant _CommandCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.command.instruction != widget.command.instruction &&
        _instruction.text != widget.command.instruction) {
      _instruction.text = widget.command.instruction;
    }
  }

  @override
  void dispose() {
    _instruction.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final rejected = ActivationCommandGrammar.rejectReason(_instruction.text);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(ColonySpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _instruction,
              decoration: InputDecoration(
                labelText: AppStrings.activationNextMove,
                errorText: rejected == null ? null : AppStrings.activationDisclaimer,
              ),
              onChanged: (value) => widget.onChanged(
                widget.command.copyWith(
                  instruction: value,
                  actionVerb: value.trim().split(RegExp(r'\s+')).first,
                ),
              ),
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text(AppStrings.activationFirstMeaningful),
              value: widget.command.isFirstMeaningfulAction,
              onChanged: (value) => widget.onChanged(
                widget.command.copyWith(
                  isFirstMeaningfulAction: value,
                  releasesOnConfirm: value,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
