import 'package:fallhub/features/habitat/simulation/authority/habitat_authority.dart';
import 'package:fallhub/features/habitat/simulation/embodied/embodied_runtime.dart';
import 'package:fallhub/features/habitat/simulation/embodied/need_engine.dart';
import 'package:fallhub/features/habitat/simulation/embodied/pawn_embodied_state.dart';
import 'package:fallhub/features/habitat/simulation/embodied/pawn_embodied_store.dart';
import 'package:fallhub/features/habitat/simulation/identity/pawn_identity.dart';
import 'package:fallhub/features/habitat/simulation/identity/proxy_privacy.dart';
import 'package:fallhub/features/habitat/simulation/mirror/mirror_signal.dart';
import 'package:fallhub/features/habitat/simulation/persist/habitat_snapshot.dart';
import 'package:fallhub/features/habitat/simulation/time/background_sim.dart';
import 'package:fallhub/features/habitat/simulation/time/habitat_episode.dart';
import 'package:fallhub/features/habitat/simulation/debug/habitat_invariants.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  EmbodiedRuntime runtime() => EmbodiedRuntime(
        store: PawnEmbodiedStore(),
        episodes: HabitatEpisodeLedger(),
      );

  group('M45 proxy privacy', () {
    test('blocks intimate signals on personProxy; labels simulated', () {
      final p = ProxyPrivacyPolicy();
      expect(
        p.mayAttachPersonalSignal(
          kind: PawnIdentityKind.personProxy,
          isSensitiveIntimate: true,
        ),
        isFalse,
      );
      expect(
        p.mayAttachPersonalSignal(
          kind: PawnIdentityKind.self,
          isSensitiveIntimate: true,
        ),
        isTrue,
      );
      expect(
        p.labelForNeed('Sleepiness', isProxy: true),
        contains('simulated'),
      );
      final sig = MirrorSignal<double>(
        id: 'sleep.real',
        value: 0.2,
        source: MirrorSignalSource.manual,
        observedAt: DateTime.now().toUtc(),
        confidence: 1,
        isSensitive: true,
      );
      expect(p.redactLog(sig), contains('redacted'));
    });
  });

  group('M46 authority', () {
    test('intents go through LocalHabitatAuthority', () {
      final rt = runtime();
      final ev = rt.authority.submit(
        ApplyScenePresetIntent(
          id: 'i1',
          actorId: 'user',
          sourceId: 'debug',
          atSim: 1,
          presetId: 'movieNight',
        ),
      );
      expect(ev.first.kind, 'presetApplied');
      expect(rt.scenes.activePresetId, 'movieNight');
      expect(rt.authority.snapshotJson(), contains('presetApplied'));
    });
  });

  group('M47 persistence', () {
    test('migrate v1→v3; corrupt fallback; debounce writes', () {
      final store = HabitatSnapshotStore(debounceWrites: 2);
      final v1 = MirrorReadyHabitatSnapshot(
        schemaVersion: 1,
        worldSeed: 7,
        clockState: {'hour': 10},
        payload: {'particles': true},
      );
      store.forceSave(v1);
      final loaded = store.load()!;
      expect(loaded.schemaVersion, 3);
      expect(loaded.payload.containsKey('workpieces'), isTrue);
      expect(loaded.payload.containsKey('particles'), isFalse);

      expect(MirrorReadyHabitatSnapshot.tryDecode('{broken'), isNull);
      store.markDirty();
      expect(store.maybeFlush(() => v1), isFalse);
      store.markDirty();
      expect(store.maybeFlush(() => loaded), isTrue);
      expect(store.writeCount, greaterThan(1));
    });
  });

  group('M48 background sim', () {
    test('LOD + needs.advance coarse', () {
      final bg = BackgroundSimScheduler();
      expect(
        bg.lodFor(siteVisible: true, sameSite: true, dormant: false),
        HabitatSimLod.lod0,
      );
      expect(
        bg.lodFor(siteVisible: false, sameSite: false, dormant: true),
        HabitatSimLod.lod3,
      );
      expect(
        bg.nextInterestingTime(
          isSleeping: true,
          nowSim: 10,
          wakeCandidateAt: 500,
        ),
        500,
      );
      final needs = NeedEngine(tickIntervalSimSeconds: 10);
      var state = PawnEmbodiedState.mock('p1');
      final before = state.need(NeedKind.food)!.pressure;
      state = needs.advance(
        state: state,
        deltaSimTime: 3600,
        observedAt: DateTime.now().toUtc(),
      );
      expect(state.need(NeedKind.food)!.pressure, greaterThan(before));
    });
  });

  group('M49 invariants soak', () {
    test('soak keeps world consistent', () {
      final rt = runtime();
      final soak = HabitatSoakRunner(rt.invariants);
      final report = soak.run(
        steps: 50,
        tick: (_) {
          rt.applyScenePreset('normal');
          rt.inventory.seedDemo();
        },
        check: () => rt.checkInvariants(knownPawnIds: {'p1'}),
      );
      expect(report.ok, isTrue);
    });
  });

  group('M50 mirror-ready gate', () {
    test('gate passes on seeded runtime', () {
      final rt = runtime();
      expect(rt.mirrorReadyGateIssues(), isEmpty);
      expect(rt.privacy.allowsScope('x', ProxyDataScope.appearance), isTrue);
      expect(rt.background.withinBudget, isTrue);
    });
  });
}
