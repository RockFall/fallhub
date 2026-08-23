import 'package:colony_design_system/colony_design_system.dart';
import 'package:colony_domain/colony_domain.dart';
import 'package:flutter/material.dart';

class WaypointRouteMap extends StatelessWidget {
  const WaypointRouteMap({
    super.key,
    required this.waypoints,
    this.onSelect,
    this.height = 220,
  });

  final List<ActivationWaypoint> waypoints;
  final ValueChanged<ActivationWaypoint>? onSelect;
  final double height;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return ClipRRect(
      borderRadius: BorderRadius.circular(ColonyRadii.soft),
      child: SizedBox(
        height: height,
        width: double.infinity,
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.asset(
              ActivationArtAssets.map,
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) =>
                  const ColoredBox(color: ColonyColors.panel),
            ),
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0x33080C10), Color(0x99080C10)],
                ),
              ),
            ),
            for (final waypoint in waypoints)
              _WaypointDot(
                waypoint: waypoint,
                labelStyle: text.labelSmall,
                onTap: onSelect == null ? null : () => onSelect!(waypoint),
              ),
          ],
        ),
      ),
    );
  }
}

class _WaypointDot extends StatelessWidget {
  const _WaypointDot({
    required this.waypoint,
    required this.labelStyle,
    this.onTap,
  });

  final ActivationWaypoint waypoint;
  final TextStyle? labelStyle;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final x = (waypoint.settings['map_x'] as num?)?.toDouble() ?? 0.5;
    final y = (waypoint.settings['map_y'] as num?)?.toDouble() ?? 0.5;
    final reliable = (waypoint.reliabilityScore ?? 0) >= 0.5;
    return Align(
      alignment: Alignment(x * 2 - 1, y * 2 - 1),
      child: GestureDetector(
        onTap: onTap,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DecoratedBox(
              decoration: BoxDecoration(
                color: reliable
                    ? ColonyMiniAppColors.activation
                    : ColonyColors.accentSand,
                shape: BoxShape.circle,
                border: Border.all(color: ColonyColors.textPrimary, width: 1.5),
              ),
              child: const SizedBox(width: 14, height: 14),
            ),
            const SizedBox(height: 4),
            DecoratedBox(
              decoration: BoxDecoration(
                color: ColonyColors.void_.withValues(alpha: 0.72),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                child: Text(waypoint.name, style: labelStyle),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
