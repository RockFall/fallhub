import 'dart:math' as math;

part 'habitat_social_dialogue_pack.dart';

/// Social venue affordance (V9.14).
enum SocialVenue {
  stand,
  table,
  sofa,
  gatheringSpot,
  doorwayChat,
}

/// Topic seeds — used for memory / scoring / pack routing.
enum SocialTopic {
  roomBeauty,
  lampLight,
  filth,
  weatherOut,
  mealTable,
  workDesk,
  nightQuiet,
  idleLife,
  crowding,
  cozyWarm,
  humorBanter,
  plansFuture,
  restSleep,
  foodTalk,
  memoryPast,
  colonyLife,
}

/// Legacy beat labels kept for a few call sites / docs.
enum SocialBeatType { greet, talk, joke, glance, agree, farewell }

class SocialBeatPlan {
  const SocialBeatPlan(this.type, {this.satelliteTopic = false});
  final SocialBeatType type;
  final bool satelliteTopic;
}

/// Immutable snapshot for one encounter's dialogue.
class TalkContext {
  const TalkContext({
    required this.venue,
    required this.phaseLabel,
    required this.beautyBand,
    required this.cleanBand,
    required this.lightBand,
    required this.tempBand,
    required this.affinity,
    required this.isOutdoor,
    required this.spaceTight,
    required this.comfortOk,
    required this.hasLamp,
    required this.isOffice,
    this.recentTopics = const [],
    this.listenerName = '',
    this.speakerName = '',
  });

  final SocialVenue venue;
  final String phaseLabel;
  final String beautyBand;
  final String cleanBand;
  final String lightBand;
  final String tempBand;
  final double affinity;
  final bool isOutdoor;
  final bool spaceTight;
  final bool comfortOk;
  final bool hasLamp;
  final bool isOffice;
  final List<SocialTopic> recentTopics;
  final String listenerName;
  final String speakerName;

  String get phaseWord => switch (phaseLabel) {
        'Madrugada' => 'madrugada',
        'Amanhecer' => 'amanhecer',
        'Dia' => 'dia',
        'Entardecer' => 'entardecer',
        'Noite' => 'noite',
        _ => 'momento',
      };

  String get venueWord => switch (venue) {
        SocialVenue.table => 'nessa mesa',
        SocialVenue.gatheringSpot => 'aqui no ponto',
        SocialVenue.doorwayChat => 'nessa porta',
        SocialVenue.sofa => 'nesse sofá',
        SocialVenue.stand => 'por aqui',
      };

  String get tempWord => switch (tempBand) {
        'hot' => 'quente',
        'cold' => 'frio',
        _ => 'ameno',
      };
}

/// Topic + reply-tag chosen for this encounter.
class DialoguePlan {
  const DialoguePlan(this.topic, {this.satellite, this.replyTag});

  final SocialTopic topic;
  final SocialTopic? satellite;
  final String? replyTag;
}

/// One spoken line in a scripted adjacency pair.
class DialogueLine {
  const DialogueLine({
    required this.speakerId,
    required this.text,
    this.isThought = false,
    this.replyTag,
  });

  final String speakerId;
  final String text;
  final bool isThought;
  final String? replyTag;
}

/// Full SpeakUp-lite script for one encounter.
class DialogueScript {
  const DialogueScript({
    required this.plan,
    required this.lines,
  });

  final DialoguePlan plan;
  final List<DialogueLine> lines;
}

/// Result of a single assemble (compat / tests).
class AssembledLine {
  const AssembledLine(
    this.text, {
    this.polarity,
    this.usedOpener = false,
    this.replyTag,
  });

  final String text;
  final String? polarity;
  final bool usedOpener;
  final String? replyTag;
}

enum SocialDialogueRole { open, reply, follow, farewell }

