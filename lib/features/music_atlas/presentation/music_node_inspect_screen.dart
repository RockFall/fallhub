import 'package:colony_design_system/colony_design_system.dart';
import 'package:colony_domain/colony_domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../app/localization/app_strings.dart';
import '../application/music_atlas_controllers.dart';
import '../application/music_atlas_providers.dart';
import 'widgets/capture_music_encounter_sheet.dart';
import 'widgets/music_flashcard_candidates_sheet.dart';

class MusicNodeInspectScreen extends ConsumerWidget {
  const MusicNodeInspectScreen({super.key, required this.nodeId});

  final String nodeId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final inspect = ref.watch(musicNodeInspectProvider(nodeId));
    return inspect.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => Center(child: Text('$error')),
      data: (data) {
        if (data == null) {
          return const Center(child: Text(AppStrings.musicAtlasEmpty));
        }
        final spotify = data.identities.where((i) => i.provider == 'spotify');
        return ListView(
          padding: const EdgeInsets.all(ColonySpacing.lg),
          children: [
            Text(
              data.node.canonicalName,
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            Text(
              [
                AppStrings.musicAtlasNodeTypeLabel(data.node.nodeType),
                if (data.node.beginYear != null) '${data.node.beginYear}',
                if (data.state != null)
                  AppStrings.musicAtlasDiscoveryLabel(data.state!.discoveryState),
              ].join(' · '),
            ),
            if (data.node.description != null) ...[
              const SizedBox(height: ColonySpacing.sm),
              Text(data.node.description!),
            ],
            const SizedBox(height: ColonySpacing.md),
            Wrap(
              spacing: ColonySpacing.sm,
              children: [
                if (MusicNodeKind.isAlbumLike(data.node.nodeType))
                  FilledButton(
                    onPressed: () => context.go(
                      '/research/music-atlas/albums/${data.node.id.value}',
                    ),
                    child: const Text(AppStrings.musicAtlasOpenAlbum),
                  ),
                FilledButton(
                  onPressed: () => CaptureMusicEncounterSheet.show(
                    context,
                    nodeId: data.node.id,
                  ),
                  child: const Text(AppStrings.musicAtlasCapture),
                ),
                if (data.encounters.isNotEmpty)
                  OutlinedButton(
                    onPressed: () => MusicFlashcardCandidatesSheet.show(
                      context,
                      encounterId: data.encounters.first.id,
                    ),
                    child: const Text(AppStrings.musicAtlasSuggestCards),
                  ),
                if (spotify.isNotEmpty)
                  OutlinedButton(
                    onPressed: () {
                      final id = spotify.first.externalId;
                      final uri = Uri.parse(MusicSpotifyPolicy.openAlbumUri(id));
                      launchUrl(uri, mode: LaunchMode.externalApplication).catchError((
                        _,
                      ) {
                        return launchUrl(
                          Uri.parse(MusicSpotifyPolicy.openAlbumUrl(id)),
                        );
                      });
                    },
                    child: const Text(AppStrings.musicAtlasOpenSpotify),
                  ),
              ],
            ),
            const SizedBox(height: ColonySpacing.lg),
            ColonyPanel(
              title: AppStrings.musicAtlasState,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (final state in MusicDiscoveryState.values)
                    RadioListTile<MusicDiscoveryState>(
                      contentPadding: EdgeInsets.zero,
                      title: Text(AppStrings.musicAtlasDiscoveryLabel(state)),
                      value: state,
                      groupValue:
                          data.state?.discoveryState ??
                          MusicDiscoveryState.unmapped,
                      onChanged: (value) {
                        if (value == null) return;
                        ref
                            .read(musicAtlasControllerProvider.notifier)
                            .setState(nodeId: data.node.id, state: value);
                      },
                    ),
                ],
              ),
            ),
            const SizedBox(height: ColonySpacing.md),
            ColonyPanel(
              title: AppStrings.musicAtlasEncountersTitle,
              child: data.encounters.isEmpty
                  ? const Text('Nenhum encontro ainda.')
                  : Column(
                      children: [
                        for (final encounter in data.encounters)
                          ListTile(
                            contentPadding: EdgeInsets.zero,
                            title: Text(
                              AppStrings.musicAtlasEncounterLabel(
                                encounter.encounterType,
                              ),
                            ),
                            subtitle: Text(
                              [
                                encounter.occurredAt.toIso8601String(),
                                if (encounter.note != null) encounter.note!,
                              ].join(' · '),
                            ),
                          ),
                      ],
                    ),
            ),
            if (data.claimsFrom.isNotEmpty || data.claimsTo.isNotEmpty) ...[
              const SizedBox(height: ColonySpacing.md),
              ColonyPanel(
                title: AppStrings.musicAtlasRelationsTitle,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    for (final claim in [...data.claimsFrom, ...data.claimsTo])
                      Text(
                        '${claim.relationType.name} · ${claim.status.name}'
                        '${claim.description == null ? '' : ' — ${claim.description}'}',
                      ),
                  ],
                ),
              ),
            ],
          ],
        );
      },
    );
  }
}
