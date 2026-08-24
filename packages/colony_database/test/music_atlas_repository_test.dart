import 'dart:convert';

import 'package:colony_database/colony_database.dart';
import 'package:colony_domain/colony_domain.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late ColonyDatabase db;
  late ColonyRepositories repos;
  var now = DateTime.utc(2026, 8, 23, 12);

  setUp(() {
    now = DateTime.utc(2026, 8, 23, 12);
    db = ColonyDatabase.inMemory();
    repos = ColonyRepositories.create(
      db,
      idGenerator: FixedIdGenerator([
        for (var i = 1; i <= 200; i++) 'id-$i',
      ]),
      clock: () => now,
    );
  });

  tearDown(() async {
    await db.close();
  });

  Future<ColonyProfile> profile() {
    return repos.profiles.create(
      colonyName: 'Atlas',
      displayName: 'Caio',
      timezone: 'UTC',
      locale: 'pt_BR',
      baseCurrency: 'BRL',
    );
  }

  test('create node, encounter and refuse cards from casual listen', () async {
    final created = await profile();
    final node = await repos.musicAtlas.createNode(
      nodeType: MusicNodeType.releaseGroup,
      canonicalName: 'Kind of Blue',
      beginYear: 1959,
    );
    expect(node.canonicalName, 'Kind of Blue');

    final encounter = await repos.musicAtlas.recordEncounter(
      profileId: created.id,
      nodeId: node.id,
      encounterType: MusicEncounterType.listen,
      note: 'no elevador',
    );
    expect(encounter.encounterType, MusicEncounterType.listen);

    final casual = await repos.musicAtlas.candidatesForEncounter(encounter.id);
    expect(casual, isEmpty);

    final attentive = await repos.musicAtlas.recordEncounter(
      profileId: created.id,
      nodeId: node.id,
      encounterType: MusicEncounterType.attentiveListen,
      note: 'modal, sem piano a mais',
    );
    final cards = await repos.musicAtlas.candidatesForEncounter(attentive.id);
    expect(cards, isNotEmpty);
    expect(cards.any((c) => c.front.contains('1959') || c.back == '1959'), isTrue);
  });

  test('JSON apply dedups by external id and clamps cartographed', () async {
    final created = await profile();
    final doc = MusicAtlasJsonCodec.parse('''
{
  "version": 1,
  "kind": "music_atlas",
  "nodes": [
    {
      "key": "kind-of-blue",
      "nodeType": "releaseGroup",
      "title": "Kind of Blue",
      "year": 1959,
      "discoveryState": "cartographed",
      "externalIds": [
        {"provider": "spotify", "entityType": "album", "id": "kob"}
      ]
    }
  ]
}
''');
    final first = await repos.musicAtlas.importJson(
      profileId: created.id,
      document: doc,
    );
    expect(first.createdNodes, 1);
    expect(first.conflictNodes, 0);

    final inspect = await repos.musicAtlas.inspect(
      (await repos.musicAtlas.listNodes()).single.id,
      created.id,
    );
    expect(inspect!.state!.discoveryState, isNot(MusicDiscoveryState.cartographed));
    expect(inspect.state!.discoveryState, MusicDiscoveryState.sighted);

    final again = await repos.musicAtlas.importJson(
      profileId: created.id,
      document: doc,
    );
    expect(again.createdNodes, 0);
    expect(again.linkedNodes, 1);
    expect(await repos.musicAtlas.listNodes(), hasLength(1));
  });

  test('Spotify library is contact/rumor, never cartographed', () async {
    final created = await profile();
    final result = await repos.musicAtlas.importSpotifyLibrary(
      profileId: created.id,
      consentId: const EntityId('consent-1'),
      albums: const [
        SpotifySavedAlbum(
          spotifyId: 'alb-1',
          title: 'Dummy',
          artists: ['A'],
          year: 2001,
          imageUrl: 'https://i.scdn.co/image/dummy',
          genres: const ['modal jazz'],
        ),
      ],
    );
    expect(result.createdNodes, 1);
    final node = (await repos.musicAtlas.listNodes()).single;
    final inspect = await repos.musicAtlas.inspect(node.id, created.id);
    expect(inspect!.encounters.single.encounterType, MusicEncounterType.contact);
    expect(inspect.state!.discoveryState, MusicDiscoveryState.rumor);
    expect(inspect.state!.discoveryState, isNot(MusicDiscoveryState.cartographed));
    expect(
      MusicNodeProvenance.coverArtUrl(inspect.node.provenanceJson),
      'https://i.scdn.co/image/dummy',
    );
    expect(
      MusicNodeProvenance.territoryKeys(inspect.node.provenanceJson),
      contains('jazz.modal'),
    );
  });

  test('export v35 includes nodes and never writes token keys', () async {
    final created = await profile();
    await repos.musicAtlas.createNode(
      nodeType: MusicNodeType.artist,
      canonicalName: 'Miles Davis',
    );
    final snapshot = await repos.export.buildSnapshot();
    expect(snapshot.version, 37);
    expect(snapshot.profile.id, created.id);
    expect(snapshot.musicNodes, hasLength(1));
    final encoded = jsonEncode(snapshot.toJson());
    expect(encoded.contains('accessToken'), isFalse);
    expect(encoded.contains('access_token'), isFalse);
    expect(encoded.contains('refreshToken'), isFalse);
    expect(encoded.contains('refresh_token'), isFalse);
    expect(encoded.contains('spotify.tokens'), isFalse);
  });

  test('clearSpotifySync removes local sync row', () async {
    final created = await profile();
    await repos.musicAtlas.upsertSpotifySync(
      MusicSpotifySyncState(
        profileId: created.id,
        consentId: const EntityId('consent-1'),
        updatedAt: now,
      ),
    );
    expect(await repos.musicAtlas.getSpotifySync(created.id), isNotNull);
    await repos.musicAtlas.clearSpotifySync(created.id);
    expect(await repos.musicAtlas.getSpotifySync(created.id), isNull);
  });

  test('extended history import lights albums as importListen, not cartographed', () async {
    final created = await profile();
    final history = SpotifyStreamingHistoryCodec.parseJson('''
[
  {
    "ts": "2024-01-01T12:00:00Z",
    "ms_played": 240000,
    "master_metadata_track_name": "So What",
    "master_metadata_album_artist_name": "Miles Davis",
    "master_metadata_album_album_name": "Kind of Blue",
    "reason_end": "trackdone"
  }
]
''');
    final result = await repos.musicAtlas.importSpotifyHistory(
      profileId: created.id,
      history: history,
    );
    expect(result.createdNodes, 1);
    expect(result.createdEncounters, 1);
    final inspect = await repos.musicAtlas.inspect(
      (await repos.musicAtlas.listNodes()).single.id,
      created.id,
    );
    expect(inspect!.encounters.single.encounterType, MusicEncounterType.importListen);
    expect(inspect.encounters.single.durationSeconds, greaterThanOrEqualTo(30));
    expect(inspect.state!.discoveryState, MusicDiscoveryState.sampled);
    expect(inspect.state!.discoveryState, isNot(MusicDiscoveryState.cartographed));

    final again = await repos.musicAtlas.importSpotifyHistory(
      profileId: created.id,
      history: history,
    );
    expect(again.createdEncounters, 0);
    expect(again.skippedNodes, 1);
  });
}
