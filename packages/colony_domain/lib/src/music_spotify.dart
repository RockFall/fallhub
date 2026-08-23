import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:equatable/equatable.dart';

import 'id_generator.dart';
import 'music_atlas.dart';

class SpotifyPkceChallenge extends Equatable {
  const SpotifyPkceChallenge({
    required this.verifier,
    required this.challenge,
    required this.state,
  });

  final String verifier;
  final String challenge;
  final String state;

  @override
  List<Object?> get props => [verifier, challenge, state];
}

class SpotifyAuthRequest extends Equatable {
  const SpotifyAuthRequest({
    required this.authorizationUrl,
    required this.pkce,
    required this.scopes,
    required this.redirectUri,
  });

  final String authorizationUrl;
  final SpotifyPkceChallenge pkce;
  final List<String> scopes;
  final String redirectUri;

  @override
  List<Object?> get props => [authorizationUrl, pkce, scopes, redirectUri];
}

class SpotifyTokenSet extends Equatable {
  const SpotifyTokenSet({
    required this.accessToken,
    this.refreshToken,
    required this.scope,
    required this.expiresAt,
    this.tokenType = 'Bearer',
  });

  final String accessToken;
  final String? refreshToken;
  final List<String> scope;
  final DateTime expiresAt;
  final String tokenType;

  bool isExpiredAt(DateTime now) => !expiresAt.isAfter(now);

  @override
  List<Object?> get props => [
    accessToken,
    refreshToken,
    scope,
    expiresAt,
    tokenType,
  ];
}

class SpotifyCapabilityProbe extends Equatable {
  const SpotifyCapabilityProbe({
    required this.scope,
    required this.httpStatus,
    this.retryAfterSeconds,
    required this.probedAt,
    this.detail,
  });

  final String scope;
  final int httpStatus;
  final int? retryAfterSeconds;
  final DateTime probedAt;
  final String? detail;

  bool get available => httpStatus >= 200 && httpStatus < 300;
  bool get quotaOrForbidden => httpStatus == 403;
  bool get unauthorized => httpStatus == 401;
  bool get rateLimited => httpStatus == 429;

  Map<String, Object?> toJson() => {
    'scope': scope,
    'httpStatus': httpStatus,
    if (retryAfterSeconds != null) 'retryAfterSeconds': retryAfterSeconds,
    'probedAt': probedAt.toUtc().toIso8601String(),
    if (detail != null) 'detail': detail,
  };

  @override
  List<Object?> get props => [
    scope,
    httpStatus,
    retryAfterSeconds,
    probedAt,
    detail,
  ];
}

class SpotifySavedAlbum extends Equatable {
  const SpotifySavedAlbum({
    required this.spotifyId,
    required this.title,
    required this.artists,
    this.year,
    this.externalUrl,
    this.addedAt,
    this.imageUrl,
    this.genres = const [],
  });

  final String spotifyId;
  final String title;
  final List<String> artists;
  final int? year;
  final String? externalUrl;
  final DateTime? addedAt;
  final String? imageUrl;
  final List<String> genres;

  String get artistCredit => artists.join(', ');

  @override
  List<Object?> get props => [
    spotifyId,
    title,
    artists,
    year,
    externalUrl,
    addedAt,
    imageUrl,
    genres,
  ];
}

class SpotifyRecentlyPlayed extends Equatable {
  const SpotifyRecentlyPlayed({
    required this.trackId,
    required this.trackTitle,
    required this.artists,
    this.albumId,
    this.albumTitle,
    required this.playedAt,
  });

  final String trackId;
  final String trackTitle;
  final List<String> artists;
  final String? albumId;
  final String? albumTitle;
  final DateTime playedAt;

  @override
  List<Object?> get props => [
    trackId,
    trackTitle,
    artists,
    albumId,
    albumTitle,
    playedAt,
  ];
}

class SpotifyPlaylistSummary extends Equatable {
  const SpotifyPlaylistSummary({
    required this.spotifyId,
    required this.name,
    required this.trackCount,
    this.snapshotId,
    this.externalUrl,
    this.tracks = const [],
  });

  final String spotifyId;
  final String name;
  final int trackCount;
  final String? snapshotId;
  final String? externalUrl;
  final List<SpotifySavedAlbum> tracks;

  @override
  List<Object?> get props => [
    spotifyId,
    name,
    trackCount,
    snapshotId,
    externalUrl,
    tracks,
  ];
}

