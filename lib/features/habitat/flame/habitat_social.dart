import 'dart:math' as math;

import 'habitat_locations.dart';
import 'habitat_room_stats.dart';
import 'habitat_social_dialogue.dart';

/// FSM phase for one active encounter.
enum SocialEncounterPhase {
  idle,
  probe,
  approach,
  formUp,
  beatLoop,
  windDown,
}

/// Stable ordered pair key.
class SocialPairKey {
  const SocialPairKey(this.a, this.b);

  final String a;
  final String b;

  String get minId => a.compareTo(b) <= 0 ? a : b;
  String get maxId => a.compareTo(b) <= 0 ? b : a;

  @override
  bool operator ==(Object other) =>
      other is SocialPairKey && minId == other.minId && maxId == other.maxId;

  @override
  int get hashCode => Object.hash(minId, maxId);
}

/// Lightweight pawn snapshot for social scoring (no Flame deps).
class SocialPawnSnapshot {
  const SocialPawnSnapshot({
    required this.memberId,
    required this.displayName,
    required this.cellX,
    required this.cellY,
    required this.isWander,
    required this.isDrafted,
    required this.isBusy,
    this.allowedZone,
    this.socialTolerance = 0.7,
    this.solitudePressure = 0.15,
    this.socialConnectionPressure = 0.3,
  });

  final String memberId;
  final String displayName;
  final int cellX;
  final int cellY;
  final bool isWander;
  final bool isDrafted;
  final bool isBusy;
  final Set<(int, int)>? allowedZone;

  /// Embodied social battery (M10) — 0..1.
  final double socialTolerance;
  final double solitudePressure;
  final double socialConnectionPressure;
}

/// Inputs for one social tick (testable without Flame).
class HabitatSocialContext {
  const HabitatSocialContext({
    required this.pawns,
    required this.roomStats,
    required this.darknessAt,
    required this.filthAt,
    required this.phaseLabel,
    required this.locationId,
    required this.isOutdoor,
    required this.spaceTight,
    required this.comfortOk,
    required this.tempBand,
    required this.now,
    required this.isWalkable,
    this.hasLamp = false,
    this.tables = const [],
    this.gatheringSpots = const [],
    this.doorCell,
  });

  final List<SocialPawnSnapshot> pawns;
  final HabitatRoomStats roomStats;
  final double Function(int x, int y) darknessAt;
  final double Function(int x, int y) filthAt;
  final String phaseLabel;
  final String locationId;
  final bool isOutdoor;
  final bool spaceTight;
  final bool comfortOk;
  final String tempBand;
  final double now;
  final bool Function(int x, int y) isWalkable;
  final bool hasLamp;
  final List<(int, int)> tables;
  final List<(int, int)> gatheringSpots;
  final (int, int)? doorCell;
}

/// Candidate pair with score.
class SocialCandidate {
  const SocialCandidate({
    required this.a,
    required this.b,
    required this.score,
    required this.venue,
    required this.hostId,
  });

  final String a;
  final String b;
  final double score;
  final SocialVenue venue;
  final String hostId;
}

/// Active encounter state.
class SocialEncounter {
  SocialEncounter({
    required this.aId,
    required this.bId,
    required this.venue,
    required this.hostId,
    required this.plan,
    required this.talkContext,
    required this.script,
  });

  final String aId;
  final String bId;
  final SocialVenue venue;
  final String hostId;
  final DialoguePlan plan;
  final TalkContext talkContext;

  /// SpeakUp-lite adjacency script (A→B→optional A→bye).
  final DialogueScript script;

  SocialEncounterPhase phase = SocialEncounterPhase.probe;
  int lineIndex = 0;
  double phaseT = 0;
  double beatT = 0;
  double bubbleGap = 0;
  bool cancelled = false;
  bool playerInterrupted = false;

  (int, int)? hostTarget;
  (int, int)? guestTarget;
  bool pathsRequested = false;
}

/// Session affinity + cooldown memory.
class SocialMemory {
  final Map<SocialPairKey, double> affinity = {};
  final Map<SocialPairKey, double> pairCooldownUntil = {};
  final Map<String, double> venueCooldownUntil = {};
  double globalQuietUntil = 0;
  final Map<SocialPairKey, List<SocialTopic>> recentTopics = {};
}

