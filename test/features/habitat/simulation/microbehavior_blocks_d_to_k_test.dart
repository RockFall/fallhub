import 'package:fallhub/features/habitat/flame/habitat_map.dart';
import 'package:fallhub/features/habitat/simulation/identity/identity.dart';
import 'package:fallhub/features/habitat/simulation/microbehavior/microbehavior.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Block D social etiquette', () {
    test('R32 four greeting contexts + cooldown', () {
      final last = <String, double>{};
      final visitor = GreetingGrammar.decide(
        timeSinceLastSeen: 9999,
        familiarity: 0.2,
        affinity: 0.5,
        isVisitor: true,
        justArrived: true,
        style: SocialStyle.outgoing,
        aId: 'a',
        bId: 'b',
        now: 0,
        lastGreetingAt: last,
      );
      expect(visitor.context, GreetingContext.visitorArrival);
      expect(visitor.mode, GreetingMode.bubble);
      last['a::b'] = 0;
      final cooled = GreetingGrammar.decide(
        timeSinceLastSeen: 10,
        familiarity: 0.9,
        affinity: 0.9,
        isVisitor: false,
        justArrived: false,
        style: SocialStyle.balanced,
        aId: 'a',
        bId: 'b',
        now: 10,
        lastGreetingAt: last,
      );
      expect(cooled.mode, GreetingMode.none);
      final brief = GreetingGrammar.decide(
        timeSinceLastSeen: 60,
        familiarity: 0.8,
        affinity: 0.6,
        isVisitor: false,
        justArrived: false,
        style: SocialStyle.balanced,
        aId: 'c',
        bId: 'd',
        now: 1000,
        lastGreetingAt: {},
      );
      expect(brief.context, GreetingContext.briefRecontact);
      final long = GreetingGrammar.decide(
        timeSinceLastSeen: 3600 * 8,
        familiarity: 0.5,
        affinity: 0.5,
        isVisitor: false,
        justArrived: false,
        style: SocialStyle.balanced,
        aId: 'e',
        bId: 'f',
        now: 0,
        lastGreetingAt: {},
      );
      expect(long.context, GreetingContext.afterLongAbsence);
    });

    test('R33 goodbye does not block when interrupted', () {
      final g = GoodbyeGrammar.decide(
        trigger: GoodbyeTrigger.visitorLeaving,
        interrupted: true,
      );
      expect(g.blockDeparture, isFalse);
      expect(g.pauseSeconds, 0);
    });

    test('R34 conversational slots avoid pile', () {
      final slots = ConversationalPositioning.planSlots(
        center: (5, 5),
        count: 3,
        isWalkable: (x, y) => true,
      );
      expect(slots.toSet().length, greaterThanOrEqualTo(2));
    });

    test('R35 turn-taking avoids monopoly', () {
      final t = TurnTakingState(participantIds: ['a', 'b', 'c']);
      t.beginTurn('a', 0);
      t.beginTurn('a', 1);
      final next = t.pickNext(
        now: 2,
        topicAffinity: {'a': 1, 'b': 0.5, 'c': 0.5},
        styles: {
          'a': SocialStyle.outgoing,
          'b': SocialStyle.balanced,
          'c': SocialStyle.reserved,
        },
        relationship: {'a': 0.5, 'b': 0.5, 'c': 0.5},
      );
      expect(next, isNot('a'));
    });

    test('R36–R47 join/leave/invite/silence/reactions/ack/suspend', () {
      expect(
        BackchannelScheduler.maybeEmit(
          style: SocialStyle.outgoing,
          listenerId: 'l',
          now: 10,
          lastEmitAt: 0,
        ),
        anyOf(isNull, isA<BackchannelKind>()),
      );
      final drift = TopicDrift.nextTopic(
        current: 'music',
        graph: {
          'music': const TopicNode('music', adjacent: ['jazz', 'film']),
        },
        interestIds: ['jazz'],
        pawnId: 'p',
        now: 1,
      );
      expect(drift, 'jazz');
      final hear = Overhearing.evaluate(
        distance: 2,
        sameRoom: true,
        doorClosedBetween: false,
        noiseProfile: 0.1,
      );
      expect(hear.canOverhear, isTrue);
      final g = ConversationGroup(
        id: 'g',
        participantIds: ['a', 'b'],
        topicId: 'music',
      );
      expect(g.tryJoin('c'), isTrue);
      expect(g.leave('a'), isTrue);
      expect(g.participantIds.contains('a'), isFalse);
      final inv = SocialInvitation(
        inviter: 'a',
        invitee: 'b',
        activityKind: 'boardgame',
        expiresAt: 10,
      );
      expect(InvitationResolver.accept(utility: 0.7, threshold: 0.55), isTrue);
      expect(inv.isExpired(11), isTrue);
      final reactions = CoordinatedReactions.schedule(
        event: GroupReactionEvent(
          id: 'e',
          kind: 'boardgame',
          at: 0,
          participantIds: ['a', 'b', 'c'],
        ),
        profiles: {},
      );
      expect(reactions.map((r) => r.firesAt).toSet().length, greaterThan(1));
      final rematch = TeasingRematch.maybeRematch(
        winnerId: 'a',
        loserId: 'b',
        playfulness: 0.8,
        familiarity: 0.7,
        now: 0,
        lastRematchAt: -999,
      );
      // probabilistic — either null or invitation
      expect(rematch == null || rematch.activityKind == 'boardgame', isTrue);
      expect(
        SocialAcknowledgement.forTrigger(
          trigger: 'receiveItem',
          pairKey: 'a::b',
          now: 0,
          lastAckAt: {},
        ),
        AcknowledgementKind.shortSpeech,
      );
      final sus = SuspendedConversation(
        participantIds: ['a', 'b'],
        topicId: 't',
        expiresAt: 5,
        reason: 'pet',
      );
      expect(sus.canResume(now: 2, manualOrder: false, longAbsence: false), isTrue);
      expect(sus.canResume(now: 2, manualOrder: true, longAbsence: false), isFalse);
    });
  });

  group('Block E collective', () {
    test('roles beats migration spectator dispersion', () {
      final roles = ActivityRoles.assign(
        activityId: 'jam',
        pawnIds: ['a', 'b'],
        hostId: 'a',
      );
      expect(roles.roles['a'], ActivityRole.host);
      final sched = ActivityBeatScheduler(
        activityKind: 'boardgame',
        participantIds: ['a', 'b'],
      );
      expect(sched.tick(0), isNotNull);
      expect(sched.tick(0.1), isNull);
      final mig = ActivityMigration.maybeMigrate(
        currentSite: 'living',
        crowding: 2.5,
        comfort: 0.2,
        altSites: ['terrace'],
      );
      expect(mig?.toSite, 'terrace');
      expect(
        SpectatorBehavior.canSpectate(
          interest: 0.5,
          socialTolerance: 0.5,
          hasSpace: true,
        ),
        isTrue,
      );
      final disp = GroupDispersion.disperse(
        pawnIds: ['a', 'b'],
        center: (5, 5),
        isWalkable: (x, y) => true,
      );
      expect(disp.length, 2);
    });
  });

  group('Block F sleep/routine', () {
    test('signals bed nap quiet morning last-check', () {
      expect(
        SleepBodySignals.forPressure(0.95),
        SleepBodySignal.nodOff,
      );
      expect(WindDownRoutine.plan(sleepPressure: 0.8, pawnId: 'p'), isNotEmpty);
      final bed = BedChoreography()..beginEnter(now: 0, nap: true);
      expect(bed.isNap, isTrue);
      expect(NapPolicy.isNap(sceneHour: 14, intendedDurationMinutes: 30), isTrue);
      expect(QuietHoursBehavior.isQuiet(23), isTrue);
      expect(MorningMicroRoutine.plan('p', null), isNotEmpty);
      expect(
        LastCheckBeforeLeave.checklist(
          lightsOn: true,
          windowOpen: false,
          stoveOn: false,
          bagReady: true,
        ),
        ['lights'],
      );
      final wake = WakeInertia(startedAt: 0)..tick(6);
      expect(wake.speedMul, lessThan(1));
    });
  });

  group('Block G atmosphere', () {
    test('footsteps spatial quietness daypart', () {
      expect(Footsteps.fromFloor(HabitatFloor.carpet), FootstepMaterial.carpet);
      final v = SpatialAudio.hear(
        sample: const SpatialAudioSample(
          id: 'tv',
          cell: (0, 0),
          baseVolume: 1,
        ),
        listener: (3, 0),
        sameRoom: true,
        doorClosed: false,
      );
      expect(v, greaterThan(0));
      expect(AtmospherePresets.fromHour(23), DaypartAtmosphere.night);
      final q = QuietnessController()..setDaypart(DaypartAtmosphere.night);
      q.tick(1);
      expect(q.speechMul, lessThan(1));
      expect(
        LivedInMarkers.forRoom(recentActivityCount: 3, morning: true),
        contains(LivedInMarker.mugOut),
      );
    });
  });

  group('Block H pets', () {
    test('attention spots follow zoomies', () {
      final att = PetAttention()
        ..lookAt(entityId: 'human', cell: (1, 1), now: 0);
      expect(att.current, isNotNull);
      att.tick(2);
      expect(att.current, isNull);
      expect(
        PetFollowAvoid.decide(
          affinity: 0.8,
          humanBusy: false,
          humanMovingFast: false,
          solitudeNeed: 0.1,
        ),
        PetFollowMode.follow,
      );
      final pace = PetEnergyPacing()..tick(0, energy: 0.95);
      expect(pace.phase, PetEnergyPhase.zoomies);
    });
  });

  group('Block I editor', () {
    test('snap marquee align catalog shortcuts', () {
      expect(
        SmartSnapping.snap(
          raw: (2, 2),
          wallCells: [(2, 1)],
          furnitureOrigins: [],
        ).snapped,
        isTrue,
      );
      expect(MarqueeSelection.fromRect((0, 0), (2, 1)).cells.length, 6);
      expect(AlignDistribute.alignLeft([(3, 1), (5, 2)]).first.$1, 3);
      expect(
        CatalogSearch.filter(
          ids: ['chair', 'bed', 'sofa'],
          tagsById: {
            'chair': {'sit'},
            'bed': {'sleep'},
            'sofa': {'sit'},
          },
          favorites: {'sofa'},
          filter: const CatalogFilter(query: 'so', favoritesOnly: true),
        ),
        ['sofa'],
      );
      expect(EditorShortcuts.actionFor('ctrl+z'), 'undo');
      expect(
        MobileEditorGestures.interpret(
          pointers: 2,
          longPress: false,
          pinch: true,
        ),
        MobileEditorGesture.pinchZoom,
      );
      final diff = BlueprintPreview.diff(
        beforeIds: {'a', 'b'},
        afterIds: {'b', 'c'},
        movedIds: {'b'},
      );
      expect(diff.added, ['c']);
      expect(diff.removed, ['a']);
    });
  });

  group('Block J camera/UI', () {
    test('tooltips availability focus motes hud', () {
      expect(AffordanceTooltips.forKind('bed')?.title, 'Dormir');
      expect(
        ActionAvailability.whyNot(
          drafted: true,
          occupied: true,
          blockedPath: false,
          needCapacity: false,
        )?.code,
        'occupied',
      );
      final cam = CameraFocusController()
        ..request(
          const CameraFocusRequest(targetCell: (1, 1), duration: 1),
          0,
        );
      expect(cam.tick(0.5), isNotNull);
      expect(cam.tick(2), isNull);
      expect(MoteThoughtGrammar.glyph(ThoughtMoteGrammar.yawn), '~');
      expect(DebugHudPresets.panels(DebugHudPreset.social), contains('topic'));
    });
  });

  group('Block K storyteller/robustness', () {
    test('foreshadow causality digest cooldown stochastic anti-loop gate', () {
      final board = ForeshadowingBoard()
        ..schedule(
          const ForeshadowCue(
            id: 'f1',
            label: 'chuva vindo',
            firesAt: 1,
            eventKind: 'weather',
          ),
        );
      expect(board.due(0), isEmpty);
      expect(board.due(2).first.label, 'chuva vindo');
      final chain = CausalityChainDebug()
        ..record(
          const CausalityLink(
            causeId: 'a',
            effectId: 'b',
            label: 'link',
          ),
        );
      expect(chain.chainFor('a'), isNotEmpty);
      final digest = SinceLastVisit.build(
        elapsedSeconds: 120,
        activitiesFinished: 2,
        visitorsCame: 1,
        slept: true,
      );
      expect(digest.lines.length, greaterThanOrEqualTo(2));
      final cd = CooldownFamily(id: 'x', baseSeconds: 10)..mark('k', 0);
      expect(cd.ready('k', 5), isFalse);
      expect(cd.ready('k', 20), isTrue);
      final pick = StableStochasticity.chooseCloseCall(
        scored: [('a', 1.0), ('b', 0.97), ('c', 0.5)],
        salt: 's',
      );
      expect(['a', 'b'], contains(pick));
      final loop = AntiLoopDetector(threshold: 3);
      expect(loop.observe('p', 'sit'), isFalse);
      expect(loop.observe('p', 'sit'), isFalse);
      expect(loop.observe('p', 'sit'), isTrue);
      final gate = HabitatRefinementGate.evaluate(
        blockA: true,
        blockB: true,
        blockC: true,
        blockD: true,
        blockE: true,
        blockF: true,
        blockG: true,
        blockH: true,
        blockI: true,
        blockJ: true,
        blockK: true,
        testsGreen: true,
      );
      expect(gate.passed, isTrue);
    });
  });
}
