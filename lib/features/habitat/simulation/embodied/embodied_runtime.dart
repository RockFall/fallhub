import '../authority/habitat_authority.dart';
import '../content/habitat_content_registry.dart';
import '../content/habitat_custom_content.dart';
import '../content/habitat_devices.dart';
import '../content/habitat_food.dart';
import '../content/habitat_inventory.dart';
import '../content/habitat_media.dart';
import '../content/habitat_preparation.dart';
import '../content/habitat_workpiece.dart';
import '../debug/habitat_invariants.dart';
import '../identity/habitat_loadout.dart';
import '../identity/identity.dart';
import '../identity/pawn_identity.dart';
import '../identity/proxy_privacy.dart';
import '../persist/habitat_snapshot.dart';
import '../ports/habitat_ports.dart';
import '../presence/habitat_appointment.dart';
import '../presence/habitat_transit.dart';
import '../presence/planned_activity.dart';
import '../presence/presence_lifecycle.dart';
import '../presence/remote_call.dart';
import '../social/conversation_topic_graph.dart';
import '../time/background_sim.dart';
import '../time/habitat_episode.dart';
import '../world/context_profile.dart';
import '../world/habitat_travel.dart';
import '../world/habitat_world.dart';
import '../world/habitat_world_map.dart';
import '../world/perceived_comfort.dart';
import '../world/scene_preset.dart';
import 'affordance_catalog.dart';
import 'behavior_routine.dart';
import 'capacity_engine.dart';
import 'condition_engine.dart';
import 'movement_recovery_system.dart';
import 'need_engine.dart';
import 'pawn_embodied_state.dart';
import 'pawn_embodied_store.dart';
import 'sleep_system.dart';

/// Orchestrates embodied + identity + presence + world systems (M5–M24).
class EmbodiedRuntime {
  EmbodiedRuntime({
    required this.store,
    required this.episodes,
  })  : needs = NeedEngine(),
        capacities = CapacityEngine(),
        conditions = ConditionEngine(),
        sleep = SleepSystem(episodes: episodes),
        movement = MovementRecoverySystem(),
        scorer = const ChoiceScorer(),
        preferences = PreferenceStore(),
        novelty = NoveltyTracker(),
        media = HabitatMediaLibrary(),
        topics = ConversationTopicGraph(),
        identity = HabitatIdentityRegistry(),
        visitors = VisitorLifecycleDirector(episodes: episodes),
        world = HabitatWorld(),
        transit = HabitatTransitDirector(episodes: episodes),
        calls = RemoteCallDirector(episodes: episodes),
        planned = PlannedActivityComposer(),
        comfort = PerceivedComfortSystem(),
        scenes = ScenePresetDirector(),
        loadouts = HabitatLoadoutResolver(),
        inventory = HabitatInventory()..seedDemo(),
        devices = HabitatDeviceDirector(),
        routines = BehaviorRoutineEngine(),
        kitchen = HabitatKitchenDirector(),
        workpieces = HabitatWorkpieceDirector(),
        preparation = PreparationDirector(),
        travel = HabitatTravelDirector(),
        content = HabitatContentRegistry(),
        ports = HabitatPortBundle(episodes: episodes),
        privacy = ProxyPrivacyPolicy(),
        snapshots = HabitatSnapshotStore(),
        background = BackgroundSimScheduler(),
        invariants = HabitatInvariantChecker() {
    customContent = HabitatCustomContentCreator(content);
    authority = LocalHabitatAuthority(
      applyPreset: (id, at) => applyScenePreset(id, nowSim: at),
      startRoutine: (rid, pid) => startRoutine(rid, pid),
      travelTo: (pid, siteId, at) {
        transit.beginTransit(
          pawnId: pid,
          originSiteId: 'home_apartment',
          destinationSiteId: siteId,
          nowSim: at,
          durationSeconds: 30,
        );
      },
      equipLoadout: (pid, lid) {
        final lo = loadouts.byId(lid);
        if (lo != null) {
          loadouts.maybeApply(
            pawnId: pid,
            loadout: lo,
            force: true,
            applyVisual: (_, __) {},
          );
        }
      },
      placeItem: (itemId, containerId) {
        inventory.putIn(itemId: itemId, containerId: containerId);
      },
    );
    appointments = HabitatAppointmentDirector(
      episodes: episodes,
      presence: visitors,
    );
    inventory.seedDemo();
    preparation.seedPrepItems(inventory);
    transit.materializeSite = (siteId) {
      final site = world.sites[siteId];
      if (site == null) return false;
      for (final roomId in site.roomIds) {
        final room = world.rooms[roomId];
        if (room?.mapLocationId != null) return true;
      }
      return false;
    };
  }

