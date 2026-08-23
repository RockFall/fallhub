import 'package:colony_design_system/colony_design_system.dart';
import 'package:colony_domain/colony_domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/localization/app_strings.dart';
import '../application/music_atlas_controllers.dart';
import '../application/music_atlas_providers.dart';

class MusicConstellationScreen extends ConsumerWidget {
  const MusicConstellationScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final constellation = ref.watch(musicSpotifyConstellationProvider);
    return ListView(
      padding: const EdgeInsets.all(ColonySpacing.lg),
      children: [
        Text(
          AppStrings.musicAtlasConstellation,
          style: Theme.of(context).textTheme.headlineMedium,
        ),
        const SizedBox(height: ColonySpacing.md),
        FilledButton(
          onPressed: () => ref
              .read(musicAtlasControllerProvider.notifier)
              .pullSpotifyLibrary(),
          child: const Text(AppStrings.musicAtlasSpotifyPull),
        ),
        const SizedBox(height: ColonySpacing.lg),
        constellation.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => Text('$error'),
          data: (data) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _Partition(
                  title: AppStrings.musicAtlasAttentiveSaved,
                  items: data.of(MusicSpotifyPartition.attentiveAndSaved),
                ),
                _Partition(
                  title: AppStrings.musicAtlasSavedInbox,
                  items: data.of(MusicSpotifyPartition.savedWithoutEncounter),
                ),
                _Partition(
                  title: AppStrings.musicAtlasLocalOnly,
                  items: data.of(MusicSpotifyPartition.localOnly),
                ),
              ],
            );
          },
        ),
      ],
    );
  }
}

class _Partition extends StatelessWidget {
  const _Partition({required this.title, required this.items});

  final String title;
  final List<MusicSpotifyConstellationItem> items;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: ColonySpacing.lg),
      child: ColonyPanel(
        title: '$title (${items.length})',
        child: items.isEmpty
            ? const Text('—')
            : Column(
                children: [
                  for (final item in items)
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(item.node.canonicalName),
                      onTap: () => context.go(
                        '/research/music-atlas/nodes/${item.node.id.value}',
                      ),
                    ),
                ],
              ),
      ),
    );
  }
}
