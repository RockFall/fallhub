import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../flame/habitat_locations.dart';

/// Snapshot pushed from Habitat → app chrome mini-portrait (V9.5).
class HabitatChromeSnapshot {
  const HabitatChromeSnapshot({
    this.locationId = HabitatLocationIds.bedroom,
    this.phaseLabel = 'Dia',
    this.muted = true,
  });

  final String locationId;
  final String phaseLabel;
  final bool muted;

  HabitatChromeSnapshot copyWith({
    String? locationId,
    String? phaseLabel,
    bool? muted,
  }) =>
      HabitatChromeSnapshot(
        locationId: locationId ?? this.locationId,
        phaseLabel: phaseLabel ?? this.phaseLabel,
        muted: muted ?? this.muted,
      );
}

class HabitatChromeNotifier extends Notifier<HabitatChromeSnapshot> {
  @override
  HabitatChromeSnapshot build() => const HabitatChromeSnapshot();

  void publish(HabitatChromeSnapshot next) => state = next;
}

final habitatChromeProvider =
    NotifierProvider<HabitatChromeNotifier, HabitatChromeSnapshot>(
  HabitatChromeNotifier.new,
);
