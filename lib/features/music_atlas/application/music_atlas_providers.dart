import 'package:colony_domain/colony_domain.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/app_providers.dart';

final musicAtlasOverviewProvider = FutureProvider<MusicAtlasOverview>((
  ref,
) async {
  final profile = await ref.watch(profileProvider.future);
  if (profile == null) {
    return const MusicAtlasOverview(
      nodes: [],
      states: [],
      encounters: [],
      expeditions: [],
      identities: [],
    );
  }
  return ref.watch(repositoriesProvider).musicAtlas.overview(profile.id);
});

final musicNodeInspectProvider =
    FutureProvider.family<MusicNodeInspect?, String>((ref, nodeId) async {
      final profile = await ref.watch(profileProvider.future);
      if (profile == null) return null;
      return ref
          .watch(repositoriesProvider)
          .musicAtlas
          .inspect(EntityId(nodeId), profile.id);
    });

final musicAtlasPromptProvider = FutureProvider<String>((ref) async {
  final profile = await ref.watch(profileProvider.future);
  if (profile == null) {
    return MusicAtlasJsonPromptBuilder.build(
      nodes: const [],
      claims: const [],
    );
  }
  final repos = ref.watch(repositoriesProvider);
  final overview = await repos.musicAtlas.overview(profile.id);
  final claims = await repos.musicAtlas.listClaims();
  final areas = await repos.flashcards.listAreas(profile.id);
  final placements = await repos.flashcards.listPlacements(profile.id);
  final decks = await repos.flashcards.listDecks(profile.id);
  final tags = await repos.flashcards.listTags(profile.id);
  final research = await repos.research.listAll(profile.id);
  return MusicAtlasJsonPromptBuilder.build(
    nodes: overview.nodes,
    claims: claims,
    areas: areas,
    placements: placements,
    decks: decks,
    tags: tags,
    researchNodes: research,
  );
});

final musicSpotifyConstellationProvider =
    FutureProvider<MusicSpotifyConstellation>((ref) async {
      final profile = await ref.watch(profileProvider.future);
      if (profile == null) {
        return const MusicSpotifyConstellation(items: []);
      }
      return ref.watch(repositoriesProvider).musicAtlas.constellation(profile.id);
    });

final musicExplorationProvider = FutureProvider<MusicExplorationMap>((
  ref,
) async {
  final profile = await ref.watch(profileProvider.future);
  if (profile == null) return MusicExplorationMap.empty;
  final repos = ref.watch(repositoriesProvider);
  final overview = await repos.musicAtlas.overview(profile.id);
  final claims = await repos.musicAtlas.listClaims();
  return MusicAtlasCartographer.compose(overview: overview, claims: claims);
});

final musicFlashcardCandidatesProvider =
    FutureProvider.family<List<MusicFlashcardCandidate>, String>((
      ref,
      encounterId,
    ) async {
      return ref
          .watch(repositoriesProvider)
          .musicAtlas
          .candidatesForEncounter(EntityId(encounterId));
    });
