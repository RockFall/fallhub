/// Multi-session creative work without real Projects (MD 08 M38).

enum WorkpieceKind {
  painting,
  songComposition,
  model,
  craft,
  gardenPlot,
  writingPiece,
  puzzle,
}

class HabitatWorkpiece {
  HabitatWorkpiece({
    required this.id,
    required this.kind,
    required this.title,
    this.ownerPawnId,
    this.progress = 0,
    this.stage = 'blank',
    this.stationRequirement = 'desk',
    this.interestTags = const {},
    this.collaborators = const [],
  });

  final String id;
  final WorkpieceKind kind;
  final String title;
  String? ownerPawnId;
  double progress;
  String stage;
  final String stationRequirement;
  final Set<String> interestTags;
  List<String> collaborators;
  bool abandoned = false;
  bool finished = false;
  String? chronicleCandidate;

  static const paintingStages = [
    'blank',
    'sketch',
    'base',
    'detail',
    'finished',
  ];

  List<String> get stages => switch (kind) {
        WorkpieceKind.painting => paintingStages,
        WorkpieceKind.writingPiece => const [
            'blank',
            'outline',
            'draft',
            'revise',
            'finished',
          ],
        WorkpieceKind.songComposition => const [
            'blank',
            'motif',
            'structure',
            'polish',
            'finished',
          ],
        _ => const ['blank', 'wip', 'refine', 'finished'],
      };

  /// Visual hint for prop tint/overlay (0..1 by stage index).
  double get visualProgress {
    final list = stages;
    final i = list.indexOf(stage);
    if (i < 0) return progress;
    return (i / (list.length - 1)).clamp(0.0, 1.0);
  }
}

/// Persistent workpieces across sessions (M38).
class HabitatWorkpieceDirector {
  final Map<String, HabitatWorkpiece> pieces = {};
  final List<String> debugLog = [];

  HabitatWorkpiece ensurePainting(String ownerId) {
    const id = 'wp.painting.demo';
    return pieces.putIfAbsent(
      id,
      () => HabitatWorkpiece(
        id: id,
        kind: WorkpieceKind.painting,
        title: 'Tela da manhã',
        ownerPawnId: ownerId,
        interestTags: {'art.painting'},
        stationRequirement: 'desk',
      ),
    );
  }

  HabitatWorkpiece ensureWriting(String ownerId) {
    const id = 'wp.writing.demo';
    return pieces.putIfAbsent(
      id,
      () => HabitatWorkpiece(
        id: id,
        kind: WorkpieceKind.writingPiece,
        title: 'Crônica curta',
        ownerPawnId: ownerId,
        interestTags: {'writing'},
      ),
    );
  }

  void workOn(String workpieceId, {double delta = 0.18}) {
    final w = pieces[workpieceId];
    if (w == null || w.finished) return;
    w.abandoned = false;
    w.progress = (w.progress + delta).clamp(0.0, 1.0);
    final list = w.stages;
    final targetIndex = (w.progress * (list.length - 1)).floor().clamp(
          0,
          list.length - 1,
        );
    w.stage = list[targetIndex];
    if (w.progress >= 1 || w.stage == 'finished') {
      w.finished = true;
      w.stage = 'finished';
      w.progress = 1;
      w.chronicleCandidate = 'memory:${w.kind.name}:${w.title}';
      debugLog.add('finished ${w.id}');
    } else {
      debugLog.add('work ${w.id} ${w.stage} ${(w.progress * 100).round()}%');
    }
  }

  void abandon(String workpieceId) {
    final w = pieces[workpieceId];
    if (w == null || w.finished) return;
    w.abandoned = true;
    debugLog.add('abandon ${w.id}');
  }
}
