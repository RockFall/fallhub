import 'package:equatable/equatable.dart';

import 'enums.dart';
import 'id_generator.dart';

enum MusicNodeType {
  artist,
  work,
  recording,
  releaseGroup,
  release,
  territory,
  scene,
  concept,
  label,
  place,
  show,
}

/// Personal relation to a node — not quality of the work (spec §10).
enum MusicDiscoveryState {
  unmapped,
  rumor,
  sighted,
  sampled,
  visited,
  cartographed,
  connected,
  internalized,
  living,
  dormant,
  archived,
}

enum MusicEncounterType {
  contact,
  listen,
  attentiveListen,
  comparison,
  practice,
  live,
  importListen,
}

enum MusicRelationType {
  influenced,
  sharesScene,
  successor,
  contemporaneous,
  cover,
  sample,
  memberOf,
  related,
}

enum MusicClaimStatus { proposed, accepted, disputed }

enum MusicExpeditionStatus {
  draft,
  ready,
  active,
  paused,
  completed,
  abandoned,
}

enum MusicExpeditionStopRole { camp, bridge, portal, destination }

enum MusicImportSourceKind {
  json,
  spotifyLibrary,
  spotifyRecent,
  spotifyPlaylist,
  spotifyHistory,
  listenbrainz,
  csv,
}

enum MusicImportRunStatus { preview, applied, rolledBack, failed }

enum MusicImportResolution { create, link, skip, conflict }

class MusicExternalIdentity extends Equatable {
  const MusicExternalIdentity({
    required this.id,
    required this.nodeId,
    required this.provider,
    required this.entityType,
    required this.externalId,
    this.externalUrl,
    this.confidence = 1,
    this.reviewedByUser = false,
    this.metadataJson = '{}',
    required this.createdAt,
    required this.updatedAt,
  });

  final EntityId id;
  final EntityId nodeId;
  final String provider;
  final String entityType;
  final String externalId;
  final String? externalUrl;
  final double confidence;
  final bool reviewedByUser;
  final String metadataJson;
  final DateTime createdAt;
  final DateTime updatedAt;

  @override
  List<Object?> get props => [
    id,
    nodeId,
    provider,
    entityType,
    externalId,
    externalUrl,
    confidence,
    reviewedByUser,
    metadataJson,
    createdAt,
    updatedAt,
  ];
}

class MusicNode extends Equatable {
  const MusicNode({
    required this.id,
    required this.nodeType,
    required this.canonicalName,
    required this.sortName,
    this.description,
    this.beginYear,
    this.endYear,
    this.metadataQuality = 0,
    this.provenanceJson = '{}',
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
    this.version = 1,
  });

  final EntityId id;
  final MusicNodeType nodeType;
  final String canonicalName;
  final String sortName;
  final String? description;
  final int? beginYear;
  final int? endYear;
  final double metadataQuality;
  final String provenanceJson;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? deletedAt;
  final int version;

  factory MusicNode.create({
    required EntityId id,
    required MusicNodeType nodeType,
    required String canonicalName,
    required DateTime now,
    String? description,
    int? beginYear,
    int? endYear,
    String provenanceJson = '{}',
  }) {
    final name = canonicalName.trim();
    if (name.isEmpty) {
      throw ArgumentError('MusicNode.canonicalName must not be empty');
    }
    return MusicNode(
      id: id,
      nodeType: nodeType,
      canonicalName: name,
      sortName: MusicIdentityPolicy.sortName(name),
      description: description?.trim().isEmpty == true
          ? null
          : description?.trim(),
      beginYear: beginYear,
      endYear: endYear,
      provenanceJson: provenanceJson,
      createdAt: now,
      updatedAt: now,
    );
  }

  MusicNode copyWith({
    String? canonicalName,
    String? description,
    int? beginYear,
    int? endYear,
    String? provenanceJson,
    DateTime? updatedAt,
    DateTime? deletedAt,
    int? version,
  }) {
    final name = canonicalName?.trim() ?? this.canonicalName;
    return MusicNode(
      id: id,
      nodeType: nodeType,
      canonicalName: name,
      sortName: MusicIdentityPolicy.sortName(name),
      description: description ?? this.description,
      beginYear: beginYear ?? this.beginYear,
      endYear: endYear ?? this.endYear,
      metadataQuality: metadataQuality,
      provenanceJson: provenanceJson ?? this.provenanceJson,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
      version: version ?? this.version,
    );
  }

  @override
  List<Object?> get props => [
    id,
    nodeType,
    canonicalName,
    sortName,
    description,
    beginYear,
    endYear,
    metadataQuality,
    provenanceJson,
    createdAt,
    updatedAt,
    deletedAt,
    version,
  ];
}

