import 'dart:math' as math;

import 'package:colony_design_system/colony_design_system.dart';
import 'package:colony_domain/colony_domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/localization/app_strings.dart';
import '../application/relations_providers.dart';
import 'relations_assets.dart';
import 'relations_navigation.dart';
import 'relations_shortcut_bar.dart';
import 'relations_visuals.dart';
import 'widgets/create_friendship_circle_sheet.dart';

class CirclesMapScreen extends ConsumerWidget {
  const CirclesMapScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final circles = (ref.watch(friendshipCirclesProvider).value ?? const [])
        .where((c) => !c.isArchived)
        .toList();
    final overviews = ref.watch(friendshipOverviewsProvider).value ?? const [];

    return Padding(
      padding: const EdgeInsets.all(ColonySpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            AppStrings.relationsCirclesTitle,
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: ColonySpacing.sm),
          Text(
            AppStrings.relationsCirclesHint,
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: ColonySpacing.md),
          const RelationsShortcutBar(current: RelationsDoor.circles),
          const SizedBox(height: ColonySpacing.lg),
          Expanded(
            child: circles.isEmpty && overviews.isEmpty
                ? RelationsEmptyState(
                    asset: RelationsAssets.emptyCircles,
                    title: AppStrings.relationsCirclesEmpty,
                    hint: AppStrings.relationsCirclesEmptyHint,
                  )
                : ListView(
                    children: [
                      if (overviews.isNotEmpty)
                        SizedBox(
                          height: 280,
                          child: _ConstellationMap(
                            circles: circles,
                            overviews: overviews,
                          ),
                        ),
                      const SizedBox(height: ColonySpacing.lg),
                      if (circles.isEmpty)
                        Text(
                          AppStrings.relationsCirclesEmpty,
                          style: Theme.of(context).textTheme.bodySmall,
                        )
                      else
                        for (final circle in circles)
                          _CircleCard(
                            circle: circle,
                            members: overviews
                                .where(
                                  (row) =>
                                      row.circles.any((c) => c.id == circle.id),
                                )
                                .toList(),
                          ),
                    ],
                  ),
          ),
          const SizedBox(height: ColonySpacing.md),
          FilledButton.icon(
            onPressed: () => CreateFriendshipCircleSheet.show(context),
            icon: const Icon(Icons.hub_outlined),
            label: Text(AppStrings.friendshipCircleNew),
          ),
        ],
      ),
    );
  }
}

class _CircleCard extends StatelessWidget {
  const _CircleCard({required this.circle, required this.members});

  final FriendshipCircle circle;
  final List<FriendshipOverview> members;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: ColonySpacing.sm),
      child: ListTile(
        leading: RelationsMark(asset: RelationsAssets.markCircle),
        title: Text(circle.name),
        subtitle: Text(
          [
            AppStrings.circleMemberCount(members.length),
            if (circle.defaultCadence != null)
              AppStrings.friendshipCadenceLabel(circle.defaultCadence!),
          ].join(' · '),
        ),
        trailing: SizedBox(
          width: 88,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              for (final row in members.take(3))
                Align(
                  widthFactor: 0.65,
                  child: PersonGlyph(person: row.person, size: 28),
                ),
            ],
          ),
        ),
        onTap: () => openCircleDetail(context, circle.id),
      ),
    );
  }
}

class _ConstellationMap extends StatelessWidget {
  const _ConstellationMap({
    required this.circles,
    required this.overviews,
  });

  final List<FriendshipCircle> circles;
  final List<FriendshipOverview> overviews;

  _Layout _layout(Size size) {
    final centers = <EntityId, Offset>{};
    final origin = Offset(size.width / 2, size.height / 2);
    final clusterR = math.min(size.width, size.height) * 0.28;
    for (var i = 0; i < circles.length; i++) {
      final angle = -math.pi / 2 + (2 * math.pi * i / circles.length);
      centers[circles[i].id] = origin +
          Offset(math.cos(angle) * clusterR, math.sin(angle) * clusterR);
    }

    final nodes = <_PersonNode>[];
    for (var i = 0; i < overviews.length; i++) {
      final row = overviews[i];
      final memberCenters = [
        for (final circle in row.circles)
          if (centers.containsKey(circle.id)) centers[circle.id]!,
      ];
      final hub = memberCenters.isEmpty
          ? origin
          : Offset(
              memberCenters.map((o) => o.dx).reduce((a, b) => a + b) /
                  memberCenters.length,
              memberCenters.map((o) => o.dy).reduce((a, b) => a + b) /
                  memberCenters.length,
            );
      final orbit = 36.0 + (i % 4) * 8;
      final angle = (i * 2.4) + row.person.displayName.hashCode / 1000;
      nodes.add(
        _PersonNode(
          row: row,
          offset: hub + Offset(math.cos(angle) * orbit, math.sin(angle) * orbit),
        ),
      );
    }
    return _Layout(centers: centers, nodes: nodes);
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = Size(constraints.maxWidth, constraints.maxHeight);
        final layout = _layout(size);
        return GestureDetector(
          onTapUp: (details) {
            _PersonNode? hit;
            var best = 28.0;
            for (final node in layout.nodes) {
              final d = (node.offset - details.localPosition).distance;
              if (d < best) {
                best = d;
                hit = node;
              }
            }
            if (hit != null) {
              openFriendshipDetail(context, hit.row.friendship.id);
              return;
            }
            FriendshipCircle? circleHit;
            var circleBest = 34.0;
            for (final circle in circles) {
              final center = layout.centers[circle.id];
              if (center == null) continue;
              final d = (center - details.localPosition).distance;
              if (d < circleBest) {
                circleBest = d;
                circleHit = circle;
              }
            }
            if (circleHit != null) {
              openCircleDetail(context, circleHit.id);
            }
          },
          child: CustomPaint(
            size: size,
            painter: _ConstellationPainter(
              circles: circles,
              layout: layout,
            ),
            child: Stack(
              children: [
                for (final node in layout.nodes)
                  Positioned(
                    left: node.offset.dx - 16,
                    top: node.offset.dy - 16,
                    child: IgnorePointer(
                      child: PersonGlyph(person: node.row.person, size: 32),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _PersonNode {
  const _PersonNode({required this.row, required this.offset});

  final FriendshipOverview row;
  final Offset offset;
}

class _Layout {
  const _Layout({required this.centers, required this.nodes});

  final Map<EntityId, Offset> centers;
  final List<_PersonNode> nodes;
}

class _ConstellationPainter extends CustomPainter {
  _ConstellationPainter({required this.circles, required this.layout});

  final List<FriendshipCircle> circles;
  final _Layout layout;

  @override
  void paint(Canvas canvas, Size size) {
    final glow = Paint()
      ..color = const Color(0xFF7B5EA7).withValues(alpha: 0.12)
      ..style = PaintingStyle.fill;
    final ring = Paint()
      ..color = const Color(0xFF7B5EA7).withValues(alpha: 0.55)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4;
    final edge = Paint()
      ..color = ColonyMiniAppColors.friendships.withValues(alpha: 0.45)
      ..strokeWidth = 1.2;

    for (final circle in circles) {
      final center = layout.centers[circle.id];
      if (center == null) continue;
      canvas.drawCircle(center, 42, glow);
      canvas.drawCircle(center, 42, ring);
    }

    for (final node in layout.nodes) {
      for (final circle in node.row.circles) {
        final center = layout.centers[circle.id];
        if (center == null) continue;
        canvas.drawLine(center, node.offset, edge);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _ConstellationPainter oldDelegate) =>
      oldDelegate.layout != layout || oldDelegate.circles != circles;
}
