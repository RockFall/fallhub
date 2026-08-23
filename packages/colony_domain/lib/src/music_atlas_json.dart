import 'dart:convert';

import 'package:equatable/equatable.dart';

import 'flashcard.dart';
import 'flashcard_json_import.dart';
import 'flashcard_tag.dart';
import 'id_generator.dart';
import 'knowledge_area.dart';
import 'knowledge_area_catalog.dart';
import 'knowledge_area_placement.dart';
import 'music_atlas.dart';
import 'music_atlas_exploration.dart';
import 'music_canon.dart';
import 'music_genre_atlas.dart';
import 'research_node.dart';
import 'timeline_byte_source.dart';

class MusicAtlasJsonException implements Exception {
  MusicAtlasJsonException(this.message);
  final String message;

  @override
  String toString() => message;
}

class MusicAtlasJsonExternalId extends Equatable {
  const MusicAtlasJsonExternalId({
    required this.provider,
    required this.entityType,
    required this.id,
    this.url,
  });

  final String provider;
  final String entityType;
  final String id;
  final String? url;

  Map<String, dynamic> toJson() => {
    'provider': provider,
    'entityType': entityType,
    'id': id,
    if (url != null) 'url': url,
  };

  @override
  List<Object?> get props => [provider, entityType, id, url];
}

class MusicAtlasJsonNode extends Equatable {
  const MusicAtlasJsonNode({
    required this.key,
    required this.nodeType,
    required this.title,
    this.artists = const [],
    this.year,
    this.territoryKeys = const [],
    this.externalIds = const [],
    this.summary,
    this.discoveryState,
    this.notes,
    this.localId,
  });

  final String key;
  final MusicNodeType nodeType;
  final String title;
  final List<String> artists;
  final int? year;
  final List<String> territoryKeys;
  final List<MusicAtlasJsonExternalId> externalIds;
  final String? summary;
  final String? discoveryState;
  final String? notes;
  final String? localId;

  Map<String, dynamic> toJson() => {
    'key': key,
    'nodeType': nodeType.name,
    'title': title,
    if (artists.isNotEmpty) 'artists': artists,
    if (year != null) 'year': year,
    if (territoryKeys.isNotEmpty) 'territoryKeys': territoryKeys,
    if (externalIds.isNotEmpty)
      'externalIds': [for (final id in externalIds) id.toJson()],
    if (summary != null) 'summary': summary,
    if (discoveryState != null) 'discoveryState': discoveryState,
    if (notes != null) 'notes': notes,
    if (localId != null) 'localId': localId,
  };

  @override
  List<Object?> get props => [
    key,
    nodeType,
    title,
    artists,
    year,
    territoryKeys,
    externalIds,
    summary,
    discoveryState,
    notes,
    localId,
  ];
}

class MusicAtlasJsonClaim extends Equatable {
  const MusicAtlasJsonClaim({
    required this.fromKey,
    required this.toKey,
    required this.relationType,
    this.description,
    this.confidence,
    this.validFrom,
    this.validTo,
    this.uncertainties = const [],
    this.sources = const [],
    this.acceptedByUser = false,
  });

  final String fromKey;
  final String toKey;
  final MusicRelationType relationType;
  final String? description;
  final double? confidence;
  final String? validFrom;
  final String? validTo;
  final List<String> uncertainties;
  final List<String> sources;
  final bool acceptedByUser;

  Map<String, dynamic> toJson() => {
    'fromKey': fromKey,
    'toKey': toKey,
    'relationType': relationType.name,
    if (description != null) 'description': description,
    if (confidence != null) 'confidence': confidence,
    if (validFrom != null) 'validFrom': validFrom,
    if (validTo != null) 'validTo': validTo,
    if (uncertainties.isNotEmpty) 'uncertainties': uncertainties,
    if (sources.isNotEmpty) 'sources': sources,
    'acceptedByUser': acceptedByUser,
  };

  @override
  List<Object?> get props => [
    fromKey,
    toKey,
    relationType,
    description,
    confidence,
    validFrom,
    validTo,
    uncertainties,
    sources,
    acceptedByUser,
  ];
}

class MusicAtlasJsonEncounter extends Equatable {
  const MusicAtlasJsonEncounter({
    required this.nodeKey,
    required this.encounterType,
    this.occurredAt,
    this.note,
    this.resonance,
  });

  final String nodeKey;
  final MusicEncounterType encounterType;
  final DateTime? occurredAt;
  final String? note;
  final int? resonance;

  Map<String, dynamic> toJson() => {
    'nodeKey': nodeKey,
    'encounterType': encounterType.name,
    if (occurredAt != null) 'occurredAt': occurredAt!.toUtc().toIso8601String(),
    if (note != null) 'note': note,
    if (resonance != null) 'resonance': resonance,
  };

  @override
  List<Object?> get props => [nodeKey, encounterType, occurredAt, note, resonance];
}

class MusicAtlasJsonStop extends Equatable {
  const MusicAtlasJsonStop({
    required this.nodeKey,
    this.role = MusicExpeditionStopRole.destination,
    this.reason,
    this.cues = const [],
    this.optional = true,
  });

  final String nodeKey;
  final MusicExpeditionStopRole role;
  final String? reason;
  final List<String> cues;
  final bool optional;

  Map<String, dynamic> toJson() => {
    'nodeKey': nodeKey,
    'role': role.name,
    if (reason != null) 'reason': reason,
    if (cues.isNotEmpty) 'cues': cues,
    'optional': optional,
  };

  @override
  List<Object?> get props => [nodeKey, role, reason, cues, optional];
}