/// Orkestrates organic social encounters (V9.14).
class HabitatSocialDirector {
  HabitatSocialDirector({math.Random? rng}) : _rng = rng ?? math.Random();

  final math.Random _rng;
  final SocialMemory memory = SocialMemory();
  final SocialLineAssembler assembler = SocialLineAssembler();

  SocialEncounter? active;
  bool dirty = true;
  double _refreshLeft = 0.5;
  static const double scoreThreshold = 0.55;
  static const int nearRadius = 3;
  static const int maxPairsSample = 6;

  void markDirty() => dirty = true;

  void cancelActive({bool player = false}) {
    if (active == null) return;
    active!
      ..cancelled = true
      ..playerInterrupted = player
      ..phase = SocialEncounterPhase.windDown
      ..phaseT = 0
      ..lineIndex = active!.script.lines.length;
  }

  /// Venue score component — exposed for tests.
  static double venueScore(SocialVenue venue) => switch (venue) {
        SocialVenue.table => 0.85,
        SocialVenue.gatheringSpot => 0.78,
        SocialVenue.sofa => 0.72,
        SocialVenue.doorwayChat => 0.65,
        SocialVenue.stand => 0.45,
      };

  bool _inZone(SocialPawnSnapshot p, int x, int y) {
    final z = p.allowedZone;
    return z == null || z.contains((x, y));
  }

  double _affinity(SocialPairKey key) => memory.affinity[key] ?? 0.35;

  bool _onCooldown(SocialPairKey key, double now) {
    if (now < memory.globalQuietUntil) return true;
    final until = memory.pairCooldownUntil[key];
    return until != null && now < until;
  }

  List<(String, String)> _pairSamples(List<SocialPawnSnapshot> eligible) =>
      samplePairs(eligible, rng: _rng);

  /// Exposed for budget tests — full pairs if N≤4, else ≤[maxPairsSample].
  static List<(String, String)> samplePairs(
    List<SocialPawnSnapshot> eligible, {
    math.Random? rng,
    int maxPairs = maxPairsSample,
  }) {
    final pairs = <(String, String)>[];
    for (var i = 0; i < eligible.length; i++) {
      for (var j = i + 1; j < eligible.length; j++) {
        pairs.add((eligible[i].memberId, eligible[j].memberId));
      }
    }
    if (eligible.length <= 4) return pairs;
    final r = rng ?? math.Random();
    pairs.shuffle(r);
    return pairs.take(maxPairs).toList();
  }

  SocialVenue _resolveVenue(
    SocialPawnSnapshot a,
    SocialPawnSnapshot b,
    HabitatSocialContext ctx,
  ) {
    final ax = a.cellX;
    final ay = a.cellY;
    final bx = b.cellX;
    final by = b.cellY;
    final dist = math.max((ax - bx).abs(), (ay - by).abs());
    final midX = ((ax + bx) / 2).round();
    final midY = ((ay + by) / 2).round();

    (int, int)? nearest(
      List<(int, int)> cells, {
      required int maxDist,
    }) {
      (int, int)? best;
      var bestD = 1 << 30;
      for (final c in cells) {
        if (!_inZone(a, c.$1, c.$2) || !_inZone(b, c.$1, c.$2)) continue;
        final da = (c.$1 - ax).abs() + (c.$2 - ay).abs();
        final db = (c.$1 - bx).abs() + (c.$2 - by).abs();
        if (da > maxDist || db > maxDist) continue;
        final d = (c.$1 - midX).abs() + (c.$2 - midY).abs();
        if (d < bestD) {
          bestD = d;
          best = c;
        }
      }
      return best;
    }

    if (nearest(ctx.gatheringSpots, maxDist: 4) != null) {
      return SocialVenue.gatheringSpot;
    }
    if (nearest(ctx.tables, maxDist: 4) != null) {
      return SocialVenue.table;
    }

    if (ctx.doorCell != null && dist <= 3) {
      final d = ctx.doorCell!;
      final da = (d.$1 - ax).abs() + (d.$2 - ay).abs();
      final db = (d.$1 - bx).abs() + (d.$2 - by).abs();
      if (da <= 3 &&
          db <= 3 &&
          _inZone(a, d.$1, d.$2) &&
          _inZone(b, d.$1, d.$2)) {
        return SocialVenue.doorwayChat;
      }
    }

    return SocialVenue.stand;
  }

