import 'package:fallhub/features/habitat/simulation/content/habitat_content_registry.dart';
import 'package:fallhub/features/habitat/simulation/content/habitat_custom_content.dart';
import 'package:fallhub/features/habitat/simulation/embodied/embodied_runtime.dart';
import 'package:fallhub/features/habitat/simulation/embodied/pawn_embodied_store.dart';
import 'package:fallhub/features/habitat/simulation/mirror/mirror_signal.dart';
import 'package:fallhub/features/habitat/simulation/ports/habitat_ports.dart';
import 'package:fallhub/features/habitat/simulation/time/habitat_episode.dart';
import 'package:fallhub/features/habitat/simulation/world/habitat_travel.dart';
import 'package:fallhub/features/habitat/simulation/world/habitat_world.dart';
import 'package:fallhub/features/habitat/simulation/world/habitat_world_map.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  EmbodiedRuntime runtime() => EmbodiedRuntime(
        store: PawnEmbodiedStore(),
        episodes: HabitatEpisodeLedger(),
      );

  group('M40 travel / jet lag', () {
    test('timezone hop leaves body clock lagging', () {
      final travel = HabitatTravelDirector();
      travel.beginTimezoneHop(
        pawnId: 'p1',
        originSiteId: 'home_apartment',
        destinationSiteId: 'hotel_tokyo',
        destinationTimezoneId: 'Asia/Tokyo',
        siteHourDelta: 12,
        nowSim: 10,
      );
      final c = travel.stateFor('p1');
      expect(c.bodyClockOffsetHours, 12);
      expect(c.adaptationProgress, 0);
      expect(c.isJetLagged, isTrue);
      travel.tickAdaptation('p1', dtSim: 10, rate: 0.05);
      expect(c.adaptationProgress, greaterThan(0));
      expect(c.bodyClockOffsetHours, lessThan(12));
    });
  });

  group('M41 world map', () {
    test('6+ abstract kinds; materialize and promote', () {
      expect(HabitatWorldMap.kinds.length, greaterThanOrEqualTo(6));
      final world = HabitatWorld();
      final cafe = HabitatWorldMap.kinds.firstWhere((k) => k.id == 'abstract.cafe');
      final id = HabitatWorldMap.materialize(world, cafe);
      expect(world.sites.containsKey(id), isTrue);
      expect(world.sites[id]!.kind, HabitatSiteKind.cafe);
      final custom = HabitatWorldMap.promoteCustom(world, id);
      expect(world.sites[custom]!.kind, HabitatSiteKind.custom);
      expect(HabitatWorldMap.tree['HOME'], isNotEmpty);
    });
  });

  group('M42 content registry', () {
    test('saxophone via definition; validation catches bad ref', () {
      final reg = HabitatContentRegistry();
      expect(reg.getPropDefinition('prop.saxophone_alto'), isNotNull);
      expect(reg.validate(), isEmpty);
      reg.registerProp(
        const HabitatPropDefinition(
          id: 'prop.broken',
          label: 'Broken',
          tags: {'x'},
          affordances: ['not_a_real_affordance'],
        ),
      );
      expect(reg.validate(), isNotEmpty);
    });
  });

  group('M43 custom creator', () {
    test('creates prop+activity; rejects invalid; restore', () {
      final reg = HabitatContentRegistry();
      final creator = HabitatCustomContentCreator(reg);
      final bad = creator.createProp(
        CustomContentDraft(kind: 'prop', name: '', affordances: []),
      );
      expect(bad.isOk, isFalse);
      final ok = creator.createProp(
        CustomContentDraft(
          kind: 'prop',
          name: 'Minha Guitarra',
          tags: {'guitar'},
          affordances: ['practiceInstrument'],
        ),
      );
      expect(ok.isOk, isTrue);
      final act = creator.createActivity(
        CustomContentDraft(
          kind: 'activity',
          name: 'Jam',
          tags: {'music'},
          durationSim: 20,
          needEffects: {'recreation': 0.2},
        ),
      );
      expect(act.isOk, isTrue);
      final reg2 = HabitatContentRegistry();
      creator.restoreInto(reg2);
      expect(reg2.props.containsKey(ok.id), isTrue);
    });
  });

  group('M44 ports', () {
    test('null and simulated ports have provenance', () {
      final ports = HabitatPortBundle(episodes: HabitatEpisodeLedger());
      expect(ports.appointments.readAppointments('p1'), isEmpty);
      expect(ports.sleep.readSleepSignals('p1'), isEmpty);
      final sim = SimulatedSleepSignalPort(
        episodes: const [
          HabitatSleepEpisode(startSim: 0, endSim: 100),
        ],
      );
      final signals = sim.readSleepSignals('p1');
      expect(signals, isNotEmpty);
      expect(signals.first.source, MirrorSignalSource.simulated);
      expect(signals.first.observedAt, isNotNull);
      final env = ports.environment.readEnvironment('home_apartment');
      expect(env.siteId, 'home_apartment');
    });
  });

  group('runtime wiring M40–M44', () {
    test('jet lag + world map + content', () {
      final rt = runtime();
      final hotel = rt.beginJetLagDemo('p1', nowSim: 5);
      expect(rt.world.sites.containsKey(hotel), isTrue);
      expect(rt.travel.stateFor('p1').isJetLagged, isTrue);
      final cafe = rt.goWorldMap('CAFÉ', 'p1', nowSim: 10);
      expect(cafe, isNotNull);
      expect(rt.content.validate(), isEmpty);
      expect(rt.ports.travel.readActiveTravelId(), isNull);
    });
  });
}