/// Conditioned dialogue rule (SpeakUp-lite).
class SocialDialogueRule {
  const SocialDialogueRule({
    required this.id,
    required this.role,
    required this.template,
    required this.topic,
    this.replyTag,
    this.priority = 0,
    this.weight = 1,
    this.when,
    this.thought = false,
    this.polarity,
  });

  final String id;
  final SocialDialogueRole role;
  final String template;
  final SocialTopic topic;
  final String? replyTag;
  final int priority;
  final double weight;
  final bool Function(TalkContext ctx)? when;
  final bool thought;
  final String? polarity;

  bool matches(TalkContext ctx, {String? requiredTag}) {
    if (replyTag != null &&
        requiredTag != null &&
        replyTag != requiredTag &&
        role != SocialDialogueRole.open) {
      return false;
    }
    if (when != null && !when!(ctx)) return false;
    return true;
  }
}

/// Multi-turn authored conversation on one subject (longer than open/reply).
///
/// [beats] alternate initiator → recipient → initiator → …
/// A farewell is appended by the assembler unless [includeFarewell] is false.
class DialogueThread {
  const DialogueThread({
    required this.id,
    required this.topic,
    required this.replyTag,
    required this.beats,
    this.when,
    this.priority = 0,
    this.weight = 1,
    this.includeFarewell = true,
    this.minAffinity = 0.28,
  });

  final String id;
  final SocialTopic topic;
  final String replyTag;

  /// Templates in order; even index = initiator, odd = recipient.
  final List<String> beats;
  final bool Function(TalkContext ctx)? when;
  final int priority;
  final double weight;
  final bool includeFarewell;
  final double minAffinity;

  bool matches(TalkContext ctx) {
    if (ctx.affinity < minAffinity) return false;
    if (when != null && !when!(ctx)) return false;
    return true;
  }
}

/// SpeakUp-lite dialogue engine: conditioned openers → tagged replies / threads.
class SocialLineAssembler {
  SocialLineAssembler({math.Random? rng}) : _rng = rng ?? math.Random();

  final math.Random _rng;
  final List<String> _recentRuleIds = [];
  final List<String> _recentThreadIds = [];
  static const int maxLen = 64;
  static const int recentRing = 14;

  static List<SocialDialogueRule> get _rules => SocialDialoguePack.rules;
  static List<DialogueThread> get _threads => SocialDialoguePack.threads;

  DialoguePlan buildPlan(TalkContext ctx, math.Random rng) {
    final enabled = _enabledTopics(ctx);
    final weights = <SocialTopic, double>{};
    for (final t in enabled) {
      var w = 1.0;
      if (ctx.recentTopics.contains(t)) w *= 0.15;
      weights[t] = w;
    }
    var total = weights.values.fold(0.0, (a, b) => a + b);
    if (total <= 0) {
      return const DialoguePlan(SocialTopic.idleLife, replyTag: 'idle_ok');
    }
    var roll = rng.nextDouble() * total;
    var picked = SocialTopic.idleLife;
    for (final e in weights.entries) {
      roll -= e.value;
      if (roll <= 0) {
        picked = e.key;
        break;
      }
    }
    return DialoguePlan(picked);
  }

  List<SocialBeatPlan> beatsForPlan(
    DialoguePlan plan,
    TalkContext ctx,
    math.Random rng,
  ) {
    return const [
      SocialBeatPlan(SocialBeatType.talk),
      SocialBeatPlan(SocialBeatType.talk),
      SocialBeatPlan(SocialBeatType.farewell),
    ];
  }

