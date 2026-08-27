/// Logical stateful object flags (MD 10 R23–R24, R28–R29).
enum ObjectLogicState {
  open,
  closed,
  active,
  inUse,
  idle,
}

enum ObjectWearVisual {
  pristine,
  used,
  worn,
}

class ObjectTrace {
  ObjectTrace({
    required this.key,
    required this.expiresAt,
    this.value = 1,
  });

  final String key;
  double expiresAt;
  double value;

  bool isActive(double now) => now < expiresAt && value > 0;
}

class StatefulObjectRecord {
  StatefulObjectRecord({
    required this.id,
    this.state = ObjectLogicState.idle,
    this.wear = ObjectWearVisual.pristine,
    this.usageCount = 0,
    this.homeSlotId,
    this.homeContainerId,
    this.clutterOffsetX = 0,
    this.clutterOffsetY = 0,
    this.openPage,
    this.preferredByPawnId,
  });

  final String id;
  ObjectLogicState state;
  ObjectWearVisual wear;
  int usageCount;
  String? homeSlotId;
  String? homeContainerId;
  double clutterOffsetX;
  double clutterOffsetY;
  int? openPage;
  String? preferredByPawnId;
  final List<ObjectTrace> traces = [];

  void tick(double now) {
    traces.removeWhere((t) => !t.isActive(now));
  }

  void markUsed(double now, {String? traceKey, double hold = 45}) {
    usageCount++;
    if (usageCount >= 12) {
      wear = ObjectWearVisual.worn;
    } else if (usageCount >= 3) {
      wear = ObjectWearVisual.used;
    }
    if (traceKey != null) {
      traces.removeWhere((t) => t.key == traceKey);
      traces.add(ObjectTrace(key: traceKey, expiresAt: now + hold));
    }
  }

  void setState(ObjectLogicState next) => state = next;

  void applyClutter({double dx = 0.04, double dy = 0}) {
    clutterOffsetX = (clutterOffsetX + dx).clamp(-0.2, 0.2);
    clutterOffsetY = (clutterOffsetY + dy).clamp(-0.2, 0.2);
  }

  void resetClutter() {
    clutterOffsetX = 0;
    clutterOffsetY = 0;
  }

  void resetWear() {
    wear = ObjectWearVisual.pristine;
    usageCount = 0;
  }
}

/// World registry for object logic state (not sprite-owned).
class ObjectStateBoard {
  final Map<String, StatefulObjectRecord> byId = {};

  StatefulObjectRecord ensure(String id) =>
      byId.putIfAbsent(id, () => StatefulObjectRecord(id: id));

  void tick(double now) {
    for (final r in byId.values) {
      r.tick(now);
    }
  }

  /// Cancel policy: TV/activity → idle; book → keep open briefly then close.
  void resolveOnActivityCancel(String id, double now) {
    final r = ensure(id);
    switch (r.state) {
      case ObjectLogicState.active:
      case ObjectLogicState.inUse:
        r.setState(ObjectLogicState.idle);
        r.markUsed(now, traceKey: 'recentlyOn', hold: 20);
      case ObjectLogicState.open:
        r.markUsed(now, traceKey: 'openPage', hold: 12);
        r.setState(ObjectLogicState.closed);
      case ObjectLogicState.closed:
      case ObjectLogicState.idle:
        break;
    }
  }
}