class PersonalMusicNodeState extends Equatable {
  const PersonalMusicNodeState({
    required this.profileId,
    required this.nodeId,
    required this.discoveryState,
    this.resonance,
    this.firstEncounterAt,
    this.lastEncounterAt,
    this.encounterCount = 0,
    this.personalSummary,
    this.nextAction,
    required this.createdAt,
    required this.updatedAt,
    this.version = 1,
  });

  final EntityId profileId;
  final EntityId nodeId;
  final MusicDiscoveryState discoveryState;
  final int? resonance;
  final DateTime? firstEncounterAt;
  final DateTime? lastEncounterAt;
  final int encounterCount;
  final String? personalSummary;
  final String? nextAction;
  final DateTime createdAt;
  final DateTime updatedAt;
  final int version;

  PersonalMusicNodeState copyWith({
    MusicDiscoveryState? discoveryState,
    int? resonance,
    DateTime? firstEncounterAt,
    DateTime? lastEncounterAt,
    int? encounterCount,
    String? personalSummary,
    String? nextAction,
    DateTime? updatedAt,
    int? version,
  }) {
    return PersonalMusicNodeState(
      profileId: profileId,
      nodeId: nodeId,
      discoveryState: discoveryState ?? this.discoveryState,
      resonance: resonance ?? this.resonance,
      firstEncounterAt: firstEncounterAt ?? this.firstEncounterAt,
      lastEncounterAt: lastEncounterAt ?? this.lastEncounterAt,
      encounterCount: encounterCount ?? this.encounterCount,
      personalSummary: personalSummary ?? this.personalSummary,
      nextAction: nextAction ?? this.nextAction,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      version: version ?? this.version,
    );
  }

  @override
  List<Object?> get props => [
    profileId,
    nodeId,
    discoveryState,
    resonance,
    firstEncounterAt,
    lastEncounterAt,
    encounterCount,
    personalSummary,
    nextAction,
    createdAt,
    updatedAt,
    version,
  ];
}

class MusicEncounter extends Equatable {
  const MusicEncounter({
    required this.id,
    required this.profileId,
    required this.nodeId,
    required this.encounterType,
    required this.occurredAt,
    this.durationSeconds,
    this.attentionQuality,
    this.resonance,
    this.note,
    required this.sourceType,
    required this.provenanceJson,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
  });

  final EntityId id;
  final EntityId profileId;
  final EntityId nodeId;
  final MusicEncounterType encounterType;
  final DateTime occurredAt;
  final int? durationSeconds;
  final int? attentionQuality;
  final int? resonance;
  final String? note;
  final SourceType sourceType;
  final String provenanceJson;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? deletedAt;

  factory MusicEncounter.record({
    required EntityId id,
    required EntityId profileId,
    required EntityId nodeId,
    required MusicEncounterType encounterType,
    required DateTime occurredAt,
    required DateTime now,
    required SourceType sourceType,
    int? durationSeconds,
    int? attentionQuality,
    int? resonance,
    String? note,
    String provenanceJson = '{}',
  }) {
    if (resonance != null && (resonance < -2 || resonance > 3)) {
      throw ArgumentError.value(resonance, 'resonance', 'must be -2..3');
    }
    return MusicEncounter(
      id: id,
      profileId: profileId,
      nodeId: nodeId,
      encounterType: encounterType,
      occurredAt: occurredAt,
      durationSeconds: durationSeconds,
      attentionQuality: attentionQuality,
      resonance: resonance,
      note: note?.trim().isEmpty == true ? null : note?.trim(),
      sourceType: sourceType,
      provenanceJson: provenanceJson,
      createdAt: now,
      updatedAt: now,
    );
  }

  @override
  List<Object?> get props => [
    id,
    profileId,
    nodeId,
    encounterType,
    occurredAt,
    durationSeconds,
    attentionQuality,
    resonance,
    note,
    sourceType,
    provenanceJson,
    createdAt,
    updatedAt,
    deletedAt,
  ];
}

class MusicRelationClaim extends Equatable {
  const MusicRelationClaim({
    required this.id,
    required this.fromNodeId,
    required this.toNodeId,
    required this.relationType,
    this.description,
    required this.status,
    this.confidence,
    this.validFrom,
    this.validTo,
    required this.provenanceJson,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
  });

  final EntityId id;
  final EntityId fromNodeId;
  final EntityId toNodeId;
  final MusicRelationType relationType;
  final String? description;
  final MusicClaimStatus status;
  final double? confidence;
  final String? validFrom;
  final String? validTo;
  final String provenanceJson;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? deletedAt;