  /// Build a coherent script — short adjacency pair or longer subject thread.
  DialogueScript buildScript({
    required TalkContext ctx,
    required String initiatorId,
    required String recipientId,
    required String initiatorName,
    required String recipientName,
    DialoguePlan? plan,
  }) {
    final p = plan ?? buildPlan(ctx, _rng);
    final openCtx = _ctxAs(ctx, speaker: initiatorName, listener: recipientName);
    final replyCtx = _ctxAs(ctx, speaker: recipientName, listener: initiatorName);

    if (ctx.affinity < 0.22) {
      return DialogueScript(
        plan: DialoguePlan(p.topic, replyTag: 'cold'),
        lines: [
          DialogueLine(speakerId: initiatorId, text: '…'),
          DialogueLine(
            speakerId: recipientId,
            text: '…',
            isThought: true,
          ),
        ],
      );
    }

    // Longer subject threads (~32% when available).
    if (_rng.nextDouble() < 0.32) {
      final thread = _pickThread(openCtx, p.topic);
      if (thread != null) {
        return _scriptFromThread(
          thread,
          openCtx: openCtx,
          replyCtx: replyCtx,
          initiatorId: initiatorId,
          recipientId: recipientId,
          initiatorName: initiatorName,
          recipientName: recipientName,
        );
      }
    }

    return _scriptFromRules(
      p,
      openCtx: openCtx,
      replyCtx: replyCtx,
      initiatorId: initiatorId,
      recipientId: recipientId,
      initiatorName: initiatorName,
      recipientName: recipientName,
    );
  }

  DialogueScript _scriptFromThread(
    DialogueThread thread, {
    required TalkContext openCtx,
    required TalkContext replyCtx,
    required String initiatorId,
    required String recipientId,
    required String initiatorName,
    required String recipientName,
  }) {
    _recentThreadIds.add(thread.id);
    while (_recentThreadIds.length > 6) {
      _recentThreadIds.removeAt(0);
    }

    final lines = <DialogueLine>[];
    for (var i = 0; i < thread.beats.length; i++) {
      final initiatorTurn = i.isEven;
      final speakerId = initiatorTurn ? initiatorId : recipientId;
      final c = initiatorTurn ? openCtx : replyCtx;
      final listener = initiatorTurn ? recipientName : initiatorName;
      final thought = !initiatorTurn && i == thread.beats.length - 1
          ? false
          : (!initiatorTurn && _rng.nextDouble() < 0.18);
      lines.add(
        DialogueLine(
          speakerId: speakerId,
          text: _clip(_fill(thread.beats[i], c, listener: listener)),
          isThought: thought,
          replyTag: thread.replyTag,
        ),
      );
    }

    if (thread.includeFarewell) {
      final bye = _pickRule(
        role: SocialDialogueRole.farewell,
        ctx: openCtx,
        topic: thread.topic,
      );
      lines.add(
        DialogueLine(
          speakerId: initiatorId,
          text: _clip(
            _fill(bye?.template ?? 'Até.', openCtx, listener: recipientName),
          ),
        ),
      );
    }

    return DialogueScript(
      plan: DialoguePlan(thread.topic, replyTag: thread.replyTag),
      lines: lines,
    );
  }

