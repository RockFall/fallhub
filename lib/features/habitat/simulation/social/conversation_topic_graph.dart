import '../content/habitat_media.dart';
import '../identity/identity.dart';

/// Structured conversation topic (MD 08 M16).
class ConversationTopic {
  const ConversationTopic({
    required this.id,
    required this.interestIds,
    this.tags = const {},
    this.phraseSeeds = const [],
    this.activitySuggestions = const [],
  });

  final String id;
  final Set<String> interestIds;
  final Set<String> tags;
  final List<String> phraseSeeds;
  final List<String> activitySuggestions;
}

/// Scores and picks conversation topics from interests + media + context.
class ConversationTopicGraph {
  ConversationTopicGraph({List<ConversationTopic>? seed})
      : topics = List.of(seed ?? defaultTopics);

  final List<ConversationTopic> topics;
  final Map<String, double> _recentUntil = {};

  static final List<ConversationTopic> defaultTopics = [
    const ConversationTopic(
      id: 'music.jazz',
      interestIds: {'music/jazz', 'music'},
      phraseSeeds: [
        'Esse modal fica vivo no ar…',
        'Kind of Blue nunca envelhece.',
        'Fusion hoje ou bebop clássico?',
      ],
      activitySuggestions: ['listenMusic', 'recreate'],
    ),
    const ConversationTopic(
      id: 'music.general',
      interestIds: {'music'},
      phraseSeeds: [
        'Que tal um disco?',
        'A trilha muda o cômodo.',
      ],
      activitySuggestions: ['listenMusic'],
    ),
    const ConversationTopic(
      id: 'book.current',
      interestIds: {'literature', 'learning'},
      phraseSeeds: [
        'Estou no meio de um livro bom.',
        'Capítulo curto e já volta.',
      ],
      activitySuggestions: ['sit', 'rest'],
    ),
    const ConversationTopic(
      id: 'movie',
      interestIds: {'film'},
      phraseSeeds: [
        'Filme curto hoje?',
        'A TV chama.',
      ],
      activitySuggestions: ['watchTv', 'recreate'],
    ),
    const ConversationTopic(
      id: 'food',
      interestIds: {'food', 'cooking'},
      phraseSeeds: [
        'Fome de verdade ou só vontade?',
        'Cozinha juntos?',
      ],
      activitySuggestions: ['goToTable'],
    ),
    const ConversationTopic(
      id: 'cooking',
      interestIds: {'cooking', 'food'},
      phraseSeeds: [
        'Receita nova ou clássico?',
      ],
      activitySuggestions: ['goToTable'],
    ),
    const ConversationTopic(
      id: 'travel',
      interestIds: {'travel', 'nature'},
      phraseSeeds: [
        'Lembra daquela viagem?',
        'Terraço parece quase viagem.',
      ],
      activitySuggestions: ['terraceWalk', 'wander'],
    ),
    const ConversationTopic(
      id: 'game',
      interestIds: {'game'},
      phraseSeeds: [
        'Uma partida rápida?',
        'Revanche?',
      ],
      activitySuggestions: ['recreate'],
    ),
    const ConversationTopic(
      id: 'art',
      interestIds: {'art'},
      phraseSeeds: [
        'Esse quadro mudou o clima.',
      ],
    ),
    const ConversationTopic(
      id: 'technology',
      interestIds: {'technology', 'learning'},
      phraseSeeds: [
        'Achei um truque novo.',
      ],
    ),
    const ConversationTopic(
      id: 'currentActivity',
      interestIds: {},
      tags: {'context'},
      phraseSeeds: [
        'E aí, no que você está?',
      ],
    ),
    const ConversationTopic(
      id: 'roomObject',
      interestIds: {},
      tags: {'context'},
      phraseSeeds: [
        'Olha esse canto aqui…',
      ],
    ),
    const ConversationTopic(
      id: 'weather',
      interestIds: {'nature'},
      tags: {'context'},
      phraseSeeds: [
        'O tempo lá fora…',
      ],
      activitySuggestions: ['terraceWalk'],
    ),
    const ConversationTopic(
      id: 'futurePlanSimulated',
      interestIds: {},
      tags: {'plans'},
      phraseSeeds: [
        'E se a gente marcar algo?',
      ],
    ),
  ];

  double score({
    required ConversationTopic topic,
    required PreferenceStore prefsA,
    required PreferenceStore prefsB,
    required String pawnA,
    required String pawnB,
    HabitatMediaItem? nearbyMedia,
    double now = 0,
  }) {
    double interestScore(PreferenceStore prefs, String pawn) {
      if (topic.interestIds.isEmpty) return 0.25;
      var sum = 0.0;
      for (final id in topic.interestIds) {
        sum += prefs.effectiveAffinity(pawn, id) ?? 0.3;
      }
      return sum / topic.interestIds.length;
    }

    final a = interestScore(prefsA, pawnA);
    final b = interestScore(prefsB, pawnB);
    var shared = 0.0;
    for (final id in topic.interestIds) {
      final av = prefsA.effectiveAffinity(pawnA, id) ?? 0;
      final bv = prefsB.effectiveAffinity(pawnB, id) ?? 0;
      if (av > 0.5 && bv > 0.5) shared += 0.15;
    }

    var mediaCue = 0.0;
    if (nearbyMedia != null) {
      for (final t in nearbyMedia.interestTags) {
        if (topic.interestIds.contains(t) ||
            topic.interestIds.any((i) => t.startsWith(i) || i.startsWith(t))) {
          mediaCue += 0.2;
        }
      }
    }

    final recent = _recentUntil[topic.id];
    final penalty = (recent != null && now < recent) ? 0.25 : 0.0;

    return (0.35 * a + 0.35 * b + shared + mediaCue - penalty).clamp(0.0, 1.5);
  }

  ConversationTopic? pick({
    required PreferenceStore prefsA,
    required PreferenceStore prefsB,
    required String pawnA,
    required String pawnB,
    HabitatMediaItem? nearbyMedia,
    double now = 0,
  }) {
    ConversationTopic? best;
    var bestScore = -1.0;
    for (final t in topics) {
      final s = score(
        topic: t,
        prefsA: prefsA,
        prefsB: prefsB,
        pawnA: pawnA,
        pawnB: pawnB,
        nearbyMedia: nearbyMedia,
        now: now,
      );
      if (s > bestScore) {
        bestScore = s;
        best = t;
      }
    }
    if (best != null && bestScore > 0.2) {
      _recentUntil[best.id] = now + 90;
    }
    return best;
  }

  String phraseFor(ConversationTopic topic, int salt) {
    if (topic.phraseSeeds.isEmpty) return '…';
    return topic.phraseSeeds[salt % topic.phraseSeeds.length];
  }
}
