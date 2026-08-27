/// Queue / wait spots for capacity-1 stations (MD 10 R16).
class WaitSpot {
  const WaitSpot({
    required this.cell,
    this.index = 0,
  });

  final (int, int) cell;
  final int index;
}

enum QueuePolicy {
  /// FIFO along declared wait spots.
  fifo,

  /// Nearest free wait spot.
  nearest,

  /// No queue — reject if busy.
  none,
}

class StationQueueConfig {
  const StationQueueConfig({
    required this.stationId,
    this.capacity = 1,
    this.waitSpots = const [],
    this.maxQueueLength = 3,
    this.policy = QueuePolicy.fifo,
  });

  final String stationId;
  final int capacity;
  final List<WaitSpot> waitSpots;
  final int maxQueueLength;
  final QueuePolicy policy;
}

class QueueMember {
  QueueMember({
    required this.pawnId,
    required this.joinedAt,
    this.waitSpotIndex,
    this.usingStation = false,
  });

  final String pawnId;
  final double joinedAt;
  int? waitSpotIndex;
  bool usingStation;
}

class StationQueue {
  StationQueue(this.config);

  final StationQueueConfig config;
  final List<QueueMember> members = [];

  int get length => members.length;
  bool get isFull =>
      members.where((m) => !m.usingStation).length >= config.maxQueueLength &&
      members.where((m) => m.usingStation).length >= config.capacity;

  QueueMember? get user {
    for (final m in members) {
      if (m.usingStation) return m;
    }
    return null;
  }

  /// Join queue; returns assigned wait spot cell or null if rejected.
  (int, int)? tryJoin({
    required String pawnId,
    required double now,
    required (int, int) from,
  }) {
    if (config.policy == QueuePolicy.none) {
      if (members.any((m) => m.usingStation)) return null;
    }
    // Already in queue.
    for (final m in members) {
      if (m.pawnId == pawnId) {
        return _spotCell(m.waitSpotIndex);
      }
    }
    final waiting = members.where((m) => !m.usingStation).length;
    final using = members.where((m) => m.usingStation).length;
    if (using < config.capacity && waiting == 0) {
      members.add(QueueMember(pawnId: pawnId, joinedAt: now, usingStation: true));
      return null; // go straight to station
    }
    if (waiting >= config.maxQueueLength) return null;

    final idx = _assignSpot(from);
    if (idx == null && config.waitSpots.isNotEmpty) return null;
    members.add(
      QueueMember(pawnId: pawnId, joinedAt: now, waitSpotIndex: idx),
    );
    return _spotCell(idx);
  }

  /// Promote head waiter to station user when free.
  String? promoteIfFree(double now) {
    if (members.any((m) => m.usingStation)) return null;
    QueueMember? head;
    for (final m in members) {
      if (!m.usingStation) {
        head = m;
        break;
      }
    }
    if (head == null) return null;
    head.usingStation = true;
    head.waitSpotIndex = null;
    return head.pawnId;
  }

  void leave(String pawnId) {
    members.removeWhere((m) => m.pawnId == pawnId);
  }

  /// Abandon if utility collapsed (caller decides utility).
  bool abandon(String pawnId) {
    final before = members.length;
    leave(pawnId);
    return members.length < before;
  }

  int? _assignSpot((int, int) from) {
    if (config.waitSpots.isEmpty) return null;
    final used = members.map((m) => m.waitSpotIndex).whereType<int>().toSet();
    if (config.policy == QueuePolicy.nearest) {
      var bestI = -1;
      var bestD = 1 << 30;
      for (var i = 0; i < config.waitSpots.length; i++) {
        if (used.contains(i)) continue;
        final c = config.waitSpots[i].cell;
        final d = (c.$1 - from.$1).abs() + (c.$2 - from.$2).abs();
        if (d < bestD) {
          bestD = d;
          bestI = i;
        }
      }
      return bestI >= 0 ? bestI : null;
    }
    // FIFO: first free index in order.
    for (var i = 0; i < config.waitSpots.length; i++) {
      if (!used.contains(i)) return i;
    }
    return null;
  }

  (int, int)? _spotCell(int? index) {
    if (index == null) return null;
    if (index < 0 || index >= config.waitSpots.length) return null;
    return config.waitSpots[index].cell;
  }
}

/// Registry of station queues by prop/station id.
class StationQueueBoard {
  final Map<String, StationQueue> _queues = {};

  StationQueue ensure(StationQueueConfig config) =>
      _queues.putIfAbsent(config.stationId, () => StationQueue(config));

  StationQueue? operator [](String id) => _queues[id];

  void leaveAll(String pawnId) {
    for (final q in _queues.values) {
      q.leave(pawnId);
    }
  }
}
