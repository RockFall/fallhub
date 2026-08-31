import 'package:fallhub/features/habitat/simulation/identity/identity.dart';
import 'package:fallhub/features/habitat/simulation/microbehavior/microbehavior.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('R0 AttentionController', () {
    test('higher priority steals after cooldown', () {
      final c = AttentionController(switchCooldownSeconds: 0.4);
      expect(
        c.lookAt(
          reason: AttentionReason.ambientObject,
          now: 0,
          cellX: 1,
          cellY: 1,
        ),
        isTrue,
      );
      expect(
        c.lookAt(
          reason: AttentionReason.conversationPartner,
          now: 0.1,
          entityId: 'b',
          cellX: 2,
          cellY: 2,
        ),
        isFalse, // cooldown + needs enough delta — conversation is higher
      );
      // Wait cooldown
      expect(
        c.lookAt(
          reason: AttentionReason.conversationPartner,
          now: 0.5,
          entityId: 'b',
          cellX: 2,
          cellY: 2,
        ),
        isTrue,
      );
      expect(c.current?.reason, AttentionReason.conversationPartner);
    });

    test('does not oscillate between similar ambient targets', () {
      final c = AttentionController();
      c.lookAt(
        reason: AttentionReason.ambientObject,
        now: 0,
        entityId: 'lamp',
        cellX: 0,
        cellY: 0,
      );
      expect(
        c.lookAt(
          reason: AttentionReason.ambientObject,
          now: 0.1,
          entityId: 'vase',
          cellX: 3,
          cellY: 3,
        ),
        isFalse,
      );
    });

    test('interesting event can steal early when much higher', () {
      final c = AttentionController(switchCooldownSeconds: 1);
      c.lookAt(
        reason: AttentionReason.ambientObject,
        now: 0,
        cellX: 0,
        cellY: 0,
      );
      expect(
        c.lookAt(
          reason: AttentionReason.interestingEvent,
          now: 0.05,
          cellX: 5,
          cellY: 5,
          priorityOverride: 0.95,
        ),
        isTrue,
      );
    });

    test('expires', () {
      final c = AttentionController();
      c.lookAt(
        reason: AttentionReason.passingPawn,
        now: 1,
        cellX: 1,
        cellY: 1,
        holdOverride: 0.5,
      );
      expect(c.tick(1.4), isFalse);
      expect(c.tick(1.6), isTrue);
      expect(c.current, isNull);
    });
  });

  group('R1 DesiredFacingResolver', () {
    test('priority: affordance > partner > seat > room > last', () {
      final affordance = DesiredFacingResolver.resolve(
        const FacingSettleContext(
          pawnCell: (5, 5),
          lastFacing: MicroFacing.south,
          affordanceTargetCell: (5, 3),
          partnerCell: (8, 5),
          seatFacing: MicroFacing.east,
          roomInterestCell: (0, 0),
        ),
      );
      expect(affordance.source, FacingSettleSource.affordanceTarget);
      expect(affordance.facing, MicroFacing.north);

      final partner = DesiredFacingResolver.resolve(
        const FacingSettleContext(
          pawnCell: (5, 5),
          lastFacing: MicroFacing.south,
          partnerCell: (8, 5),
          seatFacing: MicroFacing.west,
        ),
      );
      expect(partner.source, FacingSettleSource.partnerOrGroup);
      expect(partner.facing, MicroFacing.east);

      final seat = DesiredFacingResolver.resolve(
        const FacingSettleContext(
          pawnCell: (5, 5),
          lastFacing: MicroFacing.south,
          seatFacing: MicroFacing.west,
        ),
      );
      expect(seat.source, FacingSettleSource.seatFunctional);
      expect(seat.facing, MicroFacing.west);

      final last = DesiredFacingResolver.resolve(
        const FacingSettleContext(
          pawnCell: (5, 5),
          lastFacing: MicroFacing.north,
        ),
      );
      expect(last.source, FacingSettleSource.lastFacing);
      expect(last.facing, MicroFacing.north);
    });

    test('settle delay in 80–220 ms band', () {
      final r = DesiredFacingResolver.resolve(
        const FacingSettleContext(
          pawnCell: (0, 0),
          lastFacing: MicroFacing.south,
          seatFacing: MicroFacing.east,
          settleDelayUnit: 0,
        ),
      );
      expect(r.settleDelaySeconds, closeTo(0.08, 0.001));
      final r2 = DesiredFacingResolver.resolve(
        const FacingSettleContext(
          pawnCell: (0, 0),
          lastFacing: MicroFacing.south,
          seatFacing: MicroFacing.east,
          settleDelayUnit: 1,
        ),
      );
      expect(r2.settleDelaySeconds, closeTo(0.22, 0.001));
    });
  });

  group('R2 ReactionLatency', () {
    test('manual order stays fast', () {
      final d = ReactionLatency.compute(
        const ReactionLatencyContext(
          eventClass: ReactionEventClass.manualOrder,
          pawnId: 'a',
        ),
      );
      expect(d, lessThanOrEqualTo(0.12));
    });

    test('ambient slower than conversation', () {
      final (convLo, convHi) = ReactionLatencyRanges.forClass(
        ReactionEventClass.conversationBeat,
      );
      final (ambLo, ambHi) = ReactionLatencyRanges.forClass(
        ReactionEventClass.ambientEvent,
      );
      expect(ambLo, greaterThan(convLo));
      expect(ambHi, greaterThan(convHi));

      // Class bands overlap (conversation 0.12–0.60, ambient 0.25–1.40),
      // and HabitatRng uses Object.hash, which is not stable across Dart
      // versions — so a single salt can invert. The design invariant is that
      // ambient is slower on average.
      var convSum = 0.0;
      var ambSum = 0.0;
      const n = 32;
      for (var salt = 0; salt < n; salt++) {
        convSum += ReactionLatency.compute(
          ReactionLatencyContext(
            eventClass: ReactionEventClass.conversationBeat,
            pawnId: 'a',
            salt: salt,
          ),
        );
        ambSum += ReactionLatency.compute(
          ReactionLatencyContext(
            eventClass: ReactionEventClass.ambientEvent,
            pawnId: 'a',
            salt: salt,
          ),
        );
      }
      expect(ambSum / n, greaterThan(convSum / n));
    });

    test('same seed reproduces', () {
      final a = ReactionLatency.compute(
        const ReactionLatencyContext(
          eventClass: ReactionEventClass.groupJoinProbe,
          pawnId: 'colonist',
          worldSeed: 7,
          salt: 3,
          profile: BehaviorProfile(
            neuroticism: 0.4,
            conscientiousness: 0.5,
            socialStyle: SocialStyle.reserved,
          ),
        ),
      );
      final b = ReactionLatency.compute(
        const ReactionLatencyContext(
          eventClass: ReactionEventClass.groupJoinProbe,
          pawnId: 'colonist',
          worldSeed: 7,
          salt: 3,
          profile: BehaviorProfile(
            neuroticism: 0.4,
            conscientiousness: 0.5,
            socialStyle: SocialStyle.reserved,
          ),
        ),
      );
      expect(a, b);
    });

    test('scheduler drains in order', () {
      final s = ReactionScheduler();
      s.schedule(
        PendingReaction(
          id: 'b',
          eventClass: ReactionEventClass.ambientEvent,
          firesAt: 2,
          payload: 'late',
        ),
      );
      s.schedule(
        PendingReaction(
          id: 'a',
          eventClass: ReactionEventClass.ambientEvent,
          firesAt: 1,
          payload: 'early',
        ),
      );
      expect(s.drainReady(0.5), isEmpty);
      final ready = s.drainReady(2.5);
      expect(ready.map((r) => r.payload), ['early', 'late']);
    });
  });

  group('R3 MicroIdle', () {
    test('library has at least 5 variants', () {
      expect(MicroIdleKind.values.length, greaterThanOrEqualTo(5));
      expect(MicroIdleLibrary.standingPool.length, greaterThanOrEqualTo(5));
    });

    test('never two simultaneous; respects reducedMotion', () {
      final s = MicroIdleScheduler(pawnId: 'p', reducedMotion: true);
      final a = s.tick(
        now: 0,
        eligible: true,
        seated: false,
        speakingImportant: false,
      );
      expect(a, isNotNull);
      final b = s.tick(
        now: 0.1,
        eligible: true,
        seated: false,
        speakingImportant: false,
      );
      expect(identical(a, b), isTrue);
      expect(a!.presentation.highMotion, isFalse);
    });

    test('interrupted during speech', () {
      final s = MicroIdleScheduler(pawnId: 'p');
      s.tick(
        now: 0,
        eligible: true,
        seated: false,
        speakingImportant: false,
      );
      expect(s.isPlaying, isTrue);
      s.interrupt();
      expect(s.isPlaying, isFalse);
    });
  });

  group('R4 PostureController', () {
    test('sit → seated → stand pipeline', () {
      final p = PostureController();
      p.beginSit(now: 0, seatPropId: 'chair1');
      expect(p.state.phase, PosturePhase.preparingToSit);
      expect(p.state.holdsSeatReservation, isTrue);
      p.tick(PostureTimings.sitPrep + 0.01);
      expect(p.state.phase, PosturePhase.seated);
      p.beginStand(now: 1);
      expect(p.state.phase, PosturePhase.preparingToStand);
      expect(p.state.holdsSeatReservation, isTrue);
      p.tick(1 + PostureTimings.standPrep + 0.01);
      expect(p.state.phase, PosturePhase.standing);
      expect(p.state.holdsSeatReservation, isFalse);
    });

    test('cancel mid sit-prep → standing', () {
      final p = PostureController();
      p.beginSit(now: 0, seatPropId: 'c');
      p.requestCancel(now: 0.1);
      expect(p.state.phase, PosturePhase.standing);
      expect(p.state.holdsSeatReservation, isFalse);
    });

    test('cancel while seated begins stand', () {
      final p = PostureController();
      p.beginSit(now: 0);
      p.tick(PostureTimings.sitPrep + 0.01);
      p.requestCancel(now: 1);
      expect(p.state.phase, PosturePhase.preparingToStand);
    });

    test('lie / rise cancel both directions', () {
      final p = PostureController();
      p.beginLie(now: 0, bedPropId: 'bed');
      p.requestCancel(now: 0.05, force: true);
      expect(p.state.isStanding, isTrue);
      p.beginLie(now: 1);
      p.tick(1 + PostureTimings.liePrep + 0.01);
      expect(p.state.isSettledLying, isTrue);
      p.requestCancel(now: 2, force: true);
      expect(p.state.isStanding, isTrue);
    });
  });

  group('R5 LocomotorStyle', () {
    test('tired vs urgent distinguishable and within clamps', () {
      final tired = LocomotorStyle.resolve(
        const LocomotorStyleInput(fatigue: 0.8, sleepiness: 0.6),
      );
      final urgent = LocomotorStyle.resolve(
        const LocomotorStyleInput(urgency: 0.9),
      );
      expect(tired.speedMultiplier, lessThan(urgent.speedMultiplier));
      expect(tired.speedMultiplier, greaterThanOrEqualTo(LocomotorStyle.strongMin));
      expect(urgent.speedMultiplier, lessThanOrEqualTo(LocomotorStyle.strongMax));
    });

    test('subtle everyday band without strong flags', () {
      final n = LocomotorStyle.resolve(
        const LocomotorStyleInput(fatigue: 0.2, relaxed: 0.2),
      );
      expect(n.speedMultiplier, greaterThanOrEqualTo(LocomotorStyle.normalMin));
      expect(n.speedMultiplier, lessThanOrEqualTo(LocomotorStyle.normalMax));
    });
  });

  group('R6 LocomotionEasing', () {
    test('smoothstep never overshoots and is monotonic', () {
      var prev = -0.01;
      for (var i = 0; i <= 20; i++) {
        final t = i / 20;
        final e = LocomotionEasing.easeProgress(t, applyEnvelope: true);
        expect(e, greaterThanOrEqualTo(prev));
        expect(e, lessThanOrEqualTo(1.0));
        prev = e;
      }
      expect(LocomotionEasing.easeProgress(0, applyEnvelope: true), 0);
      expect(LocomotionEasing.easeProgress(1, applyEnvelope: true), 1);
    });

    test('skips ease for short/urgent paths', () {
      expect(
        LocomotionEasing.shouldEase(
          pathLengthIncludingCurrentStep: 1,
          urgent: false,
        ),
        isFalse,
      );
      expect(
        LocomotionEasing.shouldEase(
          pathLengthIncludingCurrentStep: 6,
          urgent: true,
        ),
        isFalse,
      );
      expect(
        LocomotionEasing.shouldEase(
          pathLengthIncludingCurrentStep: 6,
          urgent: false,
        ),
        isTrue,
      );
    });
  });

  group('R7 ArrivalChoreographer', () {
    test('settle → anticipate → ready; cancel frees reservation', () {
      final a = ArrivalChoreographer();
      final facing = DesiredFacingResolver.resolve(
        const FacingSettleContext(
          pawnCell: (1, 1),
          lastFacing: MicroFacing.south,
          seatFacing: MicroFacing.east,
          settleDelayUnit: 0,
        ),
      );
      a.onPathArrived(
        now: 0,
        facing: facing,
        affordanceId: 'sit',
        propId: 'chair',
        anticipation: AnticipationCatalog.sitPrep,
        pawnId: 'p',
      );
      expect(a.state.phase, ArrivalPhase.settling);
      expect(a.state.reservationHeld, isTrue);
      expect(a.cancel(now: 0.05), isTrue);
      expect(a.state.phase, ArrivalPhase.none);
      expect(a.state.reservationHeld, isFalse);

      a.onPathArrived(
        now: 1,
        facing: facing,
        affordanceId: 'sit',
        propId: 'chair',
        anticipation: const AnticipationProfile(
          id: 'fast',
          holdMinSeconds: 0.1,
          holdMaxSeconds: 0.1,
        ),
        pawnId: 'p',
      );
      a.takeFacingIfDue(1 + facing.settleDelaySeconds);
      expect(a.tick(1 + facing.settleDelaySeconds), isFalse);
      expect(a.state.phase, ArrivalPhase.anticipating);
      expect(a.tick(1 + facing.settleDelaySeconds + 0.15), isTrue);
    });
  });

  group('R8 AnticipationCatalog', () {
    test('at least 6 affordances mapped; profiles data-driven', () {
      expect(AnticipationCatalog.distinctProfiles.length, greaterThanOrEqualTo(6));
      expect(AnticipationCatalog.byAffordance.length, greaterThanOrEqualTo(6));
      expect(
        AnticipationCatalog.forAffordance('sleep').id,
        AnticipationCatalog.bedPrep.id,
      );
      expect(
        AnticipationCatalog.forAffordance('sit').holdMaxSeconds,
        lessThanOrEqualTo(0.5),
      );
    });
  });

  group('R9 BehaviorTimingOffsets', () {
    test('seed stable and pawns desync', () {
      final a = BehaviorTimingOffsets.fromSeed('alice');
      final a2 = BehaviorTimingOffsets.fromSeed('alice');
      final b = BehaviorTimingOffsets.fromSeed('bob');
      expect(a.idleProbe, a2.idleProbe);
      expect(a.needReevaluation, a2.needReevaluation);
      final same = a.idleProbe == b.idleProbe &&
          a.socialProbe == b.socialProbe &&
          a.ambientReactionProbe == b.ambientReactionProbe;
      expect(same, isFalse);
    });

    test('desync clock staggers first fires', () {
      final ca = BehaviorDesyncClock(
        offsets: BehaviorTimingOffsets.fromSeed('a'),
      );
      final cb = BehaviorDesyncClock(
        offsets: BehaviorTimingOffsets.fromSeed('b'),
      );
      final dueA = ca.debugDueIn(0)['idle']!;
      final dueB = cb.debugDueIn(0)['idle']!;
      expect(dueA == dueB, isFalse);
    });
  });
}
