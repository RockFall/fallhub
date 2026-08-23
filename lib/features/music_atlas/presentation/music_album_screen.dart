import 'package:colony_design_system/colony_design_system.dart';
import 'package:colony_domain/colony_domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../app/localization/app_strings.dart';
import '../application/music_atlas_controllers.dart';
import '../application/music_atlas_providers.dart';
import 'widgets/album_markdown_body.dart';
import 'widgets/album_sleeve.dart';
import 'widgets/capture_music_encounter_sheet.dart';

class MusicAlbumScreen extends ConsumerStatefulWidget {
  const MusicAlbumScreen({super.key, required this.nodeId});

  final String nodeId;

  @override
  ConsumerState<MusicAlbumScreen> createState() => _MusicAlbumScreenState();
}

class _MusicAlbumScreenState extends ConsumerState<MusicAlbumScreen> {
  final _notes = TextEditingController();
  var _editing = false;

  @override
  void dispose() {
    _notes.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final inspect = ref.watch(musicNodeInspectProvider(widget.nodeId));
    final exploration = ref.watch(musicExplorationProvider);

    return inspect.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => Center(child: Text('$error')),
      data: (data) {
        if (data == null) {
          return const Center(child: Text(AppStrings.musicAtlasEmpty));
        }
        final album = exploration.asData?.value.albumById(widget.nodeId) ??
            _fallback(data);
        final markdown = album.resolvedMarkdown;
        final empty = markdown == null || markdown.trim().isEmpty;
        final search = MusicAlbumSearch.google(
          title: album.node.canonicalName,
          artist: album.artistCredit,
          year: album.node.beginYear,
        );
        final territories = [
          for (final key in album.territoryKeys)
            MusicGenreAtlas.byKey[key] ??
                exploration.asData?.value.territory(key)?.spec,
        ].whereType<MusicTerritorySpec>();

        return ListView(
          padding: const EdgeInsets.fromLTRB(
            ColonySpacing.lg,
            ColonySpacing.md,
            ColonySpacing.lg,
            ColonySpacing.xxl,
          ),
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 148,
                  child: AlbumSleeve(album: album, size: 148, compact: true),
                ),
                const SizedBox(width: ColonySpacing.lg),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        album.node.canonicalName,
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      if (album.artistCredit != null)
                        Text(
                          album.artistCredit!,
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(color: ColonyColors.textOption),
                        ),
                      const SizedBox(height: ColonySpacing.xs),
                      Text(
                        [
                          if (album.node.beginYear != null)
                            '${album.node.beginYear}',
                          AppStrings.musicAtlasDiscoveryLabel(album.discovery),
                          AppStrings.musicAtlasListenDepth(album.depth),
                        ].join(' · '),
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      const SizedBox(height: ColonySpacing.sm),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: [
                          for (final spec in territories)
                            ActionChip(
                              label: Text(
                                spec.axis == MusicAxisKind.genre
                                    ? spec.title
                                    : '${MusicOntologyPolicy.axisLabel(spec.axis)} · ${spec.title}',
                              ),
                              onPressed: spec.axis == MusicAxisKind.genre
                                  ? () => context.go(
                                      '/research/music-atlas/explore?t=${spec.key}',
                                    )
                                  : null,
                            ),
                          ActionChip(
                            avatar: const Icon(Icons.add, size: 16),
                            label: const Text(AppStrings.musicAtlasAssignRiver),
                            onPressed: () => _pickTerritory(context, album),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: ColonySpacing.lg),
            Wrap(
              spacing: ColonySpacing.sm,
              runSpacing: ColonySpacing.sm,
              children: [
                FilledButton.icon(
                  onPressed: () => CaptureMusicEncounterSheet.show(
                    context,
                    nodeId: data.node.id,
                  ),
                  icon: const Icon(Icons.hearing_outlined),
                  label: const Text(AppStrings.musicAtlasCapture),
                ),
                if (empty)
                  FilledButton.tonalIcon(
                    onPressed: () => launchUrl(
                      search,
                      mode: LaunchMode.externalApplication,
                    ),
                    icon: const Icon(Icons.travel_explore),
                    label: const Text(AppStrings.musicAtlasGoogleSearch),
                  )
                else
                  OutlinedButton.icon(
                    onPressed: () => launchUrl(
                      search,
                      mode: LaunchMode.externalApplication,
                    ),
                    icon: const Icon(Icons.travel_explore),
                    label: const Text(AppStrings.musicAtlasGoogleSearchMore),
                  ),
                OutlinedButton(
                  onPressed: () => context.go(
                    '/research/music-atlas/nodes/${data.node.id.value}',
                  ),
                  child: const Text(AppStrings.musicAtlasOpenInspect),
                ),
              ],
            ),
            const SizedBox(height: ColonySpacing.lg),
            if (empty)
              _EmptyDossier(
                title: album.node.canonicalName,
                onSearch: () => launchUrl(
                  search,
                  mode: LaunchMode.externalApplication,
                ),
                onWrite: () {
                  _notes.text = album.fieldNotes ?? '';
                  setState(() => _editing = true);
                },
              )
            else
              ColonyPanel(
                title: AppStrings.musicAtlasDossier,
                child: AlbumMarkdownBody(markdown: markdown),
              ),
            const SizedBox(height: ColonySpacing.md),
            if (_editing)
              ColonyPanel(
                title: AppStrings.musicAtlasFieldNotes,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TextField(
                      controller: _notes,
                      maxLines: 8,
                      decoration: const InputDecoration(
                        hintText: AppStrings.musicAtlasFieldNotesHint,
                      ),
                    ),
                    const SizedBox(height: ColonySpacing.sm),
                    FilledButton(
                      onPressed: () async {
                        await ref
                            .read(musicAtlasControllerProvider.notifier)
                            .saveAlbumNotes(
                              nodeId: data.node.id,
                              notesMarkdown: _notes.text,
                            );
                        if (mounted) setState(() => _editing = false);
                      },
                      child: const Text(AppStrings.musicAtlasSaveNotes),
                    ),
                  ],
                ),
              )
            else
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  onPressed: () {
                    _notes.text = album.fieldNotes ?? '';
                    setState(() => _editing = true);
                  },
                  icon: const Icon(Icons.edit_note),
                  label: Text(
                    empty
                        ? AppStrings.musicAtlasWriteDossier
                        : AppStrings.musicAtlasEditNotes,
                  ),
                ),
              ),
            const SizedBox(height: ColonySpacing.lg),
            ColonyPanel(
              title: AppStrings.musicAtlasEncountersTitle,
              child: data.encounters.isEmpty
                  ? const Text(AppStrings.musicAtlasNoEncounters)
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
          ],
        );
      },
    );
  }

  MusicExplorationAlbum _fallback(MusicNodeInspect data) {
    return MusicExplorationAlbum(
      node: data.node,
      recipe: MusicCoverRecipe.from(
        title: data.node.canonicalName,
        artist: data.node.description,
        year: data.node.beginYear,
      ),
      depth: MusicListenPolicy.of(data.encounters),
      discovery: data.state?.discoveryState ?? MusicDiscoveryState.unmapped,
      territoryKeys: MusicNodeProvenance.territoryKeys(data.node.provenanceJson),
      artistCredit: data.node.description,
      coverArtUrl: MusicNodeProvenance.coverArtUrl(data.node.provenanceJson),
      dossier: MusicGenreAtlas.dossierFor(
        title: data.node.canonicalName,
        artist: data.node.description,
      ),
      fieldNotes:
          MusicNodeProvenance.notesMarkdown(data.node.provenanceJson) ??
          data.state?.personalSummary,
    );
  }

  Future<void> _pickTerritory(
    BuildContext context,
    MusicExplorationAlbum album,
  ) async {
    final picked = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      builder: (context) => const _CanonRiverPicker(),
    );
    if (picked == null || !mounted) return;
    final next = {...album.territoryKeys, picked}.toList();
    await ref
        .read(musicAtlasControllerProvider.notifier)
        .assignTerritories(nodeId: album.node.id, territoryKeys: next);
  }
}

