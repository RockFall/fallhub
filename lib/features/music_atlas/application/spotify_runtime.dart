import 'dart:convert';
import 'dart:math';

import 'package:colony_domain/colony_domain.dart';
import 'package:crypto/crypto.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

/// In-memory tokens for tests. Production uses [PrefsSpotifyTokenStore]
/// (device-local, never exported).
class MemorySpotifyTokenStore implements SpotifyTokenStore {
  final _tokens = <String, SpotifyTokenSet>{};

  @override
  Future<SpotifyTokenSet?> read(EntityId profileId) async =>
      _tokens[profileId.value];

  @override
  Future<void> write(EntityId profileId, SpotifyTokenSet tokens) async {
    _tokens[profileId.value] = tokens;
  }

  @override
  Future<void> clear(EntityId profileId) async {
    _tokens.remove(profileId.value);
  }
}

/// Client ID is public. Tokens stay out of Drift / export.
class PrefsSpotifyTokenStore implements SpotifyTokenStore {
  PrefsSpotifyTokenStore([this._prefs]);

  final SharedPreferences? _prefs;

  Future<SharedPreferences> _ready() async =>
      _prefs ?? SharedPreferences.getInstance();

  String _key(EntityId profileId) => 'spotify.tokens.${profileId.value}';

  @override
  Future<SpotifyTokenSet?> read(EntityId profileId) async {
    final prefs = await _ready();
    final raw = prefs.getString(_key(profileId));
    if (raw == null || raw.isEmpty) return null;
    final json = jsonDecode(raw);
    if (json is! Map<String, dynamic>) return null;
    return SpotifyTokenSet(
      accessToken: json['accessToken'] as String? ?? '',
      refreshToken: json['refreshToken'] as String?,
      scope: [
        for (final item in json['scope'] as List? ?? const []) item.toString(),
      ],
      expiresAt: DateTime.tryParse(json['expiresAt'] as String? ?? '')?.toUtc() ??
          DateTime.utc(1970),
    );
  }

  @override
  Future<void> write(EntityId profileId, SpotifyTokenSet tokens) async {
    final prefs = await _ready();
    await prefs.setString(
      _key(profileId),
      jsonEncode({
        'accessToken': tokens.accessToken,
        'refreshToken': tokens.refreshToken,
        'scope': tokens.scope,
        'expiresAt': tokens.expiresAt.toIso8601String(),
      }),
    );
  }

  @override
  Future<void> clear(EntityId profileId) async {
    final prefs = await _ready();
    await prefs.remove(_key(profileId));
  }
}

