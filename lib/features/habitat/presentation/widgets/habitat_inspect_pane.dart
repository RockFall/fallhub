import 'package:flutter/material.dart';

import '../../../../app/localization/app_strings.dart';
import '../../flame/habitat_game.dart';

/// Minimal selection readout — white text, bottom-right over the scene.
///
/// When nothing is selected, ambient clock/weather occupies bottom-right.
/// Actions stay in float menus / draft orders.
class HabitatInspectHud extends StatelessWidget {
  const HabitatInspectHud({super.key, required this.selection});

  final HabitatSelection? selection;

  String? get _line {
    return switch (selection) {
      null => null,
      HabitatPawnSelection(:final pawn) => pawn.displayName,
      HabitatPropSelection(:final prop) => prop.name,
      HabitatCellSelection(:final cell) =>
        '${AppStrings.habitatInspectCell} ${cell.$1},${cell.$2}',
    };
  }

  @override
  Widget build(BuildContext context) {
    final line = _line;
    if (line == null) return const SizedBox.shrink();
    return IgnorePointer(
      child: Align(
        alignment: Alignment.bottomRight,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
          child: Text(
            line,
            textAlign: TextAlign.right,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              height: 1.25,
              fontWeight: FontWeight.w500,
              shadows: [
                Shadow(
                  color: Color(0xCC000000),
                  blurRadius: 4,
                  offset: Offset(0, 1),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
