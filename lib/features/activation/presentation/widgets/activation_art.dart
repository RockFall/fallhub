import 'package:colony_design_system/colony_design_system.dart';
import 'package:colony_domain/colony_domain.dart';
import 'package:flutter/material.dart';

abstract final class ActivationVisualResolver {
  static ActivationVisualSpec specFor(ActivationProtocol? protocol) {
    if (protocol == null) {
      return ActivationVisualCatalog.catalog.first;
    }
    return ActivationVisualCatalog.forProtocol(protocol);
  }

  static ActivationVisualSpec specForType(ActivationProtocolType type) {
    return ActivationVisualCatalog.forType(type);
  }

  static int currentStation({
    required ActivationVisualSpec spec,
    ActivationCommandRun? current,
    List<ActivationCommandRun> runs = const [],
  }) {
    final index = current == null
        ? 0
        : runs.indexWhere((run) => run.id == current.id);
    return ActivationVisualCatalog.stationIndex(
      spec: spec,
      destinationRef: null,
      objectRef: null,
      runIndex: index < 0 ? 0 : index,
      runCount: runs.isEmpty ? spec.stations.length : runs.length,
    );
  }
}

class ActivationArtFrame extends StatelessWidget {
  const ActivationArtFrame({
    super.key,
    required this.assetPath,
    this.height,
    this.fit = BoxFit.cover,
    this.borderRadius,
  });

  final String assetPath;
  final double? height;
  final BoxFit fit;
  final BorderRadius? borderRadius;

  @override
  Widget build(BuildContext context) {
    final radius = borderRadius ?? BorderRadius.circular(ColonyRadii.soft);
    final image = Image.asset(
      assetPath,
      height: height,
      width: double.infinity,
      fit: fit,
      errorBuilder: (_, _, _) => ColoredBox(
        color: ColonyMiniAppColors.activation.withValues(alpha: 0.22),
        child: SizedBox(
          height: height ?? 96,
          child: const Icon(
            Icons.directions_walk_outlined,
            color: ColonyColors.textMuted,
          ),
        ),
      ),
    );
    return ClipRRect(
      borderRadius: radius,
      child: height == null ? SizedBox.expand(child: image) : image,
    );
  }
}