class HttpSpotifyCatalog implements SpotifyCatalogPort {
  HttpSpotifyCatalog({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  @override
  Future<SpotifyTokenSet> exchangeCode({
    required String clientId,
    required String redirectUri,
    required String code,
    required String verifier,
  }) async {
    final response = await _client.post(
      Uri.parse(MusicSpotifyPolicy.tokenUrl),
      headers: {'Content-Type': 'application/x-www-form-urlencoded'},
      body: {
        'grant_type': 'authorization_code',
        'code': code,
        'redirect_uri': redirectUri,
        'client_id': clientId,
        'code_verifier': verifier,
      },
    );
    return _parseToken(response, fallbackRefresh: null);
  }

  @override
  Future<SpotifyTokenSet> refresh({
    required String clientId,
    required SpotifyTokenSet current,
  }) async {
    final refresh = current.refreshToken;
    if (refresh == null) {
      throw StateError('Sem refresh token Spotify');
    }
    final response = await _client.post(
      Uri.parse(MusicSpotifyPolicy.tokenUrl),
      headers: {'Content-Type': 'application/x-www-form-urlencoded'},
      body: {
        'grant_type': 'refresh_token',
        'refresh_token': refresh,
        'client_id': clientId,
      },
    );
    return _parseToken(response, fallbackRefresh: refresh);
  }

  @override
  Future<List<SpotifySavedAlbum>> listSavedAlbums(SpotifyTokenSet tokens) async {
    final items = <SpotifySavedAlbum>[];
    var url = '${MusicSpotifyPolicy.apiBase}/me/albums?limit=50';
    while (url.isNotEmpty) {
      final response = await _get(url, tokens);
      if (response.statusCode == 429 ||
          response.statusCode == 403 ||
          response.statusCode == 401) {
        throw StateError('Spotify biblioteca: HTTP ${response.statusCode}');
      }
      if (response.statusCode < 200 || response.statusCode >= 300) {
        break;
      }
      final json = jsonDecode(response.body);
      if (json is! Map<String, dynamic>) break;
      final rawItems = json['items'];
      if (rawItems is List) {
        for (final item in rawItems) {
          if (item is! Map) continue;
          final album = item['album'];
          if (album is! Map) continue;
          final albumMap = _map(album);
          final id = albumMap['id']?.toString();
          final name = albumMap['name']?.toString();
          if (id == null || name == null) continue;
          items.add(
            SpotifySavedAlbum(
              spotifyId: id,
              title: name,
              artists: _artists(albumMap['artists']),
              year: _year(albumMap['release_date']?.toString()),
              externalUrl: _openUrl(albumMap),
              addedAt: DateTime.tryParse(item['added_at']?.toString() ?? ''),
            ),
          );
        }
      }
      url = json['next']?.toString() ?? '';
    }
    return items;
  }

  @override
  Future<List<SpotifyRecentlyPlayed>> listRecentlyPlayed(
    SpotifyTokenSet tokens,
  ) async {
    final response = await _get(
      '${MusicSpotifyPolicy.apiBase}/me/player/recently-played?limit=50',
      tokens,
    );
    if (response.statusCode < 200 || response.statusCode >= 300) {
      return const [];
    }
    final json = jsonDecode(response.body);
    if (json is! Map<String, dynamic>) return const [];
    final items = json['items'];
    if (items is! List) return const [];
    return [
      for (final item in items)
        if (item is Map) _recent(_map(item)),
    ].whereType<SpotifyRecentlyPlayed>().toList();
  }

  @override
  Future<List<SpotifyPlaylistSummary>> listPlaylists(
    SpotifyTokenSet tokens,
  ) async {
    final response = await _get(
      '${MusicSpotifyPolicy.apiBase}/me/playlists?limit=50',
      tokens,
    );
    if (response.statusCode < 200 || response.statusCode >= 300) {
      return const [];
    }
    final json = jsonDecode(response.body);
    if (json is! Map<String, dynamic>) return const [];
    final items = json['items'];
    if (items is! List) return const [];
    return [
      for (final item in items)
        if (item is Map)
          SpotifyPlaylistSummary(
            spotifyId: _map(item)['id']?.toString() ?? '',
            name: _map(item)['name']?.toString() ?? '',
            trackCount: (_map(item)['tracks'] is Map)
                ? (_map(_map(item)['tracks'] as Map)['total'] as num?)?.toInt() ??
                      0
                : 0,
            snapshotId: _map(item)['snapshot_id']?.toString(),
            externalUrl: _openUrl(_map(item)),
          ),
    ].where((p) => p.spotifyId.isNotEmpty).toList();
  }

  @override
  Future<List<SpotifySavedAlbum>> listPlaylistTracks(
    SpotifyTokenSet tokens,
    String playlistId,
  ) async {
    final items = <SpotifySavedAlbum>[];
    var url =
        '${MusicSpotifyPolicy.apiBase}/playlists/${Uri.encodeComponent(playlistId)}/tracks?limit=50';
    while (url.isNotEmpty) {
      final response = await _get(url, tokens);
      if (response.statusCode < 200 || response.statusCode >= 300) {
        break;
      }
      final json = jsonDecode(response.body);
      if (json is! Map<String, dynamic>) break;
      final rawItems = json['items'];
      if (rawItems is List) {
        for (final item in rawItems) {
          if (item is! Map) continue;
          final track = item['track'];
          if (track is! Map) continue;
          final trackMap = _map(track);
          final album = trackMap['album'] is Map
              ? _map(trackMap['album'] as Map)
              : null;
          final albumId = album?['id']?.toString();
          final title = album?['name']?.toString() ?? trackMap['name']?.toString();
          if (albumId == null || title == null) continue;
          items.add(
            SpotifySavedAlbum(
              spotifyId: albumId,
              title: title,
              artists: _artists(trackMap['artists']),
              year: _year(album?['release_date']?.toString()),
              externalUrl: _openUrl(album ?? trackMap),
            ),
          );
        }
      }
      url = json['next']?.toString() ?? '';
    }
    return items;
  }

  @override
  Future<SpotifyNowPlaying?> currentlyPlaying(SpotifyTokenSet tokens) async {
    final response = await _get(
      '${MusicSpotifyPolicy.apiBase}/me/player/currently-playing',
      tokens,
    );
    if (response.statusCode == 204 || response.body.isEmpty) return null;
    if (response.statusCode < 200 || response.statusCode >= 300) return null;
    final json = jsonDecode(response.body);
    if (json is! Map<String, dynamic>) return null;
    final item = json['item'];
    if (item is! Map) return null;
    final track = _map(item);
    final album = track['album'] is Map ? _map(track['album'] as Map) : null;
    return SpotifyNowPlaying(
      trackId: track['id']?.toString() ?? '',
      trackTitle: track['name']?.toString() ?? '',
      artists: _artists(track['artists']),
      albumId: album?['id']?.toString(),
      albumTitle: album?['name']?.toString(),
      externalUrl: _openUrl(track),
    );
  }

  @override
  Future<SpotifyCapabilityProbe> probe({
    required SpotifyTokenSet tokens,
    required String scope,
    required DateTime now,
  }) async {
    final path = switch (scope) {
      MusicSpotifyPolicy.libraryScope => '/me/albums?limit=1',
      MusicSpotifyPolicy.recentScope => '/me/player/recently-played?limit=1',
      MusicSpotifyPolicy.playlistScope => '/me/playlists?limit=1',
      MusicSpotifyPolicy.currentlyPlayingScope => '/me/player/currently-playing',
      _ => '/me',
    };
    final response = await _get('${MusicSpotifyPolicy.apiBase}$path', tokens);
    return SpotifyCapabilityProbe(
      scope: scope,
      httpStatus: response.statusCode,
      retryAfterSeconds: int.tryParse(response.headers['retry-after'] ?? ''),
      probedAt: now.toUtc(),
      detail: response.statusCode >= 400
          ? response.body.substring(0, min(180, response.body.length))
          : null,
    );
  }

  Future<http.Response> _get(String url, SpotifyTokenSet tokens) {
    return _client.get(
      Uri.parse(url),
      headers: {'Authorization': 'Bearer ${tokens.accessToken}'},
    );
  }

  SpotifyTokenSet _parseToken(
    http.Response response, {
    required String? fallbackRefresh,
  }) {
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw StateError('Spotify token: HTTP ${response.statusCode}');
    }
    final json = jsonDecode(response.body);
    if (json is! Map<String, dynamic>) {
      throw StateError('Spotify token inválido');
    }
    final expires = (json['expires_in'] as num?)?.toInt() ?? 3600;
    final scope = (json['scope'] as String? ?? '')
        .split(' ')
        .where((s) => s.isNotEmpty)
        .toList();
    return SpotifyTokenSet(
      accessToken: json['access_token'] as String? ?? '',
      refreshToken: json['refresh_token'] as String? ?? fallbackRefresh,
      scope: scope,
      expiresAt: DateTime.now().toUtc().add(Duration(seconds: expires - 30)),
    );
  }

  static Map<String, dynamic> _map(Map raw) => {
    for (final e in raw.entries) e.key.toString(): e.value,
  };

  static List<String> _artists(Object? raw) {
    if (raw is! List) return const [];
    return [
      for (final item in raw)
        if (item is Map && item['name'] != null) item['name'].toString(),
    ];
  }

  static int? _year(String? raw) {
    if (raw == null || raw.length < 4) return null;
    return int.tryParse(raw.substring(0, 4));
  }

  static String? _openUrl(Map<String, dynamic> map) {
    final external = map['external_urls'];
    if (external is Map && external['spotify'] != null) {
      return external['spotify'].toString();
    }
    return null;
  }

  static SpotifyRecentlyPlayed? _recent(Map<String, dynamic> item) {
    final track = item['track'];
    if (track is! Map) return null;
    final trackMap = _map(track);
    final album = trackMap['album'] is Map ? _map(trackMap['album'] as Map) : null;
    return SpotifyRecentlyPlayed(
      trackId: trackMap['id']?.toString() ?? '',
      trackTitle: trackMap['name']?.toString() ?? '',
      artists: _artists(trackMap['artists']),
      albumId: album?['id']?.toString(),
      albumTitle: album?['name']?.toString(),
      playedAt:
          DateTime.tryParse(item['played_at']?.toString() ?? '')?.toUtc() ??
          DateTime.now().toUtc(),
    );
  }
}

SpotifyPkceChallenge completePkce(SpotifyPkceChallenge seed) {
  final digest = sha256.convert(utf8.encode(seed.verifier));
  return SpotifyPkceChallenge(
    verifier: seed.verifier,
    challenge: base64UrlEncode(digest.bytes).replaceAll('=', ''),
    state: seed.state,
  );
}

final spotifyCatalogPortProvider = Provider<SpotifyCatalogPort>((ref) {
  return HttpSpotifyCatalog();
});

final spotifyTokenStoreProvider = Provider<SpotifyTokenStore>((ref) {
  return PrefsSpotifyTokenStore();
});

/// Deterministic catalog for widget and repository tests — never hits the network.
class FakeSpotifyCatalog implements SpotifyCatalogPort {
  FakeSpotifyCatalog({
    this.albums = const [],
    this.recent = const [],
    this.playlists = const [],
    this.playlistTracks = const {},
    this.nowPlaying,
    this.probeStatus = 200,
  });

