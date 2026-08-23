import 'dart:convert';

import 'package:equatable/equatable.dart';

import 'music_atlas.dart';

/// One play event from a Spotify privacy dump (extended or account-data).
class SpotifyHistoryStream extends Equatable {
  const SpotifyHistoryStream({
    required this.endedAt,
    required this.msPlayed,
    this.trackName,
    this.artistName,
    this.albumName,
    this.spotifyTrackUri,
    this.skipped = false,
    this.podcast = false,
    this.reasonEnd,
  });

  final DateTime endedAt;
  final int msPlayed;
  final String? trackName;
  final String? artistName;
  final String? albumName;
  final String? spotifyTrackUri;
  final bool skipped;
  final bool podcast;
  final String? reasonEnd;

  bool get completed => reasonEnd == 'trackdone';

  @override
  List<Object?> get props => [
    endedAt,
    msPlayed,
    trackName,
    artistName,
    albumName,
    spotifyTrackUri,
    skipped,
    podcast,
    reasonEnd,
  ];
}

class SpotifyHistoryAlbumRollup extends Equatable {
  const SpotifyHistoryAlbumRollup({
    required this.albumTitle,
    required this.artist,
    required this.playCount,
    required this.totalMs,
    required this.firstPlayed,
    required this.lastPlayed,
    this.spotifyTrackUri,
  });

  final String albumTitle;
  final String artist;
  final int playCount;
  final int totalMs;
  final DateTime firstPlayed;
  final DateTime lastPlayed;
  final String? spotifyTrackUri;

  int get durationSeconds => (totalMs / 1000).round();

  @override
  List<Object?> get props => [
    albumTitle,
    artist,
    playCount,
    totalMs,
    firstPlayed,
    lastPlayed,
    spotifyTrackUri,
  ];
}

class SpotifyHistoryParseResult extends Equatable {
  const SpotifyHistoryParseResult({
    required this.streams,
    required this.albums,
    this.podcastCount = 0,
    this.shortCount = 0,
    this.namelessCount = 0,
    this.files = const [],
  });

  final List<SpotifyHistoryStream> streams;
  final List<SpotifyHistoryAlbumRollup> albums;
  final int podcastCount;
  final int shortCount;
  final int namelessCount;
  final List<String> files;

  int get streamCount => streams.length;

  @override
  List<Object?> get props => [
    streams,
    albums,
    podcastCount,
    shortCount,
    namelessCount,
    files,
  ];
}

class SpotifyHistoryParseException implements Exception {
  SpotifyHistoryParseException(this.message);
  final String message;

  @override
  String toString() => message;
}

/// GDPR / privacy-page dump — never a substitute for attentive knowledge.
abstract final class SpotifyStreamingHistoryPolicy {
  static const minHeardMs = 30000;
  static const privacyUrl = 'https://www.spotify.com/account/privacy/';
  static const developerDashboardUrl =
      'https://developer.spotify.com/dashboard';

  static bool isHistoryFileName(String name) {
    final lower = name.replaceAll('\\', '/').split('/').last.toLowerCase();
    if (!lower.endsWith('.json')) return false;
    return lower.startsWith('streaming_history') ||
        lower.startsWith('streaminghistory') ||
        lower.startsWith('endsong') ||
        lower.contains('streaming_history_audio') ||
        lower.contains('streaming_history_video');
  }

  static bool countsAsListen(SpotifyHistoryStream stream) {
    if (stream.podcast) return false;
    if (stream.skipped) return false;
    final uri = stream.spotifyTrackUri ?? '';
    if (uri.startsWith('spotify:local')) return false;
    if ((stream.albumName ?? '').trim().isEmpty) return false;
    if ((stream.artistName ?? '').trim().isEmpty) return false;
    if (stream.msPlayed >= minHeardMs) return true;
    if (stream.completed && stream.msPlayed > 0) return true;
    return false;
  }
}

abstract final class SpotifyStreamingHistoryCodec {
  static SpotifyHistoryParseResult parseJson(
    String source, {
    String fileName = 'history.json',
  }) {
    final decoded = jsonDecode(source);
    if (decoded is! List) {
      throw SpotifyHistoryParseException(
        'O ficheiro $fileName não é uma lista de escutas Spotify.',
      );
    }
    final streams = <SpotifyHistoryStream>[];
    for (final item in decoded) {
      if (item is! Map) continue;
      final stream = _parseItem(Map<String, dynamic>.from(item));
      if (stream != null) streams.add(stream);
    }
    return rollup(streams, files: [fileName]);
  }

