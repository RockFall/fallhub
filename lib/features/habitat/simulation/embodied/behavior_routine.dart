// Reusable behavior graphs (MD 08 M34).

enum RoutineNodeKind {
  goTo,
  wait,
  setNeed,
  applyLoadout,
  applyPreset,
  useDevice,
  pickUp,
  putIn,
  emitBubble,
  checkCondition,
  end,
}

class RoutineNode {
  const RoutineNode({
    required this.id,
    required this.kind,
    this.params = const {},
  });

  final String id;
  final RoutineNodeKind kind;
  final Map<String, Object?> params;
}

class RoutineEdge {
  const RoutineEdge({
    required this.from,
    required this.to,
    this.when,
  });

  final String from;
  final String to;

  /// Optional condition key evaluated by host (`ok`, `fail`, `default`).
  final String? when;
}

class BehaviorRoutineDefinition {
  const BehaviorRoutineDefinition({
    required this.id,
    required this.label,
    required this.nodes,
    required this.edges,
    this.tags = const {},
    this.entryNodeId,
  });

  final String id;
  final String label;
  final List<RoutineNode> nodes;
  final List<RoutineEdge> edges;
  final Set<String> tags;
  final String? entryNodeId;

  RoutineNode? node(String id) {
    for (final n in nodes) {
      if (n.id == id) return n;
    }
    return null;
  }
}

enum RoutineRunStatus {
  idle,
  running,
  waiting,
  paused,
  completed,
  aborted,
}

class BehaviorRoutineRun {
  BehaviorRoutineRun({
    required this.definitionId,
    required this.pawnId,
    required this.currentNodeId,
  });

  final String definitionId;
  final String pawnId;
  String currentNodeId;
  RoutineRunStatus status = RoutineRunStatus.running;
  double waitUntilSim = 0;
  double stepDeadlineSim = double.infinity;
  final List<String> executed = [];
}

/// Catalog + runner for composed behaviors (M34).
class BehaviorRoutineEngine {
  BehaviorRoutineEngine() {
    for (final d in seedDefinitions) {
      definitions[d.id] = d;
    }
  }

  final Map<String, BehaviorRoutineDefinition> definitions = {};
  final Map<String, BehaviorRoutineRun> runsByPawn = {};
  final List<String> debugLog = [];