  @override
  List<Object?> get props => [
    id,
    fromNodeId,
    toNodeId,
    relationType,
    description,
    status,
    confidence,
    validFrom,
    validTo,
    provenanceJson,
    createdAt,
    updatedAt,
    deletedAt,
  ];
}

class MusicExpedition extends Equatable {
  const MusicExpedition({
    required this.id,
    required this.profileId,
    required this.title,
    required this.question,
    required this.status,
    this.purpose,
    this.questId,
    this.startedAt,
    this.completedAt,
    this.abandonedAt,
    this.abandonmentReason,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
    this.version = 1,
  });

  final EntityId id;
  final EntityId profileId;
  final String title;
  final String question;
  final MusicExpeditionStatus status;
  final String? purpose;
  final EntityId? questId;
  final DateTime? startedAt;
  final DateTime? completedAt;
  final DateTime? abandonedAt;
  final String? abandonmentReason;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? deletedAt;
  final int version;

  factory MusicExpedition.draft({
    required EntityId id,
    required EntityId profileId,
    required String title,
    required String question,
    required DateTime now,
    String? purpose,
  }) {
    final q = question.trim();
    if (q.isEmpty) {
      throw ArgumentError('MusicExpedition.question is required');
    }
    final t = title.trim();
    if (t.isEmpty) {
      throw ArgumentError('MusicExpedition.title is required');
    }
    return MusicExpedition(
      id: id,
      profileId: profileId,
      title: t,
      question: q,
      status: MusicExpeditionStatus.draft,
      purpose: purpose?.trim().isEmpty == true ? null : purpose?.trim(),
      createdAt: now,
      updatedAt: now,
    );
  }

  MusicExpedition copyWith({
    String? title,
    String? question,
    MusicExpeditionStatus? status,
    String? purpose,
    DateTime? startedAt,
    DateTime? completedAt,
    DateTime? abandonedAt,
    String? abandonmentReason,
    DateTime? updatedAt,
    int? version,
  }) {
    return MusicExpedition(
      id: id,
      profileId: profileId,
      title: title ?? this.title,
      question: question ?? this.question,
      status: status ?? this.status,
      purpose: purpose ?? this.purpose,
      questId: questId,
      startedAt: startedAt ?? this.startedAt,
      completedAt: completedAt ?? this.completedAt,
      abandonedAt: abandonedAt ?? this.abandonedAt,
      abandonmentReason: abandonmentReason ?? this.abandonmentReason,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt,
      version: version ?? this.version,
    );
  }

  @override
  List<Object?> get props => [
    id,
    profileId,
    title,
    question,
    status,
    purpose,
    questId,
    startedAt,
    completedAt,
    abandonedAt,
    abandonmentReason,
    createdAt,
    updatedAt,
    deletedAt,
    version,
  ];
}

class MusicExpeditionStop extends Equatable {
  const MusicExpeditionStop({
    required this.id,
    required this.expeditionId,
    required this.nodeId,
    required this.displayOrder,
    required this.role,
    this.reason,
    this.cues = const [],
    this.isOptional = true,
    this.completedAt,
  });

  final EntityId id;
  final EntityId expeditionId;
  final EntityId nodeId;
  final int displayOrder;
  final MusicExpeditionStopRole role;
  final String? reason;
  final List<String> cues;
  final bool isOptional;
  final DateTime? completedAt;

  bool get isCompleted => completedAt != null;

  @override
  List<Object?> get props => [
    id,
    expeditionId,
    nodeId,
    displayOrder,
    role,
    reason,
    cues,
    isOptional,
    completedAt,
  ];
}

class MusicImportRun extends Equatable {
  const MusicImportRun({
    required this.id,
    required this.profileId,
    required this.sourceKind,
    required this.status,
    this.documentVersion,
    this.itemCount = 0,
    this.createdCount = 0,
    this.skippedCount = 0,
    this.conflictCount = 0,
    required this.provenanceJson,
    this.reportJson,
    required this.createdAt,
    this.appliedAt,
    this.rolledBackAt,
  });

  final EntityId id;
  final EntityId profileId;
  final MusicImportSourceKind sourceKind;
  final MusicImportRunStatus status;
  final int? documentVersion;
  final int itemCount;
  final int createdCount;
  final int skippedCount;
  final int conflictCount;
  final String provenanceJson;
  final String? reportJson;
  final DateTime createdAt;
  final DateTime? appliedAt;
  final DateTime? rolledBackAt;

