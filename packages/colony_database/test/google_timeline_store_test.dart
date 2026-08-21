import 'dart:convert';
import 'dart:io';

import 'package:colony_database/colony_database.dart';
import 'package:colony_domain/colony_domain.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

void main() {
  test('timeline import stores sidecar file and hydrates it', () async {
    final dir = Directory.systemTemp.createTempSync('colony-tl-');
    addTearDown(() async {
      if (dir.existsSync()) await dir.delete(recursive: true);
    });

    final db = ColonyDatabase(NativeDatabase.memory(), dataDirectory: dir.path);
    addTearDown(db.close);

    final repos = ColonyRepositories.create(
      db,
      idGenerator: FixedIdGenerator(['profile-1', 'tl-1', 'event-1']),
      clock: () => DateTime.utc(2026, 8, 21, 12),
    );
    final profile = await repos.profiles.create(
      colonyName: 'Test',
      displayName: 'Caio',
      timezone: 'UTC',
      locale: 'pt_BR',
      baseCurrency: 'BRL',
    );

    final imported = await repos.googleTimeline.replaceImport(
      profileId: profile.id,
      fileName: 'Linha do tempo.json',
      document: GoogleTimelineDocument(
        visits: [
          TimelineVisit(
            startAt: DateTime.utc(2026, 8, 1, 12),
            endAt: DateTime.utc(2026, 8, 1, 14),
            placeId: 'ChIJ_KEEP',
            location: const GeoPoint(-19.9167, -43.9345),
          ),
        ],
      ),
    );

    expect(imported.fileName, 'Linha do tempo.json');
    expect(imported.document.visits, hasLength(1));

    final row = await db
        .customSelect('SELECT payload_json FROM google_timeline_imports')
        .getSingle();
    final stored = jsonDecode(row.read<String>('payload_json'));
    expect(stored, isA<Map>());
    expect(
      (stored as Map)[ColonyMappers.googleTimelineExternalFileKey],
      'google_timeline_${profile.id.value}.json',
    );
    expect(stored.containsKey('visits'), isFalse);

    final sidecar = File(
      p.join(dir.path, 'google_timeline_${profile.id.value}.json'),
    );
    expect(sidecar.existsSync(), isTrue);
    final sidecarJson = jsonDecode(sidecar.readAsStringSync()) as Map;
    expect((sidecarJson['visits'] as List), hasLength(1));

    final loaded = await repos.googleTimeline.getForProfile(profile.id);
    expect(loaded!.document.visits, hasLength(1));
    expect(loaded.document.visits.single.placeId, 'ChIJ_KEEP');

    final watched = await repos.googleTimeline.watchImport(profile.id).first;
    expect(watched!.document.visits.single.placeId, 'ChIJ_KEEP');
  });

  test('in-memory timeline import still stores inline JSON', () async {
    final db = ColonyDatabase.inMemory();
    addTearDown(db.close);
    final repos = ColonyRepositories.create(
      db,
      idGenerator: FixedIdGenerator(['profile-1', 'tl-1', 'event-1']),
      clock: () => DateTime.utc(2026, 8, 21, 12),
    );
    final profile = await repos.profiles.create(
      colonyName: 'Test',
      displayName: 'Caio',
      timezone: 'UTC',
      locale: 'pt_BR',
      baseCurrency: 'BRL',
    );
    await repos.googleTimeline.replaceImport(
      profileId: profile.id,
      fileName: 'Timeline.json',
      document: GoogleTimelineDocument(
        visits: [
          TimelineVisit(
            startAt: DateTime.utc(2026, 8, 2, 9),
            endAt: DateTime.utc(2026, 8, 2, 10),
            placeId: 'ChIJ_INLINE',
          ),
        ],
      ),
    );
    final row = await db
        .customSelect('SELECT payload_json FROM google_timeline_imports')
        .getSingle();
    final stored = jsonDecode(row.read<String>('payload_json')) as Map;
    expect(stored[ColonyMappers.googleTimelineExternalFileKey], isNull);
    expect((stored['visits'] as List), hasLength(1));
  });
}
