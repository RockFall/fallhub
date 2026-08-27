import 'package:fallhub/features/habitat/simulation/content/habitat_media.dart';
import 'package:fallhub/features/habitat/simulation/identity/identity.dart';
import 'package:fallhub/features/habitat/simulation/identity/pawn_identity.dart';
import 'package:fallhub/features/habitat/simulation/mirror/mirror.dart';
import 'package:fallhub/features/habitat/simulation/presence/habitat_appointment.dart';
import 'package:fallhub/features/habitat/simulation/presence/presence_lifecycle.dart';
import 'package:fallhub/features/habitat/simulation/social/conversation_topic_graph.dart';
import 'package:fallhub/features/habitat/simulation/time/time.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('M15 Media', () {
    test('picks album for jazz affinity', () {
      final lib = HabitatMediaLibrary();
      final prefs = PreferenceStore();
      prefs.put(
        'p',
        PreferenceReading(
          path: InterestPath.parse('music/jazz'),
          affinity: 0.95,
          source: MirrorSignalSource.userDeclared,
        ),
      );
      final id = lib.pickForPawn(
        pawnId: 'p',
        affinities: const {},
        prefs: prefs,
        preferKind: MediaKind.album,
      );
      expect(id, isNotNull);
      final item = lib.byId(id!)!;
      expect(item.kind, MediaKind.album);
      expect(item.interestTags.any((t) => t.contains('jazz')), isTrue);
    });

    test('progress advances', () {
      final lib = HabitatMediaLibrary();
      final item = lib.items.first;
      final updated = lib.advanceProgress(item.id, 0.5)!;
      expect(updated.progress, MediaProgress.inProgress);
    });
  });

  group('M16 Topics', () {
    test('shared jazz interest raises music.jazz topic', () {
      final graph = ConversationTopicGraph();
      final prefs = PreferenceStore();
      for (final id in ['a', 'b']) {
        prefs.put(
          id,
          PreferenceReading(
            path: InterestPath.parse('music/jazz'),
            affinity: 0.9,
            source: MirrorSignalSource.simulated,
          ),
        );
      }
      final topic = graph.pick(
        prefsA: prefs,
        prefsB: prefs,
        pawnA: 'a',
        pawnB: 'b',
        nearbyMedia: HabitatMediaLibrary.defaultSeed.first,
      );
      expect(topic, isNotNull);
      expect(topic!.id, anyOf('music.jazz', 'music.general'));
      expect(graph.topics.length, greaterThanOrEqualTo(8));
    });
  });

  group('M17 Identity', () {
    test('personProxy blocks personal signals; self allows', () {
      final reg = HabitatIdentityRegistry();
      reg.ensure('me', kind: PawnIdentityKind.self, isPrimarySelf: true);
      reg.ensure('friend', kind: PawnIdentityKind.personProxy);
      expect(reg.allowPersonalSignals('me'), isTrue);
      expect(reg.allowPersonalSignals('friend'), isFalse);
      expect(reg.primarySelfId, 'me');
    });

    test('taxonomy has 30+ tags', () {
      expect(InterestTaxonomy.seed.length, greaterThanOrEqualTo(30));
    });
  });

  group('M18 Visitor', () {
    test('visitor arrives and leaves with episodes', () {
      final ledger = HabitatEpisodeLedger();
      final life = VisitorLifecycleDirector(episodes: ledger);
      life.scheduleVisit(
        pawnId: 'v1',
        arriveAtSim: 10,
        leaveAtSim: 100,
      );
      var ev = life.tick(simSeconds: 5, siteId: 'home');
      expect(ev.spawnAtEntrance, isEmpty);
      ev = life.tick(simSeconds: 10, siteId: 'home');
      expect(ev.spawnAtEntrance, contains('v1'));
      expect(life.status['v1']!.state, PresenceState.present);
      expect(ledger.openOfKind('presence'), isNotEmpty);
      ev = life.tick(simSeconds: 60, siteId: 'home');
      expect(life.status['v1']!.state, PresenceState.leaving);
      expect(ev.farewellOpportunity, contains('v1'));
      ev = life.tick(simSeconds: 100, siteId: 'home');
      expect(ev.despawn, contains('v1'));
      expect(life.status['v1']!.state, PresenceState.absent);
    });
  });

  group('M19 Appointment', () {
    test('phases prepare → active → complete', () {
      final ledger = HabitatEpisodeLedger();
      final dir = HabitatAppointmentDirector(episodes: ledger);
      dir.scheduleDemoDinner(
        participants: {'a', 'b'},
        nowSim: 0,
        delaySeconds: 100,
        durationSeconds: 50,
      );
      var intents = dir.tick(39); // prep starts at 40
      expect(intents, isEmpty);
      intents = dir.tick(40); // preparing
      expect(intents.any((i) => i.kind == AppointmentIntentKind.prepare), isTrue);
      intents = dir.tick(100);
      expect(intents.any((i) => i.kind == AppointmentIntentKind.start), isTrue);
      intents = dir.tick(160);
      expect(
        intents.any((i) => i.kind == AppointmentIntentKind.complete),
        isTrue,
      );
      expect(dir.debugTimeline, isNotEmpty);
      expect(dir.appointments.first.appointment.source, MirrorSignalSource.manual);
    });
  });
}
