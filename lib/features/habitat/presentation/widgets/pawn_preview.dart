import 'dart:async';
import 'dart:math' as math;

import 'package:colony_design_system/colony_design_system.dart';
import 'package:flutter/material.dart';
import 'package:living_habitat_assets/living_habitat_assets.dart';

import '../../../../app/localization/app_strings.dart';
import '../../flame/habitat_pawn_draw.dart';
import '../../flame/habitat_tint.dart';

/// Layered RimWorld-style pawn preview (Flutter, no Flame).
class PawnPreview extends StatelessWidget {
  const PawnPreview({
    super.key,
    required this.appearance,
    this.direction = 'south',
    this.size = HabitatPawnDraw.portraitPx,
    this.flipX = false,
    this.walkBob = 0,
  });

  final PawnAppearance appearance;
  final String direction;
  final double size;
  final bool flipX;
  final double walkBob;

  @override
  Widget build(BuildContext context) {
    final dir = direction == 'west' ? 'east' : direction;
    final flip = flipX || direction == 'west';

    Widget layer(String path, Color tint) {
      return ColorFiltered(
        colorFilter: ColorFilter.mode(tint, BlendMode.modulate),
        child: Image.asset(
          path,
          package: HabitatAssets.package,
          width: size,
          height: size,
          filterQuality: FilterQuality.none,
          fit: BoxFit.contain,
          gaplessPlayback: true,
        ),
      );
    }

    final bodyType = appearance.bodyType;
    // Preview [size] ≈ mesh edge; RW headOffset is in tiles of that mesh (~1.5).
    final headOff = HabitatPawnDraw.headPixelOffset(
      bodyType: bodyType,
      facing: dir,
      tileOrSize: size / HabitatPawnDraw.mapTiles,
    );

    Widget headLayer(String path, Color tint) {
      return Transform.translate(
        offset: headOff,
        child: layer(path, tint),
      );
    }

    final children = <Widget>[
      layer(
        HabitatAssets.body(dir, bodyType: bodyType),
        appearance.skin,
      ),
      if (appearance.apparelTop != null)
        layer(
          HabitatAssets.apparel(appearance.apparelTop!, bodyType, dir),
          appearance.apparelTint,
        ),
      headLayer(
        HabitatAssets.head(dir, bodyType: bodyType),
        appearance.skin,
      ),
      if (appearance.beardStyle != null)
        headLayer(
          HabitatAssets.beard(appearance.beardStyle!, dir),
          appearance.hair,
        ),
      headLayer(
        HabitatAssets.hair(dir, style: appearance.hairStyle),
        appearance.hair,
      ),
      if (appearance.hat != null)
        headLayer(
          HabitatAssets.hat(appearance.hat!, dir),
          appearance.apparelTint,
        ),
    ];

    // Head offset can spill above the mesh square — don't clip.
    final stack = SizedBox(
      width: size,
      height: size,
      child: Transform.translate(
        offset: Offset(0, -walkBob),
        child: Stack(
          alignment: Alignment.center,
          clipBehavior: Clip.none,
          children: children,
        ),
      ),
    );

    return Transform.flip(flipX: flip, child: stack);
  }
}

/// Auto-rotating preview with compact icon controls (create-character stage).
class PawnPreviewStage extends StatefulWidget {
  const PawnPreviewStage({
    super.key,
    required this.appearance,
    this.size = HabitatPawnDraw.portraitPx * 1.35,
    this.compact = false,
  });

  final PawnAppearance appearance;
  final double size;
  final bool compact;

  @override
  State<PawnPreviewStage> createState() => _PawnPreviewStageState();
}

class _PawnPreviewStageState extends State<PawnPreviewStage> {
  static const _dirs = ['south', 'east', 'north', 'west'];
  int _index = 0;
  bool _auto = false;
  bool _walk = false;
  double _walkT = 0;
  int _autoIdleTicks = 0;
  Timer? _timer;

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _syncTimer() {
    final need = _auto || _walk;
    if (need && _timer == null) {
      _timer = Timer.periodic(const Duration(milliseconds: 80), (_) {
        if (!mounted) return;
        setState(() {
          if (_walk) {
            _walkT = (_walkT + 0.12) % 1.0;
            if (_auto && _walkT < 0.12) {
              _index = (_index + 1) % _dirs.length;
            }
          } else {
            _walkT = 0;
            if (_auto) {
              _autoIdleTicks++;
              if (_autoIdleTicks % 10 == 0) {
                _index = (_index + 1) % _dirs.length;
              }
            }
          }
        });
      });
    } else if (!need && _timer != null) {
      _timer?.cancel();
      _timer = null;
      _walkT = 0;
      _autoIdleTicks = 0;
    }
  }

  @override
  Widget build(BuildContext context) {
    final dir = _dirs[_index];
    final bob =
        _walk ? math.sin(_walkT * math.pi * 2) * (widget.size * 0.03) : 0.0;
    final preview = PawnPreview(
      appearance: widget.appearance,
      direction: dir,
      size: widget.size,
      walkBob: bob,
    );

    final controls = Row(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          tooltip: AppStrings.habitatTurnLeft,
          visualDensity: VisualDensity.compact,
          onPressed: () => setState(() {
            _auto = false;
            _index = (_index + 3) % 4;
            _syncTimer();
          }),
          icon: const Icon(Icons.rotate_left, size: 20),
        ),
        Text(
          dir.toUpperCase(),
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: ColonyColors.textOption,
                letterSpacing: 1.0,
              ),
        ),
        IconButton(
          tooltip: AppStrings.habitatTurnRight,
          visualDensity: VisualDensity.compact,
          onPressed: () => setState(() {
            _auto = false;
            _index = (_index + 1) % 4;
            _syncTimer();
          }),
          icon: const Icon(Icons.rotate_right, size: 20),
        ),
        IconButton(
          tooltip: _auto
              ? AppStrings.habitatPreviewAuto
              : AppStrings.habitatPreviewManual,
          visualDensity: VisualDensity.compact,
          isSelected: _auto,
          onPressed: () => setState(() {
            _auto = !_auto;
            _syncTimer();
          }),
          icon: Icon(
            _auto ? Icons.autorenew : Icons.pause,
            size: 20,
            color: _auto ? ColonyColors.textOption : ColonyColors.textMuted,
          ),
        ),
        IconButton(
          tooltip: AppStrings.habitatPreviewWalk,
          visualDensity: VisualDensity.compact,
          isSelected: _walk,
          onPressed: () => setState(() {
            _walk = !_walk;
            _syncTimer();
          }),
          icon: Icon(
            Icons.directions_walk,
            size: 20,
            color: _walk ? ColonyColors.textOption : ColonyColors.textMuted,
          ),
        ),
      ],
    );

    if (widget.compact) {
      return ColonySurface(
        kind: ColonySurfaceKind.void_,
        child: Column(
          children: [
            Expanded(child: Center(child: preview)),
            controls,
          ],
        ),
      );
    }

    return ColonySurface(
      kind: ColonySurfaceKind.void_,
      child: Column(
        children: [
          Expanded(child: Center(child: preview)),
          Padding(
            padding: const EdgeInsets.only(bottom: ColonySpacing.sm),
            child: controls,
          ),
        ],
      ),
    );
  }
}