  final PawnEmbodiedStore store;
  final HabitatEpisodeLedger episodes;
  final NeedEngine needs;
  final CapacityEngine capacities;
  final ConditionEngine conditions;
  final SleepSystem sleep;
  final MovementRecoverySystem movement;
  final ChoiceScorer scorer;
  final PreferenceStore preferences;
  final NoveltyTracker novelty;
  final HabitatMediaLibrary media;
  final ConversationTopicGraph topics;
  final HabitatIdentityRegistry identity;
  final VisitorLifecycleDirector visitors;
  late final HabitatAppointmentDirector appointments;
  final HabitatWorld world;
  final HabitatTransitDirector transit;
  final RemoteCallDirector calls;
  final PlannedActivityComposer planned;
  final PerceivedComfortSystem comfort;
  final ScenePresetDirector scenes;
  final HabitatLoadoutResolver loadouts;
  final HabitatInventory inventory;
  final HabitatDeviceDirector devices;
  final BehaviorRoutineEngine routines;
  final HabitatKitchenDirector kitchen;
  final HabitatWorkpieceDirector workpieces;
  final PreparationDirector preparation;
  final HabitatTravelDirector travel;
  final HabitatContentRegistry content;
  late final HabitatCustomContentCreator customContent;
  final HabitatPortBundle ports;
  final ProxyPrivacyPolicy privacy;
  final HabitatSnapshotStore snapshots;
  final BackgroundSimScheduler background;
  final HabitatInvariantChecker invariants;
  late final LocalHabitatAuthority authority;
  final Map<String, BehaviorProfile> profiles = {};

  ConversationTopic? lastSocialTopic;
  String? lastTopicPhrase;
  String activeMapLocationId = 'bedroom';

  BehaviorProfile profileFor(String pawnId) =>
      profiles.putIfAbsent(pawnId, () => BehaviorProfile.fromSeed(pawnId));

  HabitatContextProfile get activeContext =>
      HabitatContextProfiles.forMapLocation(activeMapLocationId);

  PerceivedEnvironmentFit perceivedFit(
    String pawnId, {
    ObjectiveRoomMetrics objective = const ObjectiveRoomMetrics(),
    bool isOutdoor = false,
  }) {
    return comfort.evaluate(
      pawnId: pawnId,
      roomId: activeMapLocationId,
      objective: objective,
      context: activeContext,
      isOutdoor: isOutdoor,
    );
  }

  void ensureIdentity(
    String pawnId, {
    bool isPrimarySelf = false,
    PawnIdentityKind? kind,
  }) {
    profileFor(pawnId);
    identity.ensure(
      pawnId,
      kind: kind ??
          (isPrimarySelf ? PawnIdentityKind.self : PawnIdentityKind.resident),
      isPrimarySelf: isPrimarySelf,
    );
    if (preferences.readings(pawnId, 'music/jazz').isEmpty) {
      preferences.seedSimulated(pawnId);
    }
    visitors.ensure(
      pawnId,
      role: PresenceRole.resident,
      state: PresenceState.present,
    );
    // Do not clobber in-transit / away on every tick.
    if (!transit.locationState.containsKey(pawnId)) {
      final site = world.siteForMapLocation(activeMapLocationId);
      transit.ensureAtSite(pawnId, site?.id ?? 'home_apartment');
    }
  }

