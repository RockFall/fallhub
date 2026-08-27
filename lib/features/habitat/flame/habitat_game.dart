import 'dart:math' as math;

import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';

import '../application/colony_roster.dart';
import '../simulation/embodied/embodied.dart';
import '../simulation/identity/identity.dart';
import '../simulation/identity/pawn_identity.dart';
import '../simulation/microbehavior/microbehavior.dart';
import '../simulation/mirror/mirror.dart';
import '../simulation/presence/habitat_appointment.dart';
import '../simulation/presence/planned_activity.dart';
import '../simulation/presence/remote_call.dart';
import '../simulation/time/time.dart';
import '../simulation/world/habitat_commands.dart';
import '../simulation/world/perceived_comfort.dart';
import '../simulation/world/room_detector.dart';
import '../simulation/content/habitat_custom_content.dart';
import '../simulation/content/habitat_devices.dart';
import '../simulation/content/habitat_inventory.dart';
import '../simulation/presence/habitat_transit.dart';
import '../simulation/world/scene_preset.dart';
import '../../../app/localization/app_strings.dart';
import 'components/beauty_overlay_component.dart';
import 'components/day_night_overlay.dart';
import 'components/grid_map_component.dart';
import 'components/living_pawn_component.dart';
import 'components/order_path_overlay.dart';
import 'components/pawn_job_controller.dart';
import 'components/sweep_clean_overlay_component.dart';
import 'components/zone_overlay_component.dart';
import 'habitat_asset_loader.dart';
import 'habitat_bubbles.dart';
import 'habitat_editor.dart';
import 'habitat_light.dart';
import 'habitat_climate.dart';
import 'habitat_locations.dart';
import 'habitat_map.dart';
import 'habitat_presence.dart';
import 'habitat_prop_catalog.dart';
import 'furniture/furniture.dart';
import 'habitat_room_stats.dart';
import 'habitat_social.dart';
import 'habitat_sprites.dart';
import 'habitat_tint.dart';
import 'habitat_zones.dart';
import 'pathfinding.dart';

/// Selection payload for Flutter inspect (V4).
sealed class HabitatSelection {
  const HabitatSelection();
}

class HabitatPawnSelection extends HabitatSelection {
  const HabitatPawnSelection(this.pawn);
  final LivingPawnComponent pawn;
}

class HabitatPropSelection extends HabitatSelection {
  const HabitatPropSelection(this.prop);
  final HabitatProp prop;
}

class HabitatCellSelection extends HabitatSelection {
  const HabitatCellSelection(this.cell);
  final (int, int) cell;
}

typedef HabitatSelectionChanged = void Function(HabitatSelection? selection);
typedef HabitatContextMenuRequest = void Function({
  required HabitatSelection? selection,
  required (int, int) cell,
  required Offset canvasPosition,
});
typedef HabitatSceneReady = void Function();
typedef HabitatMapsChanged = void Function();

