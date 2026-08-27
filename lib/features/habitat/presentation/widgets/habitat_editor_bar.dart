import 'package:colony_design_system/colony_design_system.dart';
import 'package:flutter/material.dart';
import 'package:living_habitat_assets/living_habitat_assets.dart';

import '../../../../app/localization/app_strings.dart';
import '../../flame/habitat_editor.dart';
import '../../flame/habitat_game.dart';
import '../../flame/habitat_map.dart';
import '../../flame/habitat_prop_catalog.dart';
import '../../flame/habitat_tint.dart';

/// Compact bottom architect dock — icon tools + thumbnail pickers (V7 polish).
class HabitatEditorBar extends StatelessWidget {
  const HabitatEditorBar({
    super.key,
    required this.game,
    required this.onChanged,
    required this.onDone,
  });

  final HabitatGame game;
  final VoidCallback onChanged;
  final VoidCallback onDone;

  HabitatEditor get editor => game.editor;

  void _setTool(HabitatEditTool tool) {
    editor.tool = tool;
    if (tool != HabitatEditTool.move) editor.movingProp = null;
    game.setHoverCell(game.hoverCell);
    onChanged();
  }

  @override
  Widget build(BuildContext context) {
    final showFloors = editor.tool == HabitatEditTool.floor;
    final showPlace = editor.tool == HabitatEditTool.place;

    return Material(
      color: const Color(0xE0161618),
      child: SafeArea(
        top: false,
        minimum: EdgeInsets.zero,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(8, 6, 8, 6),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(
                height: 56,
                child: Row(
                  children: [
                    _IconTool(
                      label: 'OK',
                      tooltip: AppStrings.habitatEditDone,
                      selected: true,
                      accent: true,
                      onTap: onDone,
                      child: const Icon(Icons.check, size: 16, color: Colors.white),
                    ),
                    const SizedBox(width: 6),
                    const _VDiv(),
                    const SizedBox(width: 6),
                    Expanded(
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        children: [
                          _IconTool(
                            label: 'Sel',
                            tooltip: AppStrings.habitatEditToolSelect,
                            selected: editor.tool == HabitatEditTool.select,
                            onTap: () => _setTool(HabitatEditTool.select),
                            child: const Icon(Icons.near_me, size: 16),
                          ),
                          _IconTool(
                            label: 'Piso',
                            tooltip: AppStrings.habitatEditToolFloor,
                            selected: editor.tool == HabitatEditTool.floor,
                            onTap: () => _setTool(HabitatEditTool.floor),
                            child: const Icon(Icons.grid_on, size: 16),
                          ),
                          _IconTool(
                            label: 'Móvel',
                            tooltip: AppStrings.habitatEditToolPlace,
                            selected: editor.tool == HabitatEditTool.place,
                            onTap: () => _setTool(HabitatEditTool.place),
                            child: const Icon(Icons.chair_outlined, size: 16),
                          ),
                          _IconTool(
                            label: 'Mover',
                            tooltip: AppStrings.habitatEditToolMove,
                            selected: editor.tool == HabitatEditTool.move,
                            onTap: () => _setTool(HabitatEditTool.move),
                            child: const Icon(Icons.open_with, size: 16),
                          ),
                          _IconTool(
                            label: 'Apagar',
                            tooltip: AppStrings.habitatEditToolErase,
                            selected: editor.tool == HabitatEditTool.erase,
                            onTap: () => _setTool(HabitatEditTool.erase),
                            child: const Icon(Icons.delete_outline, size: 16),
                          ),
                          _IconTool(
                            label: 'Parede',
                            tooltip: AppStrings.habitatEditToolWall,
                            selected: editor.tool == HabitatEditTool.wall,
                            onTap: () => _setTool(HabitatEditTool.wall),
                            child: const Icon(Icons.crop_square, size: 16),
                          ),
                          _IconTool(
                            label: 'Porta',
                            tooltip: AppStrings.habitatEditToolDoor,
                            selected: editor.tool == HabitatEditTool.door,
                            onTap: () => _setTool(HabitatEditTool.door),
                            child: const Icon(Icons.door_front_door_outlined, size: 16),
                          ),
                          _IconTool(
                            label: 'Janela',
                            tooltip: 'Janela',
                            selected: editor.tool == HabitatEditTool.window,
                            onTap: () => _setTool(HabitatEditTool.window),
                            child: const Icon(Icons.window_outlined, size: 16),
                          ),
                          _IconTool(
                            label: 'Cômodo',
                            tooltip: 'Desenhar cômodo',
                            selected: editor.tool == HabitatEditTool.drawRoom,
                            onTap: () => _setTool(HabitatEditTool.drawRoom),
                            child: const Icon(Icons.crop_free, size: 16),
                          ),
                          _IconTool(
                            label: 'Zona',
                            tooltip: AppStrings.habitatEditToolZone,
                            selected: editor.tool == HabitatEditTool.zone,
                            onTap: () {
                              _setTool(HabitatEditTool.zone);
                              final fp = game.focusedPawn ?? game.draftedPawn;
                              if (fp != null &&
                                  game.allowedZones[fp.memberId] == null) {
                                game.seedZoneAllWalkable(fp.memberId);
                              }
                              onChanged();
                            },
                            child: const Icon(Icons.border_inner, size: 16),
                          ),
                          _IconTool(
                            label: 'Zona−',
                            tooltip: AppStrings.habitatEditToolZoneErase,
                            selected: editor.tool == HabitatEditTool.zoneErase,
                            onTap: () => _setTool(HabitatEditTool.zoneErase),
                            child: const Icon(Icons.layers_clear, size: 16),
                          ),
                          _IconTool(
                            label: 'Livre',
                            tooltip: AppStrings.habitatEditZoneClear,
                            selected: false,
                            onTap: () {
                              final fp = game.focusedPawn ?? game.draftedPawn;
                              if (fp != null) game.clearZone(fp.memberId);
                              onChanged();
                            },
                            child: const Icon(Icons.all_inclusive, size: 16),
                          ),
                          const SizedBox(width: 4),
                          const _VDiv(),
                          const SizedBox(width: 4),
                          _IconTool(
                            label: 'Undo',
                            tooltip: AppStrings.habitatEditUndo,
                            selected: false,
                            enabled: editor.canUndo,
                            onTap: () {
                              game.undoEdit();
                              onChanged();
                            },
                            child: const Icon(Icons.undo, size: 16),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              if (showFloors) ...[
                const SizedBox(height: 6),
                SizedBox(
                  width: double.infinity,
                  height: 44,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: [
                      for (final f in HabitatFloor.values)
                        _ThumbTool(
                          tooltip: _floorLabel(f),
                          selected: editor.paintFloor == f,
                          onTap: () {
                            editor.paintFloor = f;
                            onChanged();
                          },
                          child: _AssetThumb(
                            path: _floorAsset(f),
                            fit: BoxFit.cover,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
              if (showPlace) ...[
                const SizedBox(height: 8),
                // Colors above, full width.
                SizedBox(
                  width: double.infinity,
                  height: 28,
                  child: _CompactSwatches(
                    colors: StuffPalettes.furnitureSwatches,
                    selected: editor.placeTint,
                    onSelected: (c) {
                      editor.placeTint = c;
                      game.setHoverCell(game.hoverCell);
                      onChanged();
                    },
                  ),
                ),
                const SizedBox(height: 6),
                // Furniture gallery full width below.
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: [
                      for (final kind in HabitatPropKinds.all)
                        _ThumbTool(
                          tooltip: HabitatPropCatalog.label(kind),
                          selected: editor.placeKind == kind,
                          onTap: () {
                            editor.placeKind = kind;
                            game.setHoverCell(game.hoverCell);
                            onChanged();
                          },
                          child: _PropThumb(
                            kind: kind,
                            tint: editor.placeTint,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  String _floorLabel(HabitatFloor f) => switch (f) {
        HabitatFloor.wood => AppStrings.habitatFloorWood,
        HabitatFloor.carpet => AppStrings.habitatFloorCarpet,
        HabitatFloor.concrete => AppStrings.habitatFloorConcrete,
      };

  String _floorAsset(HabitatFloor f) => switch (f) {
        HabitatFloor.wood => HabitatAssets.woodFloor,
        HabitatFloor.carpet => HabitatAssets.carpet,
        HabitatFloor.concrete => HabitatAssets.concrete,
      };
}

class _VDiv extends StatelessWidget {
  const _VDiv();

  @override
  Widget build(BuildContext context) {
    return Container(width: 1, height: 36, color: const Color(0x44FFFFFF));
  }
}

class _IconTool extends StatelessWidget {
  const _IconTool({
    required this.label,
    required this.tooltip,
    required this.selected,
    required this.onTap,
    required this.child,
    this.enabled = true,
    this.accent = false,
  });

  final String label;
  final String tooltip;
  final bool selected;
  final bool enabled;
  final bool accent;
  final VoidCallback onTap;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final border = accent
        ? const Color(0xFFE8C84A)
        : selected
            ? const Color(0xFFE8E8E8)
            : const Color(0xFF4A4A4A);
    final fg = enabled
        ? (selected || accent ? Colors.white : Colors.white70)
        : ColonyColors.textDisabled;
    return Padding(
      padding: const EdgeInsets.only(right: 4),
      child: Tooltip(
        message: tooltip,
        child: InkWell(
          onTap: enabled ? onTap : null,
          borderRadius: BorderRadius.circular(3),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 90),
            width: 48,
            height: 52,
            padding: const EdgeInsets.symmetric(vertical: 4),
            decoration: BoxDecoration(
              color: accent
                  ? const Color(0xFF3A3420)
                  : selected
                      ? const Color(0xFF2A2A2E)
                      : const Color(0xFF1C1C1E),
              border: Border.all(
                color: border,
                width: selected || accent ? 1.5 : 1,
              ),
              borderRadius: BorderRadius.circular(3),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconTheme(
                  data: IconThemeData(color: fg, size: 16),
                  child: child,
                ),
                const SizedBox(height: 2),
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: fg,
                    fontSize: 9,
                    fontWeight: FontWeight.w600,
                    height: 1,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ThumbTool extends StatelessWidget {
  const _ThumbTool({
    required this.tooltip,
    required this.selected,
    required this.onTap,
    required this.child,
  });

  final String tooltip;
  final bool selected;
  final VoidCallback onTap;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: Tooltip(
        message: tooltip,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(3),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 90),
            width: 48,
            height: 48,
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              color: selected ? const Color(0xFF2A2A2E) : const Color(0xFF141416),
              border: Border.all(
                color: selected ? const Color(0xFFE8E8E8) : const Color(0xFF4A4A4A),
                width: selected ? 1.5 : 1,
              ),
              borderRadius: BorderRadius.circular(3),
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}

class _AssetThumb extends StatelessWidget {
  const _AssetThumb({required this.path, this.fit = BoxFit.contain});

  final String path;
  final BoxFit fit;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(2),
      child: Image.asset(
        path,
        package: HabitatAssets.package,
        fit: fit,
        filterQuality: FilterQuality.none,
        gaplessPlayback: true,
      ),
    );
  }
}

class _PropThumb extends StatelessWidget {
  const _PropThumb({required this.kind, required this.tint});

  final String kind;
  final Color tint;

  @override
  Widget build(BuildContext context) {
    if (HabitatPropKinds.isProcedural(kind)) {
      return CustomPaint(
        painter: _DecorThumbPainter(kind: kind, tint: tint),
        size: const Size(42, 42),
      );
    }
    return ColorFiltered(
      colorFilter: ColorFilter.mode(tint, BlendMode.modulate),
      child: Image.asset(
        HabitatPropCatalog.assetPath(kind),
        package: HabitatAssets.package,
        fit: BoxFit.contain,
        filterQuality: FilterQuality.none,
        gaplessPlayback: true,
      ),
    );
  }
}

class _DecorThumbPainter extends CustomPainter {
  _DecorThumbPainter({required this.kind, required this.tint});

  final String kind;
  final Color tint;

  @override
  void paint(Canvas canvas, Size size) {
    final box = Offset.zero & size;
    final dark = Color.lerp(tint, const Color(0xFF101010), 0.35)!;
    switch (kind) {
      case HabitatPropKinds.plant:
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(
              size.width * 0.3,
              size.height * 0.55,
              size.width * 0.4,
              size.height * 0.35,
            ),
            const Radius.circular(2),
          ),
          Paint()..color = dark,
        );
        canvas.drawCircle(
          Offset(size.width * 0.5, size.height * 0.38),
          size.width * 0.28,
          Paint()..color = tint,
        );
      case HabitatPropKinds.painting:
        canvas.drawRect(box.deflate(4), Paint()..color = dark);
        canvas.drawRect(box.deflate(7), Paint()..color = tint);
      case HabitatPropKinds.rug:
        canvas.drawRRect(
          RRect.fromRectAndRadius(box.deflate(3), const Radius.circular(2)),
          Paint()..color = tint,
        );
      case HabitatPropKinds.vase:
        canvas.drawOval(
          Rect.fromCenter(
            center: Offset(size.width / 2, size.height * 0.55),
            width: size.width * 0.35,
            height: size.height * 0.55,
          ),
          Paint()..color = tint,
        );
      default:
        canvas.drawRect(box, Paint()..color = tint);
    }
  }

  @override
  bool shouldRepaint(covariant _DecorThumbPainter oldDelegate) =>
      oldDelegate.kind != kind || oldDelegate.tint != tint;
}

class _CompactSwatches extends StatelessWidget {
  const _CompactSwatches({
    required this.colors,
    required this.selected,
    required this.onSelected,
  });

  final List<Color> colors;
  final Color selected;
  final ValueChanged<Color> onSelected;

  @override
  Widget build(BuildContext context) {
    return ListView(
      scrollDirection: Axis.horizontal,
      children: [
        for (final c in colors)
          Padding(
            padding: const EdgeInsets.only(right: 6),
            child: Tooltip(
              message: AppStrings.habitatStuffColor,
              child: InkWell(
                onTap: () => onSelected(c),
                child: Container(
                  width: 22,
                  height: 22,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: c,
                    border: Border.all(
                      color: c.toARGB32() == selected.toARGB32()
                          ? Colors.white
                          : const Color(0xFF666666),
                      width: c.toARGB32() == selected.toARGB32() ? 2 : 1,
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
