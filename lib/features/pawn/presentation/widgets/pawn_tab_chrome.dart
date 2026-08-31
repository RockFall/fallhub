import 'package:colony_design_system/colony_design_system.dart';
import 'package:flutter/material.dart';

/// Shared terminal pane for pawn tabs that are not the needs inspect.
class PawnPane extends StatelessWidget {
  const PawnPane({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(6, 4, 6, 6),
      child: LayoutBuilder(
        builder: (context, constraints) {
          return SizedBox(
            width: constraints.maxWidth,
            height: constraints.maxHeight,
            child: ColonyFrame(
              variant: ColonyFrameVariant.panel,
              grain: false,
              padding: const EdgeInsets.fromLTRB(10, 10, 10, 10),
              child: child,
            ),
          );
        },
      ),
    );
  }
}

class PawnSectionLabel extends StatelessWidget {
  const PawnSectionLabel(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text.toUpperCase(),
      style: const TextStyle(
        fontFamily: ColonyFonts.familyTiny,
        color: ColonyColors.textGoldHi,
        fontSize: 11,
        letterSpacing: 0.8,
        fontWeight: FontWeight.w700,
      ),
    );
  }
}

class PawnMutedText extends StatelessWidget {
  const PawnMutedText(this.text, {super.key, this.tiny = false});

  final String text;
  final bool tiny;

  @override
  Widget build(BuildContext context) {
    return Text(
      tiny ? text.toUpperCase() : text,
      style: tiny
          ? const TextStyle(
              fontFamily: ColonyFonts.familyTiny,
              color: ColonyColors.textMuted,
              fontSize: 10,
              letterSpacing: 0.4,
              height: 1.35,
            )
          : Theme.of(context).textTheme.bodySmall?.copyWith(
              color: ColonyColors.textMuted,
              fontFamily: ColonyFonts.familyReadable,
              height: 1.45,
            ),
    );
  }
}

class PawnStatusPlate extends StatelessWidget {
  const PawnStatusPlate({
    super.key,
    required this.label,
    required this.status,
    required this.pending,
    required this.onTap,
  });

  final String label;
  final String status;
  final bool pending;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ColonyFrame(
      variant: ColonyFrameVariant.tile,
      grain: false,
      selected: pending,
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label.toUpperCase(),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontFamily: ColonyFonts.familyTiny,
                color: ColonyColors.textMuted,
                fontSize: 9,
                letterSpacing: 0.6,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              status.toUpperCase(),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontFamily: ColonyFonts.familyTiny,
                color: pending
                    ? ColonyColors.textGoldHi
                    : ColonyColors.textSecondary,
                fontSize: 11,
                letterSpacing: 0.5,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class PawnLogRow extends StatelessWidget {
  const PawnLogRow({super.key, required this.title, this.detail, this.onTap});

  final String title;
  final String? detail;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final row = Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          const Text(
            '›',
            style: TextStyle(
              fontFamily: ColonyFonts.familyTiny,
              color: ColonyColors.accentOrange,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              title.toUpperCase(),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontFamily: ColonyFonts.familyTiny,
                color: ColonyColors.textSecondary,
                fontSize: 11,
                letterSpacing: 0.45,
              ),
            ),
          ),
          if (detail != null && detail!.isNotEmpty) ...[
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                detail!,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.right,
                style: const TextStyle(
                  fontFamily: ColonyFonts.familyTiny,
                  color: ColonyColors.textMuted,
                  fontSize: 10,
                  letterSpacing: 0.3,
                ),
              ),
            ),
          ],
        ],
      ),
    );
    if (onTap == null) return row;
    return Material(
      type: MaterialType.transparency,
      child: InkWell(onTap: onTap, child: row),
    );
  }
}
