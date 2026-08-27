import '../identity/identity.dart';
import 'habitat_rng.dart';
import 'reaction_latency.dart';

/// Block D — conversation etiquette (MD 10 R32–R47).

enum GreetingContext {
  roommateCasual,
  visitorArrival,
  briefRecontact,
  afterLongAbsence,
}

enum GreetingMode { bubble, glance, pause, none }

class GreetingDecision {
  const GreetingDecision({
    required this.context,
    required this.mode,
    this.line,
  });

  final GreetingContext context;
  final GreetingMode mode;
  final String? line;
}

abstract final class GreetingGrammar {
  static const pairCooldownSeconds = 180.0;

  static GreetingDecision decide({
    required double timeSinceLastSeen,
    required double familiarity,
    required double affinity,
    required bool isVisitor,
    required bool justArrived,
    required SocialStyle style,
    required String aId,
    required String bId,
    required double now,
    required Map<String, double> lastGreetingAt,
  }) {
    final key = _pairKey(aId, bId);
    final last = lastGreetingAt[key];
    if (last != null && now - last < pairCooldownSeconds) {
      return const GreetingDecision(
        context: GreetingContext.briefRecontact,
        mode: GreetingMode.none,
      );
    }
    if (isVisitor && justArrived) {
      return GreetingDecision(
        context: GreetingContext.visitorArrival,
        mode: GreetingMode.bubble,
        line: style == SocialStyle.reserved ? 'Oi.' : 'Oi! Que bom te ver.',
      );
    }
    if (timeSinceLastSeen > 3600 * 6) {
      return const GreetingDecision(
        context: GreetingContext.afterLongAbsence,
        mode: GreetingMode.bubble,
        line: 'Faz tempo!',
      );
    }
    if (timeSinceLastSeen < 300 && familiarity > 0.55) {
      return const GreetingDecision(
        context: GreetingContext.briefRecontact,
        mode: GreetingMode.glance,
      );
    }
    if (familiarity > 0.7 && affinity > 0.4) {
      return const GreetingDecision(
        context: GreetingContext.roommateCasual,
        mode: GreetingMode.pause,
      );
    }
    return GreetingDecision(
      context: GreetingContext.roommateCasual,
      mode: GreetingMode.bubble,
      line: 'E aí.',
    );
  }

  static String _pairKey(String a, String b) =>
      a.compareTo(b) <= 0 ? '$a::$b' : '$b::$a';
}

enum GoodbyeTrigger { visitorLeaving, activityEndDepart, remoteCallEnd }

class GoodbyeDecision {
  const GoodbyeDecision({
    required this.trigger,
    required this.facePartner,
    required this.pauseSeconds,
    this.line,
    this.blockDeparture = false,
  });

  final GoodbyeTrigger trigger;
  final bool facePartner;
  final double pauseSeconds;
  final String? line;
  final bool blockDeparture;
}

abstract final class GoodbyeGrammar {
  static GoodbyeDecision decide({
    required GoodbyeTrigger trigger,
    required bool interrupted,
  }) {
    if (interrupted) {
      return GoodbyeDecision(
        trigger: trigger,
        facePartner: false,
        pauseSeconds: 0,
        blockDeparture: false,
      );
    }
    return GoodbyeDecision(
      trigger: trigger,
      facePartner: true,
      pauseSeconds: 0.35,
      line: trigger == GoodbyeTrigger.visitorLeaving ? 'Até mais!' : 'Falamos.',
      blockDeparture: false,
    );
  }
}

class ConversationSlot {
  const ConversationSlot({
    required this.cell,
    required this.facingToward,
  });

  final (int, int) cell;
  final (int, int) facingToward;
}

abstract final class ConversationalPositioning {
  /// Arc / pair positions around a center — avoid stacking.
  static List<(int, int)> planSlots({
    required (int, int) center,
    required int count,
    required bool Function(int x, int y) isWalkable,
    double radius = 1.5,
  }) {
    if (count <= 0) return const [];
    if (count == 1) return [center];
    if (count == 2) {
      final a = (center.$1 - 1, center.$2);
      final b = (center.$1 + 1, center.$2);
      return [
        if (isWalkable(a.$1, a.$2)) a else center,
        if (isWalkable(b.$1, b.$2)) b else (center.$1, center.$2 + 1),
      ];
    }
    // Semicircle south of center for 3+.
    final angles = <(int, int)>[
      (center.$1 - 1, center.$2 + 1),
      (center.$1, center.$2 + 1),
      (center.$1 + 1, center.$2 + 1),
      (center.$1 - 1, center.$2),
      (center.$1 + 1, center.$2),
    ];
    final out = <(int, int)>[];
    for (final c in angles) {
      if (out.length >= count) break;
      if (isWalkable(c.$1, c.$2) && !out.contains(c)) out.add(c);
    }
    while (out.length < count) {
      out.add(center);
    }
    return out;
  }
}

