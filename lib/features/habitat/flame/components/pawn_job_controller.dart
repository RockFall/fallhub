import 'dart:math' as math;

import '../../simulation/embodied/affordance_catalog.dart';
import '../../simulation/identity/identity.dart';
import '../../simulation/microbehavior/microbehavior.dart';
import '../furniture/furniture_interactions.dart';
import '../habitat_map.dart';
import '../pathfinding.dart';
import 'living_pawn_component.dart';
import 'wander_behavior.dart';

enum HabitatJobKind {
  wander,
  sleep,
  sit,
  goToTable,
  goTo,
  clean,
  recreate,
}

typedef HabitatJobEvent = void Function(HabitatJobKind job);

HabitatFacing habitatFacingFromMicro(MicroFacing f) => switch (f) {
      MicroFacing.south => HabitatFacing.south,
      MicroFacing.east => HabitatFacing.east,
      MicroFacing.north => HabitatFacing.north,
      MicroFacing.west => HabitatFacing.west,
    };

MicroFacing microFacingFromHabitat(HabitatFacing f) => switch (f) {
      HabitatFacing.south => MicroFacing.south,
      HabitatFacing.east => MicroFacing.east,
      HabitatFacing.north => MicroFacing.north,
      HabitatFacing.west => MicroFacing.west,
    };

String affordanceIdForJob(HabitatJobKind job) => switch (job) {
      HabitatJobKind.sleep => HabitatAffordances.sleep,
      HabitatJobKind.sit => HabitatAffordances.sit,
      HabitatJobKind.goToTable => HabitatAffordances.goToTable,
      HabitatJobKind.recreate => HabitatAffordances.recreate,
      HabitatJobKind.clean => HabitatAffordances.clean,
      HabitatJobKind.goTo => HabitatAffordances.wander,
      HabitatJobKind.wander => HabitatAffordances.wander,
    };

/// Manual jobs — UI orders + arrival choreography (MD 10 R1/R4/R7/R8).
class PawnJobController {
  PawnJobController({
    required this.pawn,
    required this.map,
    math.Random? rng,
    this.onArrived,
    this.onFinished,
    this.onCleanCell,
    this.nowSeconds,
  }) : wander = WanderBehavior(
          pawn: pawn,
          map: map,
          rng: rng ?? math.Random(),
        );

  final LivingPawnComponent pawn;
  HabitatMap map;
  final WanderBehavior wander;
  HabitatJobEvent? onArrived;
  HabitatJobEvent? onFinished;
  void Function(int x, int y)? onCleanCell;

  /// Session/sim clock for choreography (defaults to 0-based local).
  double Function()? nowSeconds;

  HabitatJobKind kind = HabitatJobKind.wander;
  List<(int, int)> _path = [];
  bool _arrivedPose = false;
  double _poseLeft = 0;
  bool _arrivalNotified = false;
  (int, int)? _cleanTarget;
  HabitatProp? _recreateProp;
  HabitatProp? _targetProp;

  /// Partner cell for social facing settle (optional).
  (int, int)? partnerCell;

  /// Soft room interest (window / TV / table center).
  (int, int)? roomInterestCell;

  /// Last joy prop kind finished (V9.10 cooldown).
  String? lastJoyKindFinished;

  int _cleanSweep = 0;
  double _cleanSweepT = 0;

  /// Soft occupancy / door boards owned by HabitatGame (Block B).
  PropOccupancyBoard? occupancy;
  DoorReservationBoard? doors;
  StationQueueBoard? queues;

  /// Optional path cost / preference (R12/R17).
  double Function(int x, int y)? cellCost;
  RoutePreferenceContext? routePreference;

  /// Other pawn cells for crowding / slots (refreshed by game).
  List<(int, int)> peerCells = const [];
  List<PersonalSpaceAgent> peerAgents = const [];

  /// Avoidance wait leftover (R13).
  double avoidanceWaitLeft = 0;
  int avoidanceOscillation = 0;

  /// Last approach slot debug.
  String? lastSlotDebug;

  /// Room id for entry scan (R18).
  String? lastRoomId;
  RoomEntryScan? roomScan;

  Set<(int, int)>? allowedZone;

  int _initialPathLength = 0;
  (int, int)? _claimedApproachCell;