  static final List<BehaviorRoutineDefinition> seedDefinitions = [
    BehaviorRoutineDefinition(
      id: 'prepareSleep',
      label: 'Preparar sono',
      tags: {'sleep', 'evening'},
      entryNodeId: 'go_bed',
      nodes: const [
        RoutineNode(
          id: 'go_bed',
          kind: RoutineNodeKind.goTo,
          params: {'target': 'bed'},
        ),
        RoutineNode(
          id: 'preset',
          kind: RoutineNodeKind.applyPreset,
          params: {'presetId': 'sleepMode'},
        ),
        RoutineNode(
          id: 'loadout',
          kind: RoutineNodeKind.applyLoadout,
          params: {'loadoutId': 'sleep'},
        ),
        RoutineNode(
          id: 'bubble',
          kind: RoutineNodeKind.emitBubble,
          params: {'text': 'hora de dormir'},
        ),
        RoutineNode(id: 'end', kind: RoutineNodeKind.end),
      ],
      edges: const [
        RoutineEdge(from: 'go_bed', to: 'preset'),
        RoutineEdge(from: 'preset', to: 'loadout'),
        RoutineEdge(from: 'loadout', to: 'bubble'),
        RoutineEdge(from: 'bubble', to: 'end'),
      ],
    ),
    BehaviorRoutineDefinition(
      id: 'leaveHome',
      label: 'Sair de casa',
      tags: {'travel', 'away'},
      entryNodeId: 'bag',
      nodes: const [
        RoutineNode(
          id: 'bag',
          kind: RoutineNodeKind.putIn,
          params: {'containerId': 'bag', 'itemHint': 'held'},
        ),
        RoutineNode(
          id: 'loadout',
          kind: RoutineNodeKind.applyLoadout,
          params: {'loadoutId': 'travel'},
        ),
        RoutineNode(
          id: 'door',
          kind: RoutineNodeKind.goTo,
          params: {'target': 'entrance'},
        ),
        RoutineNode(
          id: 'bubble',
          kind: RoutineNodeKind.emitBubble,
          params: {'text': 'saindo'},
        ),
        RoutineNode(id: 'end', kind: RoutineNodeKind.end),
      ],
      edges: const [
        RoutineEdge(from: 'bag', to: 'loadout'),
        RoutineEdge(from: 'loadout', to: 'door'),
        RoutineEdge(from: 'door', to: 'bubble'),
        RoutineEdge(from: 'bubble', to: 'end'),
      ],
    ),
    BehaviorRoutineDefinition(
      id: 'receiveGuest',
      label: 'Receber visita',
      tags: {'social', 'guests'},
      entryNodeId: 'preset',
      nodes: const [
        RoutineNode(
          id: 'preset',
          kind: RoutineNodeKind.applyPreset,
          params: {'presetId': 'guests'},
        ),
        RoutineNode(
          id: 'loadout',
          kind: RoutineNodeKind.applyLoadout,
          params: {'loadoutId': 'socialCasual'},
        ),
        RoutineNode(
          id: 'door',
          kind: RoutineNodeKind.goTo,
          params: {'target': 'entrance'},
        ),
        RoutineNode(
          id: 'bubble',
          kind: RoutineNodeKind.emitBubble,
          params: {'text': 'olá!'},
        ),
        RoutineNode(id: 'end', kind: RoutineNodeKind.end),
      ],
      edges: const [
        RoutineEdge(from: 'preset', to: 'loadout'),
        RoutineEdge(from: 'loadout', to: 'door'),
        RoutineEdge(from: 'door', to: 'bubble'),
        RoutineEdge(from: 'bubble', to: 'end'),
      ],
    ),
    BehaviorRoutineDefinition(
      id: 'wakeUp',
      label: 'Acordar',
      tags: {'morning'},
      entryNodeId: 'preset',
      nodes: const [
        RoutineNode(
          id: 'preset',
          kind: RoutineNodeKind.applyPreset,
          params: {'presetId': 'morning'},
        ),
        RoutineNode(
          id: 'loadout',
          kind: RoutineNodeKind.applyLoadout,
          params: {'loadoutId': 'home'},
        ),
        RoutineNode(
          id: 'check_shower',
          kind: RoutineNodeKind.checkCondition,
          params: {'key': 'showerAvailable'},
        ),
        RoutineNode(
          id: 'shower',
          kind: RoutineNodeKind.wait,
          params: {'seconds': 3.0, 'label': 'banho'},
        ),
        RoutineNode(
          id: 'wash_face',
          kind: RoutineNodeKind.wait,
          params: {'seconds': 1.5, 'label': 'lavar rosto'},
        ),
        RoutineNode(
          id: 'stretch',
          kind: RoutineNodeKind.wait,
          params: {'seconds': 2.0},
        ),
        RoutineNode(
          id: 'bubble',
          kind: RoutineNodeKind.emitBubble,
          params: {'text': 'bom dia'},
        ),
        RoutineNode(id: 'end', kind: RoutineNodeKind.end),
      ],
      edges: const [
        RoutineEdge(from: 'preset', to: 'loadout'),
        RoutineEdge(from: 'loadout', to: 'check_shower'),
        RoutineEdge(from: 'check_shower', to: 'shower', when: 'ok'),
        RoutineEdge(from: 'check_shower', to: 'wash_face', when: 'fail'),
        RoutineEdge(from: 'shower', to: 'stretch'),
        RoutineEdge(from: 'wash_face', to: 'stretch'),
        RoutineEdge(from: 'stretch', to: 'bubble'),
        RoutineEdge(from: 'bubble', to: 'end'),
      ],
    ),
BehaviorRoutineDefinition(
      id: 'morning',
      label: 'Rotina matinal',
      tags: {'morning', 'selfcare'},
      entryNodeId: 'inertia',
      nodes: const [
        RoutineNode(
          id: 'inertia',
          kind: RoutineNodeKind.wait,
          params: {'seconds': 2.0, 'label': 'inércia'},
        ),
        RoutineNode(
          id: 'sit_bed',
          kind: RoutineNodeKind.goTo,
          params: {'target': 'bed'},
        ),
        RoutineNode(
          id: 'preset',
          kind: RoutineNodeKind.applyPreset,
          params: {'presetId': 'morning'},
        ),
        RoutineNode(
          id: 'bathroom',
          kind: RoutineNodeKind.goTo,
          params: {'target': 'bathroom'},
        ),
        RoutineNode(
          id: 'check_shower',
          kind: RoutineNodeKind.checkCondition,
          params: {'key': 'showerAvailable'},
        ),
        RoutineNode(
          id: 'shower',
          kind: RoutineNodeKind.wait,
          params: {'seconds': 3.0, 'label': 'banho'},
        ),
        RoutineNode(
          id: 'wash_face',
          kind: RoutineNodeKind.wait,
          params: {'seconds': 1.5, 'label': 'lavar rosto'},
        ),
        RoutineNode(
          id: 'loadout',
          kind: RoutineNodeKind.applyLoadout,
          params: {'loadoutId': 'home'},
        ),
        RoutineNode(
          id: 'kitchen',
          kind: RoutineNodeKind.goTo,
          params: {'target': 'table'},
        ),
        RoutineNode(
          id: 'bubble',
          kind: RoutineNodeKind.emitBubble,
          params: {'text': 'bom dia'},
        ),
        RoutineNode(id: 'end', kind: RoutineNodeKind.end),
      ],
      edges: const [
        RoutineEdge(from: 'inertia', to: 'sit_bed'),
        RoutineEdge(from: 'sit_bed', to: 'preset'),
        RoutineEdge(from: 'preset', to: 'bathroom'),
        RoutineEdge(from: 'bathroom', to: 'check_shower'),
        RoutineEdge(from: 'check_shower', to: 'shower', when: 'ok'),
        RoutineEdge(from: 'check_shower', to: 'wash_face', when: 'fail'),
        RoutineEdge(from: 'shower', to: 'loadout'),
        RoutineEdge(from: 'wash_face', to: 'loadout'),
        RoutineEdge(from: 'loadout', to: 'kitchen'),
        RoutineEdge(from: 'kitchen', to: 'bubble'),
        RoutineEdge(from: 'bubble', to: 'end'),
      ],
    ),
    BehaviorRoutineDefinition(
      id: 'bedtime',
      label: 'Rotina de dormir',
      tags: {'sleep', 'evening', 'selfcare'},
      entryNodeId: 'wind',
      nodes: const [
        RoutineNode(
          id: 'wind',
          kind: RoutineNodeKind.wait,
          params: {'seconds': 2.0, 'label': 'desacelerar'},
        ),
        RoutineNode(
          id: 'bathroom',
          kind: RoutineNodeKind.goTo,
          params: {'target': 'bathroom'},
        ),
        RoutineNode(
          id: 'loadout',
          kind: RoutineNodeKind.applyLoadout,
          params: {'loadoutId': 'sleep'},
        ),
        RoutineNode(
          id: 'preset',
          kind: RoutineNodeKind.applyPreset,
          params: {'presetId': 'sleepMode'},
        ),
        RoutineNode(
          id: 'bed',
          kind: RoutineNodeKind.goTo,
          params: {'target': 'bed'},
        ),
        RoutineNode(
          id: 'bubble',
          kind: RoutineNodeKind.emitBubble,
          params: {'text': 'boa noite'},
        ),
        RoutineNode(id: 'end', kind: RoutineNodeKind.end),
      ],
      edges: const [
        RoutineEdge(from: 'wind', to: 'bathroom'),
        RoutineEdge(from: 'bathroom', to: 'loadout'),
        RoutineEdge(from: 'loadout', to: 'preset'),
        RoutineEdge(from: 'preset', to: 'bed'),
        RoutineEdge(from: 'bed', to: 'bubble'),
        RoutineEdge(from: 'bubble', to: 'end'),
      ],
    ),
    BehaviorRoutineDefinition(
      id: 'prepareToLeave',
      label: 'Preparar saída',
      tags: {'travel', 'away', 'leave'},
      entryNodeId: 'loadout',
      nodes: const [
        RoutineNode(
          id: 'loadout',
          kind: RoutineNodeKind.applyLoadout,
          params: {'loadoutId': 'travel'},
        ),
        RoutineNode(
          id: 'collect',
          kind: RoutineNodeKind.putIn,
          params: {'containerId': 'bag', 'itemHint': 'prep'},
        ),
        RoutineNode(
          id: 'door',
          kind: RoutineNodeKind.goTo,
          params: {'target': 'entrance'},
        ),
        RoutineNode(
          id: 'bubble',
          kind: RoutineNodeKind.emitBubble,
          params: {'text': 'saindo'},
        ),
        RoutineNode(id: 'end', kind: RoutineNodeKind.end),
      ],
      edges: const [
        RoutineEdge(from: 'loadout', to: 'collect'),
        RoutineEdge(from: 'collect', to: 'door'),
        RoutineEdge(from: 'door', to: 'bubble'),
        RoutineEdge(from: 'bubble', to: 'end'),
      ],
    ),
    BehaviorRoutineDefinition(
      id: 'arriveHome',
      label: 'Chegar em casa',
      tags: {'home', 'arrive'},
      entryNodeId: 'enter',
      nodes: const [
        RoutineNode(
          id: 'enter',
          kind: RoutineNodeKind.goTo,
          params: {'target': 'entrance'},
        ),
        RoutineNode(
          id: 'drop',
          kind: RoutineNodeKind.putIn,
          params: {'containerId': 'table', 'itemHint': 'bag'},
        ),
        RoutineNode(
          id: 'loadout',
          kind: RoutineNodeKind.applyLoadout,
          params: {'loadoutId': 'home'},
        ),
        RoutineNode(
          id: 'decompress',
          kind: RoutineNodeKind.wait,
          params: {'seconds': 2.0},
        ),
        RoutineNode(
          id: 'bubble',
          kind: RoutineNodeKind.emitBubble,
          params: {'text': 'em casa'},
        ),
        RoutineNode(id: 'end', kind: RoutineNodeKind.end),
      ],
      edges: const [
        RoutineEdge(from: 'enter', to: 'drop'),
        RoutineEdge(from: 'drop', to: 'loadout'),
        RoutineEdge(from: 'loadout', to: 'decompress'),
        RoutineEdge(from: 'decompress', to: 'bubble'),
        RoutineEdge(from: 'bubble', to: 'end'),
      ],
    ),
  ];