class MusicAtlasJsonExpedition extends Equatable {
  const MusicAtlasJsonExpedition({
    required this.title,
    required this.question,
    this.territoryKey,
    this.stops = const [],
  });

  final String title;
  final String question;
  final String? territoryKey;
  final List<MusicAtlasJsonStop> stops;

  Map<String, dynamic> toJson() => {
    'title': title,
    'question': question,
    if (territoryKey != null) 'territoryKey': territoryKey,
    'stops': [for (final stop in stops) stop.toJson()],
  };

  @override
  List<Object?> get props => [title, question, territoryKey, stops];
}

class MusicAtlasJsonResearchLink extends Equatable {
  const MusicAtlasJsonResearchLink({
    required this.nodeKey,
    required this.researchTitle,
    required this.kind,
    this.areaPath = const [],
  });

  final String nodeKey;
  final String researchTitle;
  final ResearchKnowledgeLinkKind kind;
  final List<String> areaPath;

  Map<String, dynamic> toJson() => {
    'nodeKey': nodeKey,
    'researchTitle': researchTitle,
    'kind': kind.name,
    if (areaPath.isNotEmpty) 'areaPath': areaPath,
  };

  @override
  List<Object?> get props => [nodeKey, researchTitle, kind, areaPath];
}

class MusicAtlasJsonDocument extends Equatable {
  const MusicAtlasJsonDocument({
    required this.nodes,
    this.version = 1,
    this.kind = 'music_atlas',
    this.title,
    this.userRequest,
    this.claims = const [],
    this.encounters = const [],
    this.expeditions = const [],
    this.researchLinks = const [],
    this.cards = const [],
    this.clampedDiscoveryStates = const [],
    this.redirectToFlashcards = false,
  });

  final int version;
  final String kind;
  final String? title;
  final String? userRequest;
  final List<MusicAtlasJsonNode> nodes;
  final List<MusicAtlasJsonClaim> claims;
  final List<MusicAtlasJsonEncounter> encounters;
  final List<MusicAtlasJsonExpedition> expeditions;
  final List<MusicAtlasJsonResearchLink> researchLinks;
  final List<FlashcardJsonCard> cards;
  final List<String> clampedDiscoveryStates;
  final bool redirectToFlashcards;

  factory MusicAtlasJsonDocument.fromJson(Map<String, dynamic> json) {
    return MusicAtlasJsonCodec.documentFromJson(json);
  }

  Map<String, dynamic> toJson() => {
    'version': version,
    'kind': kind,
    if (title != null) 'title': title,
    if (userRequest != null) 'userRequest': userRequest,
    'nodes': [for (final node in nodes) node.toJson()],
    'claims': [for (final claim in claims) claim.toJson()],
    'encounters': [for (final encounter in encounters) encounter.toJson()],
    'expeditions': [for (final expedition in expeditions) expedition.toJson()],
    'researchLinks': [for (final link in researchLinks) link.toJson()],
    'cards': [for (final card in cards) card.toJson()],
    if (clampedDiscoveryStates.isNotEmpty)
      'clampedDiscoveryStates': clampedDiscoveryStates,
  };

  @override
  List<Object?> get props => [
    version,
    kind,
    title,
    userRequest,
    nodes,
    claims,
    encounters,
    expeditions,
    researchLinks,
    cards,
    clampedDiscoveryStates,
    redirectToFlashcards,
  ];
}

enum MusicAtlasJsonNodeAction { create, link, skip, conflict }

class MusicAtlasJsonNodeStep extends Equatable {
  const MusicAtlasJsonNodeStep({
    required this.action,
    required this.node,
    this.existingId,
    this.clampedState,
    this.reason,
  });

  final MusicAtlasJsonNodeAction action;
  final MusicAtlasJsonNode node;
  final EntityId? existingId;
  final MusicImportedStateDecision? clampedState;
  final String? reason;

  @override
  List<Object?> get props => [action, node, existingId, clampedState, reason];
}

class MusicAtlasJsonClaimStep extends Equatable {
  const MusicAtlasJsonClaimStep({
    required this.claim,
    required this.create,
    this.addSourceOnly = false,
  });

  final MusicAtlasJsonClaim claim;
  final bool create;
  final bool addSourceOnly;

  @override
  List<Object?> get props => [claim, create, addSourceOnly];
}

class MusicAtlasJsonImportPlan extends Equatable {
  const MusicAtlasJsonImportPlan({
    required this.document,
    required this.nodes,
    required this.claims,
    required this.encounters,
    required this.expeditions,
    required this.researchLinks,
    this.flashcards,
  });

  final MusicAtlasJsonDocument document;
  final List<MusicAtlasJsonNodeStep> nodes;
  final List<MusicAtlasJsonClaimStep> claims;
  final List<MusicAtlasJsonEncounter> encounters;
  final List<MusicAtlasJsonExpedition> expeditions;
  final List<MusicAtlasJsonResearchLink> researchLinks;
  final FlashcardJsonImportPlan? flashcards;

  int get createCount =>
      nodes.where((s) => s.action == MusicAtlasJsonNodeAction.create).length;
  int get linkCount =>
      nodes.where((s) => s.action == MusicAtlasJsonNodeAction.link).length;
  int get skipCount =>
      nodes.where((s) => s.action == MusicAtlasJsonNodeAction.skip).length;
  int get conflictCount =>
      nodes.where((s) => s.action == MusicAtlasJsonNodeAction.conflict).length;
  int get clampedCount =>
      nodes.where((s) => s.clampedState?.clamped == true).length;

  @override
  List<Object?> get props => [
    document,
    nodes,
    claims,
    encounters,
    expeditions,
    researchLinks,
    flashcards,
  ];
}

