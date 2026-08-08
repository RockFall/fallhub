import 'dart:math' as math;

import 'package:fallhub/features/habitat/flame/components/pawn_job_controller.dart';
import 'package:fallhub/features/habitat/flame/habitat_game.dart';
import 'package:fallhub/features/habitat/flame/habitat_map.dart';
import 'package:fallhub/features/habitat/flame/habitat_zones.dart';
import 'package:fallhub/features/habitat/flame/pathfinding.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('V9.13 allowed zones', () {
    test('pickWanderTarget respects allowed set', () {
      final map = HabitatMap(width: 8, height: 8, floors: [
        for (var i = 0; i < 64; i++) HabitatFloor.wood,
      ], props: []);
      final allowed = {(3, 3), (4, 3), (3, 4), (4, 4)};
      final rng = math.Random(1);
      for (var i = 0; i < 20; i++) {
        final t = pickWanderTarget(
          map: map,
          from: (3, 3),
          rng: rng,
          allowed: allowed,
        );
        expect(t, isNotNull);
        expect(allowed, contains(t));
      }
    });

    test('findPath stays inside allowed cells', () {
      final map = HabitatMap(width: 8, height: 8, floors: [
        for (var i = 0; i < 64; i++) HabitatFloor.wood,
      ], props: []);
      final allowed = {(2, 2), (3, 2), (4, 2), (3, 3), (4, 3)};
      final path = findPath(
        map: map,
        from: (2, 2),
        to: (4, 3),
        allowed: (x, y) => allowed.contains((x, y)),
      );
      expect(path, isNotEmpty);
      for (final c in path) {
        expect(allowed, contains(c));
      }
    });

    test('order outside zone rejected or snapped', () async {
      final game = HabitatGame(tileSize: 48);
      await game.onLoad();
      final pawn = game.pawns.first;
      game.draftPawn(pawn);

      final walkable = game.map.walkableCells();
      final here = (pawn.cellX, pawn.cellY);
      final neighbor = walkable.firstWhere(
        (c) => c != here,
        orElse: () => here,
      );
      final zone = {here, neighbor};
      game.allowedZones[pawn.memberId] = zone;

      final outside = walkable.firstWhere(
        (c) => !zone.contains(c),
        orElse: () => (pawn.cellX + 2, pawn.cellY),
      );

      final ok = game.issueOrder(
        cell: outside,
        hit: HabitatCellSelection(outside),
      );

      if (!ok) {
        expect(game.zoneRejectFlash, isNotNull);
        expect(
          game.bubbles.any((b) => b.text.contains('Não')),
          isTrue,
        );
      } else {
        expect(pawn.jobs.kind, HabitatJobKind.goTo);
        final dest = pawn.jobs.remainingPath.isEmpty
            ? here
            : pawn.jobs.remainingPath.last;
        expect(zone, contains(dest));
      }

      game.dispose();
    });

    test('HabitatZones nearestAllowed picks inside zone', () {
      final map = HabitatMap(width: 6, height: 6, floors: [
        for (var i = 0; i < 36; i++) HabitatFloor.wood,
      ], props: []);
      final zone = {(1, 1), (2, 1), (1, 2)};
      final near = HabitatZones.nearestAllowed(map, zone, (4, 4));
      expect(near, isNotNull);
      expect(zone, contains(near));
    });
  });
}
