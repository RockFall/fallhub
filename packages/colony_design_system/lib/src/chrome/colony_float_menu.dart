import 'dart:async';

import 'package:flutter/material.dart';

import '../tokens/colony_tokens.dart';
import 'colony_pixel_icon.dart';
import 'colony_surface.dart';

class ColonyFloatMenuItem {
  const ColonyFloatMenuItem({
    required this.label,
    required this.onSelected,
    this.icon,
    this.iconName,
    this.destructive = false,
    this.enabled = true,
  });

  final String label;
  final VoidCallback onSelected;
  final IconData? icon;
  final String? iconName;
  final bool destructive;
  final bool enabled;
}

/// Compact float menu (RimWorld option list).
///
/// When [anchorGlobal] is set, opens near the pointer (clamped to screen).
/// Otherwise falls back to a bottom sheet (shell “Mais”, narrow touch flows).
Future<void> showColonyFloatMenu({
  required BuildContext context,
  required List<ColonyFloatMenuItem> items,
  String? title,
  Offset? anchorGlobal,
}) {
  if (anchorGlobal != null) {
    return _showAnchoredFloatMenu(
      context: context,
      items: items,
      title: title,
      anchorGlobal: anchorGlobal,
    );
  }
  return _showSheetFloatMenu(context: context, items: items, title: title);
}

Future<void> _showSheetFloatMenu({
  required BuildContext context,
  required List<ColonyFloatMenuItem> items,
  String? title,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    barrierColor: ColonyColors.scrim,
    builder: (context) {
      final maxListHeight = MediaQuery.sizeOf(context).height * 0.55;

      return Padding(
        padding: const EdgeInsets.all(ColonySpacing.lg),
        child: ColonySurface(
          kind: ColonySurfaceKind.window,
          padding: const EdgeInsets.symmetric(vertical: ColonySpacing.sm),
          child: SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (title != null)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(
                      ColonySpacing.lg,
                      ColonySpacing.md,
                      ColonySpacing.lg,
                      ColonySpacing.sm,
                    ),
                    child: Text(
                      title.toUpperCase(),
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        color: ColonyColors.textGold,
                      ),
                    ),
                  ),
                ConstrainedBox(
                  constraints: BoxConstraints(maxHeight: maxListHeight),
                  child: ListView(
                    shrinkWrap: true,
                    children: [
                      for (final item in items) _FloatMenuRow(item: item),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    },
  );
}

Future<void> _showAnchoredFloatMenu({
  required BuildContext context,
  required List<ColonyFloatMenuItem> items,
  String? title,
  required Offset anchorGlobal,
}) {
  final completer = Completer<void>();
  final overlay = Overlay.of(context, rootOverlay: true);
  const menuWidth = 248.0;
  late OverlayEntry entry;

  void dismiss() {
    if (entry.mounted) entry.remove();
    if (!completer.isCompleted) completer.complete();
  }

  entry = OverlayEntry(
    builder: (ctx) {
      final media = MediaQuery.of(ctx);
      final size = media.size;
      final pad = media.padding;
      final estimatedHeight =
          (title != null ? 44.0 : 0.0) + items.length * 48.0 + 16.0;

      var left = anchorGlobal.dx;
      var top = anchorGlobal.dy;
      if (left + menuWidth > size.width - 8) {
        left = size.width - menuWidth - 8;
      }
      if (left < 8) left = 8;
      if (top + estimatedHeight > size.height - pad.bottom - 8) {
        top = size.height - pad.bottom - estimatedHeight - 8;
      }
      if (top < pad.top + 8) top = pad.top + 8;

      return Stack(
        children: [
          Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: dismiss,
              child: const ColoredBox(color: Color(0x66000000)),
            ),
          ),
          Positioned(
            left: left,
            top: top,
            width: menuWidth,
            child: Material(
              color: Colors.transparent,
              child: ColonySurface(
                kind: ColonySurfaceKind.window,
                padding: const EdgeInsets.symmetric(vertical: ColonySpacing.sm),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (title != null)
                      Padding(
                        padding: const EdgeInsets.fromLTRB(
                          ColonySpacing.lg,
                          ColonySpacing.sm,
                          ColonySpacing.lg,
                          ColonySpacing.xs,
                        ),
                        child: Text(
                          title.toUpperCase(),
                          style: Theme.of(ctx).textTheme.titleSmall?.copyWith(
                            color: ColonyColors.textGold,
                          ),
                        ),
                      ),
                    for (final item in items)
                      _FloatMenuRow(item: item, onAfterSelect: dismiss),
                  ],
                ),
              ),
            ),
          ),
        ],
      );
    },
  );

  overlay.insert(entry);
  return completer.future;
}

class _FloatMenuRow extends StatefulWidget {
  const _FloatMenuRow({required this.item, this.onAfterSelect});

  final ColonyFloatMenuItem item;
  final VoidCallback? onAfterSelect;

  @override
  State<_FloatMenuRow> createState() => _FloatMenuRowState();
}

class _FloatMenuRowState extends State<_FloatMenuRow> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final enabled = widget.item.enabled;
    final color = !enabled
        ? ColonyColors.textDisabled
        : _hover
        ? ColonyColors.textMouseover
        : widget.item.destructive
        ? ColonyColors.statusCritical
        : ColonyColors.textOption;

    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: InkWell(
        onTap: !enabled
            ? null
            : () {
                final after = widget.onAfterSelect;
                if (after != null) {
                  after();
                } else {
                  Navigator.pop(context);
                }
                widget.item.onSelected();
              },
        child: Container(
          color: _hover ? ColonyColors.lightHighlight : Colors.transparent,
          padding: const EdgeInsets.symmetric(
            horizontal: ColonySpacing.lg,
            vertical: ColonySpacing.md,
          ),
          child: Row(
            children: [
              if (widget.item.iconName != null) ...[
                ColonyPixelIcon(
                  widget.item.iconName!,
                  size: 18,
                  mono: true,
                  color: color,
                ),
                const SizedBox(width: ColonySpacing.md),
              ] else if (widget.item.icon != null) ...[
                Icon(widget.item.icon, size: 18, color: color),
                const SizedBox(width: ColonySpacing.md),
              ],
              Expanded(
                child: Text(
                  widget.item.label,
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(color: color),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