class MusicAtlasJsonImportResult extends Equatable {
  const MusicAtlasJsonImportResult({
    required this.runId,
    required this.createdNodes,
    required this.linkedNodes,
    required this.skippedNodes,
    required this.conflictNodes,
    required this.createdClaims,
    required this.createdEncounters,
    required this.createdExpeditions,
    this.flashcards,
  });

  final EntityId runId;
  final int createdNodes;
  final int linkedNodes;
  final int skippedNodes;
  final int conflictNodes;
  final int createdClaims;
  final int createdEncounters;
  final int createdExpeditions;
  final FlashcardJsonImportResult? flashcards;

  @override
  List<Object?> get props => [
    runId,
    createdNodes,
    linkedNodes,
    skippedNodes,
    conflictNodes,
    createdClaims,
    createdEncounters,
    createdExpeditions,
    flashcards,
  ];
}

class _ExistingNode {
  const _ExistingNode({
    required this.id,
    required this.type,
    required this.title,
    this.artistCredit,
    this.externalKeys = const {},
  });

  final EntityId id;
  final MusicNodeType type;
  final String title;
  final String? artistCredit;
  final Set<String> externalKeys;
}

abstract final class MusicAtlasJsonImportPolicy {
  static MusicAtlasJsonImportPlan plan({
    required MusicAtlasJsonDocument document,
    required List<MusicNode> existingNodes,
    required List<MusicExternalIdentity> existingIdentities,
    required List<MusicRelationClaim> existingClaims,
    List<KnowledgeArea> areas = const [],
    List<KnowledgeAreaPlacement> placements = const [],
    List<FlashcardDeck> decks = const [],
    List<Flashcard> cards = const [],
    List<FlashcardTag> tags = const [],
  }) {
    final identitiesByNode = <String, List<MusicExternalIdentity>>{};
    for (final identity in existingIdentities) {
      identitiesByNode.putIfAbsent(identity.nodeId.value, () => []).add(identity);
    }
    final existing = [
      for (final node in existingNodes)
        _ExistingNode(
          id: node.id,
          type: node.nodeType,
          title: node.canonicalName,
          externalKeys: {
            for (final identity in identitiesByNode[node.id.value] ?? const [])
              '${identity.provider}:${identity.entityType}:${identity.externalId}',
          },
        ),
    ];

    final steps = <MusicAtlasJsonNodeStep>[];
    for (final node in document.nodes) {
      final clamped = MusicDiscoveryPolicy.clampImported(node.discoveryState);
      final byExternal = _matchExternal(node, existing);
      if (byExternal != null) {
        steps.add(
          MusicAtlasJsonNodeStep(
            action: MusicAtlasJsonNodeAction.link,
            node: node,
            existingId: byExternal.id,
            clampedState: clamped,
          ),
        );
        continue;
      }
      if (node.localId != null) {
        final local = existing.where((e) => e.id.value == node.localId);
        if (local.isNotEmpty) {
          steps.add(
            MusicAtlasJsonNodeStep(
              action: MusicAtlasJsonNodeAction.link,
              node: node,
              existingId: local.first.id,
              clampedState: clamped,
            ),
          );
          continue;
        }
      }
      final titleMatches = [
        for (final item in existing)
          if (item.type == node.nodeType &&
              MusicIdentityPolicy.normalizeTitle(item.title) ==
                  MusicIdentityPolicy.normalizeTitle(node.title))
            item,
      ];
      if (titleMatches.length > 1) {
        steps.add(
          MusicAtlasJsonNodeStep(
            action: MusicAtlasJsonNodeAction.conflict,
            node: node,
            clampedState: clamped,
            reason: 'Vários nós com o mesmo título e tipo.',
          ),
        );
        continue;
      }
      if (titleMatches.length == 1) {
        steps.add(
          MusicAtlasJsonNodeStep(
            action: MusicAtlasJsonNodeAction.link,
            node: node,
            existingId: titleMatches.single.id,
            clampedState: clamped,
          ),
        );
        continue;
      }
      steps.add(
        MusicAtlasJsonNodeStep(
          action: MusicAtlasJsonNodeAction.create,
          node: node,
          clampedState: clamped,
        ),
      );
    }

    final claimSteps = <MusicAtlasJsonClaimStep>[];
    for (final claim in document.claims) {
      final duplicate = existingClaims.any(
        (c) =>
            _keyResolvesTo(claim.fromKey, steps, c.fromNodeId) &&
            _keyResolvesTo(claim.toKey, steps, c.toNodeId) &&
            c.relationType == claim.relationType,
      );
      claimSteps.add(
        MusicAtlasJsonClaimStep(
          claim: claim,
          create: !duplicate,
          addSourceOnly: duplicate,
        ),
      );
    }

    FlashcardJsonImportPlan? flashPlan;
    if (document.cards.isNotEmpty) {
      flashPlan = FlashcardJsonImportPolicy.plan(
        document: FlashcardJsonDocument(cards: document.cards),
        areas: areas,
        placements: placements,
        decks: decks,
        cards: cards,
      );
    }

    return MusicAtlasJsonImportPlan(
      document: document,
      nodes: steps,
      claims: claimSteps,
      encounters: document.encounters,
      expeditions: document.expeditions,
      researchLinks: document.researchLinks,
      flashcards: flashPlan,
    );
  }

  static _ExistingNode? _matchExternal(
    MusicAtlasJsonNode node,
    List<_ExistingNode> existing,
  ) {
    for (final ext in node.externalIds) {
      final key = '${ext.provider}:${ext.entityType}:${ext.id}';
      for (final item in existing) {
        if (item.externalKeys.contains(key)) return item;
      }
    }
    return null;
  }

