import 'package:colony_design_system/colony_design_system.dart';
import 'package:colony_domain/colony_domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/localization/app_strings.dart';
import '../application/music_atlas_providers.dart';
import 'widgets/genre_ramification_map.dart';

class MusicAtlasExploreScreen extends ConsumerStatefulWidget {
  const MusicAtlasExploreScreen({super.key, this.initialTerritory});

  final String? initialTerritory;

  @override
  ConsumerState<MusicAtlasExploreScreen> createState() =>
      _MusicAtlasExploreScreenState();
}

class _MusicAtlasExploreScreenState
    extends ConsumerState<MusicAtlasExploreScreen> {
  String? _selected;

  @override
  void initState() {
    super.initState();
    _selected = widget.initialTerritory;
  }

  @override
  Widget build(BuildContext context) {
    final asyncMap = ref.watch(musicExplorationProvider);

    return asyncMap.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => Center(child: Text('$error')),
      data: (base) {
        final selectedAlbums = _selected == null
            ? const <MusicExplorationAlbum>[]
            : base.albumsIn(_selected!);
        final layout = MusicRamificationLayouter.layout(
          territories: base.territories,
          selectedKey: _selected,
          selectedAlbums: selectedAlbums,
        );
        final selected = _selected == null ? null : base.territory(_selected!);
        final heard = selectedAlbums.where((a) => a.heard).length;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                ColonySpacing.lg,
                ColonySpacing.md,
                ColonySpacing.lg,
                ColonySpacing.sm,
              ),
              child: _ExploreHeader(
                selected: selected,
                heard: heard,
                contact: selectedAlbums.length - heard,
                onClear: _selected == null
                    ? null
                    : () => setState(() => _selected = null),
              ),
            ),
            Expanded(
              child: DecoratedBox(
                decoration: const BoxDecoration(color: ColonyColors.void_),
                child: GenreRamificationMap(
                  map: base,
                  layout: layout,
                  selectedKey: _selected,
                  onSelectTerritory: (key) {
                    setState(() {
                      _selected = _selected == key ? null : key;
                    });
                  },
                  onOpenAlbum: (album) {
                    context.push(
                      '/research/music-atlas/albums/${album.node.id.value}',
                    );
                  },
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _ExploreHeader extends StatelessWidget {
  const _ExploreHeader({
    required this.selected,
    required this.heard,
    required this.contact,
    required this.onClear,
  });

  final MusicExplorationTerritory? selected;
  final int heard;
  final int contact;
  final VoidCallback? onClear;

  @override
  Widget build(BuildContext context) {
    final title = selected?.title ?? AppStrings.musicAtlasExploreTitle;
    final lore = selected?.spec.loreMarkdown;
    final excerpt = lore == null
        ? AppStrings.musicAtlasExploreHint
        : lore
              .replaceAll(RegExp(r'^#+\s*', multiLine: true), '')
              .split('\n')
              .where((l) => l.trim().isNotEmpty)
              .skip(1)
              .take(2)
              .join(' ')
              .trim();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                title,
                style: Theme.of(context).textTheme.headlineSmall,
              ),
            ),
            if (onClear != null)
              TextButton(
                onPressed: onClear,
                child: const Text(AppStrings.musicAtlasExploreClear),
              ),
          ],
        ),
        const SizedBox(height: ColonySpacing.xs),
        Text(
          excerpt.isEmpty ? AppStrings.musicAtlasExploreHint : excerpt,
          maxLines: 3,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: ColonyColors.textMuted,
            height: 1.35,
          ),
        ),
        if (selected != null) ...[
          const SizedBox(height: ColonySpacing.sm),
          Text(
            AppStrings.musicAtlasExploreCounts(heard: heard, contact: contact),
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: ColonyColors.accentCyan,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ],
    );
  }
}
