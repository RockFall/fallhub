import 'package:colony_design_system/colony_design_system.dart';
import 'package:colony_domain/colony_domain.dart';
import 'package:flutter/material.dart';

import 'generated_album_cover.dart';

class AlbumSleeve extends StatelessWidget {
  const AlbumSleeve({
    super.key,
    required this.album,
    this.size = 112,
    this.onTap,
    this.hero = true,
    this.compact = false,
  });

  final MusicExplorationAlbum album;
  final double size;
  final VoidCallback? onTap;
  final bool hero;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final ghost = !album.heard;
    final cover = album.coverArtUrl;
    final art = Stack(
      fit: StackFit.expand,
      children: [
        GeneratedAlbumCover(
          recipe: album.recipe,
          heard: album.heard,
          ghost: ghost,
        ),
        if (cover != null)
          Image.network(
            cover,
            fit: BoxFit.cover,
            errorBuilder: (_, _, _) => const SizedBox.shrink(),
            loadingBuilder: (context, child, progress) {
              if (progress == null) return child;
              return const SizedBox.shrink();
            },
          ),
        if (ghost)
          Align(
            alignment: Alignment.bottomLeft,
            child: Container(
              margin: const EdgeInsets.all(4),
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
              color: ColonyColors.void_.withValues(alpha: 0.72),
              child: Text(
                album.depth == MusicListenDepth.contact
                    ? 'gravado'
                    : 'à margem',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: ColonyColors.textMuted,
                  fontSize: 8,
                  letterSpacing: 0.6,
                ),
              ),
            ),
          ),
      ],
    );

    final sleeve = SizedBox(
      width: size,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          DecoratedBox(
            decoration: BoxDecoration(
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.45),
                  blurRadius: 10,
                  offset: const Offset(2, 5),
                ),
              ],
            ),
            child: AspectRatio(aspectRatio: 1, child: art),
          ),
          if (!compact) ...[
            const SizedBox(height: 6),
            Text(
              album.node.canonicalName,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: ghost
                    ? ColonyColors.textMuted
                    : ColonyColors.textPrimary,
                height: 1.15,
              ),
            ),
            if (album.artistCredit != null)
              Text(
                album.artistCredit!,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: ColonyColors.textMuted,
                ),
              ),
          ],
        ],
      ),
    );

    final wrapped = hero
        ? Hero(
            tag: 'music-atlas-sleeve-${album.node.id.value}',
            child: Material(type: MaterialType.transparency, child: sleeve),
          )
        : sleeve;

    if (onTap == null) return wrapped;
    return Semantics(
      button: true,
      label: album.node.canonicalName,
      child: GestureDetector(
        onTap: onTap,
        child: wrapped,
      ),
    );
  }
}
