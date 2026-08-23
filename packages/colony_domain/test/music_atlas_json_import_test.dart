import 'dart:convert';

import 'package:colony_domain/colony_domain.dart';
import 'package:test/test.dart';

void main() {
  test('parse accepts fenced JSON and clamps cartographed', () {
    final doc = MusicAtlasJsonCodec.parse('''
```json
{
  "version": 1,
  "kind": "music_atlas",
  "nodes": [
    {
      "key": "kind-of-blue",
      "nodeType": "releaseGroup",
      "title": "Kind of Blue",
      "artists": ["Miles Davis"],
      "year": 1959,
      "discoveryState": "cartographed"
    }
  ]
}
```
''');
    expect(doc.nodes, hasLength(1));
    expect(doc.nodes.single.title, 'Kind of Blue');
    expect(doc.clampedDiscoveryStates, contains('cartographed'));
    final decision = MusicDiscoveryPolicy.clampImported(
      doc.nodes.single.discoveryState,
    );
    expect(decision.state, MusicDiscoveryState.sighted);
    expect(decision.clamped, isTrue);
  });

  test('parse accepts a root array of nodes', () {
    final doc = MusicAtlasJsonCodec.parse('''
[
  {"key":"a","nodeType":"artist","title":"Alice Coltrane"}
]
''');
    expect(doc.nodes.single.nodeType, MusicNodeType.artist);
  });

  test('cards-only document is rejected as flashcards', () {
    expect(
      () => MusicAtlasJsonCodec.parse('''
{"version":1,"cards":[{"front":"x","back":"y","kind":"basic","deck":"D"}]}
'''),
      throwsA(isA<MusicAtlasJsonException>()),
    );
  });

  test('plan links by Spotify id and skips duplicate claims', () {
    final now = DateTime.utc(2026, 8, 23);
    final existing = MusicNode.create(
      id: const EntityId('n1'),
      nodeType: MusicNodeType.releaseGroup,
      canonicalName: 'Kind of Blue',
      now: now,
    );
    final identity = MusicExternalIdentity(
      id: const EntityId('id1'),
      nodeId: existing.id,
      provider: 'spotify',
      entityType: 'album',
      externalId: 'abc',
      createdAt: now,
      updatedAt: now,
    );
    final claim = MusicRelationClaim(
      id: const EntityId('c1'),
      fromNodeId: existing.id,
      toNodeId: const EntityId('n2'),
      relationType: MusicRelationType.sharesScene,
      status: MusicClaimStatus.accepted,
      provenanceJson: '{}',
      createdAt: now,
      updatedAt: now,
    );
    final doc = MusicAtlasJsonCodec.parse('''
{
  "version": 1,
  "kind": "music_atlas",
  "nodes": [
    {
      "key": "kob",
      "title": "Kind of Blue",
      "nodeType": "releaseGroup",
      "externalIds": [{"provider":"spotify","entityType":"album","id":"abc"}]
    },
    {"key": "other", "title": "A Love Supreme", "nodeType": "releaseGroup"}
  ],
  "claims": [
    {"fromKey":"kob","toKey":"other","relationType":"sharesScene"}
  ]
}
''');
    final plan = MusicAtlasJsonImportPolicy.plan(
      document: doc,
      existingNodes: [existing],
      existingIdentities: [identity],
      existingClaims: [claim],
    );
    expect(plan.linkCount, 1);
    expect(plan.createCount, 1);
    expect(plan.claims.single.create, isTrue);
  });

  test('reimport of the same node is a link, not a create', () {
    final now = DateTime.utc(2026, 8, 23);
    final existing = MusicNode.create(
      id: const EntityId('n1'),
      nodeType: MusicNodeType.releaseGroup,
      canonicalName: 'Kind of Blue',
      now: now,
    );
    final doc = MusicAtlasJsonCodec.parse('''
{"version":1,"kind":"music_atlas","nodes":[{"key":"k","title":"Kind of Blue","nodeType":"releaseGroup"}]}
''');
    final plan = MusicAtlasJsonImportPolicy.plan(
      document: doc,
      existingNodes: [existing],
      existingIdentities: const [],
      existingClaims: const [],
    );
    expect(plan.createCount, 0);
    expect(plan.linkCount, 1);
  });

  test('prompt lists current nodes and forbids coverage percentages', () {
    final now = DateTime.utc(2026, 8, 23);
    final empty = MusicAtlasJsonPromptBuilder.build(nodes: const [], claims: const []);
    expect(empty, contains('ainda não há nós'));
    expect(empty, contains('areaPath'));

    final filled = MusicAtlasJsonPromptBuilder.build(
      nodes: [
        MusicNode.create(
          id: const EntityId('n1'),
          nodeType: MusicNodeType.territory,
          canonicalName: 'Tropicalismo',
          now: now,
        ),
      ],
      claims: const [],
    );
    expect(filled, contains('Tropicalismo'));
    expect(filled, contains('percentagens de cobertura'));
  });

  test('parseSource walks one node at a time and skips unknown blobs', () {
    final json = jsonEncode({
      'version': 1,
      'kind': 'music_atlas',
      'lyrics': 'x' * 2000,
      'nodes': [
        {
          'key': 'k',
          'title': 'Panis',
          'nodeType': 'releaseGroup',
          'year': 1968,
        },
      ],
    });
    final doc = MusicAtlasJsonCodec.parseSource(
      Uint8ListTimelineByteSource(utf8.encode(json)),
    );
    expect(doc.nodes.single.title, 'Panis');
  });

  test('embedded cards reuse the flashcard codec schema', () {
    final doc = MusicAtlasJsonCodec.parse('''
{
  "version": 1,
  "kind": "music_atlas",
  "nodes": [{"key":"k","title":"Kind of Blue","nodeType":"releaseGroup"}],
  "cards": [{
    "front": "Ano de Kind of Blue?",
    "back": "1959",
    "kind": "basic",
    "deck": "Jazz",
    "areaPath": "Artes / Música"
  }]
}
''');
    expect(doc.cards, hasLength(1));
    expect(doc.cards.single.areaPath, ['Artes', 'Música']);
  });

  test('expedition without a question is rejected', () {
    expect(
      () => MusicAtlasJsonCodec.parse('''
{
  "version": 1,
  "nodes": [{"key":"k","title":"X","nodeType":"artist"}],
  "expeditions": [{"title":"Rota","question":"","stops":[]}]
}
'''),
      throwsA(isA<MusicAtlasJsonException>()),
    );
  });
}
