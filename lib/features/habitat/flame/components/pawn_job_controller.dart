import 'dart:math' as math;



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



/// Manual jobs — UI orders only, no agenda/domain yet.

class PawnJobController {

  PawnJobController({

    required this.pawn,

    required this.map,

    math.Random? rng,

    this.onArrived,

    this.onFinished,

    this.onCleanCell,

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



  HabitatJobKind kind = HabitatJobKind.wander;

  List<(int, int)> _path = [];

  bool _arrivedPose = false;

  double _poseLeft = 0;

  bool _arrivalNotified = false;

  (int, int)? _cleanTarget;

  HabitatProp? _recreateProp;

  /// Last joy prop kind finished (V9.10 cooldown).
  String? lastJoyKindFinished;

  /// Lateral sweep phase for clean animation.

  int _cleanSweep = 0;

  double _cleanSweepT = 0;



  /// Optional allowed zone (V9.13).
  Set<(int, int)>? allowedZone;

  /// Remaining A* cells for the current order (excludes the pawn's current cell).

  List<(int, int)> get remainingPath => List.unmodifiable(_path);



  String get statusLabel => switch (kind) {

        HabitatJobKind.wander => 'Passeando',

        HabitatJobKind.sleep => _arrivedPose ? 'Descansando' : 'Indo dormir',

        HabitatJobKind.sit => _arrivedPose ? 'Sentado' : 'Indo sentar',

        HabitatJobKind.goToTable =>

          _arrivedPose ? 'Na mesa' : 'Indo à mesa',

        HabitatJobKind.goTo => _arrivedPose ? 'Chegou' : 'A caminho',

        HabitatJobKind.clean =>

          _arrivedPose ? 'Limpando' : 'Indo limpar',

        HabitatJobKind.recreate => _arrivedPose ? 'Recreando' : 'Indo recrear',

      };



  void order(HabitatJobKind job) {

    if (job == HabitatJobKind.wander) {

      _clearJob();

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

    final prop = map.propByKind(propKind);

    if (prop == null) return;

    orderGoToProp(prop, job);

  }



  void orderGoToProp(HabitatProp prop, HabitatJobKind job) {

    final from = (pawn.cellX, pawn.cellY);

    final target = approachCell(map, prop, from);

    if (target == null) return;

    _recreateProp = job == HabitatJobKind.recreate ? prop : null;

    _beginPath(job, target);

  }



  bool _cellAllowed(int x, int y) =>
      allowedZone == null || allowedZone!.contains((x, y));

  void orderGoToCell((int, int) cell) {
    if (!map.isWalkable(cell.$1, cell.$2)) return;
    if (!_cellAllowed(cell.$1, cell.$2)) return;
    _beginPath(HabitatJobKind.goTo, cell);
  }

  void orderCleanCell((int, int) cell) {
    if (!map.isWalkable(cell.$1, cell.$2)) return;
    if (!_cellAllowed(cell.$1, cell.$2)) return;

    if (map.filthAt(cell.$1, cell.$2) <= 0.01) return;

    _cleanTarget = cell;

    _beginPath(HabitatJobKind.clean, cell);

  }



  void orderRecreate(HabitatProp prop) {

    orderGoToProp(prop, HabitatJobKind.recreate);

  }



  void _beginPath(HabitatJobKind job, (int, int) target) {

    final from = (pawn.cellX, pawn.cellY);

    final path = findPath(
      map: map,
      from: from,
      to: target,
      allowed: allowedZone == null ? null : (x, y) => _cellAllowed(x, y),
    );

    kind = job;

    _path = List.of(path);

    _arrivedPose = false;

    _poseLeft = 0;

    _arrivalNotified = false;

    _cleanSweep = 0;

    _cleanSweepT = 0;

    pawn.poseOffsetX = 0;

    wander.pause();

  }



  void _clearJob() {

    _path = [];

    _arrivedPose = false;

    _poseLeft = 0;

    _arrivalNotified = false;

    _cleanTarget = null;

    _recreateProp = null;

    _cleanSweep = 0;

    _cleanSweepT = 0;

    pawn.poseOffsetX = 0;

    wander.resume();

  }



  HabitatProp? _propForKind() {

    if (kind == HabitatJobKind.recreate) return _recreateProp;

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



  void update(double dt) {

    if (kind == HabitatJobKind.wander) {

      wander.update(dt);

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

        _clearJob();

        kind = HabitatJobKind.wander;

        onFinished?.call(finished);

      }

      return;

    }



    if (pawn.isMoving) return;



    if (_path.isEmpty) {

      _arrivedPose = true;

      _poseLeft = switch (kind) {

        HabitatJobKind.sleep => 4.0,

        HabitatJobKind.sit => 3.0,

        HabitatJobKind.goToTable => 2.5,

        HabitatJobKind.goTo => 0.8,

        HabitatJobKind.clean => 1.8,

        HabitatJobKind.recreate => 4.0 + wander.rng.nextDouble() * 1.5,

        HabitatJobKind.wander => 0,

      };

      if (kind == HabitatJobKind.clean) {

        _cleanSweep = 0;

        _cleanSweepT = 0;

        _poseLeft = 1.8;

      }

      if (kind != HabitatJobKind.goTo) {

        pawn.facing = HabitatFacing.south;

      }

      if (!_arrivalNotified) {

        _arrivalNotified = true;

        onArrived?.call(kind);

      }

      return;

    }



    final next = _path.removeAt(0);

    final dx = next.$1 - pawn.cellX;

    final dy = next.$2 - pawn.cellY;

    if (!pawn.tryStep(dx, dy)) {

      if (kind == HabitatJobKind.goTo || kind == HabitatJobKind.clean) {

        _clearJob();

        kind = HabitatJobKind.wander;

        return;

      }

      final prop = _propForKind();

      if (prop == null) {

        _clearJob();

        kind = HabitatJobKind.wander;

        return;

      }

      final target = approachCell(map, prop, (pawn.cellX, pawn.cellY));

      if (target == null) {

        _clearJob();

        kind = HabitatJobKind.wander;

        return;

      }

      _path = findPath(
        map: map,
        from: (pawn.cellX, pawn.cellY),
        to: target,
        allowed: allowedZone == null ? null : (x, y) => _cellAllowed(x, y),
      );

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

    // Lateral bob 4 px × 3 sweeps.

    pawn.poseOffsetX = math.sin(_cleanSweepT / sweepDur * math.pi) * 4 *

        (_cleanSweep.isEven ? 1 : -1);

  }

}


