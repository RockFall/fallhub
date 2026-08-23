import 'package:colony_design_system/colony_design_system.dart';
import 'package:colony_domain/colony_domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/localization/app_strings.dart';
import '../../application/music_atlas_controllers.dart';

class SpotifyPlaylistExpeditionSheet extends ConsumerStatefulWidget {
  const SpotifyPlaylistExpeditionSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (_) => const SpotifyPlaylistExpeditionSheet(),
    );
  }

  @override
  ConsumerState<SpotifyPlaylistExpeditionSheet> createState() =>
      _SpotifyPlaylistExpeditionSheetState();
}

class _SpotifyPlaylistExpeditionSheetState
    extends ConsumerState<SpotifyPlaylistExpeditionSheet> {
  List<SpotifyPlaylistSummary>? _playlists;
  String? _error;
  var _busy = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final items = await ref
          .read(musicAtlasControllerProvider.notifier)
          .listPlaylists();
      if (!mounted) return;
      setState(() {
        _playlists = items;
        _busy = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = '$error';
        _busy = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.viewInsetsOf(context).bottom;
    return Padding(
      padding: EdgeInsets.fromLTRB(
        ColonySpacing.lg,
        ColonySpacing.md,
        ColonySpacing.lg,
        ColonySpacing.lg + bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            AppStrings.musicAtlasPlaylists,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: ColonySpacing.sm),
          Text(
            AppStrings.musicAtlasSpotifyDisclaimer,
            style: Theme.of(context).textTheme.bodySmall,
          ),
          if (_busy) const LinearProgressIndicator(),
          if (_error != null)
            Text(
              _error!,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          const SizedBox(height: ColonySpacing.md),
          if (_playlists != null)
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 360),
              child: _playlists!.isEmpty
                  ? const Text('—')
                  : ListView.builder(
                      shrinkWrap: true,
                      itemCount: _playlists!.length,
                      itemBuilder: (context, index) {
                        final playlist = _playlists![index];
                        return ListTile(
                          contentPadding: EdgeInsets.zero,
                          title: Text(playlist.name),
                          subtitle: Text('${playlist.trackCount} faixas'),
                          onTap: _busy
                              ? null
                              : () async {
                                  await ref
                                      .read(
                                        musicAtlasControllerProvider.notifier,
                                      )
                                      .draftFromPlaylist(playlist);
                                  if (context.mounted) {
                                    Navigator.of(context).pop();
                                  }
                                },
                        );
                      },
                    ),
            ),
        ],
      ),
    );
  }
}