  double scorePair(
    SocialPawnSnapshot a,
    SocialPawnSnapshot b,
    HabitatSocialContext ctx,
  ) {
    final key = SocialPairKey(a.memberId, b.memberId);
    if (_onCooldown(key, ctx.now)) return 0;

    final dist = (a.cellX - b.cellX).abs() + (a.cellY - b.cellY).abs();
    if (dist > nearRadius + 2) {
      final venue = _resolveVenue(a, b, ctx);
      if (venue == SocialVenue.stand && dist > nearRadius + 1) return 0;
    }

    final venue = _resolveVenue(a, b, ctx);
    var score = 0.0;
    score += 0.25 * (1 - dist / (nearRadius + 2)).clamp(0.0, 1.0);
    score += 0.20 * _affinity(key);
    score += 0.20 * venueScore(venue);

    final beauty = ctx.roomStats.beauty / 100.0;
    score += 0.10 * beauty;

    final dark = (darknessAt(ctx, a) + darknessAt(ctx, b)) / 2;
    if (dark < 0.55) score += 0.10 * (1 - dark);

    final hour = _hourFactor(ctx.phaseLabel);
    score += 0.10 * hour;

    // M10 — social battery / solitude (independent axes).
    final tol = (a.socialTolerance + b.socialTolerance) / 2;
    final solitude = (a.solitudePressure + b.solitudePressure) / 2;
    final desire = (a.socialConnectionPressure + b.socialConnectionPressure) / 2;
    score += 0.12 * desire;
    score -= 0.18 * (1 - tol);
    score -= 0.15 * solitude;
    // Low tolerance: prefer quieter venues (stand/doorway over table/party feel).
    if (tol < 0.35 &&
        (venue == SocialVenue.table || venue == SocialVenue.gatheringSpot)) {
      score -= 0.12;
    }

    final venueKey = '${venue.name}_${key.minId}';
    if (memory.venueCooldownUntil[venueKey] != null &&
        ctx.now < memory.venueCooldownUntil[venueKey]!) {
      score -= 0.05;
    }

    score += (_rng.nextDouble() - 0.5) * 0.1;
    return score.clamp(0.0, 1.0);
  }

  static double darknessAt(HabitatSocialContext ctx, SocialPawnSnapshot p) =>
      ctx.darknessAt(p.cellX, p.cellY);

  static double _hourFactor(String phase) => switch (phase) {
        'Dia' || 'Entardecer' => 0.9,
        'Amanhecer' => 0.7,
        'Noite' => 0.45,
        _ => 0.25,
      };

  List<SocialCandidate> _refreshCandidates(HabitatSocialContext ctx) {
    final eligible = ctx.pawns
        .where((p) => p.isWander && !p.isDrafted && !p.isBusy)
        .toList();
    if (eligible.length < 2) return const [];

    final out = <SocialCandidate>[];
    for (final (aid, bid) in _pairSamples(eligible)) {
      final a = eligible.firstWhere((p) => p.memberId == aid);
      final b = eligible.firstWhere((p) => p.memberId == bid);
      final s = scorePair(a, b, ctx);
      if (s < scoreThreshold) continue;
      final venue = _resolveVenue(a, b, ctx);
      final host = _rng.nextBool() ? aid : bid;
      out.add(
        SocialCandidate(a: aid, b: bid, score: s, venue: venue, hostId: host),
      );
    }
    out.sort((x, y) => y.score.compareTo(x.score));
    return out;
  }

  SocialCandidate? _pickCandidate(List<SocialCandidate> candidates) {
    if (candidates.isEmpty) return null;
    final top = candidates.take(3).toList();
    var total = 0.0;
    for (final c in top) {
      total += c.score;
    }
    var roll = _rng.nextDouble() * total;
    for (final c in top) {
      roll -= c.score;
      if (roll <= 0) return c;
    }
    return top.last;
  }