  @override
  List<Object?> get props => [
    id,
    profileId,
    sourceKind,
    status,
    documentVersion,
    itemCount,
    createdCount,
    skippedCount,
    conflictCount,
    provenanceJson,
    reportJson,
    createdAt,
    appliedAt,
    rolledBackAt,
  ];
}

class MusicSpotifySyncState extends Equatable {
  const MusicSpotifySyncState({
    required this.profileId,
    required this.consentId,
    this.grantedScopes = const [],
    this.libraryCursor,
    this.recentCursor,
    this.lastLibraryAt,
    this.lastRecentAt,
    this.lastPlaylistAt,
    this.capabilityProbeJson = '{}',
    this.lastError,
    required this.updatedAt,
  });

  final EntityId profileId;
  final EntityId consentId;
  final List<String> grantedScopes;
  final String? libraryCursor;
  final String? recentCursor;
  final DateTime? lastLibraryAt;
  final DateTime? lastRecentAt;
  final DateTime? lastPlaylistAt;
  final String capabilityProbeJson;
  final String? lastError;
  final DateTime updatedAt;

  @override
  List<Object?> get props => [
    profileId,
    consentId,
    grantedScopes,
    libraryCursor,
    recentCursor,
    lastLibraryAt,
    lastRecentAt,
    lastPlaylistAt,
    capabilityProbeJson,
    lastError,
    updatedAt,
  ];
}

/// Suggested flashcard — never applied until the user confirms (spec §77).
class MusicFlashcardCandidate extends Equatable {
  const MusicFlashcardCandidate({
    required this.origin,
    required this.originId,
    required this.suggestedKind,
    required this.front,
    required this.back,
    required this.deckTitle,
    this.areaPath = const ['Artes', 'Música'],
    this.tags = const [],
    this.researchNodeId,
    this.accepted = false,
  });

  final String origin;
  final EntityId originId;
  final String suggestedKind;
  final String front;
  final String back;
  final String deckTitle;
  final List<String> areaPath;
  final List<String> tags;
  final EntityId? researchNodeId;
  final bool accepted;

  @override
  List<Object?> get props => [
    origin,
    originId,
    suggestedKind,
    front,
    back,
    deckTitle,
    areaPath,
    tags,
    researchNodeId,
    accepted,
  ];
}

abstract final class MusicIdentityPolicy {
  static String normalizeTitle(String value) =>
      value.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');

  static String normalizeArtist(String value) => normalizeTitle(value);

  static String sortName(String value) {
    final trimmed = value.trim();
    final article = RegExp(
      r'^(the|a|an|os|as|o|a|um|uma)\s+',
      caseSensitive: false,
    );
    return article.hasMatch(trimmed)
        ? trimmed.replaceFirst(article, '').trim()
        : trimmed;
  }

  static String matchKey({
    required MusicNodeType type,
    required String title,
    String? artist,
  }) {
    final artistPart = artist == null || artist.trim().isEmpty
        ? ''
        : '|${normalizeArtist(artist)}';
    return '${type.name}|${normalizeTitle(title)}$artistPart';
  }
}

class MusicImportedStateDecision extends Equatable {
  const MusicImportedStateDecision({
    required this.state,
    required this.clamped,
    this.original,
  });

  final MusicDiscoveryState state;
  final bool clamped;
  final String? original;

  @override
  List<Object?> get props => [state, clamped, original];
}

abstract final class MusicDiscoveryPolicy {
  /// Import / Spotify may only seed weak states (spec §76.5, §79.1).
  static MusicImportedStateDecision clampImported(String? raw) {
    final value = raw?.trim().toLowerCase();
    if (value == null || value.isEmpty || value == 'unknown') {
      return const MusicImportedStateDecision(
        state: MusicDiscoveryState.unmapped,
        clamped: false,
        original: 'unknown',
      );
    }
    if (value == 'unmapped') {
      return const MusicImportedStateDecision(
        state: MusicDiscoveryState.unmapped,
        clamped: false,
      );
    }
    if (value == 'sighted' || value == 'avistado') {
      return const MusicImportedStateDecision(
        state: MusicDiscoveryState.sighted,
        clamped: false,
      );
    }
    if (value == 'contact' || value == 'rumor' || value == 'contacto') {
      return MusicImportedStateDecision(
        state: MusicDiscoveryState.rumor,
        clamped: false,
        original: value,
      );
    }
    return MusicImportedStateDecision(
      state: MusicDiscoveryState.sighted,
      clamped: true,
      original: raw,
    );
  }