class TurnTakingState {
  TurnTakingState({
    required this.participantIds,
    this.currentSpeaker,
    this.turnStartedAt = 0,
    this.minimumGap = 0.35,
  });

  final List<String> participantIds;
  String? currentSpeaker;
  double turnStartedAt;
  double minimumGap;
  final Map<String, int> recentTurns = {};
  final List<String> history = [];

  String? pickNext({
    required double now,
    required Map<String, double> topicAffinity,
    required Map<String, SocialStyle> styles,
    required Map<String, double> relationship,
    bool hasResponse = true,
  }) {
    if (now - turnStartedAt < minimumGap && currentSpeaker != null) {
      return null; // silence gap
    }
    String? best;
    var bestScore = -999.0;
    for (final id in participantIds) {
      if (id == currentSpeaker) continue;
      var score = hasResponse ? 0.4 : 0.1;
      score += switch (styles[id] ?? SocialStyle.balanced) {
        SocialStyle.outgoing => 0.35,
        SocialStyle.balanced => 0.15,
        SocialStyle.reserved => 0.0,
      };
      score += (topicAffinity[id] ?? 0.3) * 0.4;
      score += (relationship[id] ?? 0.4) * 0.2;
      score -= (recentTurns[id] ?? 0) * 0.35;
      score += HabitatRng.unit(id, 'turn', now.floor()) * 0.08;
      if (score > bestScore) {
        bestScore = score;
        best = id;
      }
    }
    return best;
  }

  void beginTurn(String speaker, double now) {
    currentSpeaker = speaker;
    turnStartedAt = now;
    recentTurns[speaker] = (recentTurns[speaker] ?? 0) + 1;
    history.add(speaker);
    // Decay monopoly.
    for (final id in participantIds) {
      if (id != speaker && (recentTurns[id] ?? 0) > 0) {
        recentTurns[id] = recentTurns[id]! - 1;
      }
    }
  }

  bool get shouldEndNaturally {
    if (history.length < 4) return false;
    final last = history.sublist(history.length - 3);
    return last.toSet().length == 1; // same speaker thrice → stall
  }
}

enum BackchannelKind { nod, facingAdjust, moteEllipsis, shortAck }

abstract final class BackchannelScheduler {
  static BackchannelKind? maybeEmit({
    required SocialStyle style,
    required String listenerId,
    required double now,
    required double lastEmitAt,
  }) {
    final minGap = switch (style) {
      SocialStyle.outgoing => 2.5,
      SocialStyle.balanced => 4.0,
      SocialStyle.reserved => 6.5,
    };
    if (now - lastEmitAt < minGap) return null;
    final u = HabitatRng.unit(listenerId, 'backchannel', now.floor());
    if (u > 0.35) return null;
    if (u < 0.1) return BackchannelKind.moteEllipsis;
    if (u < 0.2) return BackchannelKind.nod;
    if (u < 0.28) return BackchannelKind.facingAdjust;
    return BackchannelKind.shortAck;
  }
}

class TopicNode {
  const TopicNode(this.id, {this.adjacent = const []});
  final String id;
  final List<String> adjacent;
}

abstract final class TopicDrift {
  static String? nextTopic({
    required String current,
    required Map<String, TopicNode> graph,
    required List<String> interestIds,
    required String pawnId,
    required double now,
  }) {
    final node = graph[current];
    if (node == null || node.adjacent.isEmpty) return null;
    final scored = <(String, double)>[];
    for (final adj in node.adjacent) {
      var s = 0.4;
      if (interestIds.contains(adj)) s += 0.45;
      s += HabitatRng.unit(pawnId, adj, now.floor()) * 0.1;
      scored.add((adj, s));
    }
    scored.sort((a, b) => b.$2.compareTo(a.$2));
    return scored.first.$1;
  }
}

abstract final class MemoryCallback {
  static String? maybeLine({
    required List<String> sharedEventIds,
    required double now,
    required Map<String, double> lastCallbackAt,
    required String pairKey,
    double cooldown = 600,
    double minSalience = 0.5,
    Map<String, double> salience = const {},
  }) {
    final last = lastCallbackAt[pairKey] ?? -9999;
    if (now - last < cooldown) return null;
    final eligible = sharedEventIds
        .where((e) => (salience[e] ?? 0.6) >= minSalience)
        .toList();
    if (eligible.isEmpty) return null;
    final pick = eligible[
        (HabitatRng.unit(pairKey, 'mem', now.floor()) * eligible.length)
            .floor()
            .clamp(0, eligible.length - 1)];
    return 'Lembra de $pick?';
  }
}

class ConversationAudibility {
  const ConversationAudibility({
    required this.level,
    required this.canOverhear,
  });

  final double level;
  final bool canOverhear;
}