  static bool _keyResolvesTo(
    String key,
    List<MusicAtlasJsonNodeStep> steps,
    EntityId id,
  ) {
    for (final step in steps) {
      if (step.node.key == key && step.existingId == id) return true;
    }
    return false;
  }
}

abstract final class MusicAtlasJsonCodec {
  static const supportedVersion = 1;

  static MusicAtlasJsonDocument parse(String source) {
    final extracted = _extractJson(source);
    return parseSource(Uint8ListTimelineByteSource(utf8.encode(extracted)));
  }

  static MusicAtlasJsonDocument parseSource(TimelineByteSource source) {
    if (source.length == 0) {
      throw MusicAtlasJsonException('JSON vazio.');
    }
    final cursor = TimelineByteCursor(source);
    _seekJsonStart(cursor);
    final first = cursor.peek();
    if (first == 0x5B) {
      final nodes = <MusicAtlasJsonNode>[];
      _readObjectArray(cursor, (map) {
        nodes.add(_parseNode(map));
      });
      if (nodes.isEmpty) {
        throw MusicAtlasJsonException('Nenhum nó encontrado no JSON.');
      }
      return MusicAtlasJsonDocument(nodes: nodes);
    }
    if (first != 0x7B) {
      throw MusicAtlasJsonException('O JSON deve ser um objeto ou uma lista.');
    }
    return _readRoot(cursor);
  }

  static MusicAtlasJsonDocument documentFromJson(Map<String, dynamic> json) {
    return parseSource(
      Uint8ListTimelineByteSource(utf8.encode(jsonEncode(json))),
    );
  }

  static MusicAtlasJsonDocument _readRoot(TimelineByteCursor cursor) {
    cursor.expectByte(0x7B);
    cursor.skipWs();
    var version = 1;
    var kind = 'music_atlas';
    String? title;
    String? userRequest;
    final nodes = <MusicAtlasJsonNode>[];
    final claims = <MusicAtlasJsonClaim>[];
    final encounters = <MusicAtlasJsonEncounter>[];
    final expeditions = <MusicAtlasJsonExpedition>[];
    final researchLinks = <MusicAtlasJsonResearchLink>[];
    final cards = <FlashcardJsonCard>[];
    final clamped = <String>[];
    var sawCards = false;
    var sawAtlasPayload = false;

    while (!cursor.isEof && cursor.peek() != 0x7D) {
      final key = cursor.readString();
      cursor.skipWs();
      cursor.expectByte(0x3A);
      cursor.skipWs();
      switch (key) {
        case 'version':
          final raw = _decodeCurrent(cursor);
          if (raw is num) version = raw.toInt();
        case 'kind':
          kind = _readString(_decodeCurrent(cursor)) ?? kind;
        case 'meta':
          final raw = _decodeCurrent(cursor);
          if (raw is Map) {
            final map = _asStringKeyMap(raw);
            title = _readString(map['title']) ?? title;
            userRequest = _readString(map['userRequest']) ?? userRequest;
          }
        case 'nodes':
          sawAtlasPayload = true;
          if (cursor.peek() == 0x5B) {
            _readObjectArray(cursor, (map) {
              final node = _parseNode(map);
              nodes.add(node);
              final decision = MusicDiscoveryPolicy.clampImported(
                node.discoveryState,
              );
              if (decision.clamped && decision.original != null) {
                clamped.add(decision.original!);
              }
            });
          } else {
            cursor.skipValue();
          }
        case 'claims':
          sawAtlasPayload = true;
          if (cursor.peek() == 0x5B) {
            _readObjectArray(cursor, (map) => claims.add(_parseClaim(map)));
          } else {
            cursor.skipValue();
          }
        case 'encounters':
          sawAtlasPayload = true;
          if (cursor.peek() == 0x5B) {
            _readObjectArray(
              cursor,
              (map) => encounters.add(_parseEncounter(map)),
            );
          } else {
            cursor.skipValue();
          }
        case 'expeditions':
          sawAtlasPayload = true;
          if (cursor.peek() == 0x5B) {
            _readObjectArray(
              cursor,
              (map) => expeditions.add(_parseExpedition(map)),
            );
          } else {
            cursor.skipValue();
          }
        case 'researchLinks':
          sawAtlasPayload = true;
          if (cursor.peek() == 0x5B) {
            _readObjectArray(
              cursor,
              (map) => researchLinks.add(_parseResearchLink(map)),
            );
          } else {
            cursor.skipValue();
          }
        case 'cards':
          sawCards = true;
          if (cursor.peek() == 0x5B) {
            _readObjectArray(cursor, (map) {
              cards.add(
                _cardFromMap(map, fallbackDeck: FlashcardJsonCodec.defaultDeckTitle),
              );
            });
          } else {
            cursor.skipValue();
          }
        case 'decks':
          sawCards = true;
          cursor.skipValue();
        default:
          cursor.skipValue();
      }
      cursor.skipWs();
      if (cursor.peek() == 0x2C) {
        cursor.next();
        cursor.skipWs();
      }
    }
    if (cursor.peek() != 0x7D) {
      throw MusicAtlasJsonException('JSON truncado.');
    }
    cursor.next();

    if (version != supportedVersion) {
      throw MusicAtlasJsonException(
        'Versão de Atlas JSON não suportada: $version',
      );
    }
    if (!sawAtlasPayload && sawCards) {
      throw MusicAtlasJsonException(
        'Este documento é de flashcards. Abre-o em Flashcards.',
      );
    }
    if (nodes.isEmpty &&
        claims.isEmpty &&
        encounters.isEmpty &&
        expeditions.isEmpty) {
      throw MusicAtlasJsonException('Nenhum nó encontrado no JSON.');
    }
    return MusicAtlasJsonDocument(
      version: version,
      kind: kind,
      title: title,
      userRequest: userRequest,
      nodes: nodes,
      claims: claims,
      encounters: encounters,
      expeditions: expeditions,
      researchLinks: researchLinks,
      cards: cards,
      clampedDiscoveryStates: clamped,
      redirectToFlashcards: !sawAtlasPayload && sawCards,
    );
  }