  DialogueScript _scriptFromRules(
    DialoguePlan p, {
    required TalkContext openCtx,
    required TalkContext replyCtx,
    required String initiatorId,
    required String recipientId,
    required String initiatorName,
    required String recipientName,
  }) {
    final opener = _pickRule(
      role: SocialDialogueRole.open,
      ctx: openCtx,
      topic: p.topic,
    );
    final tag = opener?.replyTag ?? 'idle_ok';
    _remember(opener?.id);

    final reply = _pickRule(
      role: SocialDialogueRole.reply,
      ctx: replyCtx,
      topic: p.topic,
      requiredTag: tag,
    );
    _remember(reply?.id);

    final lines = <DialogueLine>[
      DialogueLine(
        speakerId: initiatorId,
        text: _clip(
          _fill(opener?.template ?? 'E aí.', openCtx, listener: recipientName),
        ),
        replyTag: tag,
      ),
      DialogueLine(
        speakerId: recipientId,
        text: _clip(
          _fill(reply?.template ?? 'Pois é.', replyCtx, listener: initiatorName),
        ),
        isThought: reply?.thought ?? false,
        replyTag: tag,
      ),
    ];

    // Extra back-and-forth when affinity is warm and material exists.
    final extraChance = openCtx.affinity >= 0.45 ? 0.55 : 0.38;
    if (_rng.nextDouble() < extraChance) {
      final follow = _pickRule(
        role: SocialDialogueRole.follow,
        ctx: openCtx,
        topic: p.topic,
        requiredTag: tag,
      );
      if (follow != null) {
        lines.add(
          DialogueLine(
            speakerId: initiatorId,
            text: _clip(
              _fill(follow.template, openCtx, listener: recipientName),
            ),
            replyTag: tag,
          ),
        );
        _remember(follow.id);

        // Recipient closes the thought sometimes.
        if (_rng.nextDouble() < 0.45) {
          final reply2 = _pickRule(
            role: SocialDialogueRole.reply,
            ctx: replyCtx,
            topic: p.topic,
            requiredTag: tag,
          );
          if (reply2 != null && reply2.id != reply?.id) {
            lines.add(
              DialogueLine(
                speakerId: recipientId,
                text: _clip(
                  _fill(
                    reply2.template,
                    replyCtx,
                    listener: initiatorName,
                  ),
                ),
                replyTag: tag,
              ),
            );
            _remember(reply2.id);
          }
        }
      }
    }

    final bye = _pickRule(
      role: SocialDialogueRole.farewell,
      ctx: openCtx,
      topic: p.topic,
    );
    lines.add(
      DialogueLine(
        speakerId: initiatorId,
        text: _clip(
          _fill(bye?.template ?? 'Até.', openCtx, listener: recipientName),
        ),
      ),
    );

    return DialogueScript(
      plan: DialoguePlan(p.topic, replyTag: tag),
      lines: lines,
    );
  }

  AssembledLine assemble(
    SocialBeatType beat,
    DialoguePlan plan,
    TalkContext ctx, {
    required String speakerId,
    required String listenerId,
    required String listenerName,
    required bool usedOpener,
    required bool isResponse,
    String? lastPolarity,
    String? replyTag,
  }) {
    final role = switch (beat) {
      SocialBeatType.farewell => SocialDialogueRole.farewell,
      SocialBeatType.glance => SocialDialogueRole.reply,
      _ when isResponse => SocialDialogueRole.reply,
      _ => SocialDialogueRole.open,
    };
    final rule = _pickRule(
      role: role,
      ctx: ctx,
      topic: plan.topic,
      requiredTag: role == SocialDialogueRole.reply
          ? (replyTag ?? plan.replyTag ?? _defaultTag(plan.topic))
          : null,
    );
    final text = _clip(
      _fill(rule?.template ?? '…', ctx, listener: listenerName),
    );
    return AssembledLine(
      text,
      polarity: rule?.polarity ?? lastPolarity,
      usedOpener: role == SocialDialogueRole.open,
      replyTag: rule?.replyTag ?? replyTag ?? plan.replyTag,
    );
  }

  DialogueThread? _pickThread(TalkContext ctx, SocialTopic topic) {
    bool topicOk(DialogueThread t) {
      if (t.topic == topic) return true;
      // Idle plans may borrow a matching thread from another topic.
      return topic == SocialTopic.idleLife;
    }

    var pool = _threads.where((t) {
      if (!topicOk(t)) return false;
      if (_recentThreadIds.contains(t.id)) return false;
      return t.matches(ctx);
    }).toList();

    if (pool.isEmpty) {
      pool = _threads
          .where((t) => t.topic == topic && t.matches(ctx))
          .toList();
    }
    if (pool.isEmpty) return null;

    final maxP = pool.map((t) => t.priority).reduce(math.max);
    final top = pool.where((t) => t.priority == maxP).toList();
    var total = 0.0;
    for (final t in top) {
      total += t.weight;
    }
    var roll = _rng.nextDouble() * total;
    for (final t in top) {
      roll -= t.weight;
      if (roll <= 0) return t;
    }
    return top.last;
  }