class _CanonRiverPicker extends StatefulWidget {
  const _CanonRiverPicker();

  @override
  State<_CanonRiverPicker> createState() => _CanonRiverPickerState();
}

class _CanonRiverPickerState extends State<_CanonRiverPicker> {
  final _query = TextEditingController();

  @override
  void dispose() {
    _query.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final matches = MusicGenreAtlas.searchAssignable(_query.text);
    return SizedBox(
      height: MediaQuery.sizeOf(context).height * 0.78,
      child: Padding(
        padding: const EdgeInsets.all(ColonySpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              AppStrings.musicAtlasAssignRiver,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: ColonySpacing.xs),
            Text(
              AppStrings.musicAtlasOntologyHint,
              style: Theme.of(context).textTheme.bodySmall,
            ),
            TextField(
              controller: _query,
              decoration: const InputDecoration(
                labelText: AppStrings.musicAtlasSearchRiver,
              ),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: ColonySpacing.sm),
            Expanded(
              child: ListView.builder(
                itemCount: matches.length,
                itemBuilder: (context, index) {
                  final spec = matches[index];
                  final parent = spec.parentKey == null
                      ? null
                      : MusicGenreAtlas.byKey[spec.parentKey]?.title;
                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(spec.title),
                    subtitle: Text(
                      [
                        if (parent != null) parent,
                        MusicOntologyPolicy.axisLabel(spec.axis),
                      ].join(' · '),
                    ),
                    onTap: () => Navigator.of(context).pop(spec.key),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyDossier extends StatelessWidget {
  const _EmptyDossier({
    required this.title,
    required this.onSearch,
    required this.onWrite,
  });

  final String title;
  final VoidCallback onSearch;
  final VoidCallback onWrite;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(ColonySpacing.xl),
      decoration: BoxDecoration(
        color: ColonyColors.window,
        border: Border.all(color: ColonyColors.borderStandard),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppStrings.musicAtlasNoDossier,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: ColonySpacing.sm),
          Text(
            AppStrings.musicAtlasNoDossierBody(title),
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: ColonyColors.textMuted,
              height: 1.4,
            ),
          ),
          const SizedBox(height: ColonySpacing.md),
          Wrap(
            spacing: ColonySpacing.sm,
            children: [
              FilledButton.icon(
                onPressed: onSearch,
                icon: const Icon(Icons.travel_explore),
                label: const Text(AppStrings.musicAtlasGoogleSearch),
              ),
              OutlinedButton(
                onPressed: onWrite,
                child: const Text(AppStrings.musicAtlasWriteDossier),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