  static MusicAtlasJsonNode _parseNode(Map<String, dynamic> map) {
    final title =
        _readString(map['title']) ?? _readString(map['canonicalName']) ?? '';
    if (title.isEmpty) {
      throw MusicAtlasJsonException('Cada nó precisa de title.');
    }
    final key = _readString(map['key']) ?? MusicIdentityPolicy.normalizeTitle(title);
    return MusicAtlasJsonNode(
      key: key,
      nodeType: _parseNodeType(map['nodeType']),
      title: title,
      artists: _stringList(map['artists']),
      year: _readInt(map['year']),
      territoryKeys: MusicGenreAtlas.resolveTaxonKeys(
        _stringList(map['territoryKeys']),
      ),
      externalIds: _parseExternalIds(map['externalIds']),
      summary: _readString(map['summary']),
      discoveryState: _readString(map['discoveryState']),
      notes: _readString(map['notes']),
      localId: _readString(map['localId']),
    );
  }

  static MusicAtlasJsonClaim _parseClaim(Map<String, dynamic> map) {
    final from = _readString(map['fromKey']);
    final to = _readString(map['toKey']);
    if (from == null || to == null) {
      throw MusicAtlasJsonException('Claim precisa de fromKey e toKey.');
    }
    return MusicAtlasJsonClaim(
      fromKey: from,
      toKey: to,
      relationType: _parseRelation(map['relationType']),
      description: _readString(map['description']),
      confidence: _readDouble(map['confidence']),
      validFrom: _readString(map['validFrom']),
      validTo: _readString(map['validTo']),
      uncertainties: _stringList(map['uncertainties']),
      sources: _sourceTitles(map['sources']),
      acceptedByUser: map['acceptedByUser'] == true,
    );
  }

  static MusicAtlasJsonEncounter _parseEncounter(Map<String, dynamic> map) {
    final key = _readString(map['nodeKey']);
    if (key == null) {
      throw MusicAtlasJsonException('Encontro precisa de nodeKey.');
    }
    return MusicAtlasJsonEncounter(
      nodeKey: key,
      encounterType: _parseEncounterType(map['encounterType']),
      occurredAt: _readDate(map['occurredAt']),
      note: _readString(map['note']),
      resonance: _readInt(map['resonance']),
    );
  }

  static MusicAtlasJsonExpedition _parseExpedition(Map<String, dynamic> map) {
    final title = _readString(map['title']) ?? 'Expedição';
    final question = _readString(map['question']) ?? '';
    if (question.trim().isEmpty) {
      throw MusicAtlasJsonException('Expedição precisa de pergunta.');
    }
    final stopsRaw = map['stops'];
    final stops = <MusicAtlasJsonStop>[];
    if (stopsRaw is List) {
      for (final item in stopsRaw) {
        if (item is! Map) continue;
        final stopMap = _asStringKeyMap(item);
        final nodeKey = _readString(stopMap['nodeKey']);
        if (nodeKey == null) continue;
        stops.add(
          MusicAtlasJsonStop(
            nodeKey: nodeKey,
            role: _parseStopRole(stopMap['role']),
            reason: _readString(stopMap['reason']),
            cues: _stringList(stopMap['cues']),
            optional: stopMap['optional'] != false,
          ),
        );
      }
    }
    return MusicAtlasJsonExpedition(
      title: title,
      question: question,
      territoryKey: _readString(map['territoryKey']),
      stops: stops,
    );
  }

  static MusicAtlasJsonResearchLink _parseResearchLink(
    Map<String, dynamic> map,
  ) {
    final nodeKey = _readString(map['nodeKey']);
    final title = _readString(map['researchTitle']);
    if (nodeKey == null || title == null) {
      throw MusicAtlasJsonException(
        'researchLinks precisa de nodeKey e researchTitle.',
      );
    }
    return MusicAtlasJsonResearchLink(
      nodeKey: nodeKey,
      researchTitle: title,
      kind: _parseLinkKind(map['kind']),
      areaPath: FlashcardJsonCodec.parsePath(map['areaPath']),
    );
  }

  static FlashcardJsonCard _cardFromMap(
    Map<String, dynamic> map, {
    required String fallbackDeck,
  }) {
    final nested = FlashcardJsonCodec.documentFromJson({
      'version': 1,
      'cards': [map],
    });
    final card = nested.cards.single;
    if (card.deckTitle == FlashcardJsonCodec.defaultDeckTitle &&
        fallbackDeck != FlashcardJsonCodec.defaultDeckTitle) {
      return FlashcardJsonCard(
        front: card.front,
        back: card.back,
        kind: card.kind,
        deckTitle: fallbackDeck,
        areaPath: card.areaPath,
        alsoIn: card.alsoIn,
        extra: card.extra,
        tags: card.tags,
        scheduleMode: card.scheduleMode,
        priority: card.priority,
        bidirectional: card.bidirectional,
      );
    }
    return card;
  }