  SocialDialogueRule? _pickRule({
    required SocialDialogueRole role,
    required TalkContext ctx,
    required SocialTopic topic,
    String? requiredTag,
  }) {
    bool topicGate(SocialDialogueRule r) {
      if (role == SocialDialogueRole.open) return r.topic == topic;
      if (role == SocialDialogueRole.farewell) {
        return r.topic == topic || r.topic == SocialTopic.idleLife;
      }
      return true;
    }

    var pool = _rules.where((r) {
      if (r.role != role) return false;
      if (!topicGate(r)) return false;
      if ((role == SocialDialogueRole.reply ||
              role == SocialDialogueRole.follow) &&
          requiredTag != null &&
          r.replyTag != requiredTag) {
        return false;
      }
      if (!r.matches(ctx, requiredTag: requiredTag)) return false;
      if (_recentRuleIds.contains(r.id)) return false;
      return true;
    }).toList();

    // Prefer topic-specific farewells over generic idle ones.
    if (role == SocialDialogueRole.farewell && pool.isNotEmpty) {
      final specific = pool.where((r) => r.topic == topic).toList();
      if (specific.isNotEmpty) pool = specific;
    }

    if (pool.isEmpty) {
      pool = _rules.where((r) {
        if (r.role != role) return false;
        if (role == SocialDialogueRole.farewell) {
          return r.topic == topic || r.topic == SocialTopic.idleLife;
        }
        if ((role == SocialDialogueRole.reply ||
                role == SocialDialogueRole.follow) &&
            requiredTag != null &&
            r.replyTag != requiredTag) {
          return false;
        }
        return r.matches(ctx, requiredTag: requiredTag);
      }).toList();
    }

    if (pool.isEmpty && role == SocialDialogueRole.open) {
      pool = _rules
          .where(
            (r) =>
                r.role == SocialDialogueRole.open &&
                r.topic == SocialTopic.idleLife &&
                r.matches(ctx),
          )
          .toList();
    }
    if (pool.isEmpty && role == SocialDialogueRole.reply) {
      pool = _rules
          .where(
            (r) =>
                r.role == SocialDialogueRole.reply &&
                r.replyTag == 'idle_ok' &&
                r.matches(ctx),
          )
          .toList();
    }
    if (pool.isEmpty) return null;

    final maxP = pool.map((r) => r.priority).reduce(math.max);
    final top = pool.where((r) => r.priority == maxP).toList();
    var total = 0.0;
    for (final r in top) {
      total += r.weight;
    }
    var roll = _rng.nextDouble() * total;
    for (final r in top) {
      roll -= r.weight;
      if (roll <= 0) return r;
    }
    return top.last;
  }

  void _remember(String? id) {
    if (id == null) return;
    _recentRuleIds.add(id);
    while (_recentRuleIds.length > recentRing) {
      _recentRuleIds.removeAt(0);
    }
  }

  TalkContext _ctxAs(
    TalkContext ctx, {
    required String speaker,
    required String listener,
  }) {
    return TalkContext(
      venue: ctx.venue,
      phaseLabel: ctx.phaseLabel,
      beautyBand: ctx.beautyBand,
      cleanBand: ctx.cleanBand,
      lightBand: ctx.lightBand,
      tempBand: ctx.tempBand,
      affinity: ctx.affinity,
      isOutdoor: ctx.isOutdoor,
      spaceTight: ctx.spaceTight,
      comfortOk: ctx.comfortOk,
      hasLamp: ctx.hasLamp,
      isOffice: ctx.isOffice,
      recentTopics: ctx.recentTopics,
      listenerName: listener,
      speakerName: speaker,
    );
  }

