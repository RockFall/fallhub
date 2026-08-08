import 'dart:math' as math;

import 'package:fallhub/features/habitat/flame/habitat_room_stats.dart';
import 'package:fallhub/features/habitat/flame/habitat_social.dart';
import 'package:fallhub/features/habitat/flame/habitat_social_dialogue.dart';
import 'package:flutter_test/flutter_test.dart';

HabitatSocialContext _ctx({
  required List<SocialPawnSnapshot> pawns,
  List<(int, int)> tables = const [],
  List<(int, int)> gatheringSpots = const [],
  (int, int)? doorCell,
  double now = 1,
  bool Function(int x, int y)? isWalkable,
}) {
  return HabitatSocialContext(
    pawns: pawns,
    roomStats: HabitatRoomStats.empty,
    darknessAt: (_, __) => 0.2,
    filthAt: (_, __) => 0,
    phaseLabel: 'Dia',
    locationId: 'bedroom',
    isOutdoor: false,
    spaceTight: false,
    comfortOk: true,
    tempBand: 'ok',
    now: now,
    isWalkable: isWalkable ?? (_, __) => true,
    hasLamp: true,
    tables: tables,
    gatheringSpots: gatheringSpots,
    doorCell: doorCell,
  );
}

void main() {
  group('V9.14 HabitatSocialDirector', () {
    test('pair cooldown blocks immediate restart', () {
      final director = HabitatSocialDirector();
      final key = const SocialPairKey('a', 'b');
      director.memory.pairCooldownUntil[key] = 999;

      final ctx = _ctx(
        pawns: const [
          SocialPawnSnapshot(
            memberId: 'a',
            displayName: 'A',
            cellX: 3,
            cellY: 3,
            isWander: true,
            isDrafted: false,
            isBusy: false,
          ),
          SocialPawnSnapshot(
            memberId: 'b',
            displayName: 'B',
            cellX: 4,
            cellY: 3,
            isWander: true,
            isDrafted: false,
            isBusy: false,
          ),
        ],
        tables: const [(5, 5)],
      );

      expect(
        director.scorePair(ctx.pawns[0], ctx.pawns[1], ctx),
        equals(0),
      );
    });

    test('drafted pawn excluded from eligibility via isBusy flag', () {
      final ctx = _ctx(
        pawns: const [
          SocialPawnSnapshot(
            memberId: 'a',
            displayName: 'A',
            cellX: 3,
            cellY: 3,
            isWander: false,
            isDrafted: true,
            isBusy: true,
          ),
          SocialPawnSnapshot(
            memberId: 'b',
            displayName: 'B',
            cellX: 4,
            cellY: 3,
            isWander: true,
            isDrafted: false,
            isBusy: false,
          ),
        ],
      );
      final director = HabitatSocialDirector();
      director.tick(1, ctx);
      expect(director.active, isNull);
    });

    test('table venue scores higher than stand at same distance', () {
      expect(
        HabitatSocialDirector.venueScore(SocialVenue.table),
        greaterThan(HabitatSocialDirector.venueScore(SocialVenue.stand)),
      );
    });

    test('meetingCells for table picks two distinct adjacent seats', () {
      final host = const SocialPawnSnapshot(
        memberId: 'a',
        displayName: 'A',
        cellX: 2,
        cellY: 5,
        isWander: true,
        isDrafted: false,
        isBusy: false,
      );
      final guest = const SocialPawnSnapshot(
        memberId: 'b',
        displayName: 'B',
        cellX: 8,
        cellY: 5,
        isWander: true,
        isDrafted: false,
        isBusy: false,
      );
      final ctx = _ctx(
        pawns: [host, guest],
        tables: const [(5, 5)],
      );
      final (ha, ga) = HabitatSocialDirector.meetingCells(
        host: host,
        guest: guest,
        venue: SocialVenue.table,
        ctx: ctx,
      );
      expect(ha, isNot(equals(ga)));
      expect(
        (ha.$1 - 5).abs() + (ha.$2 - 5).abs(),
        equals(1),
      );
      expect(
        (ga.$1 - 5).abs() + (ga.$2 - 5).abs(),
        equals(1),
      );
    });

    test('meetingCells for stand keeps host and pulls guest adjacent', () {
      final host = const SocialPawnSnapshot(
        memberId: 'a',
        displayName: 'A',
        cellX: 3,
        cellY: 3,
        isWander: true,
        isDrafted: false,
        isBusy: false,
      );
      final guest = const SocialPawnSnapshot(
        memberId: 'b',
        displayName: 'B',
        cellX: 7,
        cellY: 3,
        isWander: true,
        isDrafted: false,
        isBusy: false,
      );
      final ctx = _ctx(pawns: [host, guest]);
      final (ha, ga) = HabitatSocialDirector.meetingCells(
        host: host,
        guest: guest,
        venue: SocialVenue.stand,
        ctx: ctx,
      );
      expect(ha, equals((3, 3)));
      expect(ha, isNot(equals(ga)));
      expect((ga.$1 - 3).abs() + (ga.$2 - 3).abs(), equals(1));
    });

    test('meetingCells never stacks two pawns on the same cell', () {
      final host = const SocialPawnSnapshot(
        memberId: 'a',
        displayName: 'A',
        cellX: 4,
        cellY: 4,
        isWander: true,
        isDrafted: false,
        isBusy: false,
      );
      final guest = const SocialPawnSnapshot(
        memberId: 'b',
        displayName: 'B',
        cellX: 4,
        cellY: 4,
        isWander: true,
        isDrafted: false,
        isBusy: false,
      );
      final ctx = _ctx(pawns: [host, guest]);
      final (ha, ga) = HabitatSocialDirector.meetingCells(
        host: host,
        guest: guest,
        venue: SocialVenue.stand,
        ctx: ctx,
      );
      expect(ha, isNot(equals(ga)));
      expect(
        (ha.$1 - ga.$1).abs() + (ha.$2 - ga.$2).abs(),
        equals(1),
      );
    });

    test('approach requests paths then advances to formUp when close', () {
      final director = HabitatSocialDirector(rng: math.Random(1));
      var hostCell = (2, 5);
      var guestCell = (8, 5);
      var pathsCalled = 0;

      SocialPawnSnapshot snap(String id, (int, int) cell) => SocialPawnSnapshot(
            memberId: id,
            displayName: id.toUpperCase(),
            cellX: cell.$1,
            cellY: cell.$2,
            isWander: true,
            isDrafted: false,
            isBusy: false,
          );

      HabitatSocialContext ctx() => _ctx(
            pawns: [snap('a', hostCell), snap('b', guestCell)],
            tables: const [(5, 5)],
            now: 100,
          );

      final talk = TalkContext(
        venue: SocialVenue.table,
        phaseLabel: 'Dia',
        beautyBand: 'mid',
        cleanBand: 'mid',
        lightBand: 'ok',
        tempBand: 'ok',
        affinity: 0.5,
        isOutdoor: false,
        spaceTight: false,
        comfortOk: true,
        hasLamp: true,
        isOffice: false,
      );
      final script = director.assembler.buildScript(
        ctx: talk,
        initiatorId: 'a',
        recipientId: 'b',
        initiatorName: 'A',
        recipientName: 'B',
        plan: const DialoguePlan(SocialTopic.mealTable),
      );
      director.active = SocialEncounter(
        aId: 'a',
        bId: 'b',
        venue: SocialVenue.table,
        hostId: 'a',
        plan: script.plan,
        talkContext: talk,
        script: script,
      )..phase = SocialEncounterPhase.approach;

      for (var i = 0;
          i < 40 &&
              director.active?.phase == SocialEncounterPhase.approach;
          i++) {
        director.tick(
          0.1,
          ctx(),
          onApproachPaths: (hId, hCell, gId, gCell) {
            pathsCalled++;
            hostCell = hCell;
            guestCell = gCell;
          },
        );
      }
      expect(pathsCalled, equals(1));
      expect(director.active?.phase, equals(SocialEncounterPhase.formUp));
      expect(director.active?.hostTarget, isNotNull);
      expect(director.active?.guestTarget, isNotNull);
    });

    test('with 8 idle pawns refresh samples at most K pairs', () {
      final pawns = [
        for (var i = 0; i < 8; i++)
          SocialPawnSnapshot(
            memberId: 'p$i',
            displayName: 'P$i',
            cellX: 2 + (i % 4),
            cellY: 2 + (i ~/ 4),
            isWander: true,
            isDrafted: false,
            isBusy: false,
          ),
      ];
      final samples = HabitatSocialDirector.samplePairs(
        pawns,
        rng: math.Random(3),
      );
      expect(samples.length, lessThanOrEqualTo(HabitatSocialDirector.maxPairsSample));
      expect(samples.length, lessThan(28)); // full C(8,2)
    });

    test('assembler yields non-empty greet lines', () {
      final asm = SocialLineAssembler(rng: math.Random(7));
      const plan = DialoguePlan(SocialTopic.idleLife);
      const talk = TalkContext(
        venue: SocialVenue.stand,
        phaseLabel: 'Dia',
        beautyBand: 'mid',
        cleanBand: 'mid',
        lightBand: 'ok',
        tempBand: 'ok',
        affinity: 0.4,
        isOutdoor: false,
        spaceTight: false,
        comfortOk: true,
        hasLamp: true,
        isOffice: false,
        recentTopics: [],
        listenerName: 'B',
      );
      final line = asm.assemble(
        SocialBeatType.greet,
        plan,
        talk,
        speakerId: 'a',
        listenerId: 'b',
        listenerName: 'B',
        usedOpener: false,
        isResponse: false,
      );
      expect(line.text.trim(), isNotEmpty);
    });
  });
}