  PawnEmbodiedState tickPawn({
    required String pawnId,
    required double simSeconds,
    required double sceneHour,
    required DateTime observedAt,
    required bool isMoving,
    required bool isSedentary,
    required bool jobIsSleep,
    double comfortStress = 0,
    double socialIntensity = 0,
    double activityPhysicalLoad = 0,
    double bedComfort = 0.65,
    double darkness = 0.4,
    double tempComfort = 1,
  }) {
    ensureIdentity(pawnId);
    final personal = identity.allowPersonalSignals(pawnId);
    var state = store.ensure(pawnId);

    var effectiveSocial = socialIntensity;
    if (calls.isOnCall && calls.active?.localPawnId == pawnId) {
      effectiveSocial = (effectiveSocial + 0.45).clamp(0.0, 1.0);
    }

    state = needs.maybeTick(
      state: state,
      simSeconds: simSeconds,
      observedAt: observedAt,
      isSedentary: isSedentary,
      isMoving: isMoving,
      isSleeping: jobIsSleep ||
          state.sleepPhase == SleepPhase.sleeping ||
          state.sleepPhase == SleepPhase.nap,
      comfortStress: comfortStress,
      socialIntensity: effectiveSocial,
    );

    state = movement.maybeTick(
      state: state,
      simSeconds: simSeconds,
      observedAt: observedAt,
      isMoving: isMoving,
      isSedentary: isSedentary,
      isSleeping: jobIsSleep ||
          state.sleepPhase == SleepPhase.sleeping ||
          state.sleepPhase == SleepPhase.nap,
      activityPhysicalLoad: activityPhysicalLoad,
    );

    if (personal) {
      state = sleep.tick(
        state: state,
        simSeconds: simSeconds,
        sceneHour: sceneHour,
        observedAt: observedAt,
        jobIsSleep: jobIsSleep,
        bedComfort: bedComfort,
        darkness: darkness,
        tempComfort: tempComfort,
      );
    }

    state = conditions.maybeTick(state: state, simSeconds: simSeconds);

    if (socialIntensity > 0.2) {
      final caps = Map<CapacityKind, CapacityReading>.from(state.capacities);
      final tol = caps[CapacityKind.socialTolerance];
      if (tol != null) {
        caps[CapacityKind.socialTolerance] = tol.copyWith(
          level: tol.level - 0.02 * socialIntensity,
          observedAt: observedAt,
        );
      }
      final needsMap = Map<NeedKind, NeedReading>.from(state.needs);
      final sol = needsMap[NeedKind.solitude];
      if (sol != null) {
        needsMap[NeedKind.solitude] = sol.copyWith(
          pressure: sol.pressure + 0.015 * socialIntensity,
          observedAt: observedAt,
        );
      }
      state = state.copyWith(capacities: caps, needs: needsMap);
      if ((caps[CapacityKind.socialTolerance]?.level ?? 1) < 0.3) {
        state = conditions.upsert(
          state,
          conditions.create(
            kind: PawnConditionKind.sociallyDrained,
            intensity: 0.55,
            atSimSeconds: simSeconds,
            durationSeconds: 500,
          ),
        );
      }
    }

    final creative = state.need(NeedKind.creativeExpression)?.pressure ?? 0;
    final open = profileFor(pawnId).openness;
    if (creative > 0.7 && open > 0.55 && simSeconds.toInt() % 97 == 0) {
      state = conditions.upsert(
        state,
        conditions.create(
          kind: PawnConditionKind.inspired,
          intensity: 0.55,
          atSimSeconds: simSeconds,
          durationSeconds: 600,
        ),
      );
    }

    final activeMedia = media.activeByPawn[pawnId];
    if (activeMedia != null && !jobIsSleep) {
      media.advanceProgress(activeMedia, 0.002);
    }

    devices.tick(simSeconds);

    state = capacities.maybeTick(
      state: state,
      simSeconds: simSeconds,
      observedAt: observedAt,
    );

    store.put(state);
    return state;
  }

