import 'package:colony_domain/colony_domain.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/app_providers.dart';
import 'activation_orchestrator.dart';

final activationOrchestratorProvider = Provider<ActivationOrchestrator>((ref) {
  final repos = ref.watch(repositoriesProvider);
  return ActivationOrchestrator(
    repository: repos.activation,
    ids: ref.watch(idGeneratorProvider),
    clock: ref.watch(clockProvider),
  );
});

final activationSeedProvider = FutureProvider<int>((ref) async {
  final profile = await ref.watch(profileProvider.future);
  if (profile == null) return 0;
  return ref.watch(activationOrchestratorProvider).ensureSeeded(profile.id);
});

final activationProtocolsProvider =
    StreamProvider<List<ActivationProtocol>>((ref) async* {
  await ref.watch(activationSeedProvider.future);
  final profile = await ref.watch(profileProvider.future);
  if (profile == null) {
    yield const [];
    return;
  }
  yield* ref.watch(repositoriesProvider).activation.watchProtocols(profile.id);
});

final activationEpisodesProvider =
    StreamProvider<List<ActivationEpisode>>((ref) async* {
  await ref.watch(activationSeedProvider.future);
  final profile = await ref.watch(profileProvider.future);
  if (profile == null) {
    yield const [];
    return;
  }
  yield* ref.watch(repositoriesProvider).activation.watchEpisodes(profile.id);
});

final openActivationEpisodeProvider =
    Provider<AsyncValue<ActivationEpisode?>>((ref) {
  return ref.watch(activationEpisodesProvider).whenData((episodes) {
    for (final episode in episodes) {
      if (episode.status.isOpen) return episode;
    }
    return null;
  });
});

final activationWaypointsProvider =
    StreamProvider<List<ActivationWaypoint>>((ref) async* {
  await ref.watch(activationSeedProvider.future);
  final profile = await ref.watch(profileProvider.future);
  if (profile == null) {
    yield const [];
    return;
  }
  yield* ref.watch(repositoriesProvider).activation.watchWaypoints(profile.id);
});

final activationInsightsProvider =
    FutureProvider<List<ActivationInsight>>((ref) async {
  final profile = await ref.watch(profileProvider.future);
  if (profile == null) return const [];
  return ref.watch(repositoriesProvider).activation.listInsights(profile.id);
});

final activationExperimentsProvider =
    FutureProvider<List<ActivationExperiment>>((ref) async {
  final profile = await ref.watch(profileProvider.future);
  if (profile == null) return const [];
  return ref.watch(repositoriesProvider).activation.listExperiments(profile.id);
});

final activationShieldProfilesProvider =
    FutureProvider<List<FrictionShieldProfile>>((ref) async {
  final profile = await ref.watch(profileProvider.future);
  if (profile == null) return const [];
  return ref
      .watch(repositoriesProvider)
      .activation
      .listShieldProfiles(profile.id);
});

final activationSnapshotProvider =
    FutureProvider.family<ActivationSnapshot?, String>((ref, episodeId) async {
  if (episodeId.isEmpty) return null;
  return ref.watch(activationOrchestratorProvider).loadSnapshot(
        EntityId(episodeId),
      );
});

final activationScheduleContextProvider =
    FutureProvider<ActivationScheduleContext>((ref) async {
  final profile = await ref.watch(profileProvider.future);
  final now = ref.watch(clockProvider)();
  if (profile == null) {
    return ActivationScheduleContext.fromBlocks(
      now: now,
      currentModes: const [],
      hasUpcomingFocus: false,
    );
  }
  final blocks =
      await ref.watch(repositoriesProvider).schedule.listAll(profile.id);
  final current = [
    for (final block in blocks)
      if (!now.isBefore(block.startAt) && now.isBefore(block.endAt)) block.mode,
  ];
  final upcoming = blocks.any(
    (block) =>
        block.mode == ScheduleBlockMode.focus &&
        block.startAt.isAfter(now) &&
        block.startAt.difference(now) <= const Duration(hours: 3),
  );
  return ActivationScheduleContext.fromBlocks(
    now: now,
    currentModes: current,
    hasUpcomingFocus: upcoming,
  );
});

final activationDetectionProvider =
    FutureProvider<ActivationDetectionProposal?>((ref) async {
  await ref.watch(activationSeedProvider.future);
  final profile = await ref.watch(profileProvider.future);
  if (profile == null) return null;
  final schedule = await ref.watch(activationScheduleContextProvider.future);
  return ref.watch(activationOrchestratorProvider).detect(
        profileId: profile.id,
        schedule: schedule,
      );
});

final activationRescueContractsProvider =
    FutureProvider<List<RescueContract>>((ref) async {
  final profile = await ref.watch(profileProvider.future);
  if (profile == null) return const [];
  return ref.watch(repositoriesProvider).activation.listRescueContracts(
        profile.id,
      );
});

final activationScenesProvider =
    FutureProvider<List<ActivationScene>>((ref) async {
  final profile = await ref.watch(profileProvider.future);
  if (profile == null) return const [];
  return ref.watch(repositoriesProvider).activation.listScenes(profile.id);
});