class SpotifyNowPlaying extends Equatable {
  const SpotifyNowPlaying({
    required this.trackId,
    required this.trackTitle,
    required this.artists,
    this.albumId,
    this.albumTitle,
    this.externalUrl,
  });

  final String trackId;
  final String trackTitle;
  final List<String> artists;
  final String? albumId;
  final String? albumTitle;
  final String? externalUrl;

  @override
  List<Object?> get props => [
    trackId,
    trackTitle,
    artists,
    albumId,
    albumTitle,
    externalUrl,
  ];
}

enum MusicSpotifyPartition { attentiveAndSaved, savedWithoutEncounter, localOnly }

class MusicSpotifyConstellationItem extends Equatable {
  const MusicSpotifyConstellationItem({
    required this.node,
    required this.partition,
    this.spotifyId,
    this.state,
  });

  final MusicNode node;
  final MusicSpotifyPartition partition;
  final String? spotifyId;
  final PersonalMusicNodeState? state;

  @override
  List<Object?> get props => [node, partition, spotifyId, state];
}

class MusicSpotifyConstellation extends Equatable {
  const MusicSpotifyConstellation({required this.items});

  final List<MusicSpotifyConstellationItem> items;

  List<MusicSpotifyConstellationItem> of(MusicSpotifyPartition partition) => [
    for (final item in items)
      if (item.partition == partition) item,
  ];

  @override
  List<Object?> get props => [items];
}

abstract final class MusicSpotifyPolicy {
  static const authorizeUrl = 'https://accounts.spotify.com/authorize';
  static const tokenUrl = 'https://accounts.spotify.com/api/token';
  static const apiBase = 'https://api.spotify.com/v1';
  static const defaultRedirectUri = 'colony://integrations/spotify/callback';

  static const libraryScope = 'user-library-read';
  static const recentScope = 'user-read-recently-played';
  static const playlistScope = 'playlist-read-private';
  static const collaborativePlaylistScope = 'playlist-read-collaborative';
  static const currentlyPlayingScope = 'user-read-currently-playing';
  static const followScope = 'user-follow-read';

  static const incrementalScopes = <String>[
    libraryScope,
    recentScope,
    playlistScope,
    collaborativePlaylistScope,
    currentlyPlayingScope,
    followScope,
  ];

  static SpotifyPkceChallenge generatePkce({
    required Random random,
    int verifierBytes = 64,
  }) {
    final verifier = _base64UrlNoPad(
      Uint8List.fromList([
        for (var i = 0; i < verifierBytes; i++) random.nextInt(256),
      ]),
    );
    // Challenge is computed by the adapter (SHA-256). Domain only stores
    // the verifier contract; [challenge] here is a placeholder filled later.
    return SpotifyPkceChallenge(
      verifier: verifier,
      challenge: '',
      state: _base64UrlNoPad(
        Uint8List.fromList([for (var i = 0; i < 16; i++) random.nextInt(256)]),
      ),
    );
  }

  static SpotifyAuthRequest authorizationRequest({
    required String clientId,
    required SpotifyPkceChallenge pkce,
    required List<String> scopes,
    String redirectUri = defaultRedirectUri,
  }) {
    if (clientId.trim().isEmpty) {
      throw ArgumentError('Spotify clientId is required');
    }
    if (pkce.challenge.isEmpty) {
      throw ArgumentError('PKCE challenge must be SHA-256 of the verifier');
    }
    final params = <String, String>{
      'client_id': clientId.trim(),
      'response_type': 'code',
      'redirect_uri': redirectUri,
      'code_challenge_method': 'S256',
      'code_challenge': pkce.challenge,
      'state': pkce.state,
      'scope': scopes.join(' '),
    };
    final query = params.entries
        .map(
          (e) =>
              '${Uri.encodeQueryComponent(e.key)}=${Uri.encodeQueryComponent(e.value)}',
        )
        .join('&');
    return SpotifyAuthRequest(
      authorizationUrl: '$authorizeUrl?$query',
      pkce: pkce,
      scopes: scopes,
      redirectUri: redirectUri,
    );
  }