  set wanderSpeedScale(double v) => wander.speedScale = v;
  double get wanderSpeedScale => wander.speedScale;

  List<(int, int)> get remainingPath => List.unmodifiable(_path);

  bool get isInArrivalPipeline {
    final phase = pawn.micro.arrival.state.phase;
    return phase == ArrivalPhase.settling ||
        phase == ArrivalPhase.anticipating ||
        phase == ArrivalPhase.approaching;
  }

  bool get isPosing => _arrivedPose;

  bool willTraverseDoor((int, int) doorCell) {
    if (_path.isNotEmpty && _path.first == doorCell) return true;
    if (_path.contains(doorCell)) return true;
    return wander.willTraverseDoor(doorCell);
  }

  String get statusLabel => switch (kind) {
        HabitatJobKind.wander => 'Passeando',
        HabitatJobKind.sleep => _statusForPose('Descansando', 'Indo dormir'),
        HabitatJobKind.sit => _statusForPose('Sentado', 'Indo sentar'),
        HabitatJobKind.goToTable => _statusForPose('Na mesa', 'Indo à mesa'),
        HabitatJobKind.goTo => _statusForPose('Chegou', 'A caminho'),
        HabitatJobKind.clean => _statusForPose('Limpando', 'Indo limpar'),
        HabitatJobKind.recreate => _statusForPose('Recreando', 'Indo recrear'),
      };

  String _statusForPose(String arrived, String going) {
    final phase = pawn.micro.arrival.state.phase;
    if (phase == ArrivalPhase.settling) return 'Orientando';
    if (phase == ArrivalPhase.anticipating) return 'Preparando';
    if (_arrivedPose) return arrived;
    return going;
  }

  double _now() => nowSeconds?.call() ?? 0;

  void order(HabitatJobKind job) {
    if (job == HabitatJobKind.wander) {
      cancelArrivalAndJobs();
      kind = HabitatJobKind.wander;
      return;
    }
    if (job == HabitatJobKind.goTo ||
        job == HabitatJobKind.clean ||
        job == HabitatJobKind.recreate) {
      return;
    }

    final propKind = switch (job) {
      HabitatJobKind.sleep => 'bed',
      HabitatJobKind.sit => 'chair',
      HabitatJobKind.goToTable => 'table',
      HabitatJobKind.wander ||
      HabitatJobKind.goTo ||
      HabitatJobKind.clean ||
      HabitatJobKind.recreate =>
        '',
    };
    HabitatProp? prop;
    if (job == HabitatJobKind.recreate) {
      for (final p in map.props) {
        if (FurnitureInteractions.isJoy(p.kind)) {
          prop = p;
          break;
        }
      }
    } else {
      prop = map.propByKind(propKind);
    }
    if (prop == null) return;
    orderGoToProp(prop, job);
  }

  void orderGoToProp(HabitatProp prop, HabitatJobKind job) {
    final from = (pawn.cellX, pawn.cellY);
    if (occupancy != null && !occupancy!.isPropFree(prop.id, forPawn: pawn.memberId)) {
      return;
    }
    final lookAt = _lookAtForProp(prop);
    final target = approachCell(
      map,
      prop,
      from,
      options: ApproachOptions(
        lookAtCell: lookAt,
        propFacing: microFacingFromHabitat(
          switch (prop.facing) {
            HabitatPropFacing.south => HabitatFacing.south,
            HabitatPropFacing.east => HabitatFacing.east,
            HabitatPropFacing.north => HabitatFacing.north,
            HabitatPropFacing.west => HabitatFacing.west,
          },
        ),
        occupiedCells: occupancy?.occupiedCells(exceptPawn: pawn.memberId) ?? {},
        pawnCells: peerCells,
        personalSpaceCostAt: (x, y) => PersonalSpace.costAt(
          cell: (x, y),
          agents: peerAgents,
          selfId: pawn.memberId,
          socialStyle: pawn.micro.profile?.socialStyle ?? SocialStyle.balanced,
          groupActivity: partnerCell != null,
        ),
        activityGroupCells: partnerCell != null ? [partnerCell!] : const [],
        pawnId: pawn.memberId,
      ),
    );
    if (target == null) return;
    lastSlotDebug = 'slot@${target.$1},${target.$2}';
    _recreateProp = job == HabitatJobKind.recreate ? prop : null;
    _targetProp = prop;
    occupancy?.tryClaimProp(prop.id, pawn.memberId);
    occupancy?.tryClaimCell(target, pawn.memberId);
    _claimedApproachCell = target;
    _beginPath(job, target, urgent: false);
  }