  TalkContext _buildTalkContext(
    SocialCandidate pick,
    HabitatSocialContext ctx,
    SocialPawnSnapshot a,
    SocialPawnSnapshot b,
  ) {
    final key = SocialPairKey(a.memberId, b.memberId);
    final midX = ((a.cellX + b.cellX) / 2).round();
    final midY = ((a.cellY + b.cellY) / 2).round();
    final dark = ctx.darknessAt(midX, midY);
    final beauty = ctx.roomStats.beauty;
    final clean = ctx.roomStats.cleanliness;

    return TalkContext(
      venue: pick.venue,
      phaseLabel: ctx.phaseLabel,
      beautyBand: beauty >= 65 ? 'high' : beauty >= 40 ? 'mid' : 'low',
      cleanBand: clean >= 55 ? 'mid' : 'low',
      lightBand: dark > 0.55 ? 'dark' : 'ok',
      tempBand: ctx.tempBand,
      affinity: _affinity(key),
      isOutdoor: ctx.isOutdoor,
      spaceTight: ctx.spaceTight,
      comfortOk: ctx.comfortOk,
      hasLamp: ctx.hasLamp,
      isOffice: ctx.locationId == HabitatLocationIds.office,
      recentTopics: memory.recentTopics[key] ?? const [],
      listenerName: b.displayName,
      speakerName: a.displayName,
    );
  }

  void _startEncounter(
    SocialCandidate pick,
    HabitatSocialContext ctx,
    SocialPawnSnapshot a,
    SocialPawnSnapshot b,
  ) {
    final key = SocialPairKey(a.memberId, b.memberId);
    final talkCtx = _buildTalkContext(pick, ctx, a, b);
    final initiator = pick.hostId == a.memberId ? a : b;
    final recipient = identical(initiator, a) ? b : a;
    final script = assembler.buildScript(
      ctx: talkCtx,
      initiatorId: initiator.memberId,
      recipientId: recipient.memberId,
      initiatorName: initiator.displayName,
      recipientName: recipient.displayName,
    );

    active = SocialEncounter(
      aId: a.memberId,
      bId: b.memberId,
      venue: pick.venue,
      hostId: pick.hostId,
      plan: script.plan,
      talkContext: talkCtx,
      script: script,
    )
      ..phase = SocialEncounterPhase.approach
      ..phaseT = 0;

    memory.pairCooldownUntil[key] = ctx.now + 12 + _rng.nextDouble() * 8;
  }

  void _finishEncounter(double now) {
    final enc = active;
    if (enc == null) return;
    final key = SocialPairKey(enc.aId, enc.bId);
    memory.affinity[key] = ((_affinity(key) + 0.08).clamp(0.0, 1.0));
    memory.pairCooldownUntil[key] = now + 45 + _rng.nextDouble() * 75;
    memory.venueCooldownUntil['${enc.venue.name}_${key.minId}'] =
        now + 30 + _rng.nextDouble() * 30;
    memory.globalQuietUntil = now + 5 + _rng.nextDouble() * 7;
    final topics = memory.recentTopics.putIfAbsent(key, () => []);
    topics.add(enc.plan.topic);
    while (topics.length > 2) {
      topics.removeAt(0);
    }
    active = null;
    dirty = true;
  }

