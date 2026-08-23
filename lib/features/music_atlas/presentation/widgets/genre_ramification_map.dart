import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:colony_design_system/colony_design_system.dart';
import 'package:colony_domain/colony_domain.dart';
import 'package:flutter/material.dart';

import '../../../../app/localization/app_strings.dart';
import 'album_sleeve.dart';

class GenreRamificationMap extends StatelessWidget {
  const GenreRamificationMap({
    super.key,
    required this.map,
    required this.layout,
    this.selectedKey,
    this.onSelectTerritory,
    this.onOpenAlbum,
  });

  final MusicExplorationMap map;
  final MusicRamificationLayout layout;
  final String? selectedKey;
  final ValueChanged<String>? onSelectTerritory;
  final ValueChanged<MusicExplorationAlbum>? onOpenAlbum;

  @override
  Widget build(BuildContext context) {
    if (layout.territoryPoints.isEmpty) {
      return Center(
        child: Text(
          AppStrings.musicAtlasExploreEmpty,
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      );
    }

    final albums = selectedKey == null
        ? const <MusicExplorationAlbum>[]
        : map.albumsIn(selectedKey!);

    return InteractiveViewer(
      constrained: false,
      boundaryMargin: const EdgeInsets.all(280),
      minScale: 0.42,
      maxScale: 2.4,
      child: SizedBox(
        width: layout.width,
        height: layout.height,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned.fill(
              child: CustomPaint(
                painter: _MyceliumPainter(
                  layout: layout,
                  territories: {
                    for (final item in map.territories) item.key: item,
                  },
                  selectedKey: selectedKey,
                ),
              ),
            ),
            for (final item in map.territories)
              if (layout.territoryPoints[item.key] != null)
                _GenreWell(
                  territory: item,
                  point: layout.territoryPoints[item.key]!,
                  selected: selectedKey == item.key,
                  onTap: () => onSelectTerritory?.call(item.key),
                ),
            for (final album in albums)
              if (layout.albumPoints[album.node.id.value] != null)
                AnimatedPositioned(
                  key: ValueKey('sleeve-${album.node.id.value}'),
                  duration: const Duration(milliseconds: 420),
                  curve: Curves.easeOutCubic,
                  left: layout.albumPoints[album.node.id.value]!.x - 52,
                  top: layout.albumPoints[album.node.id.value]!.y - 52,
                  child: AlbumSleeve(
                    album: album,
                    size: album.heard ? 104 : 88,
                    onTap: () => onOpenAlbum?.call(album),
                  ),
                ),
          ],
        ),
      ),
    );
  }
}

class _GenreWell extends StatelessWidget {
  const _GenreWell({
    required this.territory,
    required this.point,
    required this.selected,
    required this.onTap,
  });

  final MusicExplorationTerritory territory;
  final MusicMapPoint point;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final root = territory.parentKey == null;
    final size = root ? 54.0 : territory.spec.depth >= 2 ? 34.0 : 42.0;
    final hue = territory.spec.hue;
    final fill = HSVColor.fromAHSV(
      territory.explored ? 0.92 : 0.38,
      hue,
      selected ? 0.62 : 0.48,
      selected ? 0.72 : territory.explored ? 0.52 : 0.28,
    ).toColor();
    final glow = HSVColor.fromAHSV(
      territory.explored ? 0.45 : 0.08,
      hue,
      0.55,
      0.7,
    ).toColor();