  bool _cellAllowed(int x, int y) =>
      allowedZone == null || allowedZone!.contains((x, y));

  void orderGoToCell((int, int) cell, {bool urgent = true}) {
    if (!map.isWalkable(cell.$1, cell.$2)) return;
    if (!_cellAllowed(cell.$1, cell.$2)) return;
    _targetProp = null;
    _beginPath(HabitatJobKind.goTo, cell, urgent: urgent);
  }

  void orderCleanCell((int, int) cell) {
    if (!map.isWalkable(cell.$1, cell.$2)) return;
    if (!_cellAllowed(cell.$1, cell.$2)) return;
    if (map.filthAt(cell.$1, cell.$2) <= 0.01) return;
    _cleanTarget = cell;
    _targetProp = null;
    _beginPath(HabitatJobKind.clean, cell, urgent: false);
  }

  void orderRecreate(HabitatProp prop) {
    orderGoToProp(prop, HabitatJobKind.recreate);
  }

  void _beginPath(HabitatJobKind job, (int, int) target, {required bool urgent}) {
    final from = (pawn.cellX, pawn.cellY);
    final path = findPreferredPath(
      map: map,
      from: from,
      to: target,
      allowed: allowedZone == null ? null : (x, y) => _cellAllowed(x, y),
      preference: routePreference,
    );
    kind = job;
    _path = List.of(path);
    _arrivedPose = false;
    _poseLeft = 0;
    _arrivalNotified = false;
    _cleanSweep = 0;
    _cleanSweepT = 0;
    pawn.poseOffsetX = 0;
    pawn.micro.urgentLocomotion = urgent;
    _initialPathLength = _path.length;
    pawn.micro.lastPathLengthHint = _initialPathLength;
    pawn.micro.arrival.markApproaching(
      affordanceId: affordanceIdForJob(job),
      propId: _targetProp?.id,
    );
    // Look at interaction target while walking (does not interrupt path).
    final now = _now();
    if (_targetProp != null) {
      pawn.micro.attention.lookAt(
        reason: AttentionReason.interactionTarget,
        now: now,
        entityId: _targetProp!.id,
        cellX: _targetProp!.origin.$1,
        cellY: _targetProp!.origin.$2,
      );
    } else {
      pawn.micro.attention.lookAt(
        reason: AttentionReason.interactionTarget,
        now: now,
        cellX: target.$1,
        cellY: target.$2,
      );
    }
    wander.pause();
  }

  /// Draft cancel / wander — consistent posture + free reservation (R4/R7).
  void cancelArrivalAndJobs() {
    final now = _now();
    pawn.micro.arrival.cancel(now: now);
    pawn.micro.posture.requestCancel(now: now, force: true);
    pawn.micro.microIdle.interrupt();
    _releaseClaims();
    doors?.releasePawn(pawn.memberId);
    queues?.leaveAll(pawn.memberId);
    _clearJob();
  }

  void _releaseClaims() {
    final prop = _targetProp;
    if (prop != null) {
      occupancy?.releaseProp(prop.id, pawnId: pawn.memberId);
    }
    final cell = _claimedApproachCell;
    if (cell != null) {
      occupancy?.releaseCell(cell, pawnId: pawn.memberId);
    }
    occupancy?.releasePawn(pawn.memberId);
    _claimedApproachCell = null;
  }

  void _clearJob() {
    _path = [];
    _arrivedPose = false;
    _poseLeft = 0;
    _arrivalNotified = false;
    _cleanTarget = null;
    _recreateProp = null;
    _targetProp = null;
    _cleanSweep = 0;
    _cleanSweepT = 0;
    pawn.poseOffsetX = 0;
    pawn.micro.urgentLocomotion = false;
    _initialPathLength = 0;
    avoidanceWaitLeft = 0;
    pawn.micro.arrival.finish();
    wander.resume();
  }