abstract final class Overhearing {
  static ConversationAudibility evaluate({
    required double distance,
    required bool sameRoom,
    required bool doorClosedBetween,
    required double noiseProfile,
  }) {
    var level = 1.0 - (distance / 8.0).clamp(0.0, 1.0);
    if (!sameRoom) level *= 0.25;
    if (doorClosedBetween) level *= 0.15;
    level *= (1.0 - noiseProfile * 0.4);
    return ConversationAudibility(
      level: level.clamp(0.0, 1.0),
      canOverhear: level >= 0.28,
    );
  }
}

class ConversationGroup {
  ConversationGroup({
    required this.id,
    required this.participantIds,
    required this.topicId,
    this.capacity = 4,
  });

  final String id;
  final List<String> participantIds;
  String topicId;
  final int capacity;
  late final TurnTakingState turns =
      TurnTakingState(participantIds: participantIds);

  bool get canJoin => participantIds.length < capacity;

  bool tryJoin(String pawnId) {
    if (!canJoin || participantIds.contains(pawnId)) return false;
    participantIds.add(pawnId);
    return true;
  }

  bool leave(String pawnId) {
    final ok = participantIds.remove(pawnId);
    if (turns.currentSpeaker == pawnId) turns.currentSpeaker = null;
    return ok;
  }
}

class SocialInvitation {
  SocialInvitation({
    required this.inviter,
    required this.invitee,
    required this.activityKind,
    required this.expiresAt,
    this.target,
  });

  final String inviter;
  final String invitee;
  final String activityKind;
  final double expiresAt;
  final String? target;
  bool answered = false;
  bool accepted = false;

  bool isExpired(double now) => now >= expiresAt || answered;
}

abstract final class InvitationResolver {
  static bool accept({
    required double utility,
    required double threshold,
  }) =>
      utility >= threshold;
}

class SharedSilenceSession {
  SharedSilenceSession({
    required this.participantIds,
    required this.activityKind,
    required this.startedAt,
  });

  final List<String> participantIds;
  final String activityKind;
  final double startedAt;
  bool suppressBubbles = true;
}

class GroupReactionEvent {
  GroupReactionEvent({
    required this.id,
    required this.kind,
    required this.at,
    required this.participantIds,
  });

  final String id;
  final String kind;
  final double at;
  final List<String> participantIds;
}

class IndividualReaction {
  IndividualReaction({
    required this.pawnId,
    required this.firesAt,
    required this.variant,
  });

  final String pawnId;
  final double firesAt;
  final String variant;
}

abstract final class CoordinatedReactions {
  static List<IndividualReaction> schedule({
    required GroupReactionEvent event,
    required Map<String, BehaviorProfile?> profiles,
  }) {
    final variants = ['wow', 'hmm', 'nice', 'laugh'];
    return [
      for (var i = 0; i < event.participantIds.length; i++)
        IndividualReaction(
          pawnId: event.participantIds[i],
          firesAt: event.at +
              ReactionLatency.compute(
                ReactionLatencyContext(
                  eventClass: ReactionEventClass.ambientEvent,
                  pawnId: event.participantIds[i],
                  profile: profiles[event.participantIds[i]],
                  salt: i,
                  salience: 0.6,
                ),
              ),
          variant: variants[i % variants.length],
        ),
    ];
  }
}

abstract final class TeasingRematch {
  static SocialInvitation? maybeRematch({
    required String winnerId,
    required String loserId,
    required double playfulness,
    required double familiarity,
    required double now,
    required double lastRematchAt,
    String activityKind = 'boardgame',
  }) {
    if (now - lastRematchAt < 120) return null;
    if (playfulness < 0.4 || familiarity < 0.35) return null;
    if (HabitatRng.unit(loserId, 'rematch', now.floor()) > 0.55) return null;
    return SocialInvitation(
      inviter: loserId,
      invitee: winnerId,
      activityKind: activityKind,
      expiresAt: now + 25,
    );
  }
}

enum AcknowledgementKind { glance, gesture, shortSpeech }

abstract final class SocialAcknowledgement {
  static AcknowledgementKind? forTrigger({
    required String trigger,
    required String pairKey,
    required double now,
    required Map<String, double> lastAckAt,
  }) {
    final allowed = {
      'receiveItem',
      'preparedSharedActivity',
      'madeMeal',
      'visitorGift',
    };
    if (!allowed.contains(trigger)) return null;
    final last = lastAckAt[pairKey] ?? -9999;
    if (now - last < 40) return null;
    return switch (trigger) {
      'receiveItem' || 'visitorGift' => AcknowledgementKind.shortSpeech,
      'madeMeal' => AcknowledgementKind.gesture,
      _ => AcknowledgementKind.glance,
    };
  }
}

class SuspendedConversation {
  SuspendedConversation({
    required this.participantIds,
    required this.topicId,
    required this.expiresAt,
    required this.reason,
  });

  final List<String> participantIds;
  final String topicId;
  final double expiresAt;
  final String reason;

  bool canResume({
    required double now,
    required bool manualOrder,
    required bool longAbsence,
  }) {
    if (manualOrder || longAbsence) return false;
    return now <= expiresAt;
  }
}
