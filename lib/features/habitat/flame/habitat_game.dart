import 'dart:math' as math;

import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';

import '../application/colony_roster.dart';
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
  final List<HabitatBubble> bubbles = [];
  double _idleBubbleTimer = 0;

  /// Cosmetic room role + meters (V9.7).
  HabitatRoomStats roomStats = HabitatRoomStats.empty;

  /// One-shot cue for Space meter flash when the room is tight.
  bool spaceTightPulse = false;
  int _roomStatsGen = 0;

  /// Per-cell darkness + temperature (V9.11 / V9.12).
  List<double> darknessField = const [];
  List<double> climateField = const [];
  double? outdoorTemperatureC;

  /// Session clock for joy cooldowns (V9.10).
  double sessionTime = 0;
  final Map<String, double> recreateCooldownUntil = {};

  /// Per-pawn allowed cells — null/absent = unrestricted (V9.13).
  Map<String, Set<(int, int)>?> allowedZones = {};

  /// Red flash on rejected order: (x, y, age 0→1).
  (int, int, double)? zoneRejectFlash;

  late final HabitatSocialDirector social;

  double _headShakeT = 0;
  String? _socialPauseA;
  String? _socialPauseB;
  SocialEncounterPhase? _lastSocialPhase;

  double _idleAutonomyTimer = 0;
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
    );
  }

  void _refreshAtmosphere() {
    darknessField = HabitatLightField.compute(
      map,
      phase: presence.phase,
      locationId: locationId,
    );
    climateField = HabitatClimateField.compute(
      map,
      locationId: locationId,
      phase: presence.phase,
      outdoorC: outdoorTemperatureC,
    );
  }

  void setOutdoorTemperature(double? c) {
    outdoorTemperatureC = c;
    _refreshAtmosphere();
  }

  double get indoorTemperatureC => HabitatClimateField.indoorAverage(
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

  void cyclePropQuality(HabitatProp prop) {
    prop.quality = prop.quality.next();
    notifyMapVisualChanged(positive: true);
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
      if (p.kind == HabitatPropKinds.table) tables.add(p.origin);
      if (p.kind == HabitatPropKinds.gatheringSpot) spots.add(p.origin);
      if (p.kind == HabitatPropKinds.lamp) hasLamp = true;
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
    var hCell = hostCell;
    var gCell = guestCell;
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

  void _faceSocialPair(String aId, String bId) {
    final a = pawnByMemberId(aId);
    final b = pawnByMemberId(bId);
    if (a == null || b == null) return;
    a.facing = facingFromDelta(b.cellX - a.cellX, b.cellY - a.cellY);
    b.facing = facingFromDelta(a.cellX - b.cellX, a.cellY - b.cellY);
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
    presence.tick(dt);
    sessionTime += dt;
    _refreshAtmosphere();

    final prefer = _wanderPreferWeights();
    for (final p in pawns) {
      p.jobs.wander.preferBright = prefer;
      p.jobs.wander.allowedZone = zoneFor(p);
      p.jobs.allowedZone = zoneFor(p);
    }

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
      }
      _socialPauseA = _socialPauseB = null;
      _lastSocialPhase = null;
    }

    for (final b in bubbles) {
      b.age += dt;
    }
    bubbles.removeWhere((b) => b.done);

    _idleAutonomyTimer += dt;
    if (_idleAutonomyTimer >= 7) {
      _idleAutonomyTimer = 0;
      final socialIds = social.active == null
          ? const <String>{}
          : {social.active!.aId, social.active!.bId};
      for (final pawn in pawns) {
        if (pawn.drafted || pawn.jobs.kind != HabitatJobKind.wander) continue;
        if (pawn.isMoving) continue;
        if (socialIds.contains(pawn.memberId)) continue;
        if (_rng.nextDouble() < 0.35) {
          final dirty = _nearestDirtyCell((pawn.cellX, pawn.cellY));
          if (dirty != null) {
            pawn.jobs.orderCleanCell(dirty);
            continue;
          }
        }
        if (_rng.nextDouble() < 0.28) {
          final joy = _pickJoyStation();
          if (joy != null) {
            pawn.jobs.orderRecreate(joy);
          }
        }
      }
    }

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
      // Outdoor moonlight peaks ~0.48 — never "too dark". Indoor night
      // without lamps is ~0.88–0.95.
      if (d >= HabitatLightField.tooDarkThreshold) {
        final t = (_darkIdleTimer[pawn] ?? 0) + dt;
        _darkIdleTimer[pawn] = t;
        final readyAt = _darkCommentReadyAt[pawn] ?? 0;
        if (t >= 2.8 && sessionTime >= readyAt) {
          pushBubble(
            pawn,
            HabitatBubbleLines.forTooDark(_rng),
            kind: HabitatBubbleKind.thought,
          );
          // Long cooldown — complain rarely, not every linger.
          _darkCommentReadyAt[pawn] =
              sessionTime + 80 + _rng.nextDouble() * 50;
          _darkIdleTimer[pawn] = 0;
        }
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
        final job = switch (prop.kind) {
          'chair' => HabitatJobKind.sit,
          'table' => HabitatJobKind.goToTable,
          'bed' => HabitatJobKind.goTo,
          _ when HabitatPropKinds.isRecreateTarget(prop.kind) =>
            HabitatJobKind.recreate,
          _ => HabitatJobKind.goTo,
        };
        if (job == HabitatJobKind.recreate) {
          pawn.jobs.orderRecreate(prop);
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
    };
    pawnComp.jobs.onCleanCell = (_, __) {
      notifyMapVisualChanged(positive: true);
    };
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
      pawns.add(pawnComp);
      world.add(pawnComp);
    }
  }

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
      p.removeFromParent();
      pawns.remove(p);
    }
    for (final m in roster) {
      final existing = pawnByMemberId(m.id);
      if (existing != null) {
        existing.appearance.copyFrom(m.appearance);
        existing.displayName = m.appearance.name;
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