  /// Meeting cells for a venue — always two **distinct** orthogonal neighbors.
  static ((int, int), (int, int)) meetingCells({
    required SocialPawnSnapshot host,
    required SocialPawnSnapshot guest,
    required SocialVenue venue,
    required HabitatSocialContext ctx,
  }) {
    bool ok(int x, int y) {
      if (!ctx.isWalkable(x, y)) return false;
      if (host.allowedZone != null && !host.allowedZone!.contains((x, y))) {
        return false;
      }
      if (guest.allowedZone != null && !guest.allowedZone!.contains((x, y))) {
        return false;
      }
      return true;
    }

    (int, int)? nearestAdj(
      (int, int) center,
      (int, int) from, {
      (int, int)? exclude,
    }) {
      final opts = <(int, int)>[];
      for (final (dx, dy) in const [(1, 0), (-1, 0), (0, 1), (0, -1)]) {
        final x = center.$1 + dx;
        final y = center.$2 + dy;
        if (exclude != null && (x, y) == exclude) continue;
        if (ok(x, y)) opts.add((x, y));
      }
      if (opts.isEmpty) return null;
      opts.sort(
        (a, b) =>
            ((a.$1 - from.$1).abs() + (a.$2 - from.$2).abs()) -
            ((b.$1 - from.$1).abs() + (b.$2 - from.$2).abs()),
      );
      return opts.first;
    }

    ((int, int), (int, int))? pairAround((int, int) center) {
      final ha = nearestAdj(center, (host.cellX, host.cellY));
      if (ha == null) return null;
      final ga = nearestAdj(
        center,
        (guest.cellX, guest.cellY),
        exclude: ha,
      );
      if (ga == null) return null;
      return (ha, ga);
    }

    (int, int) nearestCenter(List<(int, int)> cells) {
      final midX = ((host.cellX + guest.cellX) / 2).round();
      final midY = ((host.cellY + guest.cellY) / 2).round();
      var best = cells.first;
      var bestD = 1 << 30;
      for (final c in cells) {
        final d = (c.$1 - midX).abs() + (c.$2 - midY).abs();
        if (d < bestD) {
          bestD = d;
          best = c;
        }
      }
      return best;
    }

    /// Host stays; guest stands on an orthogonal neighbor — never same cell.
    ((int, int), (int, int)) standPair() {
      final hostCell = (host.cellX, host.cellY);
      final guestCell = (guest.cellX, guest.cellY);
      final dist = (hostCell.$1 - guestCell.$1).abs() +
          (hostCell.$2 - guestCell.$2).abs();
      final ortho = dist == 1 &&
          (hostCell.$1 == guestCell.$1 || hostCell.$2 == guestCell.$2);
      if (ortho && hostCell != guestCell) {
        return (hostCell, guestCell);
      }
      final adj = nearestAdj(
        hostCell,
        guestCell,
        exclude: hostCell,
      );
      if (adj != null && adj != hostCell) {
        return (hostCell, adj);
      }
      // Last resort: host steps aside if guest is stuck on host cell.
      final hostShift = nearestAdj(guestCell, hostCell, exclude: guestCell);
      if (hostShift != null) return (hostShift, guestCell);
      return (hostCell, guestCell);
    }

    if (venue == SocialVenue.table && ctx.tables.isNotEmpty) {
      final pair = pairAround(nearestCenter(ctx.tables));
      if (pair != null && pair.$1 != pair.$2) return pair;
    }
    if (venue == SocialVenue.gatheringSpot && ctx.gatheringSpots.isNotEmpty) {
      final pair = pairAround(nearestCenter(ctx.gatheringSpots));
      if (pair != null && pair.$1 != pair.$2) return pair;
    }
    if (venue == SocialVenue.doorwayChat && ctx.doorCell != null) {
      final pair = pairAround(ctx.doorCell!);
      if (pair != null && pair.$1 != pair.$2) return pair;
    }

    return standPair();
  }

  static SocialPawnSnapshot? _pawnById(
    HabitatSocialContext ctx,
    String id,
  ) {
    for (final p in ctx.pawns) {
      if (p.memberId == id) return p;
    }
    return null;
  }

  /// Main tick — returns bubble requests `(memberId, text, isThought)`.
  List<(String, String, bool)> tick(
    double dt,
    HabitatSocialContext ctx, {
    void Function(String aId, String bId)? onProbe,
    void Function(String memberId, double lean)? onLean,
    void Function(String hostId, (int, int) hostCell, String guestId, (int, int) guestCell)?
        onApproachPaths,
  }) {
    final bubbles = <(String, String, bool)>[];

    if (active != null) {
      bubbles.addAll(
        _tickActive(
          dt,
          ctx,
          onLean: onLean,
          onApproachPaths: onApproachPaths,
        ),
      );
      return bubbles;
    }

    _refreshLeft -= dt;
    if (_refreshLeft > 0 && !dirty) return bubbles;
    _refreshLeft = 0.4 + _rng.nextDouble() * 0.3;
    dirty = false;

    final maxActive = ctx.pawns.length >= 5 ? 2 : 1;
    if (maxActive <= 0) return bubbles;

    final candidates = _refreshCandidates(ctx);
    final pick = _pickCandidate(candidates);
    if (pick == null) return bubbles;

    final a = ctx.pawns.firstWhere((p) => p.memberId == pick.a);
    final b = ctx.pawns.firstWhere((p) => p.memberId == pick.b);
    onProbe?.call(pick.a, pick.b);
    _startEncounter(pick, ctx, a, b);
    return bubbles;
  }

