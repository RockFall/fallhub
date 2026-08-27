import 'package:fallhub/features/habitat/flame/components/pawn_job_controller.dart';
import 'package:fallhub/features/habitat/flame/habitat_game.dart';
import 'package:fallhub/features/habitat/flame/habitat_map.dart';
import 'package:flame/components.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('V9.6 draft + hold order', () {
    test('draftPawn marks drafted; undraft resumes wander', () async {
      final game = HabitatGame(tileSize: 48);
      await game.onLoad();
      game.onGameResize(Vector2(800, 600));
      final pawn = game.pawns.first;

      game.draftPawn(pawn);
      expect(pawn.drafted, isTrue);
      expect(pawn.selected, isTrue);
      expect(game.draftedPawn, same(pawn));

      pawn.jobs.orderGoToCell((pawn.cellX + 1, pawn.cellY));
      expect(pawn.jobs.kind, HabitatJobKind.goTo);

      game.undraft();
      expect(pawn.drafted, isFalse);
      expect(game.draftedPawn, isNull);
      expect(pawn.jobs.kind, HabitatJobKind.wander);

      game.dispose();
    });

    test('hold on pawn drafts; tap on pawn only inspects', () async {
      final game = HabitatGame(tileSize: 48);
      await game.onLoad();
      game.onGameResize(Vector2(800, 600));
      game.resetCamera();
      final pawn = game.pawns.first;
      // Ensure world position is snapped (component onLoad may be deferred).
      pawn.teleportToCell((pawn.cellX, pawn.cellY));
      final canvas = game.camera.localToGlobal(pawn.position.clone());

      game.debugPlayTap(canvas);
      expect(pawn.drafted, isFalse, reason: 'tap must not draft');
      expect(pawn.selected, isTrue);
      expect(game.selection, isA<HabitatPawnSelection>());

      game.debugHold(canvas);
      expect(pawn.drafted, isTrue);
      expect(game.draftedPawn, same(pawn));

      game.dispose();
    });

    test('tap outside habitat undrafts', () async {
      final game = HabitatGame(tileSize: 48);
      await game.onLoad();
      game.onGameResize(Vector2(800, 600));
      game.resetCamera();
      final pawn = game.pawns.first;
      game.draftPawn(pawn);
      expect(pawn.drafted, isTrue);

      // Far outside the map in canvas space.
      game.debugPlayTap(Vector2(-200, -200));
      expect(pawn.drafted, isFalse);
      expect(game.draftedPawn, isNull);

      game.dispose();
    });

    test('order exposes remainingPath for white line overlay', () async {
      final game = HabitatGame(tileSize: 48);
      await game.onLoad();
      game.onGameResize(Vector2(800, 600));
      final pawn = game.pawns.first;
      game.draftPawn(pawn);

      final cells = game.map.walkableCells();
      final target = cells.firstWhere(
        (c) => (c.$1 - pawn.cellX).abs() + (c.$2 - pawn.cellY).abs() >= 2,
        orElse: () => cells.firstWhere(
          (c) => c != (pawn.cellX, pawn.cellY),
          orElse: () => cells.first,
        ),
      );

      final ok = game.issueOrder(
        cell: target,
        hit: HabitatCellSelection(target),
      );
      expect(ok, isTrue);
      expect(pawn.jobs.kind, HabitatJobKind.goTo);
      expect(pawn.drafted, isTrue);
      expect(pawn.jobs.remainingPath, isNotEmpty);
      expect(pawn.jobs.remainingPath.last, target);

      game.dispose();
    });

    test('hold on chair issues sit; bed issues sleep job', () async {
      final game = HabitatGame(tileSize: 48);
      await game.onLoad();
      game.onGameResize(Vector2(800, 600));
      final pawn = game.pawns.first;
      game.draftPawn(pawn);

      final chair = game.map.props.cast<HabitatProp?>().firstWhere(
            (p) => p?.kind == 'chair',
            orElse: () => null,
          );
      final bed = game.map.props.cast<HabitatProp?>().firstWhere(
            (p) => p?.kind == 'bed',
            orElse: () => null,
          );

      if (chair != null) {
        expect(
          game.issueHoldOrder(
            cell: chair.origin,
            hit: HabitatPropSelection(chair),
          ),
          isTrue,
        );
        expect(pawn.jobs.kind, HabitatJobKind.sit);
      }

      if (bed != null) {
        expect(
          game.issueHoldOrder(
            cell: bed.origin,
            hit: HabitatPropSelection(bed),
          ),
          isTrue,
        );
        // Hold on bed starts the sleep job (arrival choreography + lie posture).
        expect(pawn.jobs.kind, HabitatJobKind.sleep);
      }

      game.dispose();
    });
  });
}