  HabitatProp? _propForKind() {
    if (kind == HabitatJobKind.recreate) return _recreateProp;
    if (_targetProp != null) return _targetProp;
    final propKind = switch (kind) {
      HabitatJobKind.sleep => 'bed',
      HabitatJobKind.sit => 'chair',
      HabitatJobKind.goToTable => 'table',
      HabitatJobKind.wander ||
      HabitatJobKind.goTo ||
      HabitatJobKind.clean ||
      HabitatJobKind.recreate =>
        null,
    };
    if (propKind == null) return null;
    return map.propByKind(propKind);
  }

  (int, int)? _affordanceFocusCell() {
    // Seat/bed jobs: don't stare into the prop center — seat facing wins (R1).
    if (kind == HabitatJobKind.sit ||
        kind == HabitatJobKind.sleep ||
        kind == HabitatJobKind.goToTable ||
        kind == HabitatJobKind.recreate) {
      return _lookAtForProp(_propForKind());
    }
    final prop = _propForKind();
    if (prop != null) {
      final (ox, oy) = prop.origin;
      final (w, h) = prop.size;
      return (ox + w ~/ 2, oy + h ~/ 2);
    }
    if (kind == HabitatJobKind.clean && _cleanTarget != null) {
      return _cleanTarget;
    }
    return null;
  }

  (int, int)? _lookAtForProp(HabitatProp? prop) {
    if (prop == null) return null;
    final orient = _seatOrientation(prop);
    return orient?.lookAtCell;
  }

  SeatOrientationResult? _seatOrientation(HabitatProp prop) {
    final tags = <String>{};
    if (FurnitureInteractions.isTable(prop.kind)) tags.add('table');
    if (prop.kind.contains('tv')) tags.add('tv');
    if (prop.kind.contains('window')) tags.add('window');
    final tagCells = <String, List<(int, int)>>{};
    for (final p in map.props) {
      final c = (
        p.origin.$1 + p.size.$1 ~/ 2,
        p.origin.$2 + p.size.$2 ~/ 2,
      );
      if (p.kind.contains('tv')) {
        tagCells.putIfAbsent('tv', () => []).add(c);
      }
      if (p.kind.contains('window')) {
        tagCells.putIfAbsent('window', () => []).add(c);
      }
      if (FurnitureInteractions.isTable(p.kind)) {
        tagCells.putIfAbsent('table', () => []).add(c);
      }
    }
    (int, int)? tableCenter;
    final tables = tagCells['table'];
    if (tables != null && tables.isNotEmpty) tableCenter = tables.first;

    return SeatOrientationResolver.resolve(
      SeatOrientationContext(
        seatCell: (pawn.cellX, pawn.cellY),
        propFacing: microFacingFromHabitat(
          switch (prop.facing) {
            HabitatPropFacing.south => HabitatFacing.south,
            HabitatPropFacing.east => HabitatFacing.east,
            HabitatPropFacing.north => HabitatFacing.north,
            HabitatPropFacing.west => HabitatFacing.west,
          },
        ),
        propKind: prop.kind,
        tags: tags,
        targetTagCells: tagCells,
        tableCenter: tableCenter,
        roomCenter: roomInterestCell ??
            (map.width ~/ 2, map.height ~/ 2),
        conversationCells: partnerCell != null ? [partnerCell!] : const [],
      ),
    );
  }

  MicroFacing? _seatFacing() {
    final prop = _propForKind();
    if (prop == null) return null;
    final orient = _seatOrientation(prop);
    if (orient != null) return orient.facing;
    return microFacingFromHabitat(
      switch (prop.facing) {
        HabitatPropFacing.south => HabitatFacing.south,
        HabitatPropFacing.east => HabitatFacing.east,
        HabitatPropFacing.north => HabitatFacing.north,
        HabitatPropFacing.west => HabitatFacing.west,
      },
    );
  }