  /// Resolve and optionally apply contextual loadout (M31).
  HabitatLoadout resolveLoadout({
    required String pawnId,
    required bool jobIsSleep,
    required bool isOutdoor,
    bool inTransit = false,
    void Function(String apparelTop, String? hat)? applyVisual,
    bool force = false,
  }) {
    final suggested = loadouts.suggest(
      mapLocationId: activeMapLocationId,
      context: activeContext,
      jobIsSleep: jobIsSleep,
      isOutdoor: isOutdoor,
      scenePresetId: scenes.activePresetId,
      inTransit: inTransit,
    );
    if (applyVisual != null) {
      loadouts.maybeApply(
        pawnId: pawnId,
        loadout: suggested,
        applyVisual: applyVisual,
        force: force,
      );
    }
    return suggested;
  }

  void applyScenePreset(String presetId, {double nowSim = 0}) {
    scenes.apply(presetId, nowSim: nowSim);
  }

  /// Demo inventory path shelf → hand → table → bag (M32).
  void demoInventoryPath(String pawnId) {
    inventory.seedDemo();
    const book = 'book.dune';
    inventory.pickUp(itemId: book, pawnId: pawnId);
    inventory.placeOnTable(book);
    inventory.pickUp(itemId: book, pawnId: pawnId);
    inventory.putInBag(book);
  }

  SustainedActivity? startReadingDemo(String pawnId, {double nowSim = 0}) {
    inventory.seedDemo();
    inventory.pickUp(itemId: 'book.dune', pawnId: pawnId);
    return devices.startReading(
      pawnId: pawnId,
      bookItemId: 'book.dune',
      nowSim: nowSim,
    );
  }

  List<SustainedActivity> interruptActivities(
    String pawnId, {
    required double nowSim,
  }) =>
      devices.interruptFor(pawnId, nowSim: nowSim);

  bool resumeActivity(String activityId, {required double nowSim}) =>
      devices.resume(activityId, nowSim: nowSim);

  BehaviorRoutineRun? startRoutine(String definitionId, String pawnId) =>
      routines.start(definitionId: definitionId, pawnId: pawnId);

  /// Shared meal demo: cook → serve → satisfy food (M37).
  MealInstance demoSharedMeal({
    required String cookId,
    required List<String> guests,
    String recipeId = 'pasta_simple',
    double nowSim = 0,
  }) {
    final session = kitchen.startCook(
      recipeId: recipeId,
      cookPawnId: cookId,
      helpers: guests,
      nowSim: nowSim,
    );
    for (var i = 0; i < 6; i++) {
      kitchen.advanceCooking(session.id, step: 1);
    }
    final participants = [cookId, ...guests];
    final meal = kitchen.startMeal(
      recipeId: recipeId,
      participantIds: participants,
      nowSim: nowSim,
    );
    final updated = kitchen.finishMeal(
      meal.id,
      states: {
        for (final id in participants)
          if (store[id] != null) id: store[id]!,
      },
      observedAt: DateTime.now().toUtc(),
    );
    for (final st in updated) {
      store.put(st);
    }
    scenes.markAftermath('dinner');
    return meal;
  }

  /// Work on painting across sessions (M38).
  HabitatWorkpiece workOnPainting(String pawnId, {double delta = 0.22}) {
    final w = workpieces.ensurePainting(pawnId);
    workpieces.workOn(w.id, delta: delta);
    return w;
  }

  /// Collect prep items for context; returns check (M39).
  PrepCheckResult prepareForContext(String contextId, String pawnId) {
    preparation.seedPrepItems(inventory);
    return preparation.check(
      contextId: contextId,
      inventory: inventory,
      pawnId: pawnId,
      collect: true,
    );
  }

