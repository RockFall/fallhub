import 'package:colony_design_system/colony_design_system.dart';
import 'package:colony_domain/colony_domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/localization/app_strings.dart';
import '../application/music_atlas_controllers.dart';
import '../application/music_atlas_providers.dart';
import 'widgets/capture_music_encounter_sheet.dart';
import 'widgets/create_music_node_sheet.dart';
import 'widgets/import_music_atlas_json_sheet.dart';
import 'widgets/spotify_playlist_expedition_sheet.dart';

class MusicAtlasHubScreen extends ConsumerStatefulWidget {
  const MusicAtlasHubScreen({
    super.key,
    this.openImport = false,
    this.importSource,
  });

  final bool openImport;
  final String? importSource;

  @override
  ConsumerState<MusicAtlasHubScreen> createState() =>
      _MusicAtlasHubScreenState();
}

class _MusicAtlasHubScreenState extends ConsumerState<MusicAtlasHubScreen> {
  var _importOpened = false;

  @override
  void initState() {
    super.initState();
    if (widget.openImport) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || _importOpened) return;
        _importOpened = true;
        ImportMusicAtlasJsonSheet.show(context);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final overview = ref.watch(musicAtlasOverviewProvider);
    final constellation = ref.watch(musicSpotifyConstellationProvider);

    return ListView(
      padding: const EdgeInsets.all(ColonySpacing.lg),
      children: [
        Text(
          AppStrings.musicAtlasTitle,
          style: Theme.of(context).textTheme.headlineMedium,
        ),
        const SizedBox(height: ColonySpacing.xs),
        Text(
          AppStrings.musicAtlasSubtitle,
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const SizedBox(height: ColonySpacing.md),
        Wrap(
          spacing: ColonySpacing.sm,
          runSpacing: ColonySpacing.sm,
          children: [
            FilledButton.icon(
              onPressed: () => CreateMusicNodeSheet.show(context),
              icon: const Icon(Icons.add),
              label: const Text(AppStrings.musicAtlasCreateNode),
            ),
            OutlinedButton.icon(
              onPressed: () => ImportMusicAtlasJsonSheet.show(context),
              icon: const Icon(Icons.upload_file_outlined),
              label: const Text(AppStrings.musicAtlasImportJson),
            ),
            OutlinedButton.icon(
              onPressed: () => context.go('/research/music-atlas/constellation'),
              icon: const Icon(Icons.hub_outlined),
              label: const Text(AppStrings.musicAtlasConstellation),
            ),
            OutlinedButton.icon(
              onPressed: () => CaptureMusicEncounterSheet.showNowPlaying(context),
              icon: const Icon(Icons.hearing_outlined),
              label: const Text(AppStrings.musicAtlasNowPlaying),
            ),
            OutlinedButton.icon(
              onPressed: () => SpotifyPlaylistExpeditionSheet.show(context),
              icon: const Icon(Icons.playlist_play_outlined),
              label: const Text(AppStrings.musicAtlasDraftPlaylist),
            ),
          ],
        ),
        const SizedBox(height: ColonySpacing.lg),
        overview.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => Text('$error'),
          data: (data) {
            if (data.nodes.isEmpty) {
              return const ColonyPanel(
                title: AppStrings.musicAtlasTitle,
                child: Text(AppStrings.musicAtlasEmpty),
              );
            }
            final inbox = constellation.asData?.value.of(
              MusicSpotifyPartition.savedWithoutEncounter,
            );
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (inbox != null && inbox.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(bottom: ColonySpacing.md),
                    child: ColonyPanel(
                      title: AppStrings.musicAtlasSavedInbox,
                      child: Text('${inbox.length} álbuns gravados sem escuta atenta.'),
                    ),
                  ),
                ...data.nodes.map((node) {
                  final state = data.stateOf(node.id);
                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(node.canonicalName),
                    subtitle: Text(
                      [
                        AppStrings.musicAtlasNodeTypeLabel(node.nodeType),
                        if (node.beginYear != null) '${node.beginYear}',
                        if (state != null)
                          AppStrings.musicAtlasDiscoveryLabel(
                            state.discoveryState,
                          ),
                      ].join(' · '),
                    ),
                    onTap: () =>
                        context.go('/research/music-atlas/nodes/${node.id.value}'),
                  );
                }),
                if (data.expeditions.isNotEmpty) ...[
                  const SizedBox(height: ColonySpacing.lg),
                  Text(
                    AppStrings.musicAtlasExpeditions,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  ...data.expeditions.map(
                    (expedition) => ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(expedition.title),
                      subtitle: Text(
                        '${expedition.status.name} · ${expedition.question}',
                      ),
                      trailing: expedition.status == MusicExpeditionStatus.draft
                          ? TextButton(
                              onPressed: () => ref
                                  .read(musicAtlasControllerProvider.notifier)
                                  .startExpedition(expedition),
                              child: const Text(
                                AppStrings.musicAtlasStartExpedition,
                              ),
                            )
                          : null,
                    ),
                  ),
                ],
              ],
            );
          },
        ),
      ],
    );
  }
}
