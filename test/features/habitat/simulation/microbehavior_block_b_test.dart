import 'package:fallhub/features/habitat/simulation/identity/identity.dart';
import 'package:fallhub/features/habitat/simulation/microbehavior/microbehavior.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('R10 ApproachSlotRanker', () {
    test('ranks 4 slots — lookAt improves facing quality vs far side', () {
      bool walkable(int x, int y) => x >= 0 && y >= 0 && x < 12 && y < 12;
      final ranked = ApproachSlotRanker.rank(
        ctx: const ApproachSlotContext(
          from: (0, 5),
          propOrigin: (5, 5),
          propSize: (1, 1),
          lookAtCell: (5, 0),
          propFacing: MicroFacing.north,
        ),
        isWalkable: walkable,
      );
      expect(ranked.length, greaterThanOrEqualTo(4));
      // Slot south of prop (5,6) looks north at TV — should beat east/west sides.
      final south = ranked.where((s) => s.cell == (5, 6)).first;
      final east = ranked.where((s) => s.cell == (6, 5)).first;
      expect(south.facingQuality, greaterThan(east.facingQuality));
      expect(ranked.first.score, lessThanOrEqualTo(south.score + 0.01));
    });

    test('occupied slots are skipped', () {
      bool walkable(int x, int y) => true;
      final all = ApproachSlotRanker.candidateCells(
        propOrigin: (2, 2),
        propSize: (1, 1),
        isWalkable: walkable,
      );
      final ranked = ApproachSlotRanker.rank(
        ctx: ApproachSlotContext(
          from: (0, 0),
          propOrigin: (2, 2),
          propSize: (1, 1),
          occupiedCells: all.toSet(),
        ),
        isWalkable: walkable,
      );
      expect(ranked, isEmpty);
    });
  });

  group('R11 SeatOrientation', () {
    test('sofa/tv faces target tag; dining faces table; reading faces room', () {
      final tv = SeatOrientationResolver.resolve(
        const SeatOrientationContext(
          seatCell: (3, 5),
          propFacing: MicroFacing.south,
          propKind: 'sofa',
          targetTagCells: {
            'tv': [(3, 1)],
          },
        ),
      );
      expect(tv.policyApplied, SeatOrientationPolicy.faceTargetTag);
      expect(tv.facing, MicroFacing.north);

      final dining = SeatOrientationResolver.resolve(
        const SeatOrientationContext(
          seatCell: (4, 4),
          propFacing: MicroFacing.east,
          propKind: 'dining_chair',
          tags: {'table'},
          tableCenter: (6, 4),
        ),
      );
      expect(dining.policyApplied, SeatOrientationPolicy.faceTableCenter);
      expect(dining.facing, MicroFacing.east);

      final reading = SeatOrientationResolver.resolve(
        const SeatOrientationContext(
          seatCell: (2, 2),
          propFacing: MicroFacing.south,
          propKind: 'reading_armchair',
          roomCenter: (8, 2),
        ),
      );
      expect(reading.policyApplied, SeatOrientationPolicy.faceRoomCenter);
      expect(reading.facing, MicroFacing.east);
    });
  });

  group('R12 PersonalSpace', () {
    test('strangers pay more than group activity', () {
      final agents = [
        const PersonalSpaceAgent(pawnId: 'a', cell: (0, 0)),
        const PersonalSpaceAgent(pawnId: 'b', cell: (1, 0)),
      ];
      final stranger = PersonalSpace.costAt(
        cell: (1, 0),
        agents: agents,
        selfId: 'a',
        socialStyle: SocialStyle.reserved,
        relationshipComfort: 0.2,
      );
      final group = PersonalSpace.costAt(
        cell: (1, 0),
        agents: agents,
        selfId: 'a',
        groupActivity: true,
      );
      expect(stranger, greaterThan(group));
    });
  });

  group('R13 SoftLocalAvoidance', () {
    test('lower priority yields with wait or side-step; no oscillation loop', () {
      const self = AvoidanceAgentSnapshot(
        pawnId: 'a',
        cell: (0, 0),
        nextCell: (1, 0),
        urgency: 0.1,
        remainingPathLength: 5,
      );
      const other = AvoidanceAgentSnapshot(
        pawnId: 'b',
        cell: (2, 0),
        nextCell: (1, 0),
        urgency: 0.9,
        remainingPathLength: 1,
      );
      final conflict = SoftLocalAvoidance.detect(self: self, others: [other]);
      expect(conflict, isNotNull);
      final d = SoftLocalAvoidance.resolve(
        self: self,
        other: other,
        conflict: conflict!,
        isWalkable: (x, y) => y == 0 || y == 1,
        blockedByPawns: {(2, 0)},
        oscillationCount: SoftLocalAvoidance.maxOscillationFlips,
      );
      expect(d.action, AvoidanceAction.wait);
    });

    test('head-on can side-step', () {
      const self = AvoidanceAgentSnapshot(
        pawnId: 'a',
        cell: (0, 0),
        nextCell: (1, 0),
        urgency: 0.1,
      );
      const other = AvoidanceAgentSnapshot(
        pawnId: 'b',
        cell: (1, 0),
        nextCell: (0, 0),
        urgency: 0.9,
      );
      final conflict = SoftLocalAvoidance.detect(self: self, others: [other])!;
      expect(conflict.headOn, isTrue);
      final d = SoftLocalAvoidance.resolve(
        self: self,
        other: other,
        conflict: conflict,
        isWalkable: (x, y) => true,
        blockedByPawns: {(1, 0)},
        unitNoise: 0.2,
      );
      expect(
        d.action == AvoidanceAction.sideStep || d.action == AvoidanceAction.wait,
        isTrue,
      );
    });
  });

  group('R14 DoorReservation', () {
    test('second pawn cannot claim; release on cancel', () {
      final board = DoorReservationBoard();
      final a = board.tryClaim(
        doorId: 'd',
        pawnId: 'a',
        direction: (1, 0),
        now: 0,
      );
      expect(a, isNotNull);
      expect(
        board.tryClaim(
          doorId: 'd',
          pawnId: 'b',
          direction: (-1, 0),
          now: 0.1,
        ),
        isNull,
      );
      board.release('d', pawnId: 'a');
      expect(
        board.tryClaim(
          doorId: 'd',
          pawnId: 'b',
          direction: (-1, 0),
          now: 0.2,
        ),
        isNotNull,
      );
    });

    test('wait spot is lateral and walkable', () {
      final spot = DoorReservationBoard.pickWaitSpot(
        doorCell: (5, 5),
        from: (4, 5),
        toward: (6, 5),
        isWalkable: (x, y) => true,
        occupied: {},
      );
      expect(spot, isNotNull);
      expect(spot == (5, 5), isFalse);
    });
  });

  group('R16 WaitSpot queue', () {
    test('three pawns queue; abandon frees spot; promote when free', () {
      final q = StationQueue(
        const StationQueueConfig(
          stationId: 'coffee',
          waitSpots: [
            WaitSpot(cell: (1, 0), index: 0),
            WaitSpot(cell: (2, 0), index: 1),
            WaitSpot(cell: (3, 0), index: 2),
          ],
          maxQueueLength: 3,
        ),
      );
      expect(q.tryJoin(pawnId: 'a', now: 0, from: (0, 0)), isNull); // using
      expect(q.user?.pawnId, 'a');
      expect(q.tryJoin(pawnId: 'b', now: 1, from: (0, 0)), (1, 0));
      expect(q.tryJoin(pawnId: 'c', now: 2, from: (0, 0)), (2, 0));
      expect(q.abandon('b'), isTrue);
      expect(q.tryJoin(pawnId: 'd', now: 3, from: (0, 0)), (1, 0));
      q.leave('a');
      expect(q.promoteIfFree(4), isNotNull);
    });
  });

  group('R17 RoutePreference', () {
    test('rejects absurd detours; accepts small scenic bias', () {
      const ctx = RoutePreferenceContext(
        profile: RoutePreferenceProfile.scenic,
        maxDetourRatio: 1.35,
        maxExtraTiles: 6,
      );
      expect(
        RoutePreference.isAcceptableDetour(
          shortestLen: 10,
          candidateLen: 12,
          ctx: ctx,
        ),
        isTrue,
      );
      expect(
        RoutePreference.isAcceptableDetour(
          shortestLen: 10,
          candidateLen: 20,
          ctx: ctx,
        ),
        isFalse,
      );
      expect(
        RoutePreference.cellExtraCost(
          x: 1,
          y: 1,
          ctx: RoutePreferenceContext(
            profile: RoutePreferenceProfile.scenic,
            scenicCells: {(1, 1)},
          ),
        ),
        lessThan(0),
      );
    });
  });

  group('R18 RoomEntryScan', () {
    test('urgent skips; otherwise attention to salient cue', () {
      final skip = RoomEntryScanner.begin(
        pawnId: 'p',
        roomId: 'living',
        now: 0,
        cues: const [
          RoomSalienceCue(cell: (2, 2), score: 0.9, entityId: 'jam'),
        ],
        urgent: true,
      );
      expect(skip?.skipped, isTrue);

      final scan = RoomEntryScanner.begin(
        pawnId: 'p',
        roomId: 'living',
        now: 1,
        cues: const [
          RoomSalienceCue(cell: (2, 2), score: 0.9, entityId: 'jam'),
        ],
      );
      expect(scan?.skipped, isFalse);
      expect(scan?.attention?.entityId, 'jam');
      expect(scan!.endsAt - scan.startedAt, lessThanOrEqualTo(0.5));
    });
  });

  group('R19 CrowdingAwareness', () {
    test('reserved relocates from dense center; committed does not', () {
      final cells = [(5, 5), (5, 6), (6, 5), (4, 5), (5, 4)];
      final local = CrowdingAwareness.scoreAt(cell: (5, 5), pawnCells: cells);
      expect(
        CrowdingAwareness.shouldRelocate(
          local: local,
          socialStyle: SocialStyle.reserved,
          solitudePressure: 0.7,
        ),
        isTrue,
      );
      expect(
        CrowdingAwareness.shouldRelocate(
          local: local,
          socialStyle: SocialStyle.reserved,
          activityCommitted: true,
        ),
        isFalse,
      );
      final quiet = CrowdingAwareness.pickQuieterCell(
        from: (5, 5),
        pawnCells: cells,
        isWalkable: (x, y) => x >= 0 && y >= 0 && x < 20 && y < 20,
      );
      expect(quiet, isNotNull);
    });
  });

  group('PropOccupancy + Block A regressions', () {
    test('seat claim exclusive; facing settle prefers seat over prop center', () {
      final board = PropOccupancyBoard();
      expect(board.tryClaimProp('chair', 'a'), isTrue);
      expect(board.tryClaimProp('chair', 'b'), isFalse);
      board.releaseProp('chair', pawnId: 'a');
      expect(board.tryClaimProp('chair', 'b'), isTrue);

      final facing = DesiredFacingResolver.resolve(
        const FacingSettleContext(
          pawnCell: (3, 5),
          lastFacing: MicroFacing.south,
          // No affordanceTargetCell — seat wins.
          seatFacing: MicroFacing.north,
          roomInterestCell: (0, 0),
        ),
      );
      expect(facing.source, FacingSettleSource.seatFunctional);
      expect(facing.facing, MicroFacing.north);
    });
  });
}