  BehaviorRoutineRun? start({
    required String definitionId,
    required String pawnId,
    double nowSim = 0,
    double stepTimeoutSim = 60,
  }) {
    final def = definitions[definitionId];
    if (def == null) return null;
    final entry = def.entryNodeId ?? def.nodes.first.id;
    final run = BehaviorRoutineRun(
      definitionId: definitionId,
      pawnId: pawnId,
      currentNodeId: entry,
    )..stepDeadlineSim = nowSim + stepTimeoutSim;
    runsByPawn[pawnId] = run;
    debugLog.add('start $definitionId @$pawnId');
    return run;
  }

  void pause(String pawnId) {
    final run = runsByPawn[pawnId];
    if (run == null || run.status == RoutineRunStatus.completed) return;
    run.status = RoutineRunStatus.paused;
    debugLog.add('pause ${run.definitionId}');
  }

  void resume(String pawnId) {
    final run = runsByPawn[pawnId];
    if (run == null || run.status != RoutineRunStatus.paused) return;
    run.status = RoutineRunStatus.running;
    debugLog.add('resume ${run.definitionId}');
  }

  /// Advance one node; [effects] applies side-effects and returns wait seconds.
  /// [branch] returns `ok` / `fail` / `default` for checkCondition nodes.
  void tick({
    required String pawnId,
    required double nowSim,
    required double Function(RoutineNode node) effects,
    String Function(RoutineNode node)? branch,
    double stepTimeoutSim = 60,
  }) {
    final run = runsByPawn[pawnId];
    if (run == null ||
        run.status == RoutineRunStatus.completed ||
        run.status == RoutineRunStatus.aborted ||
        run.status == RoutineRunStatus.paused) {
      return;
    }
    if (run.status == RoutineRunStatus.waiting) {
      if (nowSim < run.waitUntilSim) return;
      run.status = RoutineRunStatus.running;
    }
    if (nowSim > run.stepDeadlineSim) {
      debugLog.add('timeout ${run.currentNodeId}');
      run.status = RoutineRunStatus.aborted;
      return;
    }

    final def = definitions[run.definitionId];
    if (def == null) return;
    final node = def.node(run.currentNodeId);
    if (node == null) {
      run.status = RoutineRunStatus.aborted;
      return;
    }

    if (node.kind == RoutineNodeKind.end) {
      run.executed.add(node.id);
      run.status = RoutineRunStatus.completed;
      debugLog.add('done ${run.definitionId}');
      return;
    }

    String when = 'default';
    if (node.kind == RoutineNodeKind.checkCondition) {
      when = branch?.call(node) ?? 'fail';
      run.executed.add(node.id);
    } else {
      final wait = effects(node);
      run.executed.add(node.id);
      if (wait > 0) {
        run.waitUntilSim = nowSim + wait;
        run.status = RoutineRunStatus.waiting;
      }
    }

    final next = _next(def, node.id, when: when);
    if (next == null) {
      run.status = RoutineRunStatus.completed;
      return;
    }
    run.currentNodeId = next;
    run.stepDeadlineSim = nowSim + stepTimeoutSim;
  }

  String? _next(
    BehaviorRoutineDefinition def,
    String from, {
    String when = 'default',
  }) {
    for (final e in def.edges) {
      if (e.from == from && e.when == when) return e.to;
    }
    for (final e in def.edges) {
      if (e.from == from && (e.when == null || e.when == 'default')) {
        return e.to;
      }
    }
    return null;
  }
}