  /// São Paulo → Tokyo hop with jet lag (M40).
  String beginJetLagDemo(String pawnId, {double nowSim = 0}) {
    final hotelKind =
        HabitatWorldMap.kinds.firstWhere((k) => k.id == 'abstract.hotel');
    final hotelId = HabitatWorldMap.materialize(world, hotelKind);
    travel.beginTimezoneHop(
      pawnId: pawnId,
      originSiteId: 'home_apartment',
      destinationSiteId: hotelId,
      destinationTimezoneId: hotelKind.timezoneId,
      siteHourDelta: 12,
      nowSim: nowSim,
    );
    transit.ensureAtSite(pawnId, hotelId);
    return hotelId;
  }

  /// Navigate world map label → materialize + transit (M41).
  String? goWorldMap(String navLabel, String pawnId, {double nowSim = 0}) {
    final kind = HabitatWorldMap.kindByNavLabel(navLabel);
    if (kind == null) return null;
    final siteId = HabitatWorldMap.materialize(world, kind);
    transit.beginTransit(
      pawnId: pawnId,
      originSiteId: world.siteForMapLocation(activeMapLocationId)?.id ??
          'home_apartment',
      destinationSiteId: siteId,
      nowSim: nowSim,
      durationSeconds: 25,
    );
    return siteId;
  }

  MirrorReadyHabitatSnapshot buildSnapshot({
    int worldSeed = 0,
    Map<String, Object?> clockState = const {},
  }) {
    return MirrorReadyHabitatSnapshot(
      schemaVersion: MirrorReadyHabitatSnapshot.currentVersion,
      worldSeed: worldSeed,
      clockState: clockState,
      payload: {
        'sites': world.sites.keys.toList(),
        'rooms': world.rooms.keys.toList(),
        'items': inventory.items.keys.toList(),
        'workpieces': workpieces.pieces.keys.toList(),
        'customContent': customContent.saved.keys.toList(),
        'preset': scenes.activePresetId,
        'pawns': store.ids.toList(),
      },
    );
  }

  HabitatInvariantReport checkInvariants({Set<String> knownPawnIds = const {}}) {
    return invariants.check(
      world: world,
      inventory: inventory,
      store: store,
      knownPawnIds: knownPawnIds,
    );
  }

  /// M50 gate: core systems present and healthy.
  List<String> mirrorReadyGateIssues() {
    final issues = <String>[];
    if (scenes.presets.length < 4) issues.add('presets');
    if (HabitatLoadoutResolver.catalog.length < 5) issues.add('loadouts');
    if (routines.definitions.isEmpty) issues.add('routines');
    if (content.validate().isNotEmpty) issues.add('content');
    if (!inventory.locationsConsistent) issues.add('inventory');
    final inv = checkInvariants();
    if (!inv.ok) issues.addAll(inv.issues);
    return issues;
  }