    return Positioned(
      left: point.x - size,
      top: point.y - size / 2 - 10,
      width: size * 2,
      child: GestureDetector(
        onTap: onTap,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Semantics(
              button: true,
              label: '${territory.title}. '
                  '${territory.heardCount} ${AppStrings.musicAtlasHeardShort}',
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 280),
                width: size,
                height: size,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: fill,
                  border: Border.all(
                    color: selected
                        ? ColonyColors.textPrimary
                        : ColonyColors.borderHighlight.withValues(
                            alpha: territory.explored ? 0.85 : 0.28,
                          ),
                    width: selected ? 2 : 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: glow,
                      blurRadius: selected ? 22 : territory.explored ? 14 : 4,
                      spreadRadius: selected ? 2 : 0,
                    ),
                  ],
                ),
                child: CustomPaint(
                  painter: _WellGlyphPainter(
                    motif: territory.spec.motif,
                    ticks: math.min(8, territory.heardCount),
                    selected: selected,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              territory.title,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: selected
                    ? ColonyColors.textMouseover
                    : territory.explored
                    ? ColonyColors.textPrimary
                    : ColonyColors.textMuted,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                letterSpacing: 0.2,
                height: 1.1,
              ),
            ),
            if (territory.heardCount > 0 || territory.contactCount > 0)
              Text(
                [
                  if (territory.heardCount > 0)
                    '${territory.heardCount} ${AppStrings.musicAtlasHeardShort}',
                  if (territory.contactCount > 0)
                    '${territory.contactCount} ${AppStrings.musicAtlasContactShort}',
                ].join(' · '),
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: ColonyColors.textMuted,
                  fontSize: 9,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _WellGlyphPainter extends CustomPainter {
  const _WellGlyphPainter({
    required this.motif,
    required this.ticks,
    required this.selected,
  });

  final MusicCoverMotif motif;
  final int ticks;
  final bool selected;

  @override
  void paint(Canvas canvas, Size size) {
    final c = Offset(size.width / 2, size.height / 2);
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.1
      ..color = ColonyColors.textPrimary.withValues(alpha: selected ? 0.9 : 0.55);
    switch (motif) {
      case MusicCoverMotif.river:
      case MusicCoverMotif.tide:
        final path = Path()
          ..moveTo(6, c.dy)
          ..cubicTo(size.width * 0.4, 6, size.width * 0.6, size.height - 6, size.width - 6, c.dy);
        canvas.drawPath(path, paint);
      case MusicCoverMotif.brass:
      case MusicCoverMotif.gold:
        canvas.drawCircle(c, size.shortestSide * 0.22, paint);
      case MusicCoverMotif.lattice:
      case MusicCoverMotif.concrete:
        canvas.drawRect(
          Rect.fromCenter(center: c, width: 10, height: 10),
          paint,
        );
      case MusicCoverMotif.ember:
      case MusicCoverMotif.pulse:
        canvas.drawCircle(c, 3, paint..style = PaintingStyle.fill);
      case MusicCoverMotif.spore:
      case MusicCoverMotif.ash:
        canvas.drawCircle(c, size.shortestSide * 0.18, paint);
        canvas.drawCircle(c.translate(-5, 3), 3, paint);
    }
    if (ticks <= 0) return;
    final tick = Paint()
      ..color = ColonyColors.accentCyan.withValues(alpha: 0.85)
      ..strokeWidth = 1.4;
    for (var i = 0; i < ticks; i++) {
      final a = -math.pi / 2 + (2 * math.pi * i / 8);
      final r = size.shortestSide * 0.42;
      canvas.drawCircle(
        Offset(c.dx + math.cos(a) * r, c.dy + math.sin(a) * r),
        1.3,
        tick,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _WellGlyphPainter old) =>
      old.motif != motif || old.ticks != ticks || old.selected != selected;
}

class _MyceliumPainter extends CustomPainter {
  const _MyceliumPainter({
    required this.layout,
    required this.territories,
    required this.selectedKey,
  });

  final MusicRamificationLayout layout;
  final Map<String, MusicExplorationTerritory> territories;
  final String? selectedKey;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    canvas.drawRect(
      rect,
      Paint()
        ..shader = ui.Gradient.radial(
          Offset(size.width * 0.28, size.height * 0.42),
          size.longestSide * 0.72,
          [
            const Color(0xFF101820),
            ColonyColors.void_,
            const Color(0xFF07090C),
          ],
          const [0, 0.45, 1],
        ),
    );

    final rnd = math.Random(44);
    final star = Paint()..color = Colors.white.withValues(alpha: 0.07);
    for (var i = 0; i < 160; i++) {
      canvas.drawCircle(
        Offset(rnd.nextDouble() * size.width, rnd.nextDouble() * size.height),
        rnd.nextDouble() * 1.3,
        star,
      );
    }

    for (final edge in layout.edges) {
      final from = layout.territoryPoints[edge.$1];
      final to = layout.territoryPoints[edge.$2];
      if (from == null || to == null) continue;
      final child = territories[edge.$2];
      final explored = child?.explored ?? false;
      final onPath = selectedKey != null &&
          (edge.$1 == selectedKey ||
              edge.$2 == selectedKey ||
              (child != null &&
                  MusicGenreAtlas.ancestorKeys(child.key).contains(selectedKey)));
      final hue = child?.spec.hue ?? 200;
      final color = HSVColor.fromAHSV(
        explored ? 0.72 : 0.18,
        hue,
        0.45,
        onPath ? 0.78 : explored ? 0.5 : 0.28,
      ).toColor();
      final path = Path()
        ..moveTo(from.x, from.y)
        ..cubicTo(
          from.x + (to.x - from.x) * 0.45,
          from.y,
          to.x - 40,
          to.y,
          to.x,
          to.y,
        );
      canvas.drawPath(
        path,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = onPath ? 2.4 : explored ? 1.6 : 0.9
          ..color = color
          ..maskFilter = onPath
              ? const MaskFilter.blur(BlurStyle.normal, 1.2)
              : null,
      );
    }

    if (selectedKey != null) {
      final origin = layout.territoryPoints[selectedKey];
      if (origin != null) {
        canvas.drawCircle(
          Offset(origin.x, origin.y),
          120,
          Paint()
            ..shader = ui.Gradient.radial(
              Offset(origin.x, origin.y),
              120,
              [
                HSVColor.fromAHSV(
                  0.16,
                  territories[selectedKey]?.spec.hue ?? 200,
                  0.5,
                  0.6,
                ).toColor(),
                Colors.transparent,
              ],
            ),
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant _MyceliumPainter old) =>
      old.layout != layout || old.selectedKey != selectedKey;
}
