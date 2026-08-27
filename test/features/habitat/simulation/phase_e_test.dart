import 'package:fallhub/features/habitat/simulation/embodied/embodied.dart';
import 'package:fallhub/features/habitat/simulation/mirror/mirror.dart';
import 'package:fallhub/features/habitat/simulation/presence/habitat_appointment.dart';
import 'package:fallhub/features/habitat/simulation/presence/habitat_transit.dart';
import 'package:fallhub/features/habitat/simulation/presence/planned_activity.dart';
import 'package:fallhub/features/habitat/simulation/presence/remote_call.dart';
import 'package:fallhub/features/habitat/simulation/time/time.dart';
import 'package:fallhub/features/habitat/simulation/world/context_profile.dart';
import 'package:fallhub/features/habitat/simulation/world/habitat_world.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('M20 Remote call', () {
    test('voice call without physical remote pawn', () {
      final ledger = HabitatEpisodeLedger();
      final calls = RemoteCallDirector(episodes: ledger);
      calls.startVoiceCall(
        localPawnId: 'me',
        remotePawnId: 'friend',
        remoteName: 'Amigo',
        nowSim: 0,
      );
      expect(calls.isOnCall, isTrue);
      expect(calls.active!.phase, RemoteCallPhase.ringing);
      calls.tick(3);
      expect(calls.active!.phase, RemoteCallPhase.active);
      expect(ledger.openOfKind('remoteCall'), isNotEmpty);
      calls.endActive(10, interrupted: true);
      expect(calls.isOnCall, isFalse);
      expect(calls.debugLog, isNotEmpty);
    });
  });

  group('M21 Planned activity', () {
    test('dinner maps to goToTable with fallback', () {
      final composer = PlannedActivityComposer();
      final appt = HabitatAppointment(
        id: 'a1',
        title: 'Jantar',
        startsAt: 100,
        endsAt: 200,
        participantPawnIds: {'a', 'b'},
        siteId: 'home',
        activityKind: 'dinner',
        presenceMode: AppointmentPresenceMode.physical,
        source: MirrorSignalSource.manual,
      );
      final rt = composer.attach(appt, isAvailable: (_) => true);
      expect(rt.resolvedAffordance, 'goToTable');
      expect(rt.primaryUnavailable, isFalse);

      final missing = composer.attach(
        HabitatAppointment(
          id: 'a2',
          title: 'Game',
          startsAt: 100,
          endsAt: 200,
          participantPawnIds: {'a', 'b'},
          siteId: 'home',
          activityKind: 'gameNight',
          presenceMode: AppointmentPresenceMode.physical,
          source: MirrorSignalSource.simulated,
        ),
        isAvailable: (id) => id != 'recreate',
      );
      expect(missing.primaryUnavailable, isTrue);
      expect(missing.resolvedAffordance, isNot('recreate'));
      expect(composer.utilityBoost('a2'), greaterThan(0));
    });
  });

  group('M22 World sites/rooms', () {
    test('demo home has 3+ rooms and 2 sites', () {
      final world = HabitatWorld();
      expect(world.sites.length, greaterThanOrEqualTo(2));
      final home = world.sites['home_apartment']!;
      expect(home.roomIds.length, greaterThanOrEqualTo(3));
      expect(home.timezoneId, isNotEmpty);
      final room = world.roomByMapLocation('bedroom');
      expect(room?.siteId, 'home_apartment');
      expect(world.siteForMapLocation('kitchen')?.kind, HabitatSiteKind.home);
    });
  });

  group('M23 Transit', () {
    test('leave home → transit → away at cafe', () {
      final ledger = HabitatEpisodeLedger();
      final transit = HabitatTransitDirector(
        episodes: ledger,
        materializeSite: (id) => id != 'generic_cafe_01',
      );
      transit.ensureAtSite('me', 'home_apartment');
      transit.beginTransit(
        pawnId: 'me',
        originSiteId: 'home_apartment',
        destinationSiteId: 'generic_cafe_01',
        nowSim: 0,
        durationSeconds: 30,
      );
      var ev = transit.tick(4);
      expect(ev.any((e) => e.kind == 'left'), isTrue);
      expect(transit.locationState['me'], PawnPresenceLocation.inTransit);
      expect(transit.isPhysicallyPresent('me', 'home_apartment'), isFalse);
      ev = transit.tick(30);
      expect(ev.any((e) => e.kind == 'away'), isTrue);
      expect(transit.locationState['me'], PawnPresenceLocation.away);
    });

    test('ensureIdentity does not reset away/transit', () {
      final store = PawnEmbodiedStore();
      final runtime = EmbodiedRuntime(
        store: store,
        episodes: HabitatEpisodeLedger(),
      );
      runtime.ensureIdentity('me', isPrimarySelf: true);
      runtime.transit.beginTransit(
        pawnId: 'me',
        originSiteId: 'home_apartment',
        destinationSiteId: 'generic_cafe_01',
        nowSim: 0,
        durationSeconds: 40,
      );
      runtime.transit.tick(5);
      expect(runtime.transit.locationState['me'], PawnPresenceLocation.inTransit);
      runtime.ensureIdentity('me', isPrimarySelf: true);
      expect(runtime.transit.locationState['me'], PawnPresenceLocation.inTransit);
    });
  });

  group('M24 Context profiles', () {
    test('bedroom favors focus; cafe worsens private call', () {
      expect(HabitatContextProfiles.bedroom.allows('sleep'), isTrue);
      expect(HabitatContextProfiles.cafe.allows('sleep'), isFalse);
      expect(
        HabitatContextProfiles.bedroom.focusFit(),
        greaterThan(HabitatContextProfiles.cafe.focusFit()),
      );
      expect(
        HabitatContextProfiles.bedroom.callFit(),
        greaterThan(HabitatContextProfiles.cafe.callFit()),
      );
    });

    test('runtime uses map context', () {
      final store = PawnEmbodiedStore();
      final runtime = EmbodiedRuntime(
        store: store,
        episodes: HabitatEpisodeLedger(),
      );
      runtime.activeMapLocationId = 'office';
      expect(runtime.activeContext.id, 'profile.office');
      expect(runtime.world.sites.length, greaterThanOrEqualTo(2));
    });
  });
}
