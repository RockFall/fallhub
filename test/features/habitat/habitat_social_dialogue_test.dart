import 'dart:math' as math;

import 'package:fallhub/features/habitat/flame/habitat_social_dialogue.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('V9.14 SpeakUp-lite SocialLineAssembler', () {
    late SocialLineAssembler assembler;

    setUp(() {
      assembler = SocialLineAssembler(rng: math.Random(42));
    });

    TalkContext ctx({
      String beauty = 'mid',
      String clean = 'mid',
      String light = 'ok',
      String temp = 'ok',
      String phase = 'Dia',
      bool outdoor = false,
      bool spaceTight = false,
      double affinity = 0.5,
      SocialVenue venue = SocialVenue.stand,
      bool hasLamp = true,
      bool isOffice = false,
    }) {
      return TalkContext(
        venue: venue,
        phaseLabel: phase,
        beautyBand: beauty,
        cleanBand: clean,
        lightBand: light,
        tempBand: temp,
        affinity: affinity,
        isOutdoor: outdoor,
        spaceTight: spaceTight,
        comfortOk: temp == 'ok',
        hasLamp: hasLamp,
        isOffice: isOffice,
        listenerName: 'Ana',
        speakerName: 'Bo',
      );
    }

    test('filth opener never chosen when cleanBand mid', () {
      for (var i = 0; i < 30; i++) {
        final script = assembler.buildScript(
          ctx: ctx(beauty: 'high', clean: 'mid'),
          initiatorId: 'a',
          recipientId: 'b',
          initiatorName: 'Ana',
          recipientName: 'Bo',
          plan: const DialoguePlan(SocialTopic.roomBeauty),
        );
        final joined = script.lines.map((l) => l.text.toLowerCase()).join(' ');
        expect(joined, isNot(contains('vassoura')));
        expect(joined, isNot(contains('sujeira')));
      }
    });

    test('reply shares opener replyTag (adjacency pair)', () {
      final script = assembler.buildScript(
        ctx: ctx(temp: 'hot', outdoor: true, phase: 'Dia'),
        initiatorId: 'a',
        recipientId: 'b',
        initiatorName: 'Ana',
        recipientName: 'Bo',
        plan: const DialoguePlan(SocialTopic.weatherOut),
      );
      expect(script.lines.length, greaterThanOrEqualTo(2));
      final tag = script.plan.replyTag;
      expect(tag, isNotNull);
      expect(script.lines.first.replyTag, equals(tag));
      expect(script.lines[1].replyTag, equals(tag));
    });

    test('hot weather opener grounds temperature word', () {
      var sawHot = false;
      for (var i = 0; i < 20; i++) {
        final script = assembler.buildScript(
          ctx: ctx(temp: 'hot', outdoor: true),
          initiatorId: 'a',
          recipientId: 'b',
          initiatorName: 'Ana',
          recipientName: 'Bo',
          plan: const DialoguePlan(SocialTopic.weatherOut),
        );
        if (script.lines.first.text.toLowerCase().contains('quente')) {
          sawHot = true;
          // Reply should stay on weather_hot, not random beauty.
          final reply = script.lines[1].text.toLowerCase();
          expect(
            reply.contains('vassoura') || reply.contains('mesa boa'),
            isFalse,
          );
        }
      }
      expect(sawHot, isTrue);
    });

    test('listener name can appear when affinity warm', () {
      var saw = false;
      for (var i = 0; i < 40; i++) {
        final script = assembler.buildScript(
          ctx: ctx(affinity: 0.7),
          initiatorId: 'a',
          recipientId: 'b',
          initiatorName: 'Ana',
          recipientName: 'Bo',
          plan: const DialoguePlan(SocialTopic.idleLife),
        );
        if (script.lines.any((l) => l.text.contains('Bo') || l.text.contains('Ana'))) {
          saw = true;
        }
      }
      expect(saw, isTrue);
    });

    test('cold affinity yields curt ellipsis exchange', () {
      final script = assembler.buildScript(
        ctx: ctx(affinity: 0.1),
        initiatorId: 'a',
        recipientId: 'b',
        initiatorName: 'Ana',
        recipientName: 'Bo',
      );
      expect(script.plan.replyTag, equals('cold'));
      expect(script.lines.first.text, contains('…'));
      expect(script.lines[1].text, equals('…'));
    });

    test('script lines respect max length', () {
      for (var i = 0; i < 40; i++) {
        final script = assembler.buildScript(
          ctx: ctx(
            clean: i.isEven ? 'low' : 'mid',
            venue: i % 3 == 0 ? SocialVenue.table : SocialVenue.stand,
            temp: i % 2 == 0 ? 'hot' : 'ok',
          ),
          initiatorId: 'a',
          recipientId: 'b',
          initiatorName: 'Ana',
          recipientName: 'Bo',
        );
        for (final line in script.lines) {
          expect(line.text.length, lessThanOrEqualTo(SocialLineAssembler.maxLen));
        }
      }
    });

    test('30 idle scripts yield variety', () {
      final seen = <String>{};
      for (var i = 0; i < 30; i++) {
        final asm = SocialLineAssembler(rng: math.Random(i + 3));
        final script = asm.buildScript(
          ctx: ctx(),
          initiatorId: 'a',
          recipientId: 'b',
          initiatorName: 'Ana',
          recipientName: 'Bo',
          plan: const DialoguePlan(SocialTopic.idleLife),
        );
        seen.add(script.lines.map((l) => l.text).join('|'));
      }
      expect(seen.length, greaterThanOrEqualTo(8));
    });

    test('table venue scripts mention table context', () {
      var saw = false;
      for (var i = 0; i < 25; i++) {
        final script = assembler.buildScript(
          ctx: ctx(venue: SocialVenue.table),
          initiatorId: 'a',
          recipientId: 'b',
          initiatorName: 'Ana',
          recipientName: 'Bo',
          plan: const DialoguePlan(SocialTopic.mealTable),
        );
        final joined = script.lines.map((l) => l.text.toLowerCase()).join(' ');
        if (joined.contains('mesa') || joined.contains('cadeira')) {
          saw = true;
        }
      }
      expect(saw, isTrue);
    });

    test('pack has substantial material and long threads fire', () {
      expect(SocialDialoguePack.rules.length, greaterThanOrEqualTo(100));
      expect(SocialDialoguePack.threads.length, greaterThanOrEqualTo(30));
      var sawLong = false;
      for (var i = 0; i < 60; i++) {
        final asm = SocialLineAssembler(rng: math.Random(i + 11));
        final script = asm.buildScript(
          ctx: ctx(affinity: 0.6, venue: SocialVenue.table),
          initiatorId: 'a',
          recipientId: 'b',
          initiatorName: 'Ana',
          recipientName: 'Bo',
          plan: const DialoguePlan(SocialTopic.mealTable),
        );
        if (script.lines.length >= 5) sawLong = true;
      }
      expect(sawLong, isTrue);
    });
  });
}