  /// Accepts a full redirect URI or a bare authorization code.
  static String extractAuthorizationCode(String raw, {String? expectedState}) {
    final text = raw.trim();
    if (text.isEmpty) {
      throw ArgumentError('Código Spotify vazio');
    }
    if (!text.contains('://') && !text.contains('?')) {
      return text;
    }
    final uri = Uri.parse(text);
    final error = uri.queryParameters['error'];
    if (error != null && error.isNotEmpty) {
      throw StateError('Spotify recusou a autorização: $error');
    }
    final state = uri.queryParameters['state'];
    if (expectedState != null && state != expectedState) {
      throw StateError('State OAuth inválido');
    }
    final code = uri.queryParameters['code'];
    if (code == null || code.isEmpty) {
      throw ArgumentError('A URI não contém um código de autorização');
    }
    return code;
  }

  static String openAlbumUrl(String spotifyId) =>
      'https://open.spotify.com/album/${spotifyId.trim()}';

  static String openAlbumUri(String spotifyId) =>
      'spotify:album:${spotifyId.trim()}';

  static String openArtistUri(String spotifyId) =>
      'spotify:artist:${spotifyId.trim()}';

  static String openTrackUri(String spotifyId) =>
      'spotify:track:${spotifyId.trim()}';

  static String openPlaylistUri(String spotifyId) =>
      'spotify:playlist:${spotifyId.trim()}';

  static MusicSpotifyConstellation buildConstellation({
    required List<MusicNode> nodes,
    required List<PersonalMusicNodeState> states,
    required List<MusicExternalIdentity> identities,
    required List<MusicEncounter> encounters,
  }) {
    final stateByNode = {for (final s in states) s.nodeId.value: s};
    final spotifyByNode = <String, String>{};
    for (final identity in identities) {
      if (identity.provider == 'spotify') {
        spotifyByNode[identity.nodeId.value] = identity.externalId;
      }
    }
    final attentiveNodes = <String>{};
    for (final encounter in encounters) {
      if (encounter.encounterType == MusicEncounterType.attentiveListen ||
          encounter.encounterType == MusicEncounterType.comparison ||
          encounter.encounterType == MusicEncounterType.practice ||
          encounter.encounterType == MusicEncounterType.live) {
        attentiveNodes.add(encounter.nodeId.value);
      }
    }

    final items = <MusicSpotifyConstellationItem>[];
    for (final node in nodes) {
      final spotifyId = spotifyByNode[node.id.value];
      final state = stateByNode[node.id.value];
      final attentive = attentiveNodes.contains(node.id.value);
      final partition = switch ((spotifyId != null, attentive)) {
        (true, true) => MusicSpotifyPartition.attentiveAndSaved,
        (true, false) => MusicSpotifyPartition.savedWithoutEncounter,
        (false, _) => MusicSpotifyPartition.localOnly,
      };
      items.add(
        MusicSpotifyConstellationItem(
          node: node,
          partition: partition,
          spotifyId: spotifyId,
          state: state,
        ),
      );
    }
    return MusicSpotifyConstellation(items: items);
  }

  static String capabilityProbeJson(List<SpotifyCapabilityProbe> probes) {
    return jsonEncode([for (final probe in probes) probe.toJson()]);
  }

  static String _base64UrlNoPad(Uint8List bytes) {
    return base64UrlEncode(bytes).replaceAll('=', '');
  }
}

/// Port implemented in the app layer. Domain never imports HTTP/SDKs.
abstract class SpotifyCatalogPort {
  Future<SpotifyTokenSet> exchangeCode({
    required String clientId,
    required String redirectUri,
    required String code,
    required String verifier,
  });

  Future<SpotifyTokenSet> refresh({
    required String clientId,
    required SpotifyTokenSet current,
  });

  Future<List<SpotifySavedAlbum>> listSavedAlbums(SpotifyTokenSet tokens);

  Future<List<SpotifyRecentlyPlayed>> listRecentlyPlayed(SpotifyTokenSet tokens);

  Future<List<SpotifyPlaylistSummary>> listPlaylists(SpotifyTokenSet tokens);

  Future<List<SpotifySavedAlbum>> listPlaylistTracks(
    SpotifyTokenSet tokens,
    String playlistId,
  );

  Future<SpotifyNowPlaying?> currentlyPlaying(SpotifyTokenSet tokens);

  Future<SpotifyCapabilityProbe> probe({
    required SpotifyTokenSet tokens,
    required String scope,
    required DateTime now,
  });
}

/// Secrets stay out of Drift and out of export (spec §75.12).
abstract class SpotifyTokenStore {
  Future<SpotifyTokenSet?> read(EntityId profileId);
  Future<void> write(EntityId profileId, SpotifyTokenSet tokens);
  Future<void> clear(EntityId profileId);
}
