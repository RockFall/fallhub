import 'package:colony_domain/colony_domain.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/app_providers.dart';
import 'activation_providers.dart';

class ActivationController extends AsyncNotifier<void> {
  @override
  Future<void> build() async {}

  Future<ActivationEpisode?> startProtocol({
    required EntityId protocolId,
    ActivationCapacityMode capacity = ActivationCapacityMode.standard,
    ActivationTriggerType trigger = ActivationTriggerType.userRequested,
  }) async {
    final profile = await ref.read(profileProvider.future);
    if (profile == null) return null;
    state = const AsyncLoading();
    ActivationEpisode? started;
    state = await AsyncValue.guard(() async {
      final bundle =
          await ref.read(repositoriesProvider).activation.getBundle(protocolId);
      if (bundle == null) {
        throw StateError('Protocolo não encontrado');
      }
      started = await ref.read(activationOrchestratorProvider).start(
            profileId: profile.id,
            bundle: bundle,
            capacity: capacity,
            triggerType: trigger,
          );
    });
    return started;
  }

  Future<ActivationEpisode?> startPreferred({
    required ActivationProtocolType type,
    ActivationCapacityMode capacity = ActivationCapacityMode.standard,
  }) async {
    final profile = await ref.read(profileProvider.future);
    if (profile == null) return null;
    state = const AsyncLoading();
    ActivationEpisode? started;
    state = await AsyncValue.guard(() async {
      final orch = ref.read(activationOrchestratorProvider);
      final bundle = await orch.pickProtocol(
        profileId: profile.id,
        capacity: capacity,
        preferredType: type,
      );
      if (bundle == null) {
        throw StateError('Nenhuma rota disponível');
      }
      started = await orch.start(
        profileId: profile.id,
        bundle: bundle,
        capacity: capacity,
      );
    });
    return started;
  }