  final List<SpotifySavedAlbum> albums;
  final List<SpotifyRecentlyPlayed> recent;
  final List<SpotifyPlaylistSummary> playlists;
  final Map<String, List<SpotifySavedAlbum>> playlistTracks;
  final SpotifyNowPlaying? nowPlaying;
  final int probeStatus;

  @override
  Future<SpotifyTokenSet> exchangeCode({
    required String clientId,
    required String redirectUri,
    required String code,
    required String verifier,
  }) async {
    return SpotifyTokenSet(
      accessToken: 'fake-access',
      refreshToken: 'fake-refresh',
      scope: MusicSpotifyPolicy.incrementalScopes,
      expiresAt: DateTime.now().toUtc().add(const Duration(hours: 1)),
    );
  }

  @override
  Future<SpotifyTokenSet> refresh({
    required String clientId,
    required SpotifyTokenSet current,
  }) async {
    return SpotifyTokenSet(
      accessToken: 'fake-access-refreshed',
      refreshToken: current.refreshToken,
      scope: current.scope,
      expiresAt: DateTime.now().toUtc().add(const Duration(hours: 1)),
    );
  }

  @override
  Future<List<SpotifySavedAlbum>> listSavedAlbums(SpotifyTokenSet tokens) async =>
      albums;

  @override
  Future<List<SpotifyRecentlyPlayed>> listRecentlyPlayed(
    SpotifyTokenSet tokens,
  ) async => recent;

  @override
  Future<List<SpotifyPlaylistSummary>> listPlaylists(
    SpotifyTokenSet tokens,
  ) async => playlists;

  @override
  Future<List<SpotifySavedAlbum>> listPlaylistTracks(
    SpotifyTokenSet tokens,
    String playlistId,
  ) async => playlistTracks[playlistId] ?? const [];

  @override
  Future<SpotifyNowPlaying?> currentlyPlaying(SpotifyTokenSet tokens) async =>
      nowPlaying;

  @override
  Future<SpotifyCapabilityProbe> probe({
    required SpotifyTokenSet tokens,
    required String scope,
    required DateTime now,
  }) async {
    return SpotifyCapabilityProbe(
      scope: scope,
      httpStatus: probeStatus,
      probedAt: now.toUtc(),
    );
  }
}

class SpotifyClientIdNotifier extends Notifier<String> {
  @override
  String build() => '';

  void set(String value) => state = value;
}

final spotifyClientIdProvider =
    NotifierProvider<SpotifyClientIdNotifier, String>(
      SpotifyClientIdNotifier.new,
    );
