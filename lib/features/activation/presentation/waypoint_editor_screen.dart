import 'package:colony_design_system/colony_design_system.dart';
import 'package:colony_domain/colony_domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/localization/app_strings.dart';
import '../application/activation_controllers.dart';
import '../application/activation_providers.dart';
import 'widgets/waypoint_route_map.dart';

class WaypointEditorScreen extends ConsumerStatefulWidget {
  const WaypointEditorScreen({super.key, this.initialToken});

  final String? initialToken;

  @override
  ConsumerState<WaypointEditorScreen> createState() =>
      _WaypointEditorScreenState();
}

class _WaypointEditorScreenState extends ConsumerState<WaypointEditorScreen> {
  final _name = TextEditingController();
  final _token = TextEditingController();

  @override
  void initState() {
    super.initState();
    _token.text = widget.initialToken ?? '';
    if (widget.initialToken != null && widget.initialToken!.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref
            .read(activationControllerProvider.notifier)
            .reachWaypoint(widget.initialToken!);
      });
    }
  }

  @override
  void dispose() {
    _name.dispose();
    _token.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final waypoints = ref.watch(activationWaypointsProvider);
    return Padding(
      padding: const EdgeInsets.all(ColonySpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            AppStrings.activationWaypoints,
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: ColonySpacing.sm),
          Text(
            AppStrings.activationWaypointMap,
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: ColonySpacing.md),
          waypoints.maybeWhen(
            data: (items) => WaypointRouteMap(
              waypoints: items,
              onSelect: (waypoint) {
                if (waypoint.token == null) return;
                ref
                    .read(activationControllerProvider.notifier)
                    .reachWaypoint(waypoint.token!);
              },
            ),
            orElse: () => const SizedBox(height: 8),
          ),
          const SizedBox(height: ColonySpacing.md),
          TextField(
            controller: _name,
            decoration: const InputDecoration(
              labelText: AppStrings.activationWaypointName,
            ),
          ),
          TextField(
            controller: _token,
            decoration: const InputDecoration(
              labelText: AppStrings.activationWaypointToken,
            ),
          ),
          const SizedBox(height: ColonySpacing.sm),
          FilledButton(
            onPressed: () async {
              if (_name.text.trim().isEmpty) return;
              await ref.read(activationControllerProvider.notifier).createWaypoint(
                    name: _name.text.trim(),
                    type: ActivationWaypointType.qr,
                    token: _token.text.trim().isEmpty
                        ? _name.text.trim().toLowerCase()
                        : _token.text.trim(),
                  );
              _name.clear();
            },
            child: const Text(AppStrings.activationWaypointNew),
          ),
          const SizedBox(height: ColonySpacing.lg),
          Expanded(
            child: waypoints.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (_, _) => Center(child: Text(AppStrings.errorGeneric)),
              data: (items) {
                if (items.isEmpty) {
                  return Center(child: Text(AppStrings.activationWaypointEmpty));
                }
                return ListView(
                  children: [
                    for (final waypoint in items)
                      ListTile(
                        leading: const Icon(Icons.place_outlined),
                        title: Text(waypoint.name),
                        subtitle: Text(
                          [
                            waypoint.waypointType.name,
                            if (waypoint.reliabilityScore != null)
                              '${AppStrings.activationReliability} '
                                  '${(waypoint.reliabilityScore! * 100).round()}%',
                          ].join(' · '),
                        ),
                        trailing: IconButton(
                          tooltip: AppStrings.activationConfirm,
                          icon: const Icon(Icons.qr_code_scanner),
                          onPressed: waypoint.token == null
                              ? null
                              : () => ref
                                  .read(activationControllerProvider.notifier)
                                  .reachWaypoint(waypoint.token!),
                        ),
                      ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