  String? suggestAffordance(String pawnId, {double simSeconds = 0}) {
    ensureIdentity(pawnId);
    final state = store[pawnId];
    if (state == null) return null;
    if (calls.isOnCall && calls.active?.localPawnId == pawnId) {
      return HabitatAffordances.sit; // stay put while on call
    }
    final profile = profileFor(pawnId);
    final jazz = preferences.effectiveAffinity(pawnId, 'music/jazz');
    final ctx = activeContext;
    final candidates = <String>[
      if (ctx.allows('sleep')) HabitatAffordances.sleep,
      HabitatAffordances.sit,
      if (ctx.allows('cook') || ctx.allows('groupSocial'))
        HabitatAffordances.goToTable,
      HabitatAffordances.wander,
      HabitatAffordances.stretch,
      HabitatAffordances.recreate,
      if (ctx.allows('musicPractice') || ctx.allows('read'))
        HabitatAffordances.listenMusic,
      HabitatAffordances.creativeShort,
      HabitatAffordances.rest,
      HabitatAffordances.clean,
      if (ctx.allows('groupSocial')) HabitatAffordances.socialChat,
    ];
    final ranked = scorer.rank(
      state,
      candidates: candidates,
      noveltyBonus: (id) => novelty.novelty(pawnId, id, simSeconds),
      personalityOpenness: profile.openness,
      personalityExtraversion: profile.extraversion,
      jazzAffinity: jazz,
      topicBoostIds: simSeconds < _topicBoostUntil ? _topicBoostIds : const {},
    );
    if (ranked.isEmpty) return null;
    // Context soft-scale: focus / social / calls feel different rooms.
    final scaled = [
      for (final r in ranked)
        (
          id: r.id,
          score: r.score * _contextScale(r.id, ctx) +
              scenes.affordanceBoost(r.id),
        ),
    ]..sort((a, b) => b.score.compareTo(a.score));
    final best = scaled.first;
    if (best.score > 0.35) {
      novelty.markUsed(pawnId, best.id, simSeconds);
      if (best.id == HabitatAffordances.listenMusic ||
          best.id == HabitatAffordances.recreate) {
        media.pickForPawn(
          pawnId: pawnId,
          affinities: const {},
          prefs: preferences,
          preferKind: best.id == HabitatAffordances.listenMusic
              ? MediaKind.album
              : null,
        );
      }
      return best.id;
    }
    return HabitatAffordances.wander;
  }

  double _contextScale(String affordanceId, HabitatContextProfile ctx) {
    if (affordanceId == HabitatAffordances.creativeShort ||
        affordanceId == HabitatAffordances.sleep ||
        affordanceId == HabitatAffordances.rest) {
      return ctx.focusFit();
    }
    if (affordanceId == HabitatAffordances.socialChat ||
        affordanceId == HabitatAffordances.goToTable ||
        affordanceId == HabitatAffordances.recreate) {
      // Prefer shared/busy for group social; quiet rooms slightly damp.
      final density = switch (ctx.socialDensity) {
        SocialDensityProfile.crowded => 1.15,
        SocialDensityProfile.normal => 1.0,
        SocialDensityProfile.sparse => 0.9,
        SocialDensityProfile.empty => 0.75,
      };
      final privacy = switch (ctx.privacy) {
        PrivacyProfile.public || PrivacyProfile.shared => 1.1,
        PrivacyProfile.semiPrivate => 1.0,
        PrivacyProfile.private => 0.85,
      };
      return density * privacy;
    }
    if (affordanceId == HabitatAffordances.listenMusic) {
      return ctx.noise == NoiseProfile.loud ? 0.7 : 1.05;
    }
    return 1;
  }

  ConversationTopic? pickSocialTopic({
    required String aId,
    required String bId,
    double simSeconds = 0,
  }) {
    ensureIdentity(aId);
    ensureIdentity(bId);
    final mediaA = media.activeByPawn[aId] != null
        ? media.byId(media.activeByPawn[aId]!)
        : null;
    final mediaB = media.activeByPawn[bId] != null
        ? media.byId(media.activeByPawn[bId]!)
        : null;
    final topic = topics.pick(
      prefsA: preferences,
      prefsB: preferences,
      pawnA: aId,
      pawnB: bId,
      nearbyMedia: mediaA ?? mediaB,
      now: simSeconds,
    );
    lastSocialTopic = topic;
    if (topic != null) {
      lastTopicPhrase = topics.phraseFor(topic, (simSeconds * 10).toInt());
      _topicBoostUntil = simSeconds + 90;
      _topicBoostIds = {
        for (final s in topic.activitySuggestions)
          if (HabitatAffordances.all.contains(s)) s,
      };
    }
    return topic;
  }

  double _topicBoostUntil = -1;
  Set<String> _topicBoostIds = {};

  ConditionPresentation presentationFor(String pawnId) {
    final state = store[pawnId];
    if (state == null) return const ConditionPresentation();
    return ConditionEngine.combinedPresentation(state.conditions);
  }
}
