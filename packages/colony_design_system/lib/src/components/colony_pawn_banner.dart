import 'package:flutter/material.dart';

import '../chrome/colony_assets.dart';
import '../chrome/colony_frame.dart';
import '../tokens/colony_tokens.dart';
import 'colony_pip_meter.dart';

class ColonyPawnBanner extends StatelessWidget {
  const ColonyPawnBanner({
    super.key,
    required this.name,
    this.portraitAsset,
    this.portraitPackage,
    this.restPips = 0,
    this.moodPips = 0,
    this.restLabel = 'Descanso',
    this.moodLabel = 'Humor',
    this.trailing,
    this.onTap,
  });

  final String name;
  final String? portraitAsset;
  final String? portraitPackage;
  final int restPips;
  final int moodPips;
  final String restLabel;
  final String moodLabel;
  final Widget? trailing;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final portrait = ColonyFrame(
      variant: ColonyFrameVariant.inset,
      width: ColonySizes.pawnPortrait,
      height: ColonySizes.pawnPortrait,
      grain: false,
      padding: const EdgeInsets.all(3),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(3),
        child: Image.asset(
          portraitAsset ?? ColonyGfx.portraitDefault,
          package: portraitPackage ?? ColonyGfx.package,
          fit: BoxFit.cover,
          filterQuality: FilterQuality.none,
          isAntiAlias: false,
          errorBuilder: (_, _, _) => const ColoredBox(
            color: ColonyColors.raised,
            child: Icon(Icons.person, color: ColonyColors.textMuted),
          ),
        ),
      ),
    );

    final body = ColonyFrame(
      variant: ColonyFrameVariant.panel,
      padding: const EdgeInsets.fromLTRB(8, 8, 12, 8),
      child: Row(
        children: [
          portrait,
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  name.toUpperCase(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: ColonyColors.textGoldHi,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.6,
                    fontSize: trailing != null ? 18 : 22,
                    height: 1.0,
                  ),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 10,
                  runSpacing: 6,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    ColonyPipMeter(label: restLabel, filled: restPips),
                    Container(
                      width: 1,
                      height: 12,
                      color: ColonyColors.borderSeparator,
                    ),
                    ColonyPipMeter(label: moodLabel, filled: moodPips),
                  ],
                ),
              ],
            ),
          ),
          if (trailing != null) ...[const SizedBox(width: 8), trailing!],
        ],
      ),
    );

    return Semantics(
      button: onTap != null,
      label: name,
      child: onTap == null
          ? body
          : Material(
              type: MaterialType.transparency,
              child: InkWell(onTap: onTap, child: body),
            ),
    );
  }
}