  static List<MusicAtlasJsonExternalId> _parseExternalIds(Object? raw) {
    if (raw is! List) return const [];
    return [
      for (final item in raw)
        if (item is Map)
          MusicAtlasJsonExternalId(
            provider: _readString(_asStringKeyMap(item)['provider']) ?? '',
            entityType:
                _readString(_asStringKeyMap(item)['entityType']) ?? 'album',
            id: _readString(_asStringKeyMap(item)['id']) ?? '',
            url: _readString(_asStringKeyMap(item)['url']),
          ),
    ].where((e) => e.provider.isNotEmpty && e.id.isNotEmpty).toList();
  }

  static MusicNodeType _parseNodeType(Object? raw) {
    final name = _readString(raw)?.replaceAll('-', '') ?? 'releaseGroup';
    final normalized = switch (name) {
      'release_group' || 'releaseGroup' => 'releaseGroup',
      _ => name,
    };
    return MusicNodeType.values.firstWhere(
      (v) => v.name.toLowerCase() == normalized.toLowerCase(),
      orElse: () => MusicNodeType.releaseGroup,
    );
  }

  static MusicRelationType _parseRelation(Object? raw) {
    final name = _readString(raw) ?? 'related';
    return MusicRelationType.values.firstWhere(
      (v) => v.name == name,
      orElse: () => MusicRelationType.related,
    );
  }

  static MusicEncounterType _parseEncounterType(Object? raw) {
    final name = _readString(raw) ?? 'contact';
    return MusicEncounterType.values.firstWhere(
      (v) => v.name == name,
      orElse: () => MusicEncounterType.contact,
    );
  }

  static MusicExpeditionStopRole _parseStopRole(Object? raw) {
    final name = _readString(raw) ?? 'destination';
    return MusicExpeditionStopRole.values.firstWhere(
      (v) => v.name == name,
      orElse: () => MusicExpeditionStopRole.destination,
    );
  }

  static ResearchKnowledgeLinkKind _parseLinkKind(Object? raw) {
    final name = _readString(raw) ?? 'related';
    return ResearchKnowledgeLinkKind.values.firstWhere(
      (v) => v.name == name,
      orElse: () => ResearchKnowledgeLinkKind.related,
    );
  }

  static void _readObjectArray(
    TimelineByteCursor cursor,
    void Function(Map<String, dynamic> map) onObject,
  ) {
    cursor.expectByte(0x5B);
    cursor.skipWs();
    while (!cursor.isEof && cursor.peek() != 0x5D) {
      if (cursor.peek() == 0x7B) {
        final raw = _decodeCurrent(cursor);
        if (raw is! Map) {
          throw MusicAtlasJsonException('Cada item deve ser um objeto JSON.');
        }
        onObject(_asStringKeyMap(raw));
      } else {
        cursor.skipValue();
      }
      cursor.skipWs();
      if (cursor.peek() == 0x2C) {
        cursor.next();
        cursor.skipWs();
      }
    }
    if (cursor.peek() != 0x5D) {
      throw MusicAtlasJsonException('JSON truncado: array sem fecho');
    }
    cursor.next();
  }

  static Object? _decodeCurrent(TimelineByteCursor cursor) {
    cursor.skipWs();
    final start = cursor.pos;
    cursor.skipValue();
    return jsonDecode(utf8.decode(cursor.slice(start, cursor.pos)));
  }

  static void _seekJsonStart(TimelineByteCursor cursor) {
    cursor.skipBom();
    cursor.skipWs();
  }

  static String _extractJson(String source) {
    var text = source.trim();
    if (text.isEmpty) {
      throw MusicAtlasJsonException('JSON vazio.');
    }
    final fence = RegExp(
      r'```(?:json)?\s*([\s\S]*?)\s*```',
      caseSensitive: false,
    );
    final fenced = fence.firstMatch(text);
    if (fenced != null) {
      text = fenced.group(1)!.trim();
    }
    final obj = text.indexOf('{');
    final arr = text.indexOf('[');
    if (obj < 0 && arr < 0) {
      throw MusicAtlasJsonException('Não encontrei um objeto ou lista JSON.');
    }
    final start = obj < 0
        ? arr
        : arr < 0
        ? obj
        : (obj < arr ? obj : arr);
    return text.substring(start);
  }

  static Map<String, dynamic> _asStringKeyMap(Map raw) => {
    for (final entry in raw.entries) entry.key.toString(): entry.value,
  };

  static String? _readString(Object? value) {
    if (value == null) return null;
    final text = value.toString().trim();
    return text.isEmpty ? null : text;
  }

  static int? _readInt(Object? value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '');
  }

  static double? _readDouble(Object? value) {
    if (value is num) {
      final n = value.toDouble();
      if (n < 0) return 0;
      if (n > 1) return 1;
      return n;
    }
    return null;
  }

  static DateTime? _readDate(Object? value) {
    final text = _readString(value);
    if (text == null) return null;
    return DateTime.tryParse(text)?.toUtc();
  }

  static List<String> _stringList(Object? raw) {
    if (raw is! List) return const [];
    return [
      for (final item in raw)
        if (item != null && item.toString().trim().isNotEmpty)
          item.toString().trim(),
    ];
  }

  static List<String> _sourceTitles(Object? raw) {
    if (raw is! List) return const [];
    return [
      for (final item in raw)
        if (item is String && item.trim().isNotEmpty)
          item.trim()
        else if (item is Map)
          _readString(_asStringKeyMap(item)['title']) ??
              _readString(_asStringKeyMap(item)['url']) ??
              '',
    ].where((e) => e.isNotEmpty).toList();
  }
}