  void update(double dt) {
    final now = _now();
    pawn.micro.attention.tick(now);
    pawn.micro.posture.tick(now);
    doors?.tick(now);

    if (avoidanceWaitLeft > 0) {
      avoidanceWaitLeft = (avoidanceWaitLeft - dt).clamp(0.0, 10.0);
      return;
    }

    if (kind == HabitatJobKind.wander) {
      wander.update(dt);
      return;
    }

    // Arrival choreography before pose (R7).
    final arrPhase = pawn.micro.arrival.state.phase;
    if (arrPhase == ArrivalPhase.settling ||
        arrPhase == ArrivalPhase.anticipating) {
      final facingDue = pawn.micro.arrival.takeFacingIfDue(now);
      if (facingDue != null) {
        pawn.facing = habitatFacingFromMicro(facingDue.facing);
      }
      if (pawn.micro.arrival.tick(now)) {
        _startInteractionPose(now);
      }
      return;
    }

    if (_arrivedPose) {
      if (kind == HabitatJobKind.clean) {
        _updateCleanPose(dt);
        return;
      }
      _poseLeft -= dt;
      if (_poseLeft <= 0) {
        final finished = kind;
        if (finished == HabitatJobKind.recreate && _recreateProp != null) {
          lastJoyKindFinished = _recreateProp!.kind;
        }
        final prop = _targetProp ?? _recreateProp;
        final sat = finished == HabitatJobKind.sit ||
            finished == HabitatJobKind.goToTable ||
            (finished == HabitatJobKind.recreate &&
                prop != null &&
                FurnitureInteractions.isSit(prop.kind));
        if (sat) {
          pawn.micro.posture.beginStand(now: now);
        } else if (finished == HabitatJobKind.sleep) {
          pawn.micro.posture.beginRise(now: now);
        }
        _releaseClaims();
        doors?.releasePawn(pawn.memberId);
        _clearJob();
        kind = HabitatJobKind.wander;
        onFinished?.call(finished);
      }
      return;
    }

    if (pawn.isMoving) return;

    if (_path.isEmpty) {
      _beginArrivalSettle(now);
      return;
    }

    // Keep easing based on original trip length (R6).
    pawn.micro.lastPathLengthHint = _initialPathLength;
    final next = _path.first;
    final dx = next.$1 - pawn.cellX;
    final dy = next.$2 - pawn.cellY;

    // Door etiquette (R14): claim or wait beside door.
    if (map.door.cell == next || map.doorBlocksStep(next.$1, next.$2)) {
      final doorId = 'door:${map.door.cell.$1},${map.door.cell.$2}';
      final claim = doors?.tryClaim(
        doorId: doorId,
        pawnId: pawn.memberId,
        direction: (dx.sign, dy.sign),
        now: now,
      );
      if (claim == null && doors != null) {
        final wait = DoorReservationBoard.pickWaitSpot(
          doorCell: map.door.cell,
          from: (pawn.cellX, pawn.cellY),
          toward: next,
          isWalkable: map.isWalkable,
          occupied: {
            for (final c in peerCells) c,
          },
        );
        if (wait != null && wait != (pawn.cellX, pawn.cellY)) {
          final wdx = wait.$1 - pawn.cellX;
          final wdy = wait.$2 - pawn.cellY;
          if ((wdx.abs() + wdy.abs()) == 1) {
            pawn.tryStep(wdx, wdy);
          }
        }
        map.door.requestOpen();
        // Glance at the pawn holding the door.
        final holder = doors?.reservationFor(doorId);
        if (holder != null) {
          pawn.micro.attention.lookAt(
            reason: AttentionReason.passingPawn,
            now: now,
            entityId: holder.pawnId,
            holdOverride: 0.6,
          );
        }
        return;
      }
      doors?.refresh(doorId, pawn.memberId, now);
      map.door.requestOpen();
    }

    _path.removeAt(0);
    if (!pawn.tryStep(dx, dy)) {
      if (map.doorBlocksStep(next.$1, next.$2)) {
        map.door.requestOpen();
        _path.insert(0, next);
        return;
      }
      if (kind == HabitatJobKind.goTo || kind == HabitatJobKind.clean) {
        cancelArrivalAndJobs();
        kind = HabitatJobKind.wander;
        return;
      }
      final prop = _propForKind();
      if (prop == null) {
        cancelArrivalAndJobs();
        kind = HabitatJobKind.wander;
        return;
      }
      final target = approachCell(
        map,
        prop,
        (pawn.cellX, pawn.cellY),
        options: ApproachOptions(
          lookAtCell: _lookAtForProp(prop),
          occupiedCells:
              occupancy?.occupiedCells(exceptPawn: pawn.memberId) ?? {},
          pawnCells: peerCells,
          pawnId: pawn.memberId,
        ),
      );
      if (target == null) {
        cancelArrivalAndJobs();
        kind = HabitatJobKind.wander;
        return;
      }
      _path = findPreferredPath(
        map: map,
        from: (pawn.cellX, pawn.cellY),
        to: target,
        allowed: allowedZone == null ? null : (x, y) => _cellAllowed(x, y),
        preference: routePreference,
      );
      _initialPathLength = _path.length;
      pawn.micro.lastPathLengthHint = _initialPathLength;
    } else if (map.door.cell != (pawn.cellX, pawn.cellY) &&
        !_path.contains(map.door.cell)) {
      doors?.releasePawn(pawn.memberId);
    }
  }

