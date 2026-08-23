import 'package:colony_domain/colony_domain.dart';
import 'package:test/test.dart';

void main() {
  final now = DateTime.utc(2026, 8, 23, 12);

  MusicNode album(String id, String title, {String? artist, int? year}) {
    return MusicNode.create(
      id: EntityId(id),
      nodeType: MusicNodeType.releaseGroup,
      canonicalName: title,
      description: artist,
      beginYear: year,
      now: now,
    );
  }

  MusicEncounter listen(
    String id,
    String nodeId,
    MusicEncounterType type,
  ) {
    return MusicEncounter.record(
      id: EntityId(id),
      profileId: const EntityId('p'),
      nodeId: EntityId(nodeId),
      encounterType: type,
      occurredAt: now,
      now: now,
      sourceType: SourceType.manual,
    );
  }

  test('cover recipe is deterministic and builds a monogram', () {
    final a = MusicCoverRecipe.from(title: 'Kind of Blue', artist: 'Miles Davis', year: 1959);
    final b = MusicCoverRecipe.from(title: 'Kind of Blue', artist: 'Miles Davis', year: 1959);
    expect(a.seed, b.seed);
    expect(a.monogram, 'KB');
    expect(a.motif, b.motif);
    expect(
      MusicCoverRecipe.from(title: 'Geogaddi').monogram,
      isNot(a.monogram),
    );
  });

  test('genre aliases resolve to the modal jazz river', () {
    expect(MusicGenreAtlas.matchGenreLabel('modal jazz'), 'jazz.modal');
    expect(MusicGenreAtlas.matchGenreLabel('MPB'), 'br.mpb');
    expect(MusicGenreAtlas.matchGenreLabel('post-punk'), 'rock.postpunk');
  });

  test('dossier lights Kind of Blue and Google search carries artist', () {
    final dossier = MusicGenreAtlas.dossierFor(
      title: 'Kind of Blue',
      artist: 'Miles Davis',
    );
    expect(dossier, isNotNull);
    expect(dossier!.territoryKeys, contains('jazz.modal'));
    expect(dossier.markdown, contains('So What'));

    final uri = MusicAlbumSearch.google(
      title: 'Disco sem ficha',
      artist: 'Alguém',
      year: 2020,
    );
    expect(uri.host, 'www.google.com');
    expect(uri.queryParameters['q'], contains('Disco sem ficha'));
    expect(uri.queryParameters['q'], contains('Alguém'));
    expect(uri.queryParameters['q'], contains('álbum'));
  });

  test('cartographer lights the modal branch from a heard dossier album', () {
    final node = album('n1', 'Kind of Blue', artist: 'Miles Davis', year: 1959);
    final map = MusicAtlasCartographer.compose(
      overview: MusicAtlasOverview(
        nodes: [node],
        states: [
          PersonalMusicNodeState(
            profileId: const EntityId('p'),
            nodeId: node.id,
            discoveryState: MusicDiscoveryState.sampled,
            lastEncounterAt: now,
            encounterCount: 1,
            createdAt: now,
            updatedAt: now,
          ),
        ],
        encounters: [listen('e1', 'n1', MusicEncounterType.listen)],
        expeditions: const [],
        identities: const [],
      ),
    );

    final modal = map.territory('jazz.modal');
    expect(modal, isNotNull);
    expect(modal!.heardCount, 1);
    expect(modal.explored, isTrue);
    expect(map.territory('jazz')!.heardCount, 1);
    expect(map.territory('br.samba')!.heardCount, 0);

    final heard = map.albumsIn('jazz.modal');
    expect(heard.single.node.canonicalName, 'Kind of Blue');
    expect(heard.single.heard, isTrue);
    expect(heard.single.hasDossier, isTrue);
    expect(map.layout.territoryPoints.containsKey('jazz.modal'), isTrue);
    expect(map.layout.edges, isNotEmpty);
  });

  test('saved-only contact does not count as heard', () {
    final node = album('n2', 'Unknown Pleasures', artist: 'Joy Division', year: 1979);
    final map = MusicAtlasCartographer.compose(
      overview: MusicAtlasOverview(
        nodes: [node],
        states: const [],
        encounters: [listen('e2', 'n2', MusicEncounterType.contact)],
        expeditions: const [],
        identities: const [],
      ),
    );
    final post = map.territory('rock.postpunk')!;
    expect(post.heardCount, 0);
    expect(post.contactCount, 1);
    expect(map.albumsIn('rock.postpunk').single.heard, isFalse);
  });

  test('unmapped basin collects albums without a river', () {
    final node = album('n3', 'Disco sem rio', artist: 'Local');
    final map = MusicAtlasCartographer.compose(
      overview: MusicAtlasOverview(
        nodes: [node],
        states: const [],
        encounters: [listen('e3', 'n3', MusicEncounterType.listen)],
        expeditions: const [],
        identities: const [],
      ),
    );
    expect(map.albumsIn(MusicGenreAtlas.unmappedKey).single.node.id.value, 'n3');
    expect(map.territory(MusicGenreAtlas.unmappedKey)!.heardCount, 1);
  });

  test('user-grown territory hangs from os teus rios', () {
    final territory = MusicNode.create(
      id: const EntityId('t1'),
      nodeType: MusicNodeType.territory,
      canonicalName: 'Batida de Lisboa',
      now: now,
    );
    final record = album('n4', 'Danço por aí', artist: 'Dino d\'Santiago');
    final map = MusicAtlasCartographer.compose(
      overview: MusicAtlasOverview(
        nodes: [territory, record],
        states: const [],
        encounters: [listen('e4', 'n4', MusicEncounterType.attentiveListen)],
        expeditions: const [],
        identities: const [],
      ),
      claims: [
        MusicRelationClaim(
          id: const EntityId('c1'),
          fromNodeId: record.id,
          toNodeId: territory.id,
          relationType: MusicRelationType.sharesScene,
          status: MusicClaimStatus.accepted,
          provenanceJson: '{}',
          createdAt: now,
          updatedAt: now,
        ),
      ],
    );
    expect(map.territory(MusicGenreAtlas.userRootKey), isNotNull);
    expect(
      map.territories.any((t) => t.title == 'Batida de Lisboa' && t.isUserGrown),
      isTrue,
    );
    expect(map.albumsIn(MusicGenreAtlas.userRootKey), isNotEmpty);
  });

  test('provenance merge keeps cover and notes without clobbering source', () {
    final merged = MusicNodeProvenance.merge(
      '{"source_type":"spotify_library"}',
      coverArtUrl: 'https://img.example/cover.jpg',
      notesMarkdown: '# Nota',
      territoryKeys: const ['jazz.modal'],
    );
    expect(MusicNodeProvenance.coverArtUrl(merged), contains('cover.jpg'));
    expect(MusicNodeProvenance.notesMarkdown(merged), '# Nota');
    expect(MusicNodeProvenance.territoryKeys(merged), ['jazz.modal']);
    expect(MusicNodeProvenance.decode(merged)['source_type'], 'spotify_library');
  });

  test('selected albums bloom around the chosen well', () {
    final node = album('n5', 'Kind of Blue', artist: 'Miles Davis', year: 1959);
    final map = MusicAtlasCartographer.compose(
      overview: MusicAtlasOverview(
        nodes: [node],
        states: const [],
        encounters: [listen('e5', 'n5', MusicEncounterType.listen)],
        expeditions: const [],
        identities: const [],
      ),
      selectedTerritoryKey: 'jazz.modal',
    );
    expect(map.layout.albumPoints.containsKey('n5'), isTrue);
    final well = map.layout.territoryPoints['jazz.modal']!;
    final sleeve = map.layout.albumPoints['n5']!;
    expect(sleeve.x, greaterThan(well.x));
  });
}
