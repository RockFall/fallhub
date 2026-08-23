import 'dart:math';

import 'package:colony_domain/colony_domain.dart';
import 'package:test/test.dart';

void main() {
  test('imported discovery states never become cartographed', () {
    expect(
      MusicDiscoveryPolicy.clampImported('cartographed').state,
      MusicDiscoveryState.sighted,
    );
    expect(MusicDiscoveryPolicy.clampImported('cartographed').clamped, isTrue);
    expect(
      MusicDiscoveryPolicy.clampImported('contact').state,
      MusicDiscoveryState.rumor,
    );
    expect(
      MusicDiscoveryPolicy.clampImported('sighted').clamped,
      isFalse,
    );
  });

  test('suggested state never reduces an explicit stronger one', () {
    final next = MusicDiscoveryPolicy.suggestAfterEncounter(
      current: MusicDiscoveryState.cartographed,
      encounterType: MusicEncounterType.contact,
    );
    expect(next, MusicDiscoveryState.cartographed);
  });

  test('casual listens do not spawn flashcard candidates', () {
    final now = DateTime.utc(2026, 8, 23);
    final node = MusicNode.create(
      id: const EntityId('n'),
      nodeType: MusicNodeType.releaseGroup,
      canonicalName: 'Kind of Blue',
      beginYear: 1959,
      now: now,
    );
    final listen = MusicEncounter.record(
      id: const EntityId('e'),
      profileId: const EntityId('p'),
      nodeId: node.id,
      encounterType: MusicEncounterType.listen,
      occurredAt: now,
      now: now,
      sourceType: SourceType.integration,
    );
    expect(
      MusicFlashcardCandidatePolicy.fromEncounter(node: node, encounter: listen),
      isEmpty,
    );

    final attentive = MusicEncounter.record(
      id: const EntityId('e2'),
      profileId: const EntityId('p'),
      nodeId: node.id,
      encounterType: MusicEncounterType.attentiveListen,
      occurredAt: now,
      now: now,
      sourceType: SourceType.manual,
      note: 'O piano soa espacial.',
    );
    final cards = MusicFlashcardCandidatePolicy.fromEncounter(
      node: node,
      encounter: attentive,
    );
    expect(cards.length, greaterThanOrEqualTo(2));
    expect(cards.first.areaPath.first, 'Artes');
  });

  test('constellation partitions saved vs local-only', () {
    final now = DateTime.utc(2026, 8, 23);
    final saved = MusicNode.create(
      id: const EntityId('s'),
      nodeType: MusicNodeType.releaseGroup,
      canonicalName: 'Saved',
      now: now,
    );
    final local = MusicNode.create(
      id: const EntityId('l'),
      nodeType: MusicNodeType.releaseGroup,
      canonicalName: 'Local',
      now: now,
    );
    final constellation = MusicSpotifyPolicy.buildConstellation(
      nodes: [saved, local],
      states: const [],
      identities: [
        MusicExternalIdentity(
          id: const EntityId('i'),
          nodeId: saved.id,
          provider: 'spotify',
          entityType: 'album',
          externalId: 'sp1',
          createdAt: now,
          updatedAt: now,
        ),
      ],
      encounters: [
        MusicEncounter.record(
          id: const EntityId('e'),
          profileId: const EntityId('p'),
          nodeId: saved.id,
          encounterType: MusicEncounterType.attentiveListen,
          occurredAt: now,
          now: now,
          sourceType: SourceType.manual,
        ),
      ],
    );
    expect(
      constellation.of(MusicSpotifyPartition.attentiveAndSaved),
      hasLength(1),
    );
    expect(constellation.of(MusicSpotifyPartition.localOnly), hasLength(1));
  });

  test('PKCE auth URL and callback code extraction', () {
    final pkce = MusicSpotifyPolicy.generatePkce(random: DateTime.now().microsecond.isEven
        ? _FixedRandom()
        : _FixedRandom());
    final withChallenge = SpotifyPkceChallenge(
      verifier: pkce.verifier,
      challenge: 'abc123challenge',
      state: 'st',
    );
    final request = MusicSpotifyPolicy.authorizationRequest(
      clientId: 'client',
      pkce: withChallenge,
      scopes: [MusicSpotifyPolicy.libraryScope],
    );
    expect(request.authorizationUrl, contains('code_challenge_method=S256'));
    expect(request.authorizationUrl, contains('user-library-read'));

    expect(
      MusicSpotifyPolicy.extractAuthorizationCode(
        'colony://integrations/spotify/callback?code=xyz&state=st',
        expectedState: 'st',
      ),
      'xyz',
    );
    expect(
      () => MusicSpotifyPolicy.extractAuthorizationCode(
        'colony://x?error=access_denied',
      ),
      throwsStateError,
    );
  });

  test('export v35 round-trips music nodes and never invents tokens', () {
    final now = DateTime.utc(2026, 8, 23, 12);
    final snapshot = ExportSnapshot(
      exportedAt: now,
      version: 35,
      profile: ColonyProfile(
        id: const EntityId('profile-1'),
        colonyName: 'Atlas',
        displayName: 'Tester',
        timezone: 'UTC',
        locale: 'pt_BR',
        baseCurrency: 'BRL',
        createdAt: now,
        updatedAt: now,
      ),
      preferences: AppPreferences.defaults(),
      tasks: const [],
      events: const [],
      musicNodes: [
        MusicNode.create(
          id: const EntityId('n1'),
          nodeType: MusicNodeType.releaseGroup,
          canonicalName: 'Kind of Blue',
          beginYear: 1959,
          now: now,
        ),
      ],
    );
    final json = snapshot.toJson();
    expect(json.containsKey('spotify_tokens'), isFalse);
    expect(json['music_nodes'], isNotEmpty);
    final again = ExportSnapshot.fromJson(json);
    expect(again.musicNodes.single.canonicalName, 'Kind of Blue');
  });
}

class _FixedRandom implements Random {
  @override
  int nextInt(int max) => 7;

  @override
  double nextDouble() => 0.1;

  @override
  bool nextBool() => false;
}