  Future<void> confirm(EntityId episodeId) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() {
      return ref
          .read(activationOrchestratorProvider)
          .confirmCurrent(episodeId: episodeId);
    });
    ref.invalidate(activationSnapshotProvider(episodeId.value));
  }

  Future<void> skip(EntityId episodeId) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() {
      return ref.read(activationOrchestratorProvider).skipCurrent(episodeId);
    });
    ref.invalidate(activationSnapshotProvider(episodeId.value));
  }

  Future<void> adapt(EntityId episodeId) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() {
      return ref.read(activationOrchestratorProvider).adaptCurrent(episodeId);
    });
    ref.invalidate(activationSnapshotProvider(episodeId.value));
  }

  Future<void> pause(EntityId episodeId) async {
    state = await AsyncValue.guard(() {
      return ref.read(activationOrchestratorProvider).pause(episodeId);
    });
    ref.invalidate(activationSnapshotProvider(episodeId.value));
  }

  Future<void> resume(EntityId episodeId) async {
    state = await AsyncValue.guard(() {
      return ref.read(activationOrchestratorProvider).resume(episodeId);
    });
    ref.invalidate(activationSnapshotProvider(episodeId.value));
  }

  Future<void> abort(EntityId episodeId) async {
    state = await AsyncValue.guard(() {
      return ref.read(activationOrchestratorProvider).abort(episodeId);
    });
    ref.invalidate(activationSnapshotProvider(episodeId.value));
  }

  Future<void> recover(EntityId episodeId) async {
    state = await AsyncValue.guard(() {
      return ref
          .read(activationOrchestratorProvider)
          .convertToRecovery(episodeId);
    });
    ref.invalidate(activationSnapshotProvider(episodeId.value));
  }

  Future<void> falsePositive(EntityId episodeId) async {
    state = await AsyncValue.guard(() {
      return ref
          .read(activationOrchestratorProvider)
          .reportFalsePositive(episodeId);
    });
    ref.invalidate(activationSnapshotProvider(episodeId.value));
  }

  Future<void> applyShield(EntityId episodeId) async {
    final profile = await ref.read(profileProvider.future);
    if (profile == null) return;
    state = await AsyncValue.guard(() {
      return ref.read(activationOrchestratorProvider).applyShield(
            profileId: profile.id,
            episodeId: episodeId,
          );
    });
  }

  Future<void> escapeShield() async {
    final profile = await ref.read(profileProvider.future);
    if (profile == null) return;
    state = await AsyncValue.guard(() {
      return ref.read(activationOrchestratorProvider).escapeShield(profile.id);
    });
  }

  Future<void> reachWaypoint(String token) async {
    final profile = await ref.read(profileProvider.future);
    if (profile == null) return;
    state = await AsyncValue.guard(() {
      return ref.read(activationOrchestratorProvider).observeWaypointToken(
            profileId: profile.id,
            token: token,
          );
    });
  }

  Future<void> createWaypoint({
    required String name,
    required ActivationWaypointType type,
    String? token,
    EntityId? zoneId,
  }) async {
    final profile = await ref.read(profileProvider.future);
    if (profile == null) return;
    final now = ref.read(clockProvider)();
    await ref.read(repositoriesProvider).activation.upsertWaypoint(
          ActivationWaypoint(
            id: EntityId(ref.read(idGeneratorProvider).newId()),
            profileId: profile.id,
            name: name,
            waypointType: type,
            token: token,
            zoneId: zoneId,
            createdAt: now,
            updatedAt: now,
          ),
        );
  }

  Future<void> saveProtocol(ActivationProtocol protocol) async {
    final bundle =
        await ref.read(repositoriesProvider).activation.getBundle(protocol.id);
    if (bundle == null) return;
    await ref.read(repositoriesProvider).activation.saveBundle(
          ActivationProtocolBundle(
            protocol: protocol,
            version: bundle.version,
            commands: bundle.commands,
          ),
        );
  }

  Future<void> publishProtocol(ActivationProtocolBundle bundle) async {
    await ref.read(repositoriesProvider).activation.publishNewVersion(
          current: bundle,
          commands: bundle.commands,
        );
  }

  Future<void> alreadyDone(EntityId episodeId) async {
    state = await AsyncValue.guard(() {
      return ref
          .read(activationOrchestratorProvider)
          .markAlreadyDone(episodeId);
    });
    ref.invalidate(activationSnapshotProvider(episodeId.value));
  }

  Future<void> declareResting() async {
    final profile = await ref.read(profileProvider.future);
    if (profile == null) return;
    await ref.read(activationOrchestratorProvider).declareResting(profile.id);
    ref.invalidate(activationDetectionProvider);
  }

  Future<void> analyzeExperiments() async {
    final profile = await ref.read(profileProvider.future);
    if (profile == null) return;
    await ref
        .read(activationOrchestratorProvider)
        .analyzeRunningExperiments(profile.id);
    ref.invalidate(activationInsightsProvider);
    ref.invalidate(activationExperimentsProvider);
  }

  Future<void> saveRescue({
    required String contactLabel,
    required String messageTemplate,
  }) async {
    final profile = await ref.read(profileProvider.future);
    if (profile == null) return;
    final contract = RescueContract(
      id: EntityId(ref.read(idGeneratorProvider).newId()),
      profileId: profile.id,
      contactLabel: contactLabel,
      messageTemplate: messageTemplate,
      status: RescueContractStatus.inactive,
    );
    await ref.read(activationOrchestratorProvider).armRescue(contract);
    ref.invalidate(activationRescueContractsProvider);
  }

  Future<void> requestRescueSend(RescueContract contract) async {
    await ref.read(activationOrchestratorProvider).requestRescueSend(contract);
    ref.invalidate(activationRescueContractsProvider);
  }

  Future<HomeAutomationDryRun?> dryRunFirstScene() async {
    final profile = await ref.read(profileProvider.future);
    if (profile == null) return null;
    final scenes =
        await ref.read(repositoriesProvider).activation.listScenes(profile.id);
    if (scenes.isEmpty) return null;
    return ref.read(activationOrchestratorProvider).simulateScene(scenes.first);
  }
}

final activationControllerProvider =
    AsyncNotifierProvider<ActivationController, void>(ActivationController.new);
