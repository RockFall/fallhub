import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../flame/habitat_game.dart';

/// Always-on debug strip: shows sim state without opening Context inspect.
class HabitatSimStatusHud extends StatelessWidget {
  const HabitatSimStatusHud({super.key, required this.game});

  final HabitatGame game;

  @override
  Widget build(BuildContext context) {
    if (!kDebugMode) return const SizedBox.shrink();
    return Align(
      alignment: Alignment.bottomLeft,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(10, 0, 100, 12),
          child: Material(
            color: const Color(0xDD121820),
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              child: Text(
                game.simStatusLine,
                style: const TextStyle(
                  color: Color(0xFFE8E6E3),
                  fontSize: 12,
                  height: 1.35,
                  fontWeight: FontWeight.w600,
                  fontFeatures: [FontFeature.tabularFigures()],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