  static SpotifyHistoryParseResult parseMany(
    Iterable<(String name, String source)> documents,
  ) {
    final streams = <SpotifyHistoryStream>[];
    final files = <String>[];
    for (final doc in documents) {
      if (!SpotifyStreamingHistoryPolicy.isHistoryFileName(doc.$1) &&
          documents.length > 1) {
        continue;
      }
      final decoded = jsonDecode(doc.$2);
      if (decoded is! List) continue;
      files.add(doc.$1);
      for (final item in decoded) {
        if (item is! Map) continue;
        final stream = _parseItem(Map<String, dynamic>.from(item));
        if (stream != null) streams.add(stream);
      }
    }
    if (files.isEmpty && streams.isEmpty) {
      throw SpotifyHistoryParseException(
        'Não encontrei Streaming_History_Audio_*.json nem StreamingHistory*.json.',
      );
    }
    return rollup(streams, files: files);
  }

  static SpotifyHistoryParseResult rollup(
    List<SpotifyHistoryStream> streams, {
    List<String> files = const [],
  }) {
    var podcasts = 0;
    var shorts = 0;
    var nameless = 0;
    final buckets = <String, _Bucket>{};
    for (final stream in streams) {
      if (stream.podcast) {
        podcasts++;
        continue;
      }
      final album = stream.albumName?.trim() ?? '';
      final artist = stream.artistName?.trim() ?? '';
      if (album.isEmpty || artist.isEmpty) {
        nameless++;
        continue;
      }
      if (!SpotifyStreamingHistoryPolicy.countsAsListen(stream)) {
        shorts++;
        continue;
      }
      final key =
          '${MusicIdentityPolicy.normalizeTitle(album)}|${MusicIdentityPolicy.normalizeArtist(artist)}';
      final current = buckets[key];
      if (current == null) {
        buckets[key] = _Bucket(
          albumTitle: album,
          artist: artist,
          playCount: 1,
          totalMs: stream.msPlayed,
          firstPlayed: stream.endedAt,
          lastPlayed: stream.endedAt,
          spotifyTrackUri: stream.spotifyTrackUri,
        );
      } else {
        current.playCount++;
        current.totalMs += stream.msPlayed;
        if (stream.endedAt.isBefore(current.firstPlayed)) {
          current.firstPlayed = stream.endedAt;
        }
        if (stream.endedAt.isAfter(current.lastPlayed)) {
          current.lastPlayed = stream.endedAt;
        }
        current.spotifyTrackUri ??= stream.spotifyTrackUri;
      }
    }
    final albums = [
      for (final bucket in buckets.values)
        SpotifyHistoryAlbumRollup(
          albumTitle: bucket.albumTitle,
          artist: bucket.artist,
          playCount: bucket.playCount,
          totalMs: bucket.totalMs,
          firstPlayed: bucket.firstPlayed,
          lastPlayed: bucket.lastPlayed,
          spotifyTrackUri: bucket.spotifyTrackUri,
        ),
    ]..sort((a, b) => b.playCount.compareTo(a.playCount));
    return SpotifyHistoryParseResult(
      streams: streams,
      albums: albums,
      podcastCount: podcasts,
      shortCount: shorts,
      namelessCount: nameless,
      files: files,
    );
  }

  static SpotifyHistoryStream? _parseItem(Map<String, dynamic> map) {
    final podcast =
        (map['episode_name'] != null &&
            map['episode_name'].toString().trim().isNotEmpty) ||
        (map['spotify_episode_uri'] != null &&
            map['spotify_episode_uri'].toString().trim().isNotEmpty);
    final ended =
        DateTime.tryParse(map['ts']?.toString() ?? '') ??
        DateTime.tryParse(
          (map['endTime'] ?? map['end_time'])?.toString() ?? '',
        );
    if (ended == null) return null;
    final ms =
        _asInt(map['ms_played']) ??
        _asInt(map['msPlayed']) ??
        _asInt(map['msplayed']) ??
        0;
    final album =
        _str(map['master_metadata_album_album_name']) ??
        _str(map['albumName']) ??
        _str(map['album']);
    final artist =
        _str(map['master_metadata_album_artist_name']) ??
        _str(map['artistName']) ??
        _str(map['artist']);
    final track =
        _str(map['master_metadata_track_name']) ??
        _str(map['trackName']) ??
        _str(map['track']);
    return SpotifyHistoryStream(
      endedAt: ended.toUtc(),
      msPlayed: ms,
      trackName: track,
      artistName: artist,
      albumName: album,
      spotifyTrackUri: _str(map['spotify_track_uri']),
      skipped: map['skipped'] == true,
      podcast: podcast,
      reasonEnd: _str(map['reason_end']),
    );
  }

  static String? _str(Object? value) {
    if (value == null) return null;
    final text = value.toString().trim();
    return text.isEmpty ? null : text;
  }

  static int? _asInt(Object? value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '');
  }
}

class _Bucket {
  _Bucket({
    required this.albumTitle,
    required this.artist,
    required this.playCount,
    required this.totalMs,
    required this.firstPlayed,
    required this.lastPlayed,
    this.spotifyTrackUri,
  });

  final String albumTitle;
  final String artist;
  int playCount;
  int totalMs;
  DateTime firstPlayed;
  DateTime lastPlayed;
  String? spotifyTrackUri;
}
