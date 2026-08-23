import 'package:flutter/material.dart';

import '../tokens/colony_tokens.dart';

/// Wide illustrated banner with a dark gradient for titles.
class ColonyHeroBanner extends StatelessWidget {
  const ColonyHeroBanner({
    super.key,
    required this.child,
    this.assetPath,
    this.height = 176,
    this.fallback,
  });

  final Widget child;
  final String? assetPath;
  final double height;
  final Widget? fallback;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(ColonyRadii.soft),
      child: SizedBox(
        height: height,
        width: double.infinity,
        child: Stack(
          fit: StackFit.expand,
          children: [
            ColoredBox(color: ColonyColors.panel),
            if (assetPath != null)
              Positioned.fill(
                child: Image.asset(
                  assetPath!,
                  fit: BoxFit.cover,
                  errorBuilder: (_, _, _) =>
                      fallback ??
                      const ColoredBox(color: ColonyColors.panel),
                ),
              )
            else if (fallback != null)
              fallback!,
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0x33080C10),
                    Color(0xE0080C10),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(ColonySpacing.lg),
              child: child,
            ),
          ],
        ),
      ),
    );
  }
}
