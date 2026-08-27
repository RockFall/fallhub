/// Reusable temporal episode primitive (sleep, visit, travel, …) — MD 08 M2.
class HabitatEpisode {
  HabitatEpisode({
    required this.id,
    required this.kind,
    required this.startedAtSimSeconds,
    this.endedAtSimSeconds,
    Map<String, Object?> data = const {},
  }) : data = Map.unmodifiable(data);

  final String id;
  final String kind;
  final double startedAtSimSeconds;
  final double? endedAtSimSeconds;
  final Map<String, Object?> data;

  bool get isOpen => endedAtSimSeconds == null;

  double? durationSeconds(double nowSimSeconds) {
    final end = endedAtSimSeconds ?? nowSimSeconds;
    return end - startedAtSimSeconds;
  }

  HabitatEpisode end(double atSimSeconds) {
    assert(isOpen, 'episode already ended');
    return HabitatEpisode(
      id: id,
      kind: kind,
      startedAtSimSeconds: startedAtSimSeconds,
      endedAtSimSeconds: atSimSeconds,
      data: data,
    );
  }

  HabitatEpisode withData(Map<String, Object?> extra) {
    return HabitatEpisode(
      id: id,
      kind: kind,
      startedAtSimSeconds: startedAtSimSeconds,
      endedAtSimSeconds: endedAtSimSeconds,
      data: {...data, ...extra},
    );
  }
}

/// In-memory episode ledger for the Habitat session.
class HabitatEpisodeLedger {
  final List<HabitatEpisode> _episodes = [];

  List<HabitatEpisode> get all => List.unmodifiable(_episodes);

  Iterable<HabitatEpisode> openOfKind(String kind) =>
      _episodes.where((e) => e.kind == kind && e.isOpen);

  HabitatEpisode start({
    required String id,
    required String kind,
    required double atSimSeconds,
    Map<String, Object?> data = const {},
  }) {
    final ep = HabitatEpisode(
      id: id,
      kind: kind,
      startedAtSimSeconds: atSimSeconds,
      data: data,
    );
    _episodes.add(ep);
    return ep;
  }

  HabitatEpisode? end(String id, double atSimSeconds) {
    final i = _episodes.indexWhere((e) => e.id == id);
    if (i < 0) return null;
    final current = _episodes[i];
    if (!current.isOpen) return current;
    final ended = current.end(atSimSeconds);
    _episodes[i] = ended;
    return ended;
  }
}
