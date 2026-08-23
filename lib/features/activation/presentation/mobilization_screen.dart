import 'package:colony_design_system/colony_design_system.dart';
import 'package:colony_domain/colony_domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/localization/app_strings.dart';
import '../application/activation_controllers.dart';
import '../application/activation_orchestrator.dart';
import '../application/activation_providers.dart';

class MobilizationScreen extends ConsumerWidget {
  const MobilizationScreen({
    super.key,
    required this.episodeId,
    this.protocolId,
  });

  final String? episodeId;
  final String? protocolId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (episodeId == null || episodeId!.isEmpty) {
      return _StartRouteBody(protocolId: protocolId);
    }
    final snapshot = ref.watch(activationSnapshotProvider(episodeId!));
    return snapshot.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, _) => Center(child: Text(AppStrings.errorGeneric)),
      data: (data) {
        if (data == null) {
          return Center(child: Text(AppStrings.activationEmpty));
        }
        return _DraftModeBody(snapshot: data);
      },
    );
  }
}

class _StartRouteBody extends ConsumerStatefulWidget {
  const _StartRouteBody({this.protocolId});

  final String? protocolId;

  @override
  ConsumerState<_StartRouteBody> createState() => _StartRouteBodyState();
}

class _StartRouteBodyState extends ConsumerState<_StartRouteBody> {
  ActivationCapacityMode _capacity = ActivationCapacityMode.standard;
  var _started = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _maybeAutostart());
  }

  Future<void> _maybeAutostart() async {
    if (_started) return;
    final id = widget.protocolId;
    if (id == null || id.isEmpty) return;
    _started = true;
    final episode = await ref
        .read(activationControllerProvider.notifier)
        .startProtocol(protocolId: EntityId(id), capacity: _capacity);
    if (!mounted || episode == null) return;
    context.go('/activation/episodes/${episode.id.value}');
  }

  @override
  Widget build(BuildContext context) {
    final protocols = ref.watch(activationProtocolsProvider);
    return Padding(
      padding: const EdgeInsets.all(ColonySpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            AppStrings.activationStartMorning,
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: ColonySpacing.md),
          Text(AppStrings.activationCapacity),
          const SizedBox(height: ColonySpacing.sm),
          Wrap(
            spacing: ColonySpacing.sm,
            children: [
              for (final mode in ActivationCapacityMode.values)
                ChoiceChip(
                  label: Text(AppStrings.activationCapacityLabel(mode)),
                  selected: _capacity == mode,
                  onSelected: (_) => setState(() => _capacity = mode),
                ),
            ],
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
                return ListView(
                  children: [
                    for (final protocol in items)
                      ListTile(
                        title: Text(protocol.name),
                        subtitle: Text(protocol.description ?? ''),
                        onTap: () async {
                          final episode = await ref
                              .read(activationControllerProvider.notifier)
                              .startProtocol(
                                protocolId: protocol.id,
                                capacity: _capacity,
                              );
                          if (!context.mounted || episode == null) return;
                          context.go(
                            '/activation/episodes/${episode.id.value}',
                          );
                        },
                      ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _DraftModeBody extends ConsumerWidget {
  const _DraftModeBody({required this.snapshot});

  final ActivationSnapshot snapshot;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final episode = snapshot.episode;
    final current = snapshot.current;
    final controller = ref.read(activationControllerProvider.notifier);
    final released = episode.status == ActivationEpisodeStatus.released ||
        episode.status == ActivationEpisodeStatus.convertedToRecovery;

    return Padding(
      padding: const EdgeInsets.all(ColonySpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  snapshot.bundle?.protocol.name ??
                      AppStrings.activationDraftTitle,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              TextButton(
                onPressed: () => controller.abort(episode.id),
                child: const Text(AppStrings.activationEscape),
              ),
            ],
          ),
          Text(
            AppStrings.activationStatus(episode.status),
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: ColonySpacing.xl),
          Expanded(
            child: Center(
              child: released
                  ? Text(
                      episode.targetState.label,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.headlineMedium,
                    )
                  : Semantics(
                      header: true,
                      liveRegion: true,
                      child: Text(
                        current?.instructionRendered ??
                            AppStrings.activationOperational,
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.displaySmall,
                      ),
                    ),
            ),
          ),
          if (snapshot.proofs.isNotEmpty)
            Text(
              '${AppStrings.activationProofSource}: ${snapshot.proofs.last.source}',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          if (current?.deepLink != null && current!.deepLink!.isNotEmpty)
            TextButton(
              onPressed: () => context.go(current.deepLink!),
              child: const Text(AppStrings.activationOpenFirstAction),
            ),
          ExpansionTile(
            title: const Text(AppStrings.activationRouteCollapsed),
            children: [
              for (final run in snapshot.runs)
                ListTile(
                  dense: true,
                  title: Text(run.instructionRendered),
                  subtitle: Text(run.status.name),
                ),
            ],
          ),
          const SizedBox(height: ColonySpacing.md),
          if (!released && current != null) ...[
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => controller.adapt(episode.id),
                    child: const Text(AppStrings.activationAdapt),
                  ),
                ),
                const SizedBox(width: ColonySpacing.sm),
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => controller.skip(episode.id),
                    child: const Text(AppStrings.activationSkip),
                  ),
                ),
                const SizedBox(width: ColonySpacing.sm),
                Expanded(
                  child: FilledButton(
                    onPressed: () => controller.confirm(episode.id),
                    child: const Text(AppStrings.activationConfirm),
                  ),
                ),
              ],
            ),
            const SizedBox(height: ColonySpacing.sm),
            Wrap(
              spacing: ColonySpacing.sm,
              children: [
                TextButton(
                  onPressed: () => controller.pause(episode.id),
                  child: const Text(AppStrings.activationPause),
                ),
                TextButton(
                  onPressed: () => controller.recover(episode.id),
                  child: const Text(AppStrings.activationRecover),
                ),
                TextButton(
                  onPressed: () => controller.falsePositive(episode.id),
                  child: const Text(AppStrings.activationFalsePositive),
                ),
                TextButton(
                  onPressed: () => controller.alreadyDone(episode.id),
                  child: const Text(AppStrings.activationAlreadyDone),
                ),
              ],
            ),
          ] else if (episode.status == ActivationEpisodeStatus.paused)
            FilledButton(
              onPressed: () => controller.resume(episode.id),
              child: const Text(AppStrings.activationResume),
            )
          else
            OutlinedButton(
              onPressed: () => context.go('/activation'),
              child: const Text(AppStrings.activationTitle),
            ),
          const SizedBox(height: ColonySpacing.sm),
          Text(
            AppStrings.activationEscapeHint,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}
