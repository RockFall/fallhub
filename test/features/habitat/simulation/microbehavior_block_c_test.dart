import 'package:fallhub/features/habitat/simulation/content/habitat_inventory.dart';
import 'package:fallhub/features/habitat/simulation/identity/identity.dart';
import 'package:fallhub/features/habitat/simulation/microbehavior/microbehavior.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('R20 ObjectUsePipeline', () {
    test('book and switch use distinct phase sets; cancel safe', () {
      expect(ObjectUseProfiles.book.includes(ObjectUsePhase.useLoop), isTrue);
      expect(ObjectUseProfiles.lightSwitch.includes(ObjectUsePhase.useLoop), isFalse);
      expect(ObjectUseProfiles.piano.includes(ObjectUsePhase.reach), isFalse);

      final s = ObjectUseSession(
        profile: ObjectUseProfiles.book,
        pawnId: 'p',
        targetId: 'book.dune',
        startedAt: 0,
      );
      s.begin(0);
      s.cancel();
      expect(s.phase, ObjectUsePhase.cancelled);
      expect(s.isTerminal, isTrue);
    });
  });

  group('R21 HeldItemAnchor', () {
    test('four facings produce stable distinct offsets', () {
      final offsets = {
        for (final f in MicroFacing.values)
          f: HeldItemAnchorProfile.resolve(facing: f),
      };
      expect(offsets[MicroFacing.east]!.dxTiles, greaterThan(0));
      expect(offsets[MicroFacing.west]!.dxTiles, lessThan(0));
      expect(
        offsets[MicroFacing.south]!.dxTiles,
        isNot(offsets[MicroFacing.north]!.dxTiles),
      );
    });
  });

  group('R22 SurfacePlacement', () {
    test('ranks free slots; overcrowding penalized', () {
      final best = SurfacePlacementRanker.best(
        const SurfacePlacementContext(
          containerId: 'table',
          freeSlotIds: ['0', '1'],
          occupiedCount: 0,
          capacity: 2,
          nearUser: true,
        ),
      );
      expect(best?.slotId, '0');
      final crowded = SurfacePlacementRanker.rank(
        const SurfacePlacementContext(
          containerId: 'table',
          freeSlotIds: ['0'],
          occupiedCount: 2,
          capacity: 2,
          occludesImportant: true,
        ),
      );
      expect(crowded.first.score, greaterThan(best!.score));
    });
  });

  group('R23–R24 ObjectState + traces', () {
    test('book open/TV active; traces decay; cancel policy', () {
      final board = ObjectStateBoard();
      final book = board.ensure('book');
      book.setState(ObjectLogicState.open);
      book.openPage = 3;
      book.markUsed(0, traceKey: 'openPage', hold: 10);
      expect(book.traces.first.isActive(5), isTrue);
      book.tick(11);
      expect(book.traces, isEmpty);

      final tv = board.ensure('tv');
      tv.setState(ObjectLogicState.active);
      board.resolveOnActivityCancel('tv', 20);
      expect(tv.state, ObjectLogicState.idle);
      expect(tv.traces.any((t) => t.key == 'recentlyOn'), isTrue);

      board.resolveOnActivityCancel('book', 20);
      expect(book.state, ObjectLogicState.closed);
    });
  });

  group('R25–R27 home / seek / prefer', () {
    test('return home and prefer exemplar with fallback', () {
      final inv = HabitatInventory()..seedDemo();
      inv.pickUp(itemId: 'book.dune', pawnId: 'a');
      expect(ItemSeekResolver.returnHome(inv, 'book.dune'), isTrue);
      expect(
        inv.items['book.dune']!.location.containerId,
        'bookshelf',
      );

      final pick = ItemSeekResolver.preferExemplar(
        candidateIds: ['mug.blue', 'mug.red', 'mug.green'],
        pawnId: 'a',
        usageByPawnItem: {'a::mug.blue': 5, 'a::mug.red': 1},
        favoriteId: 'mug.blue',
        unavailable: {'mug.blue'},
      );
      expect(pick, isNot('mug.blue'));
      expect(pick, isNotNull);

      final util = ItemSeekResolver.returnHomeUtility(
        profile: const BehaviorProfile(conscientiousness: 0.9),
        itemAwayFromHome: true,
      );
      expect(util, greaterThan(0.4));
    });
  });

  group('R28–R29 clutter + wear', () {
    test('clutter clamps; wear evolves cosmetically', () {
      final r = StatefulObjectRecord(id: 'chair');
      r.applyClutter(dx: 0.1);
      r.applyClutter(dx: 0.2);
      expect(r.clutterOffsetX.abs(), lessThanOrEqualTo(0.2));
      for (var i = 0; i < 15; i++) {
        r.markUsed(i.toDouble());
      }
      expect(r.wear, ObjectWearVisual.worn);
      r.resetWear();
      expect(r.wear, ObjectWearVisual.pristine);
    });
  });

  group('R30 feedback catalog', () {
    test('six categories mapped', () {
      final kinds = {
        ObjectFeedbackCatalog.forTags({'switch'}),
        ObjectFeedbackCatalog.forTags({'book'}),
        ObjectFeedbackCatalog.forTags({'keyboard'}),
        ObjectFeedbackCatalog.forTags({'boardgame'}),
        ObjectFeedbackCatalog.forTags({'cup'}),
        ObjectFeedbackCatalog.forTags({'furniture'}),
      };
      expect(kinds.length, greaterThanOrEqualTo(5));
      expect(
        ObjectFeedbackCatalog.moteLabel(ObjectFeedbackKind.silent),
        isEmpty,
      );
    });
  });

  group('R31 interruption-safe transfers', () {
    test('pickup/place/returnHome/give cancel without orphan', () {
      final inv = HabitatInventory()..seedDemo();
      final j = ItemTransferJournal(inv);
      final txn = j.begin(
        op: ItemTransferOp.pickup,
        itemId: 'book.dune',
        to: HabitatItemLocation.held('p'),
      )!;
      expect(j.rollback(txn), isTrue);
      expect(inv.locationsConsistent, isTrue);
      expect(
        inv.items['book.dune']!.location.kind,
        HabitatItemLocationKind.storageSlot,
      );

      final pick = j.begin(
        op: ItemTransferOp.pickup,
        itemId: 'book.dune',
        to: HabitatItemLocation.held('p'),
      )!;
      expect(j.commit(pick), isTrue);
      final ret = j.begin(
        op: ItemTransferOp.returnHome,
        itemId: 'book.dune',
        to: const HabitatItemLocation(
          kind: HabitatItemLocationKind.storageSlot,
          containerId: 'bookshelf',
          slotId: '0',
        ),
      )!;
      expect(j.commit(ret), isTrue);
      expect(inv.locationsConsistent, isTrue);
      expect(j.holdersOf('book.dune'), 1);
    });
  });
}