  /// Suggestion only — never silently upgrades an explicit stronger state.
  static MusicDiscoveryState suggestAfterEncounter({
    required MusicDiscoveryState current,
    required MusicEncounterType encounterType,
  }) {
    final suggested = switch (encounterType) {
      MusicEncounterType.contact => MusicDiscoveryState.rumor,
      MusicEncounterType.importListen => MusicDiscoveryState.rumor,
      MusicEncounterType.listen => MusicDiscoveryState.sampled,
      MusicEncounterType.attentiveListen => MusicDiscoveryState.visited,
      MusicEncounterType.comparison => MusicDiscoveryState.visited,
      MusicEncounterType.practice => MusicDiscoveryState.visited,
      MusicEncounterType.live => MusicDiscoveryState.visited,
    };
    return rank(suggested) > rank(current) ? suggested : current;
  }

  static int rank(MusicDiscoveryState state) => switch (state) {
    MusicDiscoveryState.unmapped => 0,
    MusicDiscoveryState.rumor => 1,
    MusicDiscoveryState.sighted => 2,
    MusicDiscoveryState.sampled => 3,
    MusicDiscoveryState.visited => 4,
    MusicDiscoveryState.cartographed => 5,
    MusicDiscoveryState.connected => 6,
    MusicDiscoveryState.internalized => 7,
    MusicDiscoveryState.living => 8,
    MusicDiscoveryState.dormant => 4,
    MusicDiscoveryState.archived => 0,
  };
}

abstract final class MusicFlashcardCandidatePolicy {
  static List<MusicFlashcardCandidate> fromEncounter({
    required MusicNode node,
    required MusicEncounter encounter,
  }) {
    if (encounter.encounterType == MusicEncounterType.contact ||
        encounter.encounterType == MusicEncounterType.importListen ||
        encounter.encounterType == MusicEncounterType.listen) {
      return const [];
    }
    final year = node.beginYear;
    final candidates = <MusicFlashcardCandidate>[
      if (year != null)
        MusicFlashcardCandidate(
          origin: 'listening_session',
          originId: encounter.id,
          suggestedKind: 'basic',
          front: 'Em que ano saiu ${node.canonicalName}?',
          back: '$year',
          deckTitle: node.canonicalName,
          tags: const ['Atlas'],
        ),
    ];
    if (encounter.note != null && encounter.note!.trim().isNotEmpty) {
      candidates.add(
        MusicFlashcardCandidate(
          origin: 'listening_session',
          originId: encounter.id,
          suggestedKind: 'freeRecall',
          front: 'O que notaste em ${node.canonicalName}?',
          back: encounter.note!.trim(),
          deckTitle: node.canonicalName,
          tags: const ['Atlas', 'Notas'],
        ),
      );
    }
    return candidates;
  }

  static List<MusicFlashcardCandidate> fromClaim({
    required MusicRelationClaim claim,
    required MusicNode from,
    required MusicNode to,
  }) {
    if (claim.status != MusicClaimStatus.accepted) return const [];
    return [
      MusicFlashcardCandidate(
        origin: 'claim',
        originId: claim.id,
        suggestedKind: 'basic',
        front:
            'Que relação reconheceste entre ${from.canonicalName} e ${to.canonicalName}?',
        back: claim.description?.trim().isNotEmpty == true
            ? claim.description!.trim()
            : claim.relationType.name,
        deckTitle: from.canonicalName,
        tags: const ['Atlas', 'Relações'],
      ),
    ];
  }
}

class MusicNodeInspect extends Equatable {
  const MusicNodeInspect({
    required this.node,
    required this.state,
    this.identities = const [],
    this.encounters = const [],
    this.claimsFrom = const [],
    this.claimsTo = const [],
  });

  final MusicNode node;
  final PersonalMusicNodeState? state;
  final List<MusicExternalIdentity> identities;
  final List<MusicEncounter> encounters;
  final List<MusicRelationClaim> claimsFrom;
  final List<MusicRelationClaim> claimsTo;

  @override
  List<Object?> get props => [
    node,
    state,
    identities,
    encounters,
    claimsFrom,
    claimsTo,
  ];
}

class MusicAtlasOverview extends Equatable {
  const MusicAtlasOverview({
    required this.nodes,
    required this.states,
    required this.encounters,
    required this.expeditions,
    required this.identities,
  });

  final List<MusicNode> nodes;
  final List<PersonalMusicNodeState> states;
  final List<MusicEncounter> encounters;
  final List<MusicExpedition> expeditions;
  final List<MusicExternalIdentity> identities;

  PersonalMusicNodeState? stateOf(EntityId nodeId) {
    for (final state in states) {
      if (state.nodeId == nodeId) return state;
    }
    return null;
  }

  @override
  List<Object?> get props => [nodes, states, encounters, expeditions, identities];
}
