import 'package:colony_domain/colony_domain.dart';
import 'package:test/test.dart';

void main() {
  test('extended history JSON rolls albums and drops podcasts and skips', () {
    const source = '''
[
  {
    "ts": "2024-01-01T12:00:00Z",
    "ms_played": 180000,
    "master_metadata_track_name": "So What",
    "master_metadata_album_artist_name": "Miles Davis",
    "master_metadata_album_album_name": "Kind of Blue",
    "spotify_track_uri": "spotify:track:aaa",
    "reason_end": "trackdone"
  },
  {
    "ts": "2024-01-02T12:00:00Z",
    "ms_played": 90000,
    "master_metadata_track_name": "Freddie Freeloader",
    "master_metadata_album_artist_name": "Miles Davis",
    "master_metadata_album_album_name": "Kind of Blue",
    "reason_end": "fwdbtn"
  },
  {
    "ts": "2024-01-03T12:00:00Z",
    "ms_played": 4000,
    "master_metadata_track_name": "Skip",
    "master_metadata_album_artist_name": "Miles Davis",
    "master_metadata_album_album_name": "Kind of Blue",
    "skipped": true,
    "reason_end": "fwdbtn"
  },
  {
    "ts": "2024-01-04T12:00:00Z",
    "ms_played": 45000,
    "master_metadata_track_name": "Local file",
    "master_metadata_album_artist_name": "Miles Davis",
    "master_metadata_album_album_name": "Kind of Blue",
    "spotify_track_uri": "spotify:local:Miles:Kind:Local:180",
    "reason_end": "trackdone"
  },
  {
    "ts": "2024-01-05T12:00:00Z",
    "ms_played": 80000,
    "master_metadata_track_name": "Skipped late",
    "master_metadata_album_artist_name": "Miles Davis",
    "master_metadata_album_album_name": "Kind of Blue",
    "skipped": true,
    "reason_end": "fwdbtn"
  },
  {
    "ts": "2024-02-01T08:00:00Z",
    "ms_played": 60000,
    "episode_name": "Interview",
    "episode_show_name": "Jazz Talk",
    "spotify_episode_uri": "spotify:episode:zzz"
  }
]
''';
    final result = SpotifyStreamingHistoryCodec.parseJson(
      source,
      fileName: 'Streaming_History_Audio_2024_0.json',
    );
    expect(result.albums, hasLength(1));
    expect(result.albums.single.albumTitle, 'Kind of Blue');
    expect(result.albums.single.artist, 'Miles Davis');
    expect(result.albums.single.playCount, 2);
    expect(result.podcastCount, 1);
    expect(result.shortCount, 3);
    expect(result.albums.single.durationSeconds, 270);
  });

  test('legacy StreamingHistory.json still parses', () {
    const source = '''
[
  {
    "endTime": "2019-05-01 10:00",
    "artistName": "Joy Division",
    "trackName": "Disorder",
    "msPlayed": 220000,
    "albumName": "Unknown Pleasures"
  }
]
''';
    final result = SpotifyStreamingHistoryCodec.parseJson(
      source,
      fileName: 'StreamingHistory0.json',
    );
    expect(result.albums.single.albumTitle, 'Unknown Pleasures');
    expect(result.albums.single.artist, 'Joy Division');
  });

  test('history file names match the dump Spotify actually sends', () {
    expect(
      SpotifyStreamingHistoryPolicy.isHistoryFileName(
        'MyData/Streaming_History_Audio_2018-2019_3.json',
      ),
      isTrue,
    );
    expect(
      SpotifyStreamingHistoryPolicy.isHistoryFileName('StreamingHistory1.json'),
      isTrue,
    );
    expect(
      SpotifyStreamingHistoryPolicy.isHistoryFileName('YourLibrary.json'),
      isFalse,
    );
  });

  test('imported listen with duration counts as heard on the map', () {
    final now = DateTime.utc(2026, 8, 23);
    final encounter = MusicEncounter.record(
      id: const EntityId('e'),
      profileId: const EntityId('p'),
      nodeId: const EntityId('n'),
      encounterType: MusicEncounterType.importListen,
      occurredAt: now,
      now: now,
      sourceType: SourceType.import,
      durationSeconds: 400,
    );
    expect(
      MusicListenPolicy.of([encounter]),
      MusicListenDepth.heard,
    );
    expect(
      MusicListenPolicy.of([
        MusicEncounter.record(
          id: const EntityId('e2'),
          profileId: const EntityId('p'),
          nodeId: const EntityId('n'),
          encounterType: MusicEncounterType.importListen,
          occurredAt: now,
          now: now,
          sourceType: SourceType.import,
          durationSeconds: 5,
        ),
      ]),
      MusicListenDepth.contact,
    );
  });

  test('callback URI is the one the dashboard must register', () {
    expect(
      MusicSpotifyPolicy.isCallbackUri(
        Uri.parse('colony://integrations/spotify/callback?code=x'),
      ),
      isTrue,
    );
    expect(
      MusicSpotifyPolicy.isCallbackUri(Uri.parse('https://open.spotify.com')),
      isFalse,
    );
  });
}