  List<(String, String, bool)> _tickActive(
    double dt,
    HabitatSocialContext ctx, {
    void Function(String memberId, double lean)? onLean,
    void Function(String hostId, (int, int) hostCell, String guestId, (int, int) guestCell)?
        onApproachPaths,
  }) {
    final enc = active!;
    final bubbles = <(String, String, bool)>[];

    if (enc.cancelled && enc.phase != SocialEncounterPhase.windDown) {
      enc.phase = SocialEncounterPhase.windDown;
      enc.phaseT = 0;
    }

    enc.phaseT += dt;

    if (enc.phase == SocialEncounterPhase.approach) {
      final host = _pawnById(ctx, enc.hostId);
      final guestId = enc.hostId == enc.aId ? enc.bId : enc.aId;
      final guest = _pawnById(ctx, guestId);
      if (host != null && guest != null && enc.hostTarget == null) {
        final meet = meetingCells(
          host: host,
          guest: guest,
          venue: enc.venue,
          ctx: ctx,
        );
        enc.hostTarget = meet.$1;
        enc.guestTarget = meet.$2;
      }
      if (!enc.pathsRequested &&
          enc.hostTarget != null &&
          enc.guestTarget != null) {
        enc.pathsRequested = true;
        onApproachPaths?.call(
          enc.hostId,
          enc.hostTarget!,
          guestId,
          enc.guestTarget!,
        );
      }
      if (host != null && guest != null) {
        final distinct =
            host.cellX != guest.cellX || host.cellY != guest.cellY;
        final arrived = distinct &&
            _near(host, enc.hostTarget) &&
            _near(guest, enc.guestTarget);
        final manh = distinct
            ? (host.cellX - guest.cellX).abs() +
                (host.cellY - guest.cellY).abs()
            : 99;
        // Adjacent (1) or diagonal (2) is fine — never same cell.
        final closeEnough = distinct && manh >= 1 && manh <= 2;
        if (arrived || closeEnough || enc.phaseT >= 5.0) {
          enc.phase = SocialEncounterPhase.formUp;
          enc.phaseT = 0;
          onLean?.call(enc.aId, 2);
          onLean?.call(enc.bId, -2);
        }
      } else if (enc.phaseT >= 5.0) {
        enc.phase = SocialEncounterPhase.formUp;
        enc.phaseT = 0;
      }
      return bubbles;
    }

    if (enc.phase == SocialEncounterPhase.formUp) {
      if (enc.phaseT >= 0.85) {
        enc.phase = SocialEncounterPhase.beatLoop;
        enc.phaseT = 0;
        enc.beatT = 0;
        enc.lineIndex = 0;
        enc.bubbleGap = 0.45;
      }
      return bubbles;
    }

    if (enc.phase == SocialEncounterPhase.beatLoop) {
      enc.beatT += dt;
      enc.bubbleGap -= dt;
      final lines = enc.script.lines;
      if (enc.lineIndex >= lines.length) {
        enc.phase = SocialEncounterPhase.windDown;
        enc.phaseT = 0;
        return bubbles;
      }
      if (enc.bubbleGap <= 0 && enc.beatT >= 0.35) {
        final line = lines[enc.lineIndex];
        if (line.text.isNotEmpty) {
          bubbles.add((line.speakerId, line.text, line.isThought));
        }
        enc.lineIndex++;
        enc.bubbleGap = 2.0 + _rng.nextDouble() * 0.8;
        enc.beatT = 0;
      }
      return bubbles;
    }

    if (enc.phase == SocialEncounterPhase.windDown) {
      // Farewell is already the last script line; just linger then finish.
      if (enc.phaseT >= (enc.playerInterrupted ? 0.2 : 1.6)) {
        _finishEncounter(ctx.now);
      }
    }

    return bubbles;
  }

  static bool _near(SocialPawnSnapshot p, (int, int)? target) {
    if (target == null) return true;
    return (p.cellX - target.$1).abs() + (p.cellY - target.$2).abs() <= 1;
  }
}