  void _beginArrivalSettle(double now) {
    final affordance = affordanceIdForJob(kind);
    final facing = pawn.micro.resolveArrivalFacing(
      FacingSettleContext(
        pawnCell: (pawn.cellX, pawn.cellY),
        lastFacing: microFacingFromHabitat(pawn.facing),
        affordanceTargetCell: _affordanceFocusCell(),
        partnerCell: partnerCell,
        seatFacing: (kind == HabitatJobKind.sit ||
                kind == HabitatJobKind.goToTable ||
                kind == HabitatJobKind.sleep ||
                kind == HabitatJobKind.recreate)
            ? _seatFacing()
            : null,
        roomInterestCell: roomInterestCell,
        attention: pawn.micro.attention.current,
        settleDelayUnit: HabitatRng.unit(pawn.memberId, 'settle', kind.name),
        now: now,
      ),
    );
    pawn.micro.arrival.onPathArrived(
      now: now,
      facing: facing,
      affordanceId: affordance,
      propId: _targetProp?.id,
      anticipation: pawn.micro.anticipationFor(affordance),
      pawnId: pawn.memberId,
    );
  }

  void _startInteractionPose(double now) {
    final poseSeconds = switch (kind) {
      HabitatJobKind.sleep => 4.0,
      HabitatJobKind.sit => 3.0,
      HabitatJobKind.goToTable => 2.5,
      HabitatJobKind.goTo => 0.8,
      HabitatJobKind.clean => 1.8,
      HabitatJobKind.recreate => 4.0 + wander.rng.nextDouble() * 1.5,
      HabitatJobKind.wander => 0.0,
    };

    // Posture transitions (R4) — sit only for true seats.
    final prop = _targetProp ?? _recreateProp;
    if (kind == HabitatJobKind.sit || kind == HabitatJobKind.goToTable) {
      pawn.micro.posture.beginSit(now: now, seatPropId: prop?.id);
    } else if (kind == HabitatJobKind.recreate &&
        prop != null &&
        FurnitureInteractions.isSit(prop.kind)) {
      pawn.micro.posture.beginSit(now: now, seatPropId: prop.id);
    } else if (kind == HabitatJobKind.sleep) {
      pawn.micro.posture.beginLie(now: now, bedPropId: prop?.id);
    }

    pawn.micro.arrival.beginInteracting(now: now, poseSeconds: poseSeconds);
    _arrivedPose = true;
    _poseLeft = poseSeconds;
    if (kind == HabitatJobKind.clean) {
      _cleanSweep = 0;
      _cleanSweepT = 0;
      _poseLeft = 1.8;
    }
    if (!_arrivalNotified) {
      _arrivalNotified = true;
      onArrived?.call(kind);
    }
  }

  void _updateCleanPose(double dt) {
    _cleanSweepT += dt;
    const sweepDur = 0.55;
    if (_cleanSweepT >= sweepDur) {
      _cleanSweepT = 0;
      _cleanSweep++;
    }
    if (_cleanSweep >= 3) {
      final t = _cleanTarget;
      if (t != null) {
        map.cleanCell(t.$1, t.$2);
        onCleanCell?.call(t.$1, t.$2);
      }
      final finished = kind;
      _clearJob();
      kind = HabitatJobKind.wander;
      onFinished?.call(finished);
      return;
    }
    pawn.poseOffsetX = math.sin(_cleanSweepT / sweepDur * math.pi) *
        4 *
        (_cleanSweep.isEven ? 1 : -1);
  }
}