  String _fill(String template, TalkContext ctx, {required String listener}) {
    final name = listener.length <= 10 && ctx.affinity >= 0.35 ? listener : '';
    final named = name.isEmpty ? '' : ', $name';
    final namedLead = name.isEmpty ? '' : '$name, ';
    return template
        .replaceAll('{name}', name)
        .replaceAll('{named}', named)
        .replaceAll('{namedLead}', namedLead)
        .replaceAll('{phase}', ctx.phaseWord)
        .replaceAll('{temp}', ctx.tempWord)
        .replaceAll('{venue}', ctx.venueWord)
        .replaceAll('{beauty}', ctx.beautyBand == 'high' ? 'bonito' : 'ok')
        .replaceAll(
          '{light}',
          ctx.lightBand == 'dark' ? 'escuro' : 'claro',
        )
        .replaceAll(RegExp(r'\s+'), ' ')
        .replaceAll(' ,', ',')
        .replaceAll('..', '.')
        .trim();
  }

  String _clip(String text) {
    if (text.length <= maxLen) return text;
    final cut = text.substring(0, maxLen - 1);
    final space = cut.lastIndexOf(' ');
    if (space > 18) return '${cut.substring(0, space)}…';
    return '$cut…';
  }

  String _defaultTag(SocialTopic t) => switch (t) {
        SocialTopic.roomBeauty => 'beauty_ok',
        SocialTopic.lampLight => 'lamp_ok',
        SocialTopic.filth => 'filth_floor',
        SocialTopic.weatherOut => 'weather_out',
        SocialTopic.mealTable => 'table_chat',
        SocialTopic.workDesk => 'work_desk',
        SocialTopic.nightQuiet => 'night_quiet',
        SocialTopic.crowding => 'crowd_tight',
        SocialTopic.cozyWarm => 'cozy_ok',
        SocialTopic.idleLife => 'idle_ok',
        SocialTopic.humorBanter => 'humor_ok',
        SocialTopic.plansFuture => 'plans_ok',
        SocialTopic.restSleep => 'rest_ok',
        SocialTopic.foodTalk => 'food_ok',
        SocialTopic.memoryPast => 'memory_ok',
        SocialTopic.colonyLife => 'colony_ok',
      };

  List<SocialTopic> _enabledTopics(TalkContext ctx) {
    final out = <SocialTopic>[
      SocialTopic.idleLife,
      SocialTopic.colonyLife,
    ];
    if (ctx.beautyBand != 'low' && ctx.lightBand != 'dark') {
      out.add(SocialTopic.roomBeauty);
    }
    if (ctx.hasLamp && ctx.lightBand != 'dark') out.add(SocialTopic.lampLight);
    if (ctx.cleanBand == 'low') out.add(SocialTopic.filth);
    if (ctx.isOutdoor ||
        ctx.phaseLabel == 'Entardecer' ||
        ctx.phaseLabel == 'Noite') {
      out.add(SocialTopic.weatherOut);
    }
    if (ctx.venue == SocialVenue.table) {
      out.add(SocialTopic.mealTable);
      out.add(SocialTopic.foodTalk);
    }
    if (ctx.isOffice && ctx.hasLamp) out.add(SocialTopic.workDesk);
    if (ctx.phaseLabel == 'Noite' || ctx.phaseLabel == 'Madrugada') {
      out.add(SocialTopic.nightQuiet);
      out.add(SocialTopic.restSleep);
    }
    if (ctx.spaceTight) out.add(SocialTopic.crowding);
    if (ctx.comfortOk && ctx.beautyBand != 'low') out.add(SocialTopic.cozyWarm);
    if (ctx.affinity >= 0.35) {
      out.add(SocialTopic.humorBanter);
      out.add(SocialTopic.memoryPast);
    }
    if (ctx.phaseLabel == 'Dia' || ctx.phaseLabel == 'Amanhecer') {
      out.add(SocialTopic.plansFuture);
    }
    if (ctx.phaseLabel == 'Dia' || ctx.venue == SocialVenue.table) {
      out.add(SocialTopic.foodTalk);
    }
    return out;
  }
}