abstract final class MusicAtlasJsonPromptBuilder {
  static String build({
    required List<MusicNode> nodes,
    required List<MusicRelationClaim> claims,
    List<KnowledgeArea> areas = const [],
    List<KnowledgeAreaPlacement> placements = const [],
    List<FlashcardDeck> decks = const [],
    List<FlashcardTag> tags = const [],
    List<ResearchNode> researchNodes = const [],
  }) {
    final buffer = StringBuffer()
      ..writeln(
        'Você formata um documento do Atlas Musical do Life Colony OS (local-first).',
      )
      ..writeln(
        'Responda APENAS com JSON válido (sem markdown, sem comentário, sem prosa).',
      )
      ..writeln(
        'O app importa o JSON, cria nós em falta, liga IDs externos, ignora duplicados',
      )
      ..writeln(
        'e NUNCA marca uma obra como cartografada só porque veio no documento.',
      )
      ..writeln()
      ..writeln('ONTOLOGIA — LÊ ISTO ANTES DE CLASSIFICAR')
      ..writeln(
        'Género, tradição, cena, movimento, forma, função, técnica e descritor NÃO são a mesma coisa.',
      )
      ..writeln(
        'Uma árvore única (Música > Rock > Progressive Rock > Canterbury) produz erros.',
      )
      ..writeln(
        'Cada obra pode receber VÁRIOS territoryKeys ao mesmo tempo, de eixos diferentes.',
      )
      ..writeln(
        'Use chaves canónicas ( Canonical Genre Base v1 ). Não invente World Music.',
      )
      ..writeln()
      ..writeln('EXEMPLOS DE CLASSIFICAÇÃO')
      ..writeln(
        '- Kind of Blue (Miles Davis, 1959): ["jazz.modal"]',
      )
      ..writeln(
        '- Heavy Weather (Weather Report): ["jazz.fusion.jazz_rock","jazz.fusion.jazz_funk"]',
      )
      ..writeln(
        '- Clube da Esquina (Milton Nascimento & Lô Borges, 1972): ["brazilian.mpb","brazilian.clube_da_esquina","scene.clube_da_esquina"]',
      )
      ..writeln(
        '- Tropicália ou Panis et Circencis: ["brazilian.tropicalia","movement.tropicalismo"]',
      )
      ..writeln(
        '- Loveless (MBV): ["rock.alt.shoegaze"]',
      )
      ..writeln(
        '- Blackgaze: ["metal.black.blackgaze"]  (o cânone já liga Shoegaze como pai secundário)',
      )
      ..writeln(
        '- Neurofunk: ["electronic.dnb.neurofunk"]  (Electronic → Jungle → DnB → Neurofunk)',
      )
      ..writeln(
        '- Funk Carioca / Baile Funk: ["brazilian.funk_br"] — NUNCA a família funk afro-americana.',
      )
      ..writeln()
      ..writeln('PROIBIDO em territoryKeys')
      ..writeln(
        '- world / world music / worldbeat (tradições não-ocidentais têm família global_art, brazilian, african, mena, …)',
      )
      ..writeln(
        '- progressive, experimental, fusion, revival, neo, post sozinhos (existem Progressive Rock, Progressive Metal, Progressive House — não um rio “Progressive”)',
      )
      ..writeln(
        '- moods (melancholic, dark, dreamy, warm) e instrumentação (acoustic, electric, lo-fi) como se fossem género',
      )
      ..writeln(
        '- MPB como pai de samba, choro, baião ou funk carioca. MPB (brazilian.mpb) é macro pós-1960, IRMÃ desses rios.',
      )
      ..writeln(
        '- percentagens de cobertura (“conheces 3% do jazz”). O Atlas não mede o mundo.',
      )
      ..writeln()
      ..writeln(MusicCanon.promptCatalog())
      ..writeln('SCHEMA')
      ..writeln('{')
      ..writeln('  "version": 1,')
      ..writeln('  "kind": "music_atlas",')
      ..writeln('  "nodes": [')
      ..writeln('    {')
      ..writeln('      "key": "kind-of-blue",')
      ..writeln('      "nodeType": "releaseGroup",')
      ..writeln('      "title": "Kind of Blue",')
      ..writeln('      "artists": ["Miles Davis"],')
      ..writeln('      "year": 1959,')
      ..writeln('      "territoryKeys": ["jazz.modal"],')
      ..writeln('      "discoveryState": "sighted",')
      ..writeln(
        '      "externalIds": [{"provider":"spotify","entityType":"album","id":"..."}]',
      )
      ..writeln('    },')
      ..writeln('    {')
      ..writeln('      "key": "clube-da-esquina",')
      ..writeln('      "nodeType": "releaseGroup",')
      ..writeln('      "title": "Clube da Esquina",')
      ..writeln('      "artists": ["Milton Nascimento", "Lô Borges"],')
      ..writeln('      "year": 1972,')
      ..writeln(
        '      "territoryKeys": ["brazilian.mpb","brazilian.clube_da_esquina","scene.clube_da_esquina"]',
      )
      ..writeln('    }')
      ..writeln('  ],')
      ..writeln('  "claims": [')
      ..writeln(
        '    {"fromKey":"kind-of-blue","toKey":"clube-da-esquina","relationType":"related","uncertainties":["comparação pedida pelo utilizador, não influência histórica"]}',
      )
      ..writeln('  ],')
      ..writeln('  "encounters": [],')
      ..writeln('  "expeditions": [')
      ..writeln('    {')
      ..writeln('      "title": "Do modal ao mineiro",')
      ..writeln(
        '      "question": "O que muda na harmonia quando sais do jazz modal para o Clube da Esquina?",',
      )
      ..writeln(
        '      "stops": [{"nodeKey":"kind-of-blue","role":"camp"},{"nodeKey":"clube-da-esquina","role":"destination"}]',
      )
      ..writeln('    }')
      ..writeln('  ],')
      ..writeln('  "researchLinks": [],')
      ..writeln('  "cards": []')
      ..writeln('}')
      ..writeln()
      ..writeln('REGRAS')
      ..writeln(
        '- territoryKeys: só chaves do cânone acima (ou aliases). Folha mais específica; podes pôr mais do que uma. Cena/tradição/movimento entram no mesmo array.',
      )
      ..writeln(
        '- discoveryState só pode ser unknown | sighted | contact. Qualquer outro valor (cartographed, demonstrated) é recusado para sighted.',
      )
      ..writeln(
        '- Não afirmes influência sem uncertainties[] ou sources[]. relationType: influenced|sharesScene|successor|contemporaneous|cover|sample|memberOf|related.',
      )
      ..writeln('- Não inventes letras, biografias ou percentagens de cobertura.')
      ..writeln(
        '- summary/notes: uma ou duas frases de escuta, não Wikipedia.',
      )
      ..writeln(
        '- cards[] usa o schema de flashcards (front, back, kind, deck, areaPath).',
      )
      ..writeln(
        '- Não cries um cartão por cada álbum. Só prática que o utilizador pediu.',
      )
      ..writeln(
        '- nodeType: artist|work|recording|releaseGroup|release|territory|scene|concept|label|place|show',
      )
      ..writeln(
        '- Nó territory/scene só se o cânone ainda não tiver essa chave. Prefere territoryKeys no álbum a criar pastas novas.',
      )
      ..writeln();

    if (nodes.isEmpty) {
      buffer.writeln(
        'MAPA ATUAL: ainda não há nós. Cria um recorte mínimo: 3–8 releaseGroups com territoryKeys canónicos (não uma pasta “World”), mais uma expedição com pergunta real de escuta.',
      );
    } else {
      buffer.writeln(
        'NÓS JÁ EXISTENTES (não dupliques pelo nome; reutiliza territoryKeys se já estiverem certos):',
      );
      final shown = nodes.take(80);
      for (final node in shown) {
        final keys = MusicNodeProvenance.territoryKeys(node.provenanceJson);
        final suffix = keys.isEmpty ? '' : '  [${keys.join(', ')}]';
        buffer.writeln(
          '- [${node.id.value}] ${node.nodeType.name}: ${node.canonicalName}$suffix',
        );
      }
      if (nodes.length > 80) {
        buffer.writeln('- … ${nodes.length - 80} mais');
      }
    }

    buffer.writeln();
    if (claims.isEmpty) {
      buffer.writeln('CLAIMS ACEITES: nenhum.');
    } else {
      buffer.writeln('CLAIMS JÁ ACEITES:');
      for (final claim in claims.take(40)) {
        buffer.writeln(
          '- ${claim.fromNodeId.value} --${claim.relationType.name}--> ${claim.toNodeId.value}',
        );
      }
    }

    buffer.writeln();
    if (areas.isEmpty) {
      buffer.writeln(
        'CATEGORIAS: ainda não há. Prefira areaPath ["Artes","Música"].',
      );
    } else {
      buffer.writeln('CATEGORIAS JÁ EXISTENTES (use estes nomes em areaPath):');
      final forest = KnowledgeAreaPolicy.buildForest(areas);
      void walk(KnowledgeAreaNode node, String indent) {
        buffer.writeln('$indent- ${node.area.title}');
        for (final child in node.children) {
          walk(child, '$indent  ');
        }
      }

      for (final root in forest) {
        walk(root, '');
      }
    }

    final visibleDecks = [
      for (final deck in decks)
        if (!deck.isArchived) deck.title,
    ]..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
    buffer.writeln();
    if (visibleDecks.isEmpty) {
      buffer.writeln('BARALHOS ATUAIS: nenhum.');
    } else {
      buffer
        ..writeln('BARALHOS JÁ EXISTENTES:')
        ..writeln(visibleDecks.map((t) => '- $t').join('\n'));
    }

    buffer.writeln();
    if (tags.isEmpty) {
      buffer.writeln('TAGS ATUAIS: nenhuma. Ex.: "Jazz", "Música / Harmonia".');
    } else {
      buffer.writeln('TAGS JÁ EXISTENTES:');
      for (final tag in tags) {
        buffer.writeln('- ${tag.title}');
      }
    }

    if (placements.isNotEmpty) {
      buffer.writeln();
      buffer.writeln(
        'COLOCAÇÕES SECUNDÁRIAS: ${placements.length} (não dupliques areaPath só para repetir uma prateleira).',
      );
    }

    buffer.writeln();
    if (researchNodes.isEmpty) {
      buffer.writeln('PESQUISA LIGADA: nenhum nó.');
    } else {
      buffer.writeln('NÓS DE PESQUISA (reutilize o título se fizer sentido):');
      for (final node in researchNodes.take(30)) {
        buffer.writeln('- ${node.title}');
      }
    }

    buffer
      ..writeln()
      ..writeln('PRATELEIRAS CANÓNICAS (opcional, para cards[].areaPath):');
    for (final path in KnowledgeAreaCatalog.labeledTitlePaths()) {
      if (path.contains('Música') ||
          path.contains('Harmonia') ||
          path.contains('Piano') ||
          path.contains('Artes')) {
        buffer.writeln('- $path');
      }
    }
    buffer
      ..writeln()
      ..writeln(
        'O pedido do utilizador vem a seguir a este bloco (ou já veio acima). Obedecele no recorte — não despejes o cânone inteiro.',
      );
    return buffer.toString();
  }
}
