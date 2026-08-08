import 'package:colony_design_system/colony_design_system.dart';
import 'package:flutter/material.dart';

import '../../../../app/localization/app_strings.dart';
import '../../flame/habitat_locations.dart';

/// Labels + RimWorld-ish float picker for V8 multi-map.
abstract final class HabitatLocationsUi {
  static String labelFor(String id) => switch (id) {
        HabitatLocationIds.bedroom => AppStrings.habitatLocationBedroom,
        HabitatLocationIds.office => AppStrings.habitatLocationOffice,
        HabitatLocationIds.kitchen => AppStrings.habitatLocationKitchen,
        HabitatLocationIds.terrace => AppStrings.habitatLocationTerrace,
        _ => HabitatLocations.label(id),
      };

  static IconData iconFor(String id) => switch (id) {
        HabitatLocationIds.bedroom => Icons.bed_outlined,
        HabitatLocationIds.office => Icons.desktop_windows_outlined,
        HabitatLocationIds.kitchen => Icons.kitchen_outlined,
        HabitatLocationIds.terrace => Icons.deck_outlined,
        _ => Icons.place_outlined,
      };

  static Future<void> showPicker({
    required BuildContext context,
    required String selectedId,
    required ValueChanged<String> onSelected,
    Offset? anchorGlobal,
  }) {
    return showColonyFloatMenu(
      context: context,
      title: AppStrings.habitatSelectLocation,
      anchorGlobal: anchorGlobal,
      items: [
        for (final id in HabitatLocationIds.all)
          ColonyFloatMenuItem(
            label: id == selectedId
                ? '• ${labelFor(id)}'
                : labelFor(id),
            icon: iconFor(id),
            onSelected: id == selectedId ? () {} : () => onSelected(id),
          ),
      ],
    );
  }
}