/// Flame root for Living Habitat (Visual++ V4–V9.5).
class HabitatGame extends FlameGame
    with
        TapCallbacks,
        SecondaryTapCallbacks,
        LongPressCallbacks,
        ScrollCallbacks {
  HabitatGame({
    HabitatMap? map,
    String? locationId,
    this.tileSize = 48,
    this.onSelectionChanged,
    this.onContextMenu,
    this.onSceneReady,
    this.onMapsChanged,
    PawnAppearance? appearance,
    List<ColonyMember>? roster,
  })  : locationId = locationId ?? HabitatLocationIds.bedroom,
        map = map ??
            HabitatLocations.create(locationId ?? HabitatLocationIds.bedroom),
        initialAppearance = appearance ?? PawnAppearance(),
        initialRoster = roster ??
            ColonyRosterStore.seedDefaults(playerLook: appearance) {
    _maps[this.locationId] = this.map;
    editor = HabitatEditor(this.map);
    commands = HabitatCommandStack(editor);
    social = HabitatSocialDirector(rng: _rng);
  }

  HabitatMap map;
  String locationId;
  final Map<String, HabitatMap> _maps = {};
  final double tileSize;
  final HabitatSelectionChanged? onSelectionChanged;
  final HabitatContextMenuRequest? onContextMenu;
  final HabitatSceneReady? onSceneReady;
  final HabitatMapsChanged? onMapsChanged;
  final PawnAppearance initialAppearance;
  final List<ColonyMember> initialRoster;
  final math.Random _rng = math.Random();
  late final HabitatEditor editor;
  late final HabitatCommandStack commands;

  GridMapComponent? grid;

  /// All living pawns on the current map.
  final List<LivingPawnComponent> pawns = [];

  /// Focused / “priority” pawn (jobs from UI, follow-cam, inspect default).
  LivingPawnComponent? focusedPawn;

  /// Back-compat alias used across the Habitat UI.
  LivingPawnComponent? get pawn => focusedPawn;

  HabitatSprites? sprites;
  BubbleLayerComponent? bubbleLayer;
  BeautyOverlayComponent? beautyOverlay;
  ZoneOverlayComponent? zoneOverlay;
  SweepCleanOverlayComponent? sweepClean;
  VoidCallback? onSweepCleanFinished;
  bool beautyOverlayOn = false;
  bool sceneReady = false;
  Object? loadError;
  HabitatSelection? selection;
  (int, int)? hoverCell;
  bool followFocused = false;

  final HabitatPresence presence = HabitatPresence();
  final HabitatClockBundle clocks = HabitatClockBundle();
  final HabitatEpisodeLedger episodes = HabitatEpisodeLedger();
  final PawnEmbodiedStore embodied = PawnEmbodiedStore();
  late final EmbodiedRuntime embodiedRuntime = EmbodiedRuntime(
    store: embodied,
    episodes: episodes,
  );

  /// When true, shows clock debug strip (M2).
  bool showClockDebug = false;

  double _conditionMoteTimer = 0;
  final List<HabitatBubble> bubbles = [];
  double _idleBubbleTimer = 0;

  /// Cosmetic room role + meters (V9.7).
  HabitatRoomStats roomStats = HabitatRoomStats.empty;

  /// One-shot cue for Space meter flash when the room is tight.
  bool spaceTightPulse = false;
  int _roomStatsGen = 0;

  /// Per-cell darkness + temperature (V9.11 / V9.12).
  List<double> darknessField = const [];

  /// Extra ambient darkness from ScenePreset (M30 visual).
  double sceneAmbientBias = 0;

  /// When false, lamps do not punch darkness (preset sleep/cinema).
  bool lampsEnabled = true;

  /// TV screen glow when scene/device says on.
  bool tvScreenOn = false;
  List<double> climateField = const [];
  double? outdoorTemperatureC;

  /// Indoor average °C as a mirror signal (MD 08 M0) — always `simulated`.
  MirrorSignal<double>? indoorTemperatureSignal;

  /// Optional debug/manual override for indoor temperature (M1).
  HabitatStateOverride<double>? indoorTemperatureOverride;

  /// Last resolution of indoor temperature (M1).
  EffectiveValue<double>? indoorTemperatureEffective;

  final EffectiveStateResolver<double> _indoorTempResolver =
      EffectiveStateResolver<double>();

  /// Session clock for joy cooldowns (V9.10).
  double sessionTime = 0;
  final Map<String, double> recreateCooldownUntil = {};

  /// Per-pawn allowed cells — null/absent = unrestricted (V9.13).
  Map<String, Set<(int, int)>?> allowedZones = {};

  /// Red flash on rejected order: (x, y, age 0→1).
  (int, int, double)? zoneRejectFlash;

  late final HabitatSocialDirector social;

  /// Block B shared navigation boards.
  final PropOccupancyBoard occupancy = PropOccupancyBoard();
  final DoorReservationBoard doorReservations = DoorReservationBoard();
  final StationQueueBoard stationQueues = StationQueueBoard();

  /// Block C object logic state (not sprite-owned).
  final ObjectStateBoard objectState = ObjectStateBoard();
  final Map<String, int> itemUsageByPawn = {};

  /// Blocks D–K refinement boards.
  final Map<String, double> lastGreetingAt = {};
  final Map<String, double> lastAckAt = {};
  final Map<String, double> lastCallbackAt = {};
  final Map<String, double> lastBackchannelAt = {};
  ConversationGroup? activeConversationGroup;
  SharedSilenceSession? sharedSilence;
  final QuietnessController quietness = QuietnessController();
  final ForeshadowingBoard foreshadow = ForeshadowingBoard();
  final CausalityChainDebug causality = CausalityChainDebug();
  final AntiLoopDetector antiLoop = AntiLoopDetector();
  final CooldownFamily bubbleCooldown = CooldownFamily(
    id: 'bubble',
    baseSeconds: 8,
  );
  final CameraFocusController cameraFocus = CameraFocusController();
  final ObserverCinematicController observer = ObserverCinematicController();
  final BubblePacingState bubblePacing = BubblePacingState();
  final RecentlyUsedCatalog editorRecentlyUsed = RecentlyUsedCatalog();
  final EditorHistoryPane editorHistory = EditorHistoryPane();
  final EditorClipboard editorClipboard = EditorClipboard();
  DebugHudPreset debugHudPreset = DebugHudPreset.minimal;
  PetEnergyPacing? petEnergy;
  EventFocusHint? eventFocusHint;

  double _headShakeT = 0;
  String? _socialPauseA;
  String? _socialPauseB;
  SocialEncounterPhase? _lastSocialPhase;

  /// Seconds standing in true darkness before a thought may fire.
  final Map<LivingPawnComponent, double> _darkIdleTimer = {};
  /// Earliest [sessionTime] each pawn may complain about darkness again.
  final Map<LivingPawnComponent, double> _darkCommentReadyAt = {};
  String? _lastIdleThought;

  /// User-adjusted camera (scroll / pinch zoom / pan) — skip auto-fit until reset.
  bool userCamera = false;
  Vector2? _panAnchorWorld;
  Vector2? _panAnchorCanvas;

  /// Ignore the tap that follows a long-press (gesture delivers both).
  bool _ignoreNextTapUp = false;

  @override
  Color backgroundColor() => const Color(0xFF15191D);

  @override
  Future<void> onLoad() async {
    images.prefix = '';
    try {
      presence.attachSceneClock(clocks.scene);
      await loadHabitatAssets(images, map);
      sprites = HabitatSprites.fromCache(images, map);

      final gridComp = GridMapComponent(
        map: map,
        tileSize: tileSize,
        sprites: sprites!,
      );
      final bubblesComp = BubbleLayerComponent(bubbles: bubbles)
        ..priority = 40;
      final dayNight = DayNightOverlayComponent();
      final beauty = BeautyOverlayComponent();
      final orderPath = OrderPathOverlayComponent();
      final zone = ZoneOverlayComponent();
      final sweep = SweepCleanOverlayComponent();

      // Do not await world.add here: awaiting children during FlameGame.onLoad
      // deadlocks GameWidget (loaderFuture never completes → black loading).
      world.add(gridComp);
      grid = gridComp;
      bubbleLayer = bubblesComp;
      beautyOverlay = beauty;
      zoneOverlay = zone;
      sweepClean = sweep;
      world.add(dayNight);
      world.add(beauty);
      world.add(zone);
      world.add(orderPath);
      world.add(sweep);
      world.add(bubblesComp);

      _spawnRoster(initialRoster);
      focusedPawn = pawns.isEmpty ? null : pawns.first;
      focusedPawn?.selected = true;

      refreshRoomStats();
      _refreshAtmosphere();
      sceneReady = true;
      onSceneReady?.call();
    } catch (e, st) {
      loadError = e;
      // ignore: avoid_print
      print('HabitatGame.onLoad failed: $e\n$st');
      rethrow;
    }
  }

  void pushBubble(
    LivingPawnComponent target,
    String text, {
    HabitatBubbleKind kind = HabitatBubbleKind.speech,
    String? stackGroupId,
  }) {
    // R109 bubble pacing + R116 habituation cooldown.
    if (kind == HabitatBubbleKind.speech) {
      if (!bubblePacing.maySpeak(sessionTime)) return;
      if (!bubbleCooldown.ready(target.memberId, sessionTime)) return;
      bubblePacing.markSpoken(sessionTime);
      bubbleCooldown.mark(target.memberId, sessionTime);
    }
    // R118 anti-loop on repeated identical speech.
    if (antiLoop.observe(target.memberId, 'bubble:$text')) {
      return;
    }
    // Habbo-style stack: newest at the chin, older rows rise and fade.
    // Active social encounter → both speakers share one column.
    var group = stackGroupId;
    final enc = social.active;
    if (group == null &&
        enc != null &&
        (target.memberId == enc.aId || target.memberId == enc.bId)) {
      group = socialBubbleStackId(enc.aId, enc.bId);
    }
    pushStackedBubble(
      bubbles,
      target,
      text,
      kind: kind,
      stackGroupId: group,
    );
  }

  void _fitCamera({bool force = false}) {
    if (!hasLayout) return;
    if (userCamera && !force) return;
    camera.viewfinder.anchor = Anchor.topLeft;
    final mapW = map.width * tileSize;
    final mapH = map.height * tileSize;
    final size = canvasSize;
    if (mapW <= 0 || mapH <= 0 || size.x <= 0 || size.y <= 0) return;
    final zoom = (size.x / mapW).clamp(0.35, 2.5);
    final zoomY = (size.y / mapH).clamp(0.35, 2.5);
    final z = (zoom < zoomY ? zoom : zoomY) * 0.92;
    camera.viewfinder.zoom = z;
    _centerCameraOnMap();
    userCamera = false;
  }

  void resetCamera() => _fitCamera(force: true);

  /// World-space top-left that centers the map in the viewport.
  void _centerCameraOnMap() {
    final mapW = map.width * tileSize;
    final mapH = map.height * tileSize;
    final z = camera.viewfinder.zoom;
    final viewW = canvasSize.x / z;
    final viewH = canvasSize.y / z;
    camera.viewfinder.position = Vector2(
      (mapW - viewW) / 2,
      (mapH - viewH) / 2,
    );
  }

  /// True when the map is larger than the viewport on at least one axis.
  bool get canPanCamera {
    if (!hasLayout) return false;
    final mapW = map.width * tileSize;
    final mapH = map.height * tileSize;
    final z = camera.viewfinder.zoom;
    final viewW = canvasSize.x / z;
    final viewH = canvasSize.y / z;
    return viewW < mapW - 0.5 || viewH < mapH - 0.5;
  }

  void zoomBy(double delta, {Offset? focusCanvas}) {
    zoomTo(camera.viewfinder.zoom * (1 + delta), focusCanvas: focusCanvas);
  }

  /// Zoom toward [focusCanvas] (viewport center by default), then clamp.
  void zoomTo(double zoom, {Offset? focusCanvas}) {
    if (!hasLayout) return;
    userCamera = true;
    followFocused = false;
    final oldZ = camera.viewfinder.zoom;
    final next = zoom.clamp(0.35, 3.2);
    if ((next - oldZ).abs() < 1e-6) return;

    final focus = focusCanvas == null
        ? Vector2(canvasSize.x / 2, canvasSize.y / 2)
        : Vector2(focusCanvas.dx, focusCanvas.dy);
    final worldBefore = camera.globalToLocal(focus);
    camera.viewfinder.zoom = next;
    final worldAfter = camera.globalToLocal(focus);
    camera.viewfinder.position += worldBefore - worldAfter;
    _clampCamera();
  }

  void panByScreen(Offset delta) {
    if (!hasLayout) return;
    userCamera = true;
    followFocused = false;
    final z = camera.viewfinder.zoom;
    camera.viewfinder.position -= Vector2(delta.dx / z, delta.dy / z);
    _clampCamera();
  }

  void _clampCamera() {
    final mapW = map.width * tileSize;
    final mapH = map.height * tileSize;
    final z = camera.viewfinder.zoom;
    final viewW = canvasSize.x / z;
    final viewH = canvasSize.y / z;
    final pos = camera.viewfinder.position;

    // Viewport larger than map → lock to center (negative top-left offset).
    final x = viewW >= mapW
        ? (mapW - viewW) / 2
        : pos.x.clamp(0.0, mapW - viewW);
    final y = viewH >= mapH
        ? (mapH - viewH) / 2
        : pos.y.clamp(0.0, mapH - viewH);
    camera.viewfinder.position = Vector2(x, y);
  }

  /// Swallow the play-mode tap that follows a drag-pan.
  void suppressNextPlayTap() {
    _ignoreNextTapUp = true;
  }

  void beginPan(Offset canvasPos) {
    _panAnchorCanvas = Vector2(canvasPos.dx, canvasPos.dy);
    _panAnchorWorld = camera.viewfinder.position.clone();
  }

  void updatePan(Offset canvasPos) {
    final start = _panAnchorCanvas;
    final origin = _panAnchorWorld;
    if (start == null || origin == null || !hasLayout) return;
    userCamera = true;
    followFocused = false;
    final z = camera.viewfinder.zoom;
    camera.viewfinder.position = origin -
        Vector2(
          (canvasPos.dx - start.x) / z,
          (canvasPos.dy - start.y) / z,
        );
    _clampCamera();
  }

  void endPan() {
    _panAnchorCanvas = null;
    _panAnchorWorld = null;
  }

  void renderWorldTo(Canvas canvas) {
    final g = grid;
    if (g == null) return;
    g.render(canvas);
    for (final p in pawns) {
      canvas.save();
      canvas.translate(
        p.position.x - p.size.x / 2,
        p.position.y - p.size.y / 2,
      );
      p.render(canvas);
      canvas.restore();
    }
    beautyOverlay?.render(canvas);
    _drawDayNightOverlay(canvas);
    bubbleLayer?.render(canvas);
  }

  void _drawDayNightOverlay(Canvas canvas) {
    HabitatLightField.paintSoftDarkness(
      canvas,
      map: map,
      tileSize: tileSize,
      phase: presence.phase,
      locationId: locationId,
      ambientBias: sceneAmbientBias,
      lampsEnabled: lampsEnabled,
    );
    if (tvScreenOn) {
      _paintTvGlow(canvas);
    }
  }

  void _paintTvGlow(Canvas canvas) {
    for (final p in map.props) {
      if (p.kind != HabitatPropKinds.tv) continue;
      final (ox, oy) = p.origin;
      final cx = (ox + 0.5) * tileSize;
      final cy = (oy + 0.35) * tileSize;
      final r = tileSize * 2.2;
      final shader = RadialGradient(
        colors: const [
          Color(0xAA4FC3F7),
          Color(0x554FC3F7),
          Color(0x004FC3F7),
        ],
      ).createShader(Rect.fromCircle(center: Offset(cx, cy), radius: r));
      canvas.drawCircle(
        Offset(cx, cy),
        r,
        Paint()
          ..shader = shader
          ..blendMode = BlendMode.plus,
      );
    }
  }

  void _tickDoor(double dt) {
    final door = map.door;
    // Occupants and adjacent pawns keep the door held open (RimWorld-ish).
    for (final p in pawns) {
      final dist = (p.cellX - door.cell.$1).abs() + (p.cellY - door.cell.$2).abs();
      if (dist == 0) {
        door.requestOpen();
      } else if (dist == 1) {
        // Approaching: next queued step is the door, or path goes through it.
        if (p.jobs.willTraverseDoor(door.cell)) {
          door.requestOpen();
        }
      }
    }
    door.tick(dt);
  }

  void _refreshAtmosphere() {
    darknessField = HabitatLightField.compute(
      map,
      phase: presence.phase,
      locationId: locationId,
      ambientBias: sceneAmbientBias,
      lampsEnabled: lampsEnabled,
    );
    climateField = HabitatClimateField.compute(
      map,
      locationId: locationId,
      phase: presence.phase,
      outdoorC: outdoorTemperatureC,
    );
    _publishIndoorTemperatureSignal();
  }

  void _publishIndoorTemperatureSignal() {
    final c = HabitatClimateField.indoorAverage(
      map,
      climateField,
      locationId: locationId,
    );
    final now = clocks.real.now().toUtc();
    final outdoor = outdoorTemperatureC;
    // Honest provenance: outdoor from live weather → derived indoor.
    final MirrorSignalSource source;
    final List<String> chain;
    final double confidence;
    if (outdoor != null) {
      source = MirrorSignalSource.systemDerived;
      chain = const [
        'outdoor_temperature',
        'climate_field',
        'indoor_average',
      ];
      confidence = 0.85;
    } else {
      source = MirrorSignalSource.simulated;
      chain = const ['climate_field_simulated'];
      confidence = 1;
    }
    indoorTemperatureSignal = MirrorSignal<double>(
      id: HabitatMirrorIds.indoorTemperatureC,
      value: c,
      source: source,
      observedAt: now,
      confidence: confidence,
      transformationChain: chain,
      sourceRef: outdoor != null ? 'outdoor:$outdoor' : null,
    );
    _resolveIndoorTemperature(now: now);
  }

  void _resolveIndoorTemperature({DateTime? now}) {
    final at = now ?? clocks.real.now().toUtc();
    final signal = indoorTemperatureSignal;
    if (signal == null) {
      indoorTemperatureEffective = null;
      return;
    }
    indoorTemperatureEffective = _indoorTempResolver.resolve(
      signals: [signal],
      override: indoorTemperatureOverride,
      now: at,
      fallback: signal.value,
    );
  }

  /// Apply a temporary manual indoor temperature override (debug / M1 demo).
  void setIndoorTemperatureOverride(
    double celsius, {
    required String reason,
    Duration ttl = const Duration(minutes: 5),
  }) {
    final now = clocks.real.now().toUtc();
    indoorTemperatureOverride = HabitatStateOverride<double>(
      dimensionId: HabitatMirrorIds.indoorTemperatureC,
      value: celsius,
      startedAt: now,
      expiresAt: now.add(ttl),
      reason: reason,
    );
    _resolveIndoorTemperature(now: now);
  }

  void clearIndoorTemperatureOverride() {
    indoorTemperatureOverride = null;
    _resolveIndoorTemperature();
  }

  void setOutdoorTemperature(double? c) {
    outdoorTemperatureC = c;
    _refreshAtmosphere();
  }

  double get indoorTemperatureC =>
      indoorTemperatureEffective?.value ??
      indoorTemperatureSignal?.value ??
      HabitatClimateField.indoorAverage(
        map,
        climateField.isEmpty
            ? HabitatClimateField.compute(
                map,
                locationId: locationId,
                phase: presence.phase,
                outdoorC: outdoorTemperatureC,
              )
            : climateField,
        locationId: locationId,
      );

  /// Debug provenance / resolution line for indoor temperature (M0–M1).
  String? get indoorTemperatureDebugLine {
    final eff = indoorTemperatureEffective;
    if (eff != null) {
      final conflict = eff.hasConflict ? ' conflict' : '';
      return '${MirrorProvenance.debugLine(eff.winningSignal)} | '
          '${eff.explanation}$conflict';
    }
    final s = indoorTemperatureSignal;
    if (s == null) return null;
    return MirrorProvenance.debugLine(s);
  }

  /// Debug: simulation/scene speed (1 / 5 / 30).
  void setDebugSimSpeed(double speed) {
    clocks.setDebugSpeed(speed);
    showClockDebug = true;
  }

  void debugSkipOneHour() {
    clocks.skipOneHour();
    presence.syncFromClock();
    _refreshAtmosphere();
    showClockDebug = true;
  }

  void debugSetSceneHour(double hour) {
    clocks.scene.setSceneHour(hour);
    presence.syncFromClock();
    _refreshAtmosphere();
    showClockDebug = true;
  }

  String get clockDebugLine => clocks.debugSummary();

  void _tickEmbodiedSystems(double dt) {
    final sim = clocks.simulation.elapsedSeconds;
    final hour = presence.phase * 24;
    final now = clocks.real.now().toUtc();
    final comfortStress = HabitatClimateField.comfortDelta(indoorTemperatureC)
        .abs()
        .clamp(0.0, 8.0) /
        8.0;

    for (final p in pawns) {
      final jobSleep = p.jobs.kind == HabitatJobKind.sleep;
      final sedentary = p.jobs.kind == HabitatJobKind.sit ||
          p.jobs.kind == HabitatJobKind.goToTable ||
          p.jobs.kind == HabitatJobKind.recreate;
      final state = embodiedRuntime.tickPawn(
        pawnId: p.memberId,
        simSeconds: sim,
        sceneHour: hour,
        observedAt: now,
        isMoving: p.isMoving,
        isSedentary: sedentary && !p.isMoving,
        jobIsSleep: jobSleep,
        comfortStress: comfortStress,
        socialIntensity: social.active != null ? 0.35 : 0,
        activityPhysicalLoad: p.jobs.kind == HabitatJobKind.clean ? 0.25 : 0,
        darkness: darknessField.isEmpty
            ? 0.3
            : darknessField[
                (p.cellY * map.width + p.cellX).clamp(0, darknessField.length - 1)],
      );

      final loc =
          embodiedRuntime.transit.locationState[p.memberId];
      embodiedRuntime.resolveLoadout(
        pawnId: p.memberId,
        jobIsSleep: jobSleep ||
            state.sleepPhase == SleepPhase.sleeping ||
            state.sleepPhase == SleepPhase.nap,
        isOutdoor: HabitatLocations.isOutdoor(locationId),
        inTransit: loc == PawnPresenceLocation.inTransit ||
            loc == PawnPresenceLocation.away,
        applyVisual: (top, hat) {
          p.appearance.apparelTop = top;
          p.appearance.hat = hat;
          p.appearance.loadoutId =
              embodiedRuntime.loadouts.currentByPawn[p.memberId] ??
                  p.appearance.loadoutId;
        },
      );

      embodiedRuntime.travel.tickAdaptation(p.memberId, dtSim: dt);

      // R5 + M7: locomotor style from embodied + job context.
      final presentation =
          ConditionEngine.combinedPresentation(state.conditions);
      final urgency = p.drafted && p.jobs.kind == HabitatJobKind.goTo
          ? 0.85
          : (state.need(NeedKind.sleep)?.pressure ?? 0) > 0.75
              ? 0.35
              : 0.0;
      final relaxed = state.conditions.any((c) => c.kind == PawnConditionKind.relaxed)
          ? 0.45
          : 0.0;
      p.micro.profile ??= BehaviorProfile.fromSeed(p.memberId);
      p.micro.updateLocomotor(
        LocomotorStyleInput(
          fatigue: state.movement.physicalFatigue,
          sleepiness: state.circadian.sleepPressure,
          urgency: urgency,
          relaxed: relaxed,
          carryingItem: p.heldLabel != null && p.heldLabel!.isNotEmpty,
          socialApproach: social.active != null &&
              (social.active!.aId == p.memberId ||
                  social.active!.bId == p.memberId) &&
              social.active!.phase == SocialEncounterPhase.approach,
          conditionWalkMultiplier: presentation.walkSpeedMultiplier,
        ),
      );
      p.jobs.wanderSpeedScale =
          p.micro.locomotor.speedMultiplier * p.micro.locomotor.cadenceMultiplier;

      p.micro.profile ??= BehaviorProfile.fromSeed(p.memberId);

      // R9: per-pawn need reevaluation (no global metronome).
      if (p.micro.desync.consumeNeedReeval(
        sim,
        period: 4.5,
      )) {
        _runEmbodiedAutonomyFor(p);
      }
    }

    _conditionMoteTimer += dt;
    if (_conditionMoteTimer >= 8) {
      _conditionMoteTimer = 0;
      _maybeConditionBubble();
    }

    _tickPresenceAndAppointments();
    _tickAmbientReactions(sim);
  }

  void _runEmbodiedAutonomyFor(LivingPawnComponent p) {
    if (p.drafted) return;
    if (p.jobs.kind != HabitatJobKind.wander) return;
    final suggestion = embodiedRuntime.suggestAffordance(
      p.memberId,
      simSeconds: clocks.simulation.elapsedSeconds,
    );
    if (suggestion == null) return;
    final job = switch (suggestion) {
      HabitatAffordances.sleep => HabitatJobKind.sleep,
      HabitatAffordances.sit || HabitatAffordances.rest => HabitatJobKind.sit,
      HabitatAffordances.goToTable => HabitatJobKind.goToTable,
      HabitatAffordances.recreate ||
      HabitatAffordances.listenMusic ||
      HabitatAffordances.watchTv ||
      HabitatAffordances.creativeShort =>
        HabitatJobKind.recreate,
      HabitatAffordances.clean => HabitatJobKind.clean,
      HabitatAffordances.stretch ||
      HabitatAffordances.terraceWalk ||
      HabitatAffordances.wander =>
        HabitatJobKind.wander,
      _ => null,
    };
    if (job == null || job == HabitatJobKind.wander) return;
    final state = embodied[p.memberId];
    if (state == null) return;
    final score = embodiedRuntime.scorer.score(
      affordanceId: suggestion,
      state: state,
    );
    if (score < 0.55) return;
    p.jobs.order(job);
    if (suggestion == HabitatAffordances.sleep &&
        state.circadian.sleepPressure > 0.6) {
      pushBubble(p, 'Hora de deitar…', kind: HabitatBubbleKind.thought);
    }
  }

  String? _lastAmbientKey; // reserved for weather foreshadow hooks

  /// R2 + R9: staggered ambient reactions (e.g. darkness / comfort).
  void _tickAmbientReactions(double sim) {
    for (final p in pawns) {
      for (final r in p.micro.reactions.drainReady(sim)) {
        if (r.eventClass != ReactionEventClass.ambientEvent) continue;
        final text = r.payload as String?;
        if (text != null) {
          pushBubble(p, text, kind: HabitatBubbleKind.thought);
          final door = map.door.cell;
          p.micro.attention.lookAt(
            reason: AttentionReason.interestingEvent,
            now: sim,
            cellX: door.$1,
            cellY: door.$2,
            holdOverride: 0.9,
          );
        }
      }
    }

    for (final pawn in pawns) {
      if (pawn.drafted ||
          pawn.isMoving ||
          pawn.jobs.kind != HabitatJobKind.wander) {
        continue;
      }
      if (!pawn.micro.desync.consumeAmbientProbe(sim, period: 5)) continue;
      final d = HabitatLightField.at(
        darknessField,
        map,
        pawn.cellX,
        pawn.cellY,
      );
      if (d < HabitatLightField.tooDarkThreshold) continue;
      final readyAt = _darkCommentReadyAt[pawn] ?? 0;
      if (sessionTime < readyAt) continue;
      final delay = pawn.micro.reactionDelay(
        ReactionLatencyContext(
          eventClass: ReactionEventClass.ambientEvent,
          pawnId: pawn.memberId,
          salience: (d - HabitatLightField.tooDarkThreshold).clamp(0.0, 1.0),
          busyCommitment: 0,
          hasAttentionFocus: pawn.micro.attention.current != null,
          profile: pawn.micro.profile,
          salt: sim.floor(),
        ),
      );
      pawn.micro.reactions.schedule(
        PendingReaction(
          id: 'ambient.dark',
          eventClass: ReactionEventClass.ambientEvent,
          firesAt: sim + delay,
          payload: HabitatBubbleLines.forTooDark(_rng),
        ),
      );
      _darkCommentReadyAt[pawn] =
          sessionTime + 14 + pawn.micro.offsets.ambientReactionProbe;
    }
    // Touch reserved key so analyzer keeps the foreshadow hook visible.
    _lastAmbientKey ??= darknessField.isEmpty ? null : 'dark';
  }

  void _tickPresenceAndAppointments() {
    embodiedRuntime.activeMapLocationId = locationId;
    final sim = clocks.simulation.elapsedSeconds;
    embodiedRuntime.calls.tick(sim);

    final transitEvents = embodiedRuntime.transit.tick(sim);
    for (final ev in transitEvents) {
      if (ev.kind == 'left') {
        final p = pawnByMemberId(ev.pawnId);
        if (p != null) {
          pushBubble(p, 'Saindo…', kind: HabitatBubbleKind.thought);
          // Soft despawn while in transit / away from this site.
          if (p.parent != null) p.removeFromParent();
        }
      } else if (ev.kind == 'arrived') {
        final p = pawnByMemberId(ev.pawnId);
        if (p != null) {
          if (p.parent == null) world.add(p);
          final spawn = HabitatLocations.spawn(locationId);
          p.teleportToCell(spawn);
          pushBubble(p, 'Cheguei.', kind: HabitatBubbleKind.speech);
        }
      } else if (ev.kind == 'away') {
        final p = pawnByMemberId(ev.pawnId);
        if (p != null && p.parent != null) p.removeFromParent();
        final host = focusedPawn ?? (pawns.isEmpty ? null : pawns.first);
        // Home may stay empty while primary is away.
        if (host != null && host.memberId != ev.pawnId) {
          pushBubble(
            host,
            'Casa mais quieta…',
            kind: HabitatBubbleKind.thought,
          );
        }
      }
    }

    final events = embodiedRuntime.visitors.tick(
      simSeconds: sim,
      siteId: locationId,
    );
    for (final id in events.spawnAtEntrance) {
      _spawnVisitorPawn(id);
      final host = focusedPawn ?? (pawns.isEmpty ? null : pawns.first);
      if (host != null) {
        pushBubble(host, 'Alguém chegou!', kind: HabitatBubbleKind.thought);
      }
      final visitor = pawnByMemberId(id);
      if (visitor != null && events.greetOpportunity.contains(id)) {
        pushBubble(visitor, 'Oi!', kind: HabitatBubbleKind.speech);
      }
    }
    for (final id in events.farewellOpportunity) {
      final visitor = pawnByMemberId(id);
      final goodbye = GoodbyeGrammar.decide(
        trigger: GoodbyeTrigger.visitorLeaving,
        interrupted: visitor?.drafted == true,
      );
      if (goodbye.line == null) continue;
      if (visitor != null) {
        final host = focusedPawn;
        if (goodbye.facePartner && host != null) {
          visitor.facing = facingFromDelta(
            host.cellX - visitor.cellX,
            host.cellY - visitor.cellY,
          );
        }
        pushBubble(visitor, goodbye.line!, kind: HabitatBubbleKind.speech);
      } else {
        final host = focusedPawn ?? (pawns.isEmpty ? null : pawns.first);
        if (host != null) {
          pushBubble(
            host,
            goodbye.line!,
            kind: HabitatBubbleKind.speech,
          );
        }
      }
    }
    for (final id in events.despawn) {
      _despawnVisitorPawn(id);
    }

    final intents = embodiedRuntime.appointments.tick(sim);
    for (final intent in intents) {
      switch (intent.kind) {
        case AppointmentIntentKind.prepare:
          for (final id in intent.participantIds) {
            final p = pawnByMemberId(id);
            if (p != null && !p.drafted) {
              pushBubble(
                p,
                'Preparar para o encontro…',
                kind: HabitatBubbleKind.thought,
              );
            }
          }
        case AppointmentIntentKind.start:
          HabitatAppointment? appt;
          for (final a in embodiedRuntime.appointments.appointments) {
            if (a.appointment.id == intent.appointmentId) {
              appt = a.appointment;
              break;
            }
          }
          if (appt != null) {
            final planned = embodiedRuntime.planned.attach(
              appt,
              isAvailable: (aff) => HabitatAffordances.all.contains(aff),
            );
            embodiedRuntime.planned.advancePhase(
              appt.id,
              PlannedActivityPhase.primary,
            );
            for (final id in intent.participantIds) {
              final p = pawnByMemberId(id);
              if (p == null || p.drafted) continue;
              final job = _jobForAffordance(
                planned.resolvedAffordance ?? intent.activityKind ?? 'sit',
              );
              if (job != null) p.jobs.order(job);
            }
          } else {
            for (final id in intent.participantIds) {
              final p = pawnByMemberId(id);
              if (p == null || p.drafted) continue;
              if (intent.activityKind == 'dinner' ||
                  intent.activityKind == 'hangout') {
                p.jobs.order(HabitatJobKind.goToTable);
              }
            }
          }
        case AppointmentIntentKind.complete:
          embodiedRuntime.planned.complete(intent.appointmentId);
      }
    }

    // Remote call bubble (M20).
    final call = embodiedRuntime.calls.active;
    if (call != null && call.phase == RemoteCallPhase.active) {
      final local = pawnByMemberId(call.localPawnId);
      if (local != null && !local.drafted && sim.toInt() % 25 == 0) {
        pushBubble(
          local,
          'Em chamada com ${call.remote.displayName}…',
          kind: HabitatBubbleKind.speech,
        );
      }
    }
  }

  HabitatJobKind? _jobForAffordance(String affordance) {
    return switch (affordance) {
      HabitatAffordances.sleep => HabitatJobKind.sleep,
      HabitatAffordances.sit => HabitatJobKind.sit,
      HabitatAffordances.goToTable => HabitatJobKind.goToTable,
      HabitatAffordances.wander => HabitatJobKind.wander,
      HabitatAffordances.recreate => HabitatJobKind.recreate,
      HabitatAffordances.listenMusic => HabitatJobKind.sit,
      HabitatAffordances.watchTv => HabitatJobKind.sit,
      HabitatAffordances.socialChat => HabitatJobKind.wander,
      HabitatAffordances.rest => HabitatJobKind.sit,
      HabitatAffordances.clean => HabitatJobKind.clean,
      _ => null,
    };
  }

  void _spawnVisitorPawn(String visitorId) {
    if (sprites == null) return;
    if (pawnByMemberId(visitorId) != null) return;
    embodiedRuntime.ensureIdentity(
      visitorId,
      kind: PawnIdentityKind.personProxy,
    );
    final spawn = HabitatLocations.spawn(locationId);
    // Entrance-adjacent: stay near spawn, never mid-room teleport.
    final cell = _firstWalkableNear(spawn.$1, spawn.$2);
    final pawnComp = LivingPawnComponent(
      map: map,
      tileSize: tileSize,
      sprites: sprites!,
      startCell: cell,
      memberId: visitorId,
      displayName: 'Visitante',
      appearance: PawnAppearance(
        name: 'Visitante',
        hair: const Color(0xFF5C4033),
        apparelTint: const Color(0xFF3D5A80),
      ),
    );
    _wirePawnJobs(pawnComp);
    embodied.ensure(
      visitorId,
      presence: EmbodiedPresenceContext(
        roomRole: locationId,
        isHome: false,
      ),
    );
    pawns.add(pawnComp);
    world.add(pawnComp);
  }

  void _despawnVisitorPawn(String visitorId) {
    final p = pawnByMemberId(visitorId);
    if (p == null) return;
    bubbles.removeWhere((b) => b.pawn == p);
    embodied.remove(visitorId);
    p.removeFromParent();
    pawns.remove(p);
  }

  /// Debug: schedule a demo dinner appointment (M19).
  void debugScheduleDinnerAppointment() {
    final ids = {for (final p in pawns) p.memberId};
    if (ids.isEmpty) return;
    embodiedRuntime.appointments.scheduleDemoDinner(
      participants: ids,
      nowSim: clocks.simulation.elapsedSeconds,
      delaySeconds: 45,
      durationSeconds: 90,
      siteId: locationId,
    );
    showClockDebug = true;
    final host = focusedPawn ?? pawns.first;
    pushBubble(
      host,
      'Jantar marcado (demo).',
      kind: HabitatBubbleKind.thought,
    );
  }

  /// Debug: schedule a visitor arrival (M18).
  void debugScheduleVisitor() {
    const visitorId = 'visitor-demo';
    final sim = clocks.simulation.elapsedSeconds;
    embodiedRuntime.visitors.scheduleVisit(
      pawnId: visitorId,
      arriveAtSim: sim + 20,
      leaveAtSim: sim + 120,
    );
    embodiedRuntime.ensureIdentity(
      visitorId,
      kind: PawnIdentityKind.personProxy,
    );
    showClockDebug = true;
  }

  /// Debug: start a simulated voice call (M20).
  void debugStartVoiceCall() {
    final host = focusedPawn ?? (pawns.isEmpty ? null : pawns.first);
    if (host == null) return;
    final fit = embodiedRuntime.activeContext.callFit();
    if (fit < 0.5) {
      pushBubble(
        host,
        'Lugar ruim pra ligar…',
        kind: HabitatBubbleKind.thought,
      );
    }
    embodiedRuntime.calls.startVoiceCall(
      localPawnId: host.memberId,
      remotePawnId: 'remote-friend',
      remoteName: 'Amigo',
      nowSim: clocks.simulation.elapsedSeconds,
    );
    embodiedRuntime.interruptActivities(
      host.memberId,
      nowSim: clocks.simulation.elapsedSeconds,
    );
    embodiedRuntime.ensureIdentity(
      'remote-friend',
      kind: PawnIdentityKind.personProxy,
    );
    host.jobs.order(HabitatJobKind.sit);
    showClockDebug = true;
    pushBubble(host, 'Ligando…', kind: HabitatBubbleKind.thought);
  }

  /// Debug: end active call.
  void debugEndVoiceCall() {
    embodiedRuntime.calls.endActive(
      clocks.simulation.elapsedSeconds,
      interrupted: true,
    );
  }

  /// Debug: leave home toward cafe (M23).
  void debugBeginTransitToCafe() {
    final host = focusedPawn ?? (pawns.isEmpty ? null : pawns.first);
    if (host == null) return;
    final origin =
        embodiedRuntime.world.siteForMapLocation(locationId)?.id ??
            'home_apartment';
    embodiedRuntime.transit.beginTransit(
      pawnId: host.memberId,
      originSiteId: origin,
      destinationSiteId: 'generic_cafe_01',
      nowSim: clocks.simulation.elapsedSeconds,
      durationSeconds: 40,
    );
    showClockDebug = true;
    pushBubble(host, 'Vou ao café…', kind: HabitatBubbleKind.thought);
  }

  /// Objective + perceived comfort for inspect (M25).
  PerceivedEnvironmentFit perceivedComfortFor(String pawnId) {
    final s = roomStats;
    final objective = ObjectiveRoomMetrics(
      beauty: (s.beauty / 100).clamp(0.0, 1.0),
      space: (s.space / 100).clamp(0.0, 1.0),
      cleanliness: (s.cleanliness / 100).clamp(0.0, 1.0),
      light: HabitatLocations.isOutdoor(locationId) ? 0.9 : 0.65,
      temperatureComfort: (s.comfort / 100).clamp(0.0, 1.0),
      quality: (s.wealth / 100).clamp(0.0, 1.0),
    );
    return embodiedRuntime.perceivedFit(
      pawnId,
      objective: objective,
      isOutdoor: HabitatLocations.isOutdoor(locationId),
    );
  }

  /// Debug: stamp a reading nook prefab near spawn (M28).
  void debugStampPrefab() {
    if (!editor.enabled) editor.enter();
    final spawn = HabitatLocations.spawn(locationId);
    commands.stampPrefab(
      HabitatPrefabs.readingNook,
      spawn.$1,
      spawn.$2,
      simSeconds: clocks.simulation.elapsedSeconds,
    );
    notifyMapVisualChanged();
    refreshRoomStats();
  }

  /// Debug: auto-furnish by detected role (M29).
  void debugAutoFurnish() {
    final regions = HabitatRoomDetector.detect(map);
    final role = regions.isEmpty ? 'generic' : regions.first.role.name;
    editor.pushUndo();
    final n = HabitatAutoFurnish.furnish(
      map,
      pickPrefab: HabitatAutoFurnish.prefabForRole,
      roleHint: role,
    );
    commands.history.add(
      HabitatEditorCommand(
        id: 'autofurnish-$n',
        label: 'autofurnish:$role ×$n',
        atSimSeconds: clocks.simulation.elapsedSeconds,
      ),
    );
    notifyMapVisualChanged();
    refreshRoomStats();
  }

  /// Sync ScenePreset / env switches → visible light + TV (M30).
  void applyEnvironmentVisuals() {
    final env = embodiedRuntime.scenes.environment;
    final lighting =
        embodiedRuntime.scenes.active?.lightingPreset ?? 'normal';
    sceneAmbientBias = switch (lighting) {
      'cinema' => 0.55,
      'night' => 0.45,
      'dim' => 0.28,
      'morning' => -0.04,
      'bright' => -0.06,
      _ => 0.0,
    };
    lampsEnabled = env[HabitatEnvSwitch.lampOn];
    tvScreenOn = env[HabitatEnvSwitch.tvOn] ||
        embodiedRuntime.devices.devices['tv']?.activeMode == 'watch';

    for (final p in map.props) {
      if (p.kind == HabitatPropKinds.tv) {
        p.tint = tvScreenOn
            ? const Color(0xFF81D4FA)
            : StuffPalettes.natural;
      }
      if (p.kind == HabitatPropKinds.lamp) {
        p.tint = lampsEnabled
            ? StuffPalettes.natural
            : const Color(0xFF3A3A3A);
      }
    }
    _refreshAtmosphere();
    notifyMapVisualChanged();
  }

  /// Human-readable sim status for HUD (always-on feedback).
  String get simStatusLine {
    final host = focusedPawn ?? (pawns.isEmpty ? null : pawns.first);
    final preset = embodiedRuntime.scenes.activePresetId ?? '—';
    final loadout = host == null
        ? '—'
        : (embodiedRuntime.loadouts.currentByPawn[host.memberId] ??
            host.appearance.loadoutId);
    final held = host == null
        ? null
        : embodiedRuntime.inventory.items.values
            .where(
              (it) =>
                  it.location.kind == HabitatItemLocationKind.heldByPawn &&
                  it.location.pawnId == host.memberId,
            )
            .map((it) => it.label)
            .firstOrNull;
    final focus = host == null
        ? null
        : embodiedRuntime.devices.activities.values
            .where((a) => a.pawnId == host.memberId)
            .where(
              (a) =>
                  a.phase == SustainedActivityPhase.active ||
                  a.phase == SustainedActivityPhase.resumable,
            )
            .map((a) => '${a.kind}/${a.phase.name}')
            .firstOrNull;
    final loc = host == null
        ? null
        : embodiedRuntime.transit.locationState[host.memberId]?.name;
    final parts = <String>[
      'cena:$preset',
      'roupa:$loadout',
      if (held != null) 'mão:$held',
      if (focus != null) 'foco:$focus',
      if (loc != null && loc != 'atSite') 'loc:$loc',
      if (tvScreenOn) 'TV:on',
      if (!lampsEnabled) 'luz:off',
    ];
    return parts.join(' · ');
  }

  /// Debug: cycle scene presets (M30).
  void debugCycleScenePreset() {
    final presets = embodiedRuntime.scenes.presets;
    if (presets.isEmpty) return;
    final cur = embodiedRuntime.scenes.activePresetId;
    var i = presets.indexWhere((p) => p.id == cur);
    i = (i + 1) % presets.length;
    embodiedRuntime.applyScenePreset(
      presets[i].id,
      nowSim: clocks.simulation.elapsedSeconds,
    );
    if (presets[i].id == 'movieNight') {
      embodiedRuntime.devices.devices['tv']?.use(
        mode: 'watch',
        mediaId: 'film.demo',
        userId: focusedPawn?.memberId,
      );
      embodiedRuntime.scenes.markAftermath('movie');
    }
    applyEnvironmentVisuals();
    showClockDebug = true;
    final host = focusedPawn ?? (pawns.isEmpty ? null : pawns.first);
    if (host != null) {
      pushBubble(
        host,
        'cena: ${presets[i].label}',
        kind: HabitatBubbleKind.thought,
      );
    }
  }

  /// Debug: force sleep loadout (M31).
  void debugApplySleepLoadout() {
    final host = focusedPawn ?? (pawns.isEmpty ? null : pawns.first);
    if (host == null) return;
    final loadout = embodiedRuntime.loadouts.byId('sleep')!;
    embodiedRuntime.loadouts.maybeApply(
      pawnId: host.memberId,
      loadout: loadout,
      force: true,
      applyVisual: (top, hat) {
        // Visually distinct from day clothes (no top = clear "pijama").
        host.appearance.apparelTop = null;
        host.appearance.hat = null;
        host.appearance.apparelTint = const Color(0xFF9FA8DA);
        host.appearance.loadoutId = loadout.id;
      },
    );
    host.jobs.order(HabitatJobKind.sleep);
    embodiedRuntime.applyScenePreset(
      'sleepMode',
      nowSim: clocks.simulation.elapsedSeconds,
    );
    applyEnvironmentVisuals();
    showClockDebug = true;
    pushBubble(host, 'pijama + luz off', kind: HabitatBubbleKind.thought);
  }

  /// Debug: inventory — first tap holds book (visible); second puts in bag.
  void debugInventoryPath() {
    final host = focusedPawn ?? (pawns.isEmpty ? null : pawns.first);
    if (host == null) return;
    embodiedRuntime.inventory.seedDemo();
    final inv = embodiedRuntime.inventory;
    if (!inv.items.containsKey('mug.red')) {
      inv.putNew(
        HabitatItem(
          id: 'mug.red',
          label: 'Caneca vermelha',
          tags: {'cup'},
          location: const HabitatItemLocation(
            kind: HabitatItemLocationKind.surfaceSlot,
            containerId: 'table',
            slotId: '1',
          ),
          preferredStorageId: 'wardrobe',
        ),
      );
    }
    const book = 'book.dune';
    final item = inv.items[book];
    final holding = item?.location.kind == HabitatItemLocationKind.heldByPawn &&
        item?.location.pawnId == host.memberId;
    final journal = ItemTransferJournal(inv);
    if (holding) {
      final txn = journal.begin(
        op: ItemTransferOp.place,
        itemId: book,
        to: const HabitatItemLocation(
          kind: HabitatItemLocationKind.storageSlot,
          containerId: 'bag',
          slotId: '0',
        ),
      );
      if (txn != null) {
        if (!journal.commit(txn)) journal.rollback(txn);
      }
      host.heldLabel = null;
      objectState.ensure(book)
        ..setState(ObjectLogicState.closed)
        ..markUsed(sessionTime, traceKey: 'openPage');
      pushBubble(host, 'guardou na bolsa', kind: HabitatBubbleKind.thought);
    } else {
      final txn = journal.begin(
        op: ItemTransferOp.pickup,
        itemId: book,
        to: HabitatItemLocation.held(host.memberId),
      );
      if (txn != null && journal.commit(txn)) {
        host.heldLabel = 'Duna';
        objectState.ensure(book)
          ..setState(ObjectLogicState.open)
          ..openPage = 12
          ..markUsed(sessionTime, traceKey: 'openPage');
        itemUsageByPawn['${host.memberId}::$book'] =
            (itemUsageByPawn['${host.memberId}::$book'] ?? 0) + 1;
        pushBubble(
          host,
          ObjectFeedbackCatalog.moteLabel(ObjectFeedbackKind.bookPage),
          kind: HabitatBubbleKind.mote,
        );
        pushBubble(host, 'pegou o livro', kind: HabitatBubbleKind.speech);
      } else if (txn != null) {
        journal.rollback(txn);
      }
    }
    showClockDebug = true;
  }

  /// Debug: start reading then leave candidate for interrupt (M33).
  void debugStartReading() {
    final host = focusedPawn ?? (pawns.isEmpty ? null : pawns.first);
    if (host == null) return;
    embodiedRuntime.startReadingDemo(
      host.memberId,
      nowSim: clocks.simulation.elapsedSeconds,
    );
    host.jobs.order(HabitatJobKind.sit);
    showClockDebug = true;
    pushBubble(host, 'lendo…', kind: HabitatBubbleKind.thought);
  }

  /// Debug: resume interrupted activity (M33).
  void debugResumeActivity() {
    final host = focusedPawn ?? (pawns.isEmpty ? null : pawns.first);
    if (host == null) return;
    final cand = embodiedRuntime.devices.bestResume(
      host.memberId,
      clocks.simulation.elapsedSeconds,
    );
    if (cand == null) {
      pushBubble(host, 'nada pra retomar', kind: HabitatBubbleKind.thought);
      return;
    }
    embodiedRuntime.resumeActivity(
      cand.activityId,
      nowSim: clocks.simulation.elapsedSeconds,
    );
    pushBubble(host, 'retomando…', kind: HabitatBubbleKind.thought);
  }

  /// Debug: run prepareSleep routine (M34).
  void debugStartRoutine([String id = 'prepareSleep']) {
    final host = focusedPawn ?? (pawns.isEmpty ? null : pawns.first);
    if (host == null) return;
    embodiedRuntime.startRoutine(id, host.memberId);
    showClockDebug = true;
    _advanceRoutineSteps(host, steps: 16);
  }

  /// Debug: morning then bedtime (M35).
  void debugMorningBedtime() {
    final host = focusedPawn ?? (pawns.isEmpty ? null : pawns.first);
    if (host == null) return;
    embodiedRuntime.startRoutine('morning', host.memberId);
    _advanceRoutineSteps(host, steps: 20);
    embodiedRuntime.startRoutine('bedtime', host.memberId);
    _advanceRoutineSteps(host, steps: 16);
    applyEnvironmentVisuals();
    showClockDebug = true;
  }

  /// Debug: prepare leave + transit + arrive (M36).
  void debugLeaveAndArrive() {
    final host = focusedPawn ?? (pawns.isEmpty ? null : pawns.first);
    if (host == null) return;
    final prep = embodiedRuntime.prepareForContext('work', host.memberId);
    embodiedRuntime.startRoutine('prepareToLeave', host.memberId);
    _advanceRoutineSteps(host, steps: 10);
    debugBeginTransitToCafe();
    // Soft return: arrive routine + home loadout.
    embodiedRuntime.transit.ensureAtSite(host.memberId, 'home_apartment');
    embodiedRuntime.startRoutine('arriveHome', host.memberId);
    _advanceRoutineSteps(host, steps: 12);
    showClockDebug = true;
    pushBubble(
      host,
      prep.satisfied ? 'ida/volta ok' : 'faltou ${prep.missingRequired}',
      kind: HabitatBubbleKind.thought,
    );
  }

  /// Debug: shared meal (M37).
  void debugSharedMeal() {
    final host = focusedPawn ?? (pawns.isEmpty ? null : pawns.first);
    if (host == null) return;
    embodiedRuntime.ensureIdentity(host.memberId, isPrimarySelf: true);
    final guestId = pawns.length > 1 ? pawns[1].memberId : 'guest-meal';
    if (guestId == 'guest-meal') {
      embodiedRuntime.ensureIdentity(guestId, kind: PawnIdentityKind.personProxy);
      embodiedRuntime.store.ensure(guestId);
    }
    embodiedRuntime.store.ensure(host.memberId);
    final meal = embodiedRuntime.demoSharedMeal(
      cookId: host.memberId,
      guests: [guestId],
      nowSim: clocks.simulation.elapsedSeconds,
    );
    host.jobs.order(HabitatJobKind.goToTable);
    showClockDebug = true;
    pushBubble(
      host,
      'jantar ${meal.recipeId}',
      kind: HabitatBubbleKind.speech,
    );
  }

  /// Debug: multi-session painting (M38).
  void debugWorkpiece() {
    final host = focusedPawn ?? (pawns.isEmpty ? null : pawns.first);
    if (host == null) return;
    var w = embodiedRuntime.workOnPainting(host.memberId, delta: 0.28);
    w = embodiedRuntime.workOnPainting(host.memberId, delta: 0.28);
    showClockDebug = true;
    pushBubble(
      host,
      'tela ${w.stage} ${(w.visualProgress * 100).round()}%',
      kind: HabitatBubbleKind.thought,
    );
  }

  /// Debug: prep requirements for work (M39).
  void debugPrepWork() {
    final host = focusedPawn ?? (pawns.isEmpty ? null : pawns.first);
    if (host == null) return;
    final r = embodiedRuntime.prepareForContext('work', host.memberId);
    showClockDebug = true;
    pushBubble(
      host,
      r.satisfied
          ? 'prep ok (${r.collectedItemIds.length})'
          : 'falta ${r.missingRequired.join(",")}',
      kind: HabitatBubbleKind.thought,
    );
  }

  /// Debug: SP → Tokyo hotel + jet lag (M40).
  void debugJetLagHop() {
    final host = focusedPawn ?? (pawns.isEmpty ? null : pawns.first);
    if (host == null) return;
    final hotelId = embodiedRuntime.beginJetLagDemo(
      host.memberId,
      nowSim: clocks.simulation.elapsedSeconds,
    );
    final site = embodiedRuntime.world.sites[hotelId];
    clocks.siteTimezoneId = site?.timezoneId ?? 'Asia/Tokyo';
    clocks.scene.siteTimezoneId = clocks.siteTimezoneId;
    // Scene hour jumps; body clock lags via travel director.
    clocks.scene.setSceneHour((presence.phase * 24 + 12) % 24);
    presence.syncFromClock();
    _refreshAtmosphere();
    showClockDebug = true;
    final circ = embodiedRuntime.travel.stateFor(host.memberId);
    pushBubble(
      host,
      'jet lag Δ${circ.bodyClockOffsetHours.toStringAsFixed(0)}h',
      kind: HabitatBubbleKind.thought,
    );
  }

  /// Debug: world map → café (M41).
  void debugWorldMapGo() {
    final host = focusedPawn ?? (pawns.isEmpty ? null : pawns.first);
    if (host == null) return;
    final id = embodiedRuntime.goWorldMap(
      'CAFÉ',
      host.memberId,
      nowSim: clocks.simulation.elapsedSeconds,
    );
    showClockDebug = true;
    pushBubble(host, 'mapa→$id', kind: HabitatBubbleKind.thought);
  }

  /// Debug: register saxophone + custom guitar (M42/M43).
  void debugCustomContent() {
    final host = focusedPawn ?? (pawns.isEmpty ? null : pawns.first);
    final sax = embodiedRuntime.content.getPropDefinition('prop.saxophone_alto');
    final prop = embodiedRuntime.customContent.createProp(
      CustomContentDraft(
        kind: 'prop',
        name: 'Minha Guitarra',
        tags: {'music', 'instrument', 'guitar'},
        affordances: ['practiceInstrument'],
        interestTags: {'music'},
      ),
    );
    final act = embodiedRuntime.customContent.createActivity(
      CustomContentDraft(
        kind: 'activity',
        name: 'Ouvir vinil',
        tags: {'recordPlayer', 'vinyl'},
        durationSim: 40,
        needEffects: {'recreation': 0.3},
        interestTags: {'music'},
      ),
    );
    showClockDebug = true;
    if (host != null) {
      pushBubble(
        host,
        'sax=${sax != null} prop=${prop.isOk} act=${act.isOk}',
        kind: HabitatBubbleKind.thought,
      );
    }
  }

  /// Debug: snapshot save/load (M47) + gate (M50).
  void debugPersistAndGate() {
    final host = focusedPawn ?? (pawns.isEmpty ? null : pawns.first);
    embodiedRuntime.snapshots.forceSave(
      embodiedRuntime.buildSnapshot(
        clockState: {
          'sim': clocks.simulation.elapsedSeconds,
          'tz': clocks.siteTimezoneId,
        },
      ),
    );
    final loaded = embodiedRuntime.snapshots.load();
    final gate = embodiedRuntime.mirrorReadyGateIssues();
    showClockDebug = true;
    if (host != null) {
      pushBubble(
        host,
        'save v${loaded?.schemaVersion} gate=${gate.isEmpty ? "ok" : gate}',
        kind: HabitatBubbleKind.thought,
      );
    }
  }

  void _advanceRoutineSteps(LivingPawnComponent host, {int steps = 6}) {
    final now = clocks.simulation.elapsedSeconds;
    for (var i = 0; i < steps; i++) {
      embodiedRuntime.routines.tick(
        pawnId: host.memberId,
        nowSim: now + i * 5,
        effects: (node) {
          switch (node.kind) {
            case RoutineNodeKind.applyPreset:
              final pid = node.params['presetId'] as String? ?? 'normal';
              embodiedRuntime.applyScenePreset(pid, nowSim: now + i * 5);
              applyEnvironmentVisuals();
            case RoutineNodeKind.applyLoadout:
              final lid = node.params['loadoutId'] as String? ?? 'home';
              final lo = embodiedRuntime.loadouts.byId(lid);
              if (lo != null) {
                embodiedRuntime.loadouts.maybeApply(
                  pawnId: host.memberId,
                  loadout: lo,
                  force: true,
                  applyVisual: (top, hat) {
                    host.appearance.apparelTop = top;
                    host.appearance.hat = hat;
                    host.appearance.loadoutId = lo.id;
                  },
                );
              }
            case RoutineNodeKind.emitBubble:
              final text = node.params['text'] as String? ?? '…';
              pushBubble(host, text, kind: HabitatBubbleKind.speech);
            case RoutineNodeKind.goTo:
              final target = node.params['target'] as String? ?? '';
              if (target == 'bed') {
                host.jobs.order(HabitatJobKind.sleep);
              } else if (target == 'table') {
                host.jobs.order(HabitatJobKind.goToTable);
              } else if (target == 'entrance' || target == 'bathroom') {
                host.jobs.order(HabitatJobKind.wander);
              }
            case RoutineNodeKind.putIn:
              final hint = node.params['itemHint'] as String? ?? 'held';
              final container =
                  node.params['containerId'] as String? ?? 'bag';
              if (hint == 'prep') {
                embodiedRuntime.prepareForContext('work', host.memberId);
              } else if (hint == 'bag') {
                // Drop bag contents onto table/dropzone.
                for (final it in embodiedRuntime.inventory.items.values
                    .where(
                      (x) =>
                          x.location.containerId == 'bag' ||
                          (x.location.kind ==
                                  HabitatItemLocationKind.heldByPawn &&
                              x.location.pawnId == host.memberId),
                    )
                    .toList()) {
                  embodiedRuntime.inventory.putIn(
                    itemId: it.id,
                    containerId: container,
                  );
                }
              } else {
                final held = embodiedRuntime.inventory.items.values
                    .where(
                      (it) =>
                          it.location.kind ==
                              HabitatItemLocationKind.heldByPawn &&
                          it.location.pawnId == host.memberId,
                    )
                    .firstOrNull;
                if (held != null) {
                  embodiedRuntime.inventory.putIn(
                    itemId: held.id,
                    containerId: container,
                  );
                }
              }
            case RoutineNodeKind.wait:
              return (node.params['seconds'] as num?)?.toDouble() ?? 0;
            default:
              break;
          }
          return 0;
        },
        branch: (node) {
          final key = node.params['key'] as String? ?? '';
          if (key == 'showerAvailable') return 'fail';
          return 'default';
        },
      );
      final run = embodiedRuntime.routines.runsByPawn[host.memberId];
      if (run == null ||
          run.status == RoutineRunStatus.completed ||
          run.status == RoutineRunStatus.aborted) {
        break;
      }
    }
  }

  /// Latest room detection snapshot (M27).
  List<DetectedRoomRegion> detectRooms() => HabitatRoomDetector.detect(map);

  // Embodied autonomy is driven per-pawn via BehaviorDesyncClock (R9).

  void _maybeConditionBubble() {
    for (final p in pawns) {
      final pres = embodiedRuntime.presentationFor(p.memberId);
      final tag = pres.bubbleTag;
      if (tag == null) continue;
      if (_rng.nextDouble() > 0.35) continue;
      final text = switch (tag) {
        'sleepy' => '…bocejo',
        'groggy' => 'Ainda meio zonzo.',
        'cold' => 'Brr.',
        'hot' => 'Ufa.',
        'need_space' => 'Preciso de um tempo.',
        _ => null,
      };
      if (text != null) {
        pushBubble(p, text, kind: HabitatBubbleKind.thought);
      }
    }
  }

  void cyclePropQuality(HabitatProp prop) {
    prop.quality = prop.quality.next();
    notifyMapVisualChanged(positive: true);
  }

  /// Rotate placed furniture 90° (updates footprint + sprite facing).
  void rotateProp(HabitatProp prop) {
    final def = FurnitureRegistry.tryGet(prop.kind);
    final nextFacing = prop.facing.next;
    if (def != null) {
      final nextSize = def.footprintFor(nextFacing);
      final probe = HabitatProp(
        id: prop.id,
        kind: prop.kind,
        name: prop.name,
        assetPath: def.assetPath(nextFacing.spriteKey),
        origin: prop.origin,
        size: nextSize,
        blocksWalk: prop.blocksWalk,
        drawSize: def.visualSizeFor(nextFacing),
        drawAlign: prop.drawAlign,
        tint: prop.tint,
        quality: prop.quality,
        facing: nextFacing,
        poweredOn: prop.poweredOn,
      );
      if (!map.canPlace(probe, prop.origin, ignoreId: prop.id)) {
        presence.playStub('reject');
        return;
      }
      final idx = map.props.indexOf(prop);
      if (idx < 0) return;
      map.props[idx] = probe;
      map.rebuildBlocked();
      grid?.selectedProp = probe;
    } else {
      prop.facing = nextFacing;
    }
    notifyMapVisualChanged(positive: true);
  }

  void togglePropPower(HabitatProp prop) {
    if (!FurnitureInteractions.isLight(prop.kind) &&
        prop.kind != HabitatPropKinds.tv) {
      return;
    }
    prop.poweredOn = !prop.poweredOn;
    if (prop.kind == HabitatPropKinds.tv) {
      tvScreenOn = prop.poweredOn;
    }
    notifyMapVisualChanged(positive: prop.poweredOn);
  }

  bool _isJoyOnCooldown(String kind) {
    final until = recreateCooldownUntil[kind];
    return until != null && sessionTime < until;
  }

  HabitatSocialContext _buildSocialContext() {
    final tables = <(int, int)>[];
    final spots = <(int, int)>[];
    var hasLamp = false;
    for (final p in map.props) {
      if (FurnitureInteractions.isTable(p.kind)) tables.add(p.origin);
      if (p.kind == HabitatPropKinds.gatheringSpot) spots.add(p.origin);
      if (FurnitureInteractions.isLight(p.kind) && p.poweredOn) hasLamp = true;
    }
    final comfortDelta = HabitatClimateField.comfortDelta(
      HabitatClimateField.effectiveOutdoor(
        outdoorTemperatureC,
        phase: presence.phase,
      ),
    );
    final enc = social.active;
    return HabitatSocialContext(
      pawns: [
        for (final p in pawns)
          SocialPawnSnapshot(
            memberId: p.memberId,
            displayName: p.displayName,
            cellX: p.cellX,
            cellY: p.cellY,
            isWander: p.jobs.kind == HabitatJobKind.wander,
            isDrafted: p.drafted,
            // Social approach uses goTo without counting as "busy" for the pair.
            isBusy: p.jobs.kind != HabitatJobKind.wander &&
                !(enc != null &&
                    (p.memberId == enc.aId || p.memberId == enc.bId) &&
                    p.jobs.kind == HabitatJobKind.goTo),
            allowedZone: zoneFor(p),
            socialTolerance:
                embodied[p.memberId]?.capacity(CapacityKind.socialTolerance)?.level ??
                    0.7,
            solitudePressure:
                embodied[p.memberId]?.need(NeedKind.solitude)?.pressure ?? 0.15,
            socialConnectionPressure: embodied[p.memberId]
                    ?.need(NeedKind.socialConnection)
                    ?.pressure ??
                0.3,
          ),
      ],
      roomStats: roomStats,
      darknessAt: (x, y) =>
          HabitatLightField.at(darknessField, map, x, y),
      filthAt: (x, y) => map.filthAt(x, y),
      phaseLabel: presence.phaseLabel,
      locationId: locationId,
      isOutdoor: HabitatLocations.isOutdoor(locationId),
      spaceTight: roomStats.spaceTight,
      comfortOk: comfortDelta.abs() <= 3,
      tempBand: comfortDelta <= -3
          ? 'cold'
          : comfortDelta >= 3
              ? 'hot'
              : 'ok',
      now: sessionTime,
      isWalkable: map.isWalkable,
      hasLamp: hasLamp,
      tables: tables,
      gatheringSpots: spots,
      doorCell: map.doorCell,
    );
  }

  void _issueSocialApproach(
    String hostId,
    (int, int) hostCell,
    String guestId,
    (int, int) guestCell,
  ) {
    int pathLen(String id, (int, int) to) {
      final p = pawnByMemberId(id);
      if (p == null) return 999;
      if (p.cellX == to.$1 && p.cellY == to.$2) return 0;
      final zone = zoneFor(p);
      final path = findPath(
        map: map,
        from: (p.cellX, p.cellY),
        to: to,
        allowed: zone == null ? null : (x, y) => zone.contains((x, y)),
      );
      if (path.isEmpty) return 999;
      return path.length;
    }

    final lh = pathLen(hostId, hostCell);
    final lg = pathLen(guestId, guestCell);
    // Spec: abort if a single approach path is too long.
    if (lh > 8 || lg > 8) {
      social.cancelActive();
      return;
    }

    void go(String id, (int, int) cell) {
      final p = pawnByMemberId(id);
      if (p == null || p.drafted) return;
      if (p.cellX == cell.$1 && p.cellY == cell.$2) return;
      if (!map.isWalkable(cell.$1, cell.$2)) return;
      if (!isCellAllowed(p, cell.$1, cell.$2)) return;
      p.jobs.orderGoToCell(cell);
    }

    // Never path both pawns onto the same cell.
    // R34: prefer conversational arc slots around the midpoint.
    final mid = (
      ((hostCell.$1 + guestCell.$1) / 2).round(),
      ((hostCell.$2 + guestCell.$2) / 2).round(),
    );
    final slots = ConversationalPositioning.planSlots(
      center: mid,
      count: 2,
      isWalkable: map.isWalkable,
    );
    var hCell = slots.isNotEmpty ? slots[0] : hostCell;
    var gCell = slots.length > 1 ? slots[1] : guestCell;
    if (hCell == gCell) {
      final host = pawnByMemberId(hostId);
      if (host != null) {
        for (final (dx, dy) in const [(1, 0), (-1, 0), (0, 1), (0, -1)]) {
          final x = hCell.$1 + dx;
          final y = hCell.$2 + dy;
          if (!map.isWalkable(x, y)) continue;
          if (!isCellAllowed(host, x, y)) continue;
          gCell = (x, y);
          break;
        }
      }
    }
    go(hostId, hCell);
    go(guestId, gCell);
  }

  void _stopSocialMovement(String aId, String bId) {
    for (final id in [aId, bId]) {
      final p = pawnByMemberId(id);
      if (p == null || p.drafted) continue;
      if (p.jobs.kind == HabitatJobKind.goTo) {
        p.jobs.order(HabitatJobKind.wander);
      }
      if (p.jobs.kind == HabitatJobKind.wander) {
        p.jobs.wander.pause();
      }
    }
  }

  void _separateIfOverlapping(String aId, String bId) {
    final a = pawnByMemberId(aId);
    final b = pawnByMemberId(bId);
    if (a == null || b == null) return;
    if (a.cellX != b.cellX || a.cellY != b.cellY) return;
    for (final (dx, dy) in const [(1, 0), (-1, 0), (0, 1), (0, -1)]) {
      final x = a.cellX + dx;
      final y = a.cellY + dy;
      if (!map.isWalkable(x, y)) continue;
      if (!isCellAllowed(b, x, y)) continue;
      b.teleportToCell((x, y));
      return;
    }
  }

  (int, int)? _nearestRoomInterest(LivingPawnComponent p) {
    (int, int)? best;
    var bestD = 1 << 30;
    for (final prop in map.props) {
      final kind = prop.kind;
      if (!(kind.contains('window') ||
          kind == 'tv' ||
          kind.contains('tv') ||
          kind.contains('table'))) {
        continue;
      }
      final c = (
        prop.origin.$1 + prop.size.$1 ~/ 2,
        prop.origin.$2 + prop.size.$2 ~/ 2,
      );
      final d = (c.$1 - p.cellX).abs() + (c.$2 - p.cellY).abs();
      if (d < bestD) {
        bestD = d;
        best = c;
      }
    }
    return best;
  }

  void _tickSoftAvoidance() {
    final snaps = <AvoidanceAgentSnapshot>[
      for (final p in pawns)
        AvoidanceAgentSnapshot(
          pawnId: p.memberId,
          cell: (p.cellX, p.cellY),
          nextCell: p.jobs.remainingPath.isEmpty
              ? null
              : p.jobs.remainingPath.first,
          urgency: p.micro.urgentLocomotion
              ? 0.9
              : (p.drafted ? 0.7 : 0.2),
          carrying: p.heldLabel != null && p.heldLabel!.isNotEmpty,
          remainingPathLength: p.jobs.remainingPath.length,
        ),
    ];
    final blocked = {for (final p in pawns) (p.cellX, p.cellY)};
    for (final p in pawns) {
      if (p.isMoving || p.jobs.avoidanceWaitLeft > 0) continue;
      final self = snaps.firstWhere((s) => s.pawnId == p.memberId);
      final conflict = SoftLocalAvoidance.detect(self: self, others: snaps);
      if (conflict == null) {
        p.jobs.avoidanceOscillation = 0;
        continue;
      }
      final other = snaps.firstWhere((s) => s.pawnId == conflict.otherId);
      final decision = SoftLocalAvoidance.resolve(
        self: self,
        other: other,
        conflict: conflict,
        isWalkable: map.isWalkable,
        blockedByPawns: blocked,
        oscillationCount: p.jobs.avoidanceOscillation,
        unitNoise: HabitatRng.unit(p.memberId, 'avoid', sessionTime.floor()),
      );
      switch (decision.action) {
        case AvoidanceAction.wait:
          p.jobs.avoidanceWaitLeft = decision.waitSeconds;
        case AvoidanceAction.sideStep:
          final side = decision.sideStepCell;
          if (side != null) {
            final dx = side.$1 - p.cellX;
            final dy = side.$2 - p.cellY;
            if (p.tryStep(dx, dy)) {
              p.jobs.avoidanceOscillation++;
            } else {
              p.jobs.avoidanceWaitLeft = SoftLocalAvoidance.waitMin;
            }
          }
        case AvoidanceAction.shortReplan:
          p.jobs.avoidanceWaitLeft = SoftLocalAvoidance.waitMin;
        case AvoidanceAction.none:
          break;
      }
    }
  }

  void _tickRoomEntryScans() {
    for (final p in pawns) {
      // Treat door cell crossing as room portal for MVP.
      final onDoor = p.cellX == map.door.cell.$1 && p.cellY == map.door.cell.$2;
      final roomKey = onDoor ? 'portal:${locationId}' : locationId;
      if (p.jobs.lastRoomId == roomKey) continue;
      final prev = p.jobs.lastRoomId;
      p.jobs.lastRoomId = roomKey;
      if (prev == null) continue; // spawn
      if (!onDoor && prev.startsWith('portal:')) {
        // Entered room after portal — scan.
        final cues = <RoomSalienceCue>[
          for (final o in pawns)
            if (o.memberId != p.memberId)
              RoomSalienceCue(
                cell: (o.cellX, o.cellY),
                score: o.jobs.kind == HabitatJobKind.recreate ? 0.8 : 0.4,
                entityId: o.memberId,
                label: o.jobs.kind.name,
              ),
          for (final prop in map.props)
            if (FurnitureInteractions.isJoy(prop.kind))
              RoomSalienceCue(
                cell: prop.origin,
                score: 0.7,
                entityId: prop.id,
                label: prop.kind,
              ),
        ];
        final scan = RoomEntryScanner.begin(
          pawnId: p.memberId,
          roomId: locationId,
          now: sessionTime,
          cues: cues,
          urgent: p.micro.urgentLocomotion || p.drafted,
          transitOnly: p.jobs.kind == HabitatJobKind.goTo &&
              p.jobs.remainingPath.length > 6,
        );
        p.jobs.roomScan = scan;
        final att = scan?.attention;
        if (att != null) {
          p.micro.attention.propose(candidate: att, now: sessionTime);
        }
      }
    }
  }

  void _tickCrowdingRelocate() {
    final cells = [for (final p in pawns) (p.cellX, p.cellY)];
    for (final p in pawns) {
      if (p.drafted || p.isMoving) continue;
      if (p.jobs.kind != HabitatJobKind.wander) continue;
      if (p.jobs.isInArrivalPipeline || p.jobs.isPosing) continue;
      if (!p.micro.desync.consumeSocialProbe(sessionTime, period: 6)) continue;
      final local = CrowdingAwareness.scoreAt(
        cell: (p.cellX, p.cellY),
        pawnCells: cells,
      );
      final state = embodied[p.memberId];
      final should = CrowdingAwareness.shouldRelocate(
        local: local,
        socialStyle: p.micro.profile?.socialStyle ?? SocialStyle.balanced,
        solitudePressure: state?.need(NeedKind.solitude)?.pressure ?? 0,
        socialTolerance:
            state?.capacity(CapacityKind.socialTolerance)?.level ?? 0.5,
        activityCommitted: false,
      );
      if (!should) continue;
      final quieter = CrowdingAwareness.pickQuieterCell(
        from: (p.cellX, p.cellY),
        pawnCells: cells,
        isWalkable: map.isWalkable,
      );
      if (quieter != null) {
        p.jobs.orderGoToCell(quieter, urgent: false);
      }
    }
  }

  void _tickRefinementSystems(double dt) {
    final hour = presence.phase * 24;
    quietness.setDaypart(AtmospherePresets.fromHour(hour));
    quietness.tick(dt);
    observer.tick(dt);
    cameraFocus.tick(sessionTime);

    // R70 footsteps stub when moving.
    for (final p in pawns) {
      if (!p.isMoving) continue;
      final floor = map.floorAt(p.cellX, p.cellY);
      final mat = Footsteps.fromFloor(floor);
      // Soft presence cue — no spam: only occasionally.
      if (HabitatRng.unit(p.memberId, 'step', sessionTime.floor()) > 0.92) {
        presence.playStub(Footsteps.stubId(mat));
      }
    }

    // R112 foreshadow due cues → soft event focus hint (no camera steal).
    for (final cue in foreshadow.due(sessionTime)) {
      eventFocusHint = EventFocusHints.forEvent(
        cell: pawns.isEmpty ? null : (pawns.first.cellX, pawns.first.cellY),
        label: cue.label,
        salience: 0.7,
      );
      causality.record(
        CausalityLink(
          causeId: cue.id,
          effectId: cue.eventKind,
          label: cue.label,
        ),
      );
    }

    // R59 sleep body signals → mote grammar.
    for (final p in pawns) {
      final st = embodied[p.memberId];
      if (st == null) continue;
      final sig = SleepBodySignals.forPressure(st.circadian.sleepPressure);
      if (sig == SleepBodySignal.yawn &&
          HabitatRng.unit(p.memberId, 'yawn', sessionTime.floor()) > 0.97) {
        pushBubble(
          p,
          MoteThoughtGrammar.glyph(ThoughtMoteGrammar.yawn),
          kind: HabitatBubbleKind.mote,
        );
      }
    }

    // R82–R87: pet energy pacing when a pet identity is present.
    String? petId;
    for (final p in pawns) {
      if (embodiedRuntime.identity[p.memberId]?.kind == PawnIdentityKind.pet) {
        petId = p.memberId;
        break;
      }
    }
    if (petId != null) {
      petEnergy ??= PetEnergyPacing();
      petEnergy!.tick(
        sessionTime,
        energy: 0.5 + HabitatRng.unit(petId, 'energy') * 0.4,
      );
      final pet = pawnByMemberId(petId);
      if (pet != null && petEnergy!.phase == PetEnergyPhase.zoomies) {
        if (!pet.isMoving &&
            !pet.drafted &&
            pet.jobs.kind == HabitatJobKind.wander) {
          pet.jobs.orderGoToCell(
            (
              (pet.cellX + 2).clamp(0, map.width - 1),
              (pet.cellY + 1).clamp(0, map.height - 1),
            ),
            urgent: false,
          );
        }
      }
    }

    _tickConversationEtiquette();
  }

  /// Block D — backchannels, overhearing, memory callbacks, shared silence.
  void _tickConversationEtiquette() {
    final enc = social.active;
    final group = activeConversationGroup;
    if (enc == null || group == null) {
      sharedSilence = null;
      return;
    }
    if (enc.phase != SocialEncounterPhase.beatLoop &&
        enc.phase != SocialEncounterPhase.formUp) {
      return;
    }

    final a = pawnByMemberId(enc.aId);
    final b = pawnByMemberId(enc.bId);
    if (a == null || b == null) return;

    // R35 turn bookkeeping from who last spoke via bubbles is soft —
    // alternate candidate when silence grows.
    final speaker = group.turns.currentSpeaker ?? enc.aId;
    final listenerId = speaker == enc.aId ? enc.bId : enc.aId;
    final listener = pawnByMemberId(listenerId);
    if (listener != null) {
      final style =
          listener.micro.profile?.socialStyle ?? SocialStyle.balanced;
      final kind = BackchannelScheduler.maybeEmit(
        style: style,
        listenerId: listenerId,
        now: sessionTime,
        lastEmitAt: lastBackchannelAt[listenerId] ?? -999,
      );
      if (kind != null) {
        lastBackchannelAt[listenerId] = sessionTime;
        switch (kind) {
          case BackchannelKind.moteEllipsis:
            pushBubble(
              listener,
              MoteThoughtGrammar.glyph(ThoughtMoteGrammar.ellipsis),
              kind: HabitatBubbleKind.mote,
            );
          case BackchannelKind.shortAck:
            pushBubble(listener, 'hm', kind: HabitatBubbleKind.speech);
          case BackchannelKind.facingAdjust:
            listener.facing = facingFromDelta(
              (speaker == enc.aId ? a : b).cellX - listener.cellX,
              (speaker == enc.aId ? a : b).cellY - listener.cellY,
            );
          case BackchannelKind.nod:
            listener.poseOffsetX = 1.5;
        }
      }
    }

    // R38 memory callback (strong cooldown).
    final pairKey =
        enc.aId.compareTo(enc.bId) <= 0 ? '${enc.aId}::${enc.bId}' : '${enc.bId}::${enc.aId}';
    final mem = MemoryCallback.maybeLine(
      sharedEventIds: const ['rematch', 'musica', 'visita'],
      now: sessionTime,
      lastCallbackAt: lastCallbackAt,
      pairKey: pairKey,
    );
    if (mem != null) {
      lastCallbackAt[pairKey] = sessionTime;
      pushBubble(a, mem, kind: HabitatBubbleKind.speech);
    }

    // R39 overhearing — nearby non-participants glance only.
    for (final p in pawns) {
      if (p.memberId == enc.aId || p.memberId == enc.bId) continue;
      final dist = (p.cellX - a.cellX).abs() + (p.cellY - a.cellY).abs();
      final hear = Overhearing.evaluate(
        distance: dist.toDouble(),
        sameRoom: true,
        doorClosedBetween: false,
        noiseProfile: (1.0 - quietness.current).clamp(0.0, 1.0),
      );
      if (!hear.canOverhear) continue;
      if (HabitatRng.unit(p.memberId, 'overhear', sessionTime.floor()) < 0.92) {
        continue;
      }
      p.micro.attention.lookAt(
        reason: AttentionReason.interestingEvent,
        now: sessionTime,
        entityId: enc.aId,
        cellX: a.cellX,
        cellY: a.cellY,
        holdOverride: 0.8,
      );
    }

    // R43 shared silence — soft hold when neither moves a beat.
    sharedSilence ??= SharedSilenceSession(
      startedAt: sessionTime,
      participantIds: [enc.aId, enc.bId],
      activityKind: 'chat',
    );
  }

  /// R119 gate snapshot for debug / tests.
  RefinementGateResult refinementGate({required bool testsGreen}) =>
      HabitatRefinementGate.evaluate(
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
        testsGreen: testsGreen,
      );

  void _faceSocialPair(String aId, String bId) {
    final a = pawnByMemberId(aId);
    final b = pawnByMemberId(bId);
    if (a == null || b == null) return;
    a.facing = facingFromDelta(b.cellX - a.cellX, b.cellY - a.cellY);
    b.facing = facingFromDelta(a.cellX - b.cellX, a.cellY - b.cellY);
    // R0: conversation partner wins ambient gaze.
    final now = sessionTime;
    a.micro.attention.lookAt(
      reason: AttentionReason.conversationPartner,
      now: now,
      entityId: bId,
      cellX: b.cellX,
      cellY: b.cellY,
    );
    b.micro.attention.lookAt(
      reason: AttentionReason.conversationPartner,
      now: now,
      entityId: aId,
      cellX: a.cellX,
      cellY: a.cellY,
    );
    a.jobs.partnerCell = (b.cellX, b.cellY);
    b.jobs.partnerCell = (a.cellX, a.cellY);
    a.micro.microIdle.interrupt();
    b.micro.microIdle.interrupt();

    // R32 greeting grammar.
    final greet = GreetingGrammar.decide(
      timeSinceLastSeen: 400,
      familiarity: 0.6,
      affinity: 0.5,
      isVisitor: embodiedRuntime.identity[bId]?.kind ==
          PawnIdentityKind.personProxy,
      justArrived: false,
      style: a.micro.profile?.socialStyle ?? SocialStyle.balanced,
      aId: aId,
      bId: bId,
      now: now,
      lastGreetingAt: lastGreetingAt,
    );
    if (greet.mode == GreetingMode.bubble && greet.line != null) {
      final key = aId.compareTo(bId) <= 0 ? '$aId::$bId' : '$bId::$aId';
      lastGreetingAt[key] = now;
      pushBubble(a, greet.line!, kind: HabitatBubbleKind.speech);
    } else if (greet.mode == GreetingMode.glance) {
      // Attention already set.
    }

    activeConversationGroup = ConversationGroup(
      id: 'enc.$aId.$bId',
      participantIds: [aId, bId],
      topicId: embodiedRuntime.lastSocialTopic?.id ?? 'smalltalk',
    );
    causality.record(
      CausalityLink(
        causeId: 'social.formUp',
        effectId: 'social.greeting',
        label: 'encounter greeting',
      ),
    );
  }

  void _markJoyUsed(String kind) {
    recreateCooldownUntil[kind] = sessionTime + 180;
  }

  Set<(int, int)>? zoneFor(LivingPawnComponent pawn) =>
      allowedZones[pawn.memberId];

  bool isCellAllowed(LivingPawnComponent pawn, int x, int y) =>
      HabitatZones.isAllowed(zoneFor(pawn), x, y);

  void seedZoneAllWalkable(String memberId) {
    allowedZones[memberId] = HabitatZones.allWalkable(map);
    zoneOverlay?.bumpPaintAnim();
    onMapsChanged?.call();
  }

  void clearZone(String memberId) {
    allowedZones[memberId] = null;
    zoneOverlay?.bumpPaintAnim();
    onMapsChanged?.call();
  }

  bool applyZonePaint(int x, int y, {required bool erase}) {
    final pawn = focusedPawn ?? draftedPawn;
    if (pawn == null || !map.inBounds(x, y) || !map.isWalkable(x, y)) {
      return false;
    }
    final id = pawn.memberId;
    var zone = allowedZones[id];
    if (zone == null) {
      seedZoneAllWalkable(id);
      zone = allowedZones[id]!;
    }
    final next = Set<(int, int)>.from(zone);
    if (erase) {
      next.remove((x, y));
    } else {
      next.add((x, y));
    }
    allowedZones[id] = next;
    zoneOverlay?.bumpPaintAnim();
    onMapsChanged?.call();
    return true;
  }

  void _rejectOrder(LivingPawnComponent pawn, (int, int) cell) {
    zoneRejectFlash = (cell.$1, cell.$2, 0);
    _headShakeT = 0.35;
    pushBubble(
      pawn,
      AppStrings.habitatBubbleOrderDenied,
      kind: HabitatBubbleKind.speech,
    );
    presence.playStub('order_deny');
  }

  (int, int)? _orderTargetCell(
    LivingPawnComponent pawn,
    HabitatSelection? hit,
    (int, int) cell,
  ) {
    switch (hit) {
      case HabitatPropSelection(:final prop):
        return approachCell(map, prop, (pawn.cellX, pawn.cellY)) ?? prop.origin;
      case HabitatCellSelection(:final cell):
        return cell;
      case HabitatPawnSelection():
      case null:
        return cell;
    }
  }

  (int, int)? _nearestDirtyCell((int, int) from, {int radius = 4}) {
    (int, int)? best;
    var bestD = 999;
    for (var dy = -radius; dy <= radius; dy++) {
      for (var dx = -radius; dx <= radius; dx++) {
        final x = from.$1 + dx;
        final y = from.$2 + dy;
        if (!map.isWalkable(x, y)) continue;
        if (map.filthAt(x, y) <= 0.12) continue;
        final d = dx.abs() + dy.abs();
        if (d < bestD) {
          bestD = d;
          best = (x, y);
        }
      }
    }
    return best;
  }

  HabitatProp? _pickJoyStation() {
    final candidates = <HabitatProp>[];
    for (final p in map.props) {
      if (!HabitatPropKinds.isJoy(p.kind)) continue;
      if (_isJoyOnCooldown(p.kind)) continue;
      candidates.add(p);
    }
    if (candidates.isEmpty) return null;
    return candidates[_rng.nextInt(candidates.length)];
  }

  List<double>? _wanderPreferWeights() {
    final indoorNight = !HabitatLocations.isOutdoor(locationId) &&
        HabitatLightField.ambientDarkness(
          presence.phase,
          outdoor: false,
        ) >
            0.5;
    final outdoorExtreme = HabitatLocations.isOutdoor(locationId) &&
        climateField.isNotEmpty &&
        map.props.any((p) => p.kind == HabitatPropKinds.heater) &&
        HabitatClimateField.comfortDelta(
              HabitatClimateField.effectiveOutdoor(
                outdoorTemperatureC,
                phase: presence.phase,
              ),
            )
            .abs() >
            4;

    if (!indoorNight && !outdoorExtreme) return null;

    if (outdoorExtreme && climateField.length == map.width * map.height) {
      // Prefer cells near heaters when terrace is extreme.
      final weights = List<double>.from(climateField);
      for (final p in map.props) {
        if (p.kind != HabitatPropKinds.heater) continue;
        final (ox, oy) = p.origin;
        for (var dy = -3; dy <= 3; dy++) {
          for (var dx = -3; dx <= 3; dx++) {
            final x = ox + dx;
            final y = oy + dy;
            if (!map.inBounds(x, y)) continue;
            weights[y * map.width + x] *= 0.5;
          }
        }
      }
      return weights;
    }
    return darknessField;
  }

  @override
  void update(double dt) {
    super.update(dt);
    clocks.tick(dt);
    presence.tick(dt);
    sessionTime = clocks.simulation.elapsedSeconds;
    for (final p in pawns) {
      p.syncSessionClock(sessionTime);
    }
    _tickDoor(dt);
    _refreshAtmosphere();
    _tickEmbodiedSystems(dt);

    final prefer = _wanderPreferWeights();
    final peerCells = [for (final p in pawns) (p.cellX, p.cellY)];
    final peerAgents = [
      for (final p in pawns)
        PersonalSpaceAgent(
          pawnId: p.memberId,
          cell: (p.cellX, p.cellY),
          moving: p.isMoving,
        ),
    ];
    doorReservations.tick(sessionTime);
    objectState.tick(sessionTime);
    for (final p in pawns) {
      p.jobs.wander.preferBright = prefer;
      p.jobs.wander.allowedZone = zoneFor(p);
      p.jobs.allowedZone = zoneFor(p);
      p.jobs.occupancy = occupancy;
      p.jobs.doors = doorReservations;
      p.jobs.queues = stationQueues;
      p.jobs.peerCells = peerCells;
      p.jobs.peerAgents = peerAgents;
      p.jobs.routePreference ??= RoutePreferenceContext(
        profile: RoutePreferenceProfile.avoidCrowd,
        crowdCostAt: (x, y) => PersonalSpace.costAt(
          cell: (x, y),
          agents: peerAgents,
          selfId: p.memberId,
          socialStyle: p.micro.profile?.socialStyle ?? SocialStyle.balanced,
        ),
      );
      // Nearest room interest POI (R1 polish).
      p.jobs.roomInterestCell = _nearestRoomInterest(p);
    }

    _tickSoftAvoidance();
    _tickRoomEntryScans();
    _tickCrowdingRelocate();
    _tickRefinementSystems(dt);

    if (zoneRejectFlash != null) {
      final (x, y, age) = zoneRejectFlash!;
      final next = age + dt / 0.2;
      zoneRejectFlash = next >= 1 ? null : (x, y, next);
    }
    if (_headShakeT > 0) {
      _headShakeT -= dt;
      final dp = draftedPawn;
      if (dp != null) {
        dp.poseOffsetX = math.sin(_headShakeT * 45) * 3;
      }
    } else {
      final dp = draftedPawn;
      if (dp != null && dp.jobs.kind != HabitatJobKind.clean) {
        dp.poseOffsetX = 0;
      }
    }

    // Capture before tick — encounter may finish in the same frame as farewell.
    final encBefore = social.active;
    final socialGroup = encBefore != null
        ? socialBubbleStackId(encBefore.aId, encBefore.bId)
        : (_socialPauseA != null && _socialPauseB != null)
            ? socialBubbleStackId(_socialPauseA!, _socialPauseB!)
            : null;
    final socialOut = social.tick(
      dt,
      _buildSocialContext(),
      onLean: (id, lean) {
        final p = pawnByMemberId(id);
        if (p != null) p.poseOffsetX = lean;
      },
      onApproachPaths: _issueSocialApproach,
    );
    for (final (memberId, text, isThought) in socialOut) {
      final p = pawnByMemberId(memberId);
      if (p == null) continue;
      pushBubble(
        p,
        text,
        kind: isThought ? HabitatBubbleKind.thought : HabitatBubbleKind.speech,
        stackGroupId: socialGroup,
      );
    }
    final enc = social.active;
    if (enc != null) {
      _socialPauseA = enc.aId;
      _socialPauseB = enc.bId;
      final enteredTalk = enc.phase != _lastSocialPhase &&
          (enc.phase == SocialEncounterPhase.formUp ||
              enc.phase == SocialEncounterPhase.beatLoop) &&
          (_lastSocialPhase == null ||
              _lastSocialPhase == SocialEncounterPhase.approach);
      if (enteredTalk) {
        _stopSocialMovement(enc.aId, enc.bId);
        _separateIfOverlapping(enc.aId, enc.bId);
        _faceSocialPair(enc.aId, enc.bId);
        // M16 — pick interest/media topic and seed a bubble.
        final topic = embodiedRuntime.pickSocialTopic(
          aId: enc.aId,
          bId: enc.bId,
          simSeconds: sessionTime,
        );
        final phrase = embodiedRuntime.lastTopicPhrase;
        if (topic != null && phrase != null) {
          final speaker = pawnByMemberId(enc.aId);
          if (speaker != null) {
            pushBubble(
              speaker,
              phrase,
              kind: HabitatBubbleKind.speech,
              stackGroupId: socialBubbleStackId(enc.aId, enc.bId),
            );
          }
        }
      }
      _lastSocialPhase = enc.phase;
      // Approach: let goTo run. FormUp/BeatLoop: pause wander in place.
      if (enc.phase != SocialEncounterPhase.approach) {
        for (final id in [enc.aId, enc.bId]) {
          final p = pawnByMemberId(id);
          if (p != null &&
              !p.drafted &&
              p.jobs.kind == HabitatJobKind.wander &&
              !p.isMoving) {
            p.jobs.wander.pause();
          }
        }
      }
    } else if (_socialPauseA != null || _socialPauseB != null) {
      for (final id in [_socialPauseA, _socialPauseB]) {
        if (id == null) continue;
        final p = pawnByMemberId(id);
        if (p != null && p.jobs.kind == HabitatJobKind.wander) {
          p.jobs.wander.resume();
          p.poseOffsetX = 0;
        }
        p?.jobs.partnerCell = null;
      }
      _socialPauseA = _socialPauseB = null;
      _lastSocialPhase = null;
    }

    for (final b in bubbles) {
      b.age += dt;
    }
    bubbles.removeWhere((b) => b.done);

    // R9: per-pawn idle probes (clean / recreate) — desynced.
    final socialIds = social.active == null
        ? const <String>{}
        : {social.active!.aId, social.active!.bId};
    for (final pawn in pawns) {
      if (pawn.drafted || pawn.jobs.kind != HabitatJobKind.wander) continue;
      if (pawn.isMoving) continue;
      if (socialIds.contains(pawn.memberId)) continue;
      if (!pawn.micro.desync.consumeIdleProbe(sessionTime, period: 7)) {
        continue;
      }
      final stream = HabitatRng.stream(
        pawnId: pawn.memberId,
        concern: 'idleAutonomy',
        worldSeed: sessionTime.floor(),
      );
      if (stream.nextDouble() < 0.35) {
        final dirty = _nearestDirtyCell((pawn.cellX, pawn.cellY));
        if (dirty != null) {
          pawn.jobs.orderCleanCell(dirty);
          continue;
        }
      }
      if (stream.nextDouble() < 0.28) {
        final joy = _pickJoyStation();
        if (joy != null) {
          pawn.jobs.orderRecreate(joy);
        }
      }
    }

    // Darkness standing timer kept for inspect/debug; bubbles via R2 scheduler.
    final socialBusy = social.active != null
        ? {social.active!.aId, social.active!.bId}
        : const <String>{};
    for (final pawn in pawns) {
      if (pawn.drafted ||
          pawn.isMoving ||
          pawn.jobs.kind != HabitatJobKind.wander ||
          socialBusy.contains(pawn.memberId)) {
        _darkIdleTimer.remove(pawn);
        continue;
      }
      final d = HabitatLightField.at(
        darknessField,
        map,
        pawn.cellX,
        pawn.cellY,
      );
      if (d >= HabitatLightField.tooDarkThreshold) {
        _darkIdleTimer[pawn] = (_darkIdleTimer[pawn] ?? 0) + dt;
      } else {
        _darkIdleTimer.remove(pawn);
      }
    }

    _idleBubbleTimer += dt;
    // Sparse ambient thoughts — mostly silence between lines.
    if (_idleBubbleTimer >= 22) {
      _idleBubbleTimer = 0;
      if (_rng.nextDouble() < 0.30) {
        final idle = [
          for (final p in pawns)
            if ((p.jobs.kind == HabitatJobKind.wander || p.drafted) &&
                !p.isMoving &&
                !socialBusy.contains(p.memberId))
              p,
        ];
        if (idle.isNotEmpty) {
          final pawn = idle[_rng.nextInt(idle.length)];
          // V9.8 — occasional “observe art” near plant/painting.
          HabitatProp? art;
          for (final prop in map.props) {
            if (prop.kind != HabitatPropKinds.plant &&
                prop.kind != HabitatPropKinds.painting) {
              continue;
            }
            final dx = (prop.origin.$1 - pawn.cellX).abs();
            final dy = (prop.origin.$2 - pawn.cellY).abs();
            if (dx + dy <= 3) {
              art = prop;
              break;
            }
          }
          if (art != null && _rng.nextDouble() < 0.28) {
            pawn.jobs.orderGoToProp(art, HabitatJobKind.goTo);
            final text = HabitatBubbleLines.forArt(_rng);
            pushBubble(pawn, text, kind: HabitatBubbleKind.thought);
            _lastIdleThought = text;
          } else {
            final roomLine =
                HabitatBubbleLines.forRoomStats(roomStats, _rng);
            final text = roomLine ??
                HabitatBubbleLines.forIdle(
                  _rng,
                  avoid: _lastIdleThought,
                );
            pushBubble(pawn, text, kind: HabitatBubbleKind.thought);
            _lastIdleThought = text;
          }
          presence.playStub('idle_thought');
        }
      }
    }

    if (followFocused) {
      final p = focusedPawn;
      if (p != null && hasLayout) {
        final z = camera.viewfinder.zoom;
        final viewW = canvasSize.x / z;
        final viewH = canvasSize.y / z;
        final target = Vector2(
          p.position.x - viewW / 2,
          p.position.y - viewH / 2,
        );
        camera.viewfinder.position +=
            (target - camera.viewfinder.position) * (1 - math.exp(-3 * dt));
        _clampCamera();
      }
    }
  }

  @override
  void onGameResize(Vector2 size) {
    super.onGameResize(size);
    _fitCamera();
  }

  @override
  void onScroll(ScrollEvent event) {
    final dy = event.scrollDelta.y;
    if (dy.abs() < 0.1) return;
    zoomBy(-dy * 0.0018);
  }

  (int, int) _firstWalkableNear(int x, int y) {
    if (map.isWalkable(x, y)) return (x, y);
    for (var r = 1; r < 8; r++) {
      for (var dy = -r; dy <= r; dy++) {
        for (var dx = -r; dx <= r; dx++) {
          if (map.isWalkable(x + dx, y + dy)) return (x + dx, y + dy);
        }
      }
    }
    final cells = map.walkableCells();
    return cells.isEmpty ? (1, 1) : cells.first;
  }

  (int, int) _cellAtWorld(Vector2 worldPos) => (
        (worldPos.x / tileSize).floor(),
        (worldPos.y / tileSize).floor(),
      );

  HabitatSelection? _hitSelection(Vector2 worldPos) {
    // Prefer the last pawn in list (drawn on top) when overlapping.
    for (var i = pawns.length - 1; i >= 0; i--) {
      final p = pawns[i];
      if (p.containsWorldPoint(worldPos)) return HabitatPawnSelection(p);
    }
    final cell = _cellAtWorld(worldPos);
    final prop = map.propAt(cell.$1, cell.$2);
    if (prop != null) return HabitatPropSelection(prop);
    if (map.inBounds(cell.$1, cell.$2)) return HabitatCellSelection(cell);
    return null;
  }

  LivingPawnComponent? get draftedPawn {
    for (final p in pawns) {
      if (p.drafted) return p;
    }
    return null;
  }

  /// Draft this pawn for click orders (roster / explicit). Map uses hold-to-draft.
  void selectPawn(LivingPawnComponent p) {
    draftPawn(p);
  }

  /// Soft focus for inspect — does **not** enter draft (hold on pawn to draft).
  void inspectPawn(LivingPawnComponent p) {
    for (final x in pawns) {
      if (x.drafted) {
        x.drafted = false;
        x.jobs.order(HabitatJobKind.wander);
      }
      x.selected = identical(x, p);
    }
    p.drafted = false;
    p.selected = true;
    focusedPawn = p;
    grid?.selectedProp = null;
    selection = HabitatPawnSelection(p);
    onSelectionChanged?.call(selection);
  }

  void draftPawn(LivingPawnComponent p) {
    social.cancelActive(player: true);
    for (final x in pawns) {
      if (x.drafted && !identical(x, p)) {
        x.drafted = false;
        x.selected = false;
        x.jobs.order(HabitatJobKind.wander);
      }
    }
    p.selected = true;
    p.drafted = true;
    focusedPawn = p;
    grid?.selectedProp = null;
    selection = HabitatPawnSelection(p);
    onSelectionChanged?.call(selection);
  }

  /// Release draft — pawn resumes wander (V9.6).
  void undraft({bool resumeWander = true}) {
    for (final x in pawns) {
      if (x.drafted && resumeWander) {
        x.jobs.order(HabitatJobKind.wander);
      }
      x.drafted = false;
      x.selected = false;
    }
    grid?.selectedProp = null;
    selection = null;
    onSelectionChanged?.call(null);
  }

  void selectProp(HabitatProp prop) {
    undraft(resumeWander: true);
    grid?.selectedProp = prop;
    selection = HabitatPropSelection(prop);
    onSelectionChanged?.call(selection);
  }

  void selectCell((int, int) cell) {
    undraft(resumeWander: true);
    grid?.selectedProp = null;
    selection = HabitatCellSelection(cell);
    onSelectionChanged?.call(selection);
  }

  void clearSelection() {
    undraft(resumeWander: false);
  }

  void prioritizePawn(LivingPawnComponent p) {
    draftPawn(p);
    followFocused = false;
  }

  /// Order for the drafted pawn (tap or hold). Returns true if issued.
  ///
  /// Bed uses [HabitatJobKind.goTo] (cosmetic approach).
  bool issueOrder({
    required (int, int) cell,
    HabitatSelection? hit,
  }) {
    final pawn = draftedPawn;
    if (pawn == null) return false;

    final target = _orderTargetCell(pawn, hit, cell);
    if (target != null && !isCellAllowed(pawn, target.$1, target.$2)) {
      final snap = zoneFor(pawn);
      if (snap != null) {
        final near = HabitatZones.nearestAllowed(
          map,
          snap,
          (pawn.cellX, pawn.cellY),
        );
        if (near != null && near != target) {
          social.cancelActive(player: true);
          pawn.jobs.orderGoToCell(near);
          presence.playStub('order');
          return true;
        }
      }
      _rejectOrder(pawn, target);
      return false;
    }

    social.cancelActive(player: true);

    switch (hit) {
      case HabitatPawnSelection():
        return false;
      case HabitatPropSelection(:final prop):
        // Lights toggle in place; other uses route via furniture tags.
        if (FurnitureInteractions.isLight(prop.kind)) {
          prop.poweredOn = !prop.poweredOn;
          notifyMapVisualChanged(positive: prop.poweredOn);
          presence.playStub('order');
          return true;
        }
        final job = FurnitureInteractions.jobForUse(prop.kind) ??
            HabitatJobKind.goTo;
        if (job == HabitatJobKind.recreate) {
          pawn.jobs.orderRecreate(prop);
        } else if (job == HabitatJobKind.sleep) {
          // Sleep is a full job — approach then rest pose.
          pawn.jobs.orderGoToProp(prop, HabitatJobKind.sleep);
        } else {
          pawn.jobs.orderGoToProp(prop, job);
        }
        presence.playStub('order');
        return true;
      case HabitatCellSelection(:final cell):
        if (map.filthAt(cell.$1, cell.$2) > 0.12) {
          pawn.jobs.orderCleanCell(cell);
          presence.playStub('order');
          return true;
        }
        if (!map.isWalkable(cell.$1, cell.$2)) return false;
        pawn.jobs.orderGoToCell(cell);
        presence.playStub('order');
        return true;
      case null:
        if (map.filthAt(cell.$1, cell.$2) > 0.12) {
          pawn.jobs.orderCleanCell(cell);
          presence.playStub('order');
          return true;
        }
        if (!map.isWalkable(cell.$1, cell.$2)) return false;
        pawn.jobs.orderGoToCell(cell);
        presence.playStub('order');
        return true;
    }
  }

  /// Alias used by older call sites / tests.
  bool issueHoldOrder({
    required (int, int) cell,
    HabitatSelection? hit,
  }) =>
      issueOrder(cell: cell, hit: hit);

  void setFollowFocused(bool on) {
    followFocused = on;
    if (on && focusedPawn == null && pawns.isNotEmpty) {
      selectPawn(pawns.first);
    }
  }

  void applySelection(HabitatSelection? sel) {
    switch (sel) {
      case HabitatPawnSelection(:final pawn):
        inspectPawn(pawn);
      case HabitatPropSelection(:final prop):
        selectProp(prop);
      case HabitatCellSelection(:final cell):
        selectCell(cell);
      case null:
        clearSelection();
    }
  }

  /// Switch cosmetic locale. Session edits per map are kept in [_maps].
  void switchLocation(String id) {
    if (id == locationId) return;
    social.cancelActive(player: true);
    final next = _maps.putIfAbsent(id, () => HabitatLocations.create(id));
    locationId = id;
    embodiedRuntime.activeMapLocationId = id;
    map = next;
    editor.bind(next);
    grid?.rebindMap(next);
    final spawn = HabitatLocations.spawn(id);
    for (var i = 0; i < pawns.length; i++) {
      final p = pawns[i];
      p.rebindMap(next);
      final cell = _spawnCellForIndex(spawn, i);
      p.teleportToCell(cell);
    }
    bubbles.clear();
    clearSelection();
    hoverCell = null;
    _syncGhost();
    resetCamera();
    notifyMapVisualChanged();
    _refreshAtmosphere();
    if (beautyOverlayOn) beautyOverlay?.setWantVisible(true);
  }

  void refreshRoomStats() {
    final prevTight = roomStats.spaceTight;
    roomStats = HabitatRoomAnalyzer.analyze(map, locationId: locationId);
    _roomStatsGen++;
    if (roomStats.spaceTight && !prevTight) {
      spaceTightPulse = true;
    }
  }

  int get roomStatsGeneration => _roomStatsGen;

  void consumeSpaceTightPulse() {
    spaceTightPulse = false;
  }

  /// Play-mode broom: animated wave clears all filth on the current map.
  bool startSweepClean() {
    final sweep = sweepClean;
    if (sweep == null || sweep.active || !sceneReady) return false;
    social.cancelActive(player: true);
    sweep.start();
    presence.playStub('sweep_clean');
    return true;
  }

  bool get isSweepCleaning => sweepClean?.active ?? false;

  void setBeautyOverlay(bool on) {
    beautyOverlayOn = on;
    beautyOverlay?.setWantVisible(on);
  }

  void notifyMapVisualChanged({
    (int, int)? rippleAt,
    bool positive = true,
  }) {
    social.markDirty();
    refreshRoomStats();
    _refreshAtmosphere();
    beautyOverlay?.refreshField();
    if (rippleAt != null) {
      beautyOverlay?.addRipple(
        rippleAt.$1,
        rippleAt.$2,
        positive: positive,
      );
    }
    onMapsChanged?.call();
  }

  /// Snapshot of all locale maps for persistence.
  Map<String, HabitatMap> exportMaps() {
    _maps[locationId] = map;
    return {
      for (final e in _maps.entries) e.key: e.value,
    };
  }

  /// Restore layouts saved from a previous visit.
  void restoreWorld({
    required String locationId,
    required Map<String, HabitatMap> maps,
  }) {
    if (maps.isEmpty) return;
    _maps
      ..clear()
      ..addAll(maps);
    final id = _maps.containsKey(locationId) ? locationId : _maps.keys.first;
    final next = _maps[id]!;
    this.locationId = id;
    map = next;
    editor.bind(next);
    grid?.rebindMap(next);
    final spawn = HabitatLocations.spawn(id);
    for (var i = 0; i < pawns.length; i++) {
      final p = pawns[i];
      p.rebindMap(next);
      final cell = _spawnCellForIndex(spawn, i);
      p.teleportToCell(cell);
    }
    bubbles.clear();
    clearSelection();
    hoverCell = null;
    _syncGhost();
    if (sceneReady) {
      resetCamera();
      refreshRoomStats();
      _refreshAtmosphere();
      if (beautyOverlayOn) beautyOverlay?.setWantVisible(true);
    }
  }

  void _wirePawnJobs(LivingPawnComponent pawnComp) {
    pawnComp.jobs.onArrived = (job) {
      pushBubble(
        pawnComp,
        HabitatBubbleLines.forJobArrived(job, _rng),
        kind: job == HabitatJobKind.sleep
            ? HabitatBubbleKind.mote
            : HabitatBubbleKind.speech,
      );
    };
    pawnComp.jobs.onFinished = (job) {
      if (job == HabitatJobKind.recreate) {
        final kind = pawnComp.jobs.lastJoyKindFinished;
        if (kind != null) _markJoyUsed(kind);
      }
      _applyJobNeedSatisfaction(pawnComp.memberId, job);
    };
    pawnComp.jobs.onCleanCell = (_, _) {
      notifyMapVisualChanged(positive: true);
    };
  }

  void _applyJobNeedSatisfaction(String memberId, HabitatJobKind job) {
    final affordance = switch (job) {
      HabitatJobKind.sleep => HabitatAffordances.sleep,
      HabitatJobKind.sit => HabitatAffordances.sit,
      HabitatJobKind.goToTable => HabitatAffordances.goToTable,
      HabitatJobKind.recreate => HabitatAffordances.recreate,
      HabitatJobKind.clean => HabitatAffordances.clean,
      HabitatJobKind.wander || HabitatJobKind.goTo => HabitatAffordances.wander,
    };
    final def = AffordanceCatalog.get(affordance);
    if (def == null || def.satisfies.isEmpty) return;
    final current = embodied.ensure(memberId);
    embodied.put(
      embodiedRuntime.needs.applySatisfaction(
        state: current,
        satisfies: def.satisfies,
        observedAt: clocks.real.now().toUtc(),
      ),
    );
  }

  void _spawnRoster(List<ColonyMember> roster) {
    final spawn = HabitatLocations.spawn(locationId);
    for (var i = 0; i < roster.length; i++) {
      final member = roster[i];
      final cell = _spawnCellForIndex(spawn, i);
      final pawnComp = LivingPawnComponent(
        map: map,
        tileSize: tileSize,
        sprites: sprites!,
        startCell: cell,
        memberId: member.id,
        displayName: member.appearance.name,
        appearance: member.appearance.copy(),
      );
      _wirePawnJobs(pawnComp);
      embodiedRuntime.ensureIdentity(
        member.id,
        isPrimarySelf: member.isPlayer,
        kind: member.isPlayer ? PawnIdentityKind.self : PawnIdentityKind.resident,
      );
      embodied.ensure(
        member.id,
        presence: EmbodiedPresenceContext(
          roomRole: locationId,
          isHome: true,
        ),
      );
      pawns.add(pawnComp);
      world.add(pawnComp);
    }
  }

  /// Embodied state for inspect — never stored only on the Flame component.
  PawnEmbodiedState? embodiedFor(String memberId) => embodied[memberId];

  PawnEmbodiedState ensureEmbodied(String memberId) => embodied.ensure(
        memberId,
        presence: EmbodiedPresenceContext(roomRole: locationId),
      );

  (int, int) _spawnCellForIndex((int, int) base, int index) {
    final offsets = <(int, int)>[
      (0, 0),
      (1, 0),
      (-1, 0),
      (0, 1),
      (2, 0),
      (-2, 1),
      (1, 1),
      (-1, 1),
    ];
    final (dx, dy) = offsets[index % offsets.length];
    return _firstWalkableNear(base.$1 + dx, base.$2 + dy);
  }

  /// Rebuild pawns from roster (add/remove/edit cosmetics).
  void syncRoster(List<ColonyMember> roster) {
    if (sprites == null) return;
    final keep = <String>{for (final m in roster) m.id};
    final removing = [for (final p in pawns) if (!keep.contains(p.memberId)) p];
    for (final p in removing) {
      bubbles.removeWhere((b) => b.pawn == p);
      embodied.remove(p.memberId);
      p.removeFromParent();
      pawns.remove(p);
    }
    for (final m in roster) {
      final existing = pawnByMemberId(m.id);
      if (existing != null) {
        existing.appearance.copyFrom(m.appearance);
        existing.displayName = m.appearance.name;
        embodied.ensure(m.id);
      } else {
        final spawn = HabitatLocations.spawn(locationId);
        final cell = _spawnCellForIndex(spawn, pawns.length);
        final pawnComp = LivingPawnComponent(
          map: map,
          tileSize: tileSize,
          sprites: sprites!,
          startCell: cell,
          memberId: m.id,
          displayName: m.appearance.name,
          appearance: m.appearance.copy(),
        );
        _wirePawnJobs(pawnComp);
        embodied.ensure(
          m.id,
          presence: EmbodiedPresenceContext(roomRole: locationId),
        );
        pawns.add(pawnComp);
        world.add(pawnComp);
      }
    }
    if (focusedPawn == null || !pawns.contains(focusedPawn)) {
      focusedPawn = pawns.isEmpty ? null : pawns.first;
      for (final p in pawns) {
        p.drafted = false;
        p.selected = false;
      }
    } else {
      for (final p in pawns) {
        final focus = identical(p, focusedPawn);
        p.drafted = focus && p.drafted;
        p.selected = p.drafted;
      }
    }
  }

  LivingPawnComponent? pawnByMemberId(String id) {
    for (final p in pawns) {
      if (p.memberId == id) return p;
    }
    return null;
  }

  void setEditMode(bool on) {
    if (on) {
      editor.enter();
      clearSelection();
    } else {
      editor.exit();
      grid?.ghostProp = null;
    }
    _syncGhost();
  }

  void setHoverCell((int, int)? cell) {
    hoverCell = cell;
    _syncGhost();
  }

  void _syncGhost() {
    final g = grid;
    if (g == null) return;
    final cell = hoverCell;
    if (!editor.enabled || cell == null) {
      g.ghostProp = null;
      return;
    }
    g.ghostProp = editor.ghostAt(cell.$1, cell.$2);
    g.ghostValid = editor.ghostValidAt(cell.$1, cell.$2);
  }

  void ensurePawnWalkable() {
    for (final p in pawns) {
      if (!map.isWalkable(p.cellX, p.cellY)) {
        p.teleportToCell(_firstWalkableNear(p.cellX, p.cellY));
      }
    }
  }

  bool undoEdit() {
    if (!editor.undo()) return false;
    ensurePawnWalkable();
    clearSelection();
    _syncGhost();
    notifyMapVisualChanged(positive: false);
    return true;
  }

  void _handleEditTap(Vector2 canvasPos) {
    final worldPos = camera.globalToLocal(canvasPos);
    final cell = _cellAtWorld(worldPos);
    hoverCell = cell;
    if (editor.tool == HabitatEditTool.select) {
      final hit = _hitSelection(worldPos);
      if (hit is HabitatPropSelection || hit is HabitatCellSelection) {
        applySelection(hit);
      } else {
        clearSelection();
      }
    } else {
      final tool = editor.tool;
      if (tool == HabitatEditTool.zone) {
        applyZonePaint(cell.$1, cell.$2, erase: false);
      } else if (tool == HabitatEditTool.zoneErase) {
        applyZonePaint(cell.$1, cell.$2, erase: true);
      } else {
        final changed = editor.applyTap(cell.$1, cell.$2);
        if (changed) {
          ensurePawnWalkable();
          final positive = tool == HabitatEditTool.place ||
              tool == HabitatEditTool.floor ||
              tool == HabitatEditTool.wall ||
              tool == HabitatEditTool.door;
          notifyMapVisualChanged(
            rippleAt: cell,
            positive: positive && tool != HabitatEditTool.erase,
          );
        }
      }
      if (editor.tool == HabitatEditTool.move && editor.movingProp != null) {
        selectProp(editor.movingProp!);
      }
    }
    _syncGhost();
  }

  /// Play-mode tap (on tap-up): order while drafted, or soft-inspect.
  ///
  /// Draft requires **hold on the pawn**. Tap outside the map undrafts.
  /// When drafted, tap on a cell/prop **orders** (path line shows). Tap the
  /// drafted pawn again to release.
  void _handlePlayTap(Vector2 canvasPos) {
    final worldPos = camera.globalToLocal(canvasPos);
    final cell = _cellAtWorld(worldPos);
    hoverCell = cell;
    final hit = _hitSelection(worldPos);
    final drafted = draftedPawn;

    // Outside the habitat grid → deselect / undraft.
    if (hit == null || !map.inBounds(cell.$1, cell.$2)) {
      undraft(resumeWander: true);
      return;
    }

    switch (hit) {
      case HabitatPawnSelection(:final pawn):
        if (pawn.drafted) {
          undraft();
        } else {
          // Tap does not draft — hold on the pawn to select.
          if (drafted != null) undraft(resumeWander: true);
          inspectPawn(pawn);
          pushBubble(
            pawn,
            HabitatBubbleLines.forTap(_rng),
            kind: HabitatBubbleKind.speech,
          );
          presence.playStub('tap');
        }
      case HabitatPropSelection():
      case HabitatCellSelection():
        if (drafted != null) {
          final ok = issueOrder(cell: cell, hit: hit);
          if (!ok && hit is HabitatCellSelection) {
            // Non-walkable: keep draft, soft feedback.
            pushBubble(
              drafted,
              HabitatBubbleLines.forIdle(_rng),
              kind: HabitatBubbleKind.thought,
            );
          }
        } else {
          applySelection(hit);
        }
    }
  }

  /// Long-press: draft the pawn under the finger, or order when already drafted.
  void _handleHoldOrder(Vector2 canvasPos) {
    if (editor.enabled) return;
    _ignoreNextTapUp = true;
    final worldPos = camera.globalToLocal(canvasPos);
    final cell = _cellAtWorld(worldPos);
    final hit = _hitSelection(worldPos);

    if (hit is HabitatPawnSelection) {
      if (hit.pawn.drafted) {
        _handleContext(canvasPos);
      } else {
        draftPawn(hit.pawn);
        presence.playStub('tap');
      }
      return;
    }

    if (draftedPawn == null) {
      _handleContext(canvasPos);
      return;
    }

    final ordered = issueOrder(cell: cell, hit: hit);
    if (!ordered) {
      _handleContext(canvasPos);
    }
  }

  void _handleContext(Vector2 canvasPos) {
    if (editor.enabled) return;
    final worldPos = camera.globalToLocal(canvasPos);
    final cell = _cellAtWorld(worldPos);
    final hit = _hitSelection(worldPos);
    if (hit is HabitatPawnSelection) {
      draftPawn(hit.pawn);
    } else if (draftedPawn == null) {
      applySelection(hit);
    }
    onContextMenu?.call(
      selection: hit ?? selection,
      cell: cell,
      canvasPosition: Offset(canvasPos.x, canvasPos.y),
    );
  }

  @override
  bool containsLocalPoint(Vector2 point) => true;

  @override
  void onTapDown(TapDownEvent event) {
    // Paint tools need immediate feedback; play mode waits for tap-up so a
    // long-press order is not cancelled by a premature undraft.
    if (editor.enabled) {
      _handleEditTap(event.canvasPosition);
    }
  }

  @override
  void onTapUp(TapUpEvent event) {
    if (editor.enabled) return;
    if (_ignoreNextTapUp) {
      _ignoreNextTapUp = false;
      return;
    }
    _handlePlayTap(event.canvasPosition);
  }

  @visibleForTesting
  void debugPlayTap(Vector2 canvasPos) => _handlePlayTap(canvasPos);

  @visibleForTesting
  void debugHold(Vector2 canvasPos) => _handleHoldOrder(canvasPos);

  @override
  void onTapCancel(TapCancelEvent event) {
    _ignoreNextTapUp = false;
  }

  @override
  void onSecondaryTapUp(SecondaryTapUpEvent event) =>
      _handleContext(event.canvasPosition);

  @override
  void onLongPressStart(LongPressStartEvent event) {
    super.onLongPressStart(event);
    _handleHoldOrder(event.canvasPosition);
  }
}
