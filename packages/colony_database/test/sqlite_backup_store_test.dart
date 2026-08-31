import 'dart:io';
import 'dart:typed_data';

import 'package:colony_database/colony_database.dart';
import 'package:colony_domain/colony_domain.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

import 'migration_fixtures.dart';

void main() {
  test('in-memory database cannot export a sqlite snapshot', () async {
    final db = ColonyDatabase.inMemory();
    addTearDown(db.close);
    expect(
      () => SqliteBackupStore.export(db),
      throwsA(isA<ColonySqliteBackupException>()),
    );
  });

  test(
    'export install reopen keeps profile, cards and timeline sidecar',
    () async {
      final dir = Directory.systemTemp.createTempSync('colony-bk-');
      addTearDown(() {
        if (dir.existsSync()) dir.deleteSync(recursive: true);
      });

      final file = File(p.join(dir.path, ColonyDatabase.defaultFileName));
      var db = ColonyDatabase(NativeDatabase(file), dataDirectory: dir.path);
      await db.customSelect('SELECT 1').get();

      final repos = ColonyRepositories.create(
        db,
        idGenerator: FixedIdGenerator([for (var i = 1; i <= 40; i++) 'id-$i']),
        clock: () => DateTime.utc(2026, 8, 31, 12),
      );
      final profile = await repos.profiles.create(
        colonyName: 'Backup',
        displayName: 'Caio',
        timezone: 'UTC',
        locale: 'pt_BR',
        baseCurrency: 'BRL',
      );
      final deck = await repos.flashcards.createDeck(
        profileId: profile.id,
        title: 'Deck',
      );
      await repos.flashcards.createCard(
        profileId: profile.id,
        deckId: deck.id,
        front: 'Q',
        back: 'A',
      );
      final sidecarName = 'google_timeline_${profile.id.value}.json';
      await File(p.join(dir.path, sidecarName)).writeAsString('{"visits":[1]}');

      final bytes = await SqliteBackupStore.export(db);
      expect(ColonySqliteBackupCodec.looksLikeContainer(bytes), isTrue);
      final preview = await SqliteBackupStore.inspect(
        bytes,
        appSchemaVersion: ColonyDatabase.currentSchemaVersion,
      );
      expect(
        preview.manifest.schemaVersion,
        ColonyDatabase.currentSchemaVersion,
      );
      expect(preview.sidecars.containsKey(sidecarName), isTrue);
      await db.close();

      await file.delete();
      await File(p.join(dir.path, sidecarName)).delete();
      await File(
        p.join(dir.path, 'google_timeline_stale.json'),
      ).writeAsString('{"stale":true}');

      await SqliteBackupStore.install(
        directory: dir.path,
        bytes: bytes,
        appSchemaVersion: ColonyDatabase.currentSchemaVersion,
      );
      expect(
        File(p.join(dir.path, 'google_timeline_stale.json')).existsSync(),
        isFalse,
      );
      expect(
        File(p.join(dir.path, sidecarName)).readAsStringSync(),
        '{"visits":[1]}',
      );

      db = await ColonyDatabase.openInDirectory(dir.path);
      addTearDown(db.close);
      final restored = ColonyRepositories.create(
        db,
        idGenerator: FixedIdGenerator(['x']),
        clock: () => DateTime.utc(2026, 8, 31, 13),
      );
      expect((await restored.profiles.getActive())!.displayName, 'Caio');
      expect(await restored.flashcards.listCards(profile.id), hasLength(1));
    },
  );

  test('restoreReplacing rolls live writes back to the snapshot', () async {
    final dir = Directory.systemTemp.createTempSync('colony-bk-swap-');
    addTearDown(() {
      if (dir.existsSync()) dir.deleteSync(recursive: true);
    });
    final file = File(p.join(dir.path, ColonyDatabase.defaultFileName));
    var db = ColonyDatabase(NativeDatabase(file), dataDirectory: dir.path);
    await db.customSelect('SELECT 1').get();
    final repos = ColonyRepositories.create(
      db,
      idGenerator: FixedIdGenerator([for (var i = 1; i <= 40; i++) 'swap-$i']),
      clock: () => DateTime.utc(2026, 8, 31, 12),
    );
    final profile = await repos.profiles.create(
      colonyName: 'Backup',
      displayName: 'Caio',
      timezone: 'UTC',
      locale: 'pt_BR',
      baseCurrency: 'BRL',
    );
    final bytes = await SqliteBackupStore.export(db);
    await repos.tasks.capture(profileId: profile.id, title: 'depois do backup');
    expect(await repos.tasks.listAll(profile.id), hasLength(1));

    db = await SqliteBackupStore.restoreReplacing(
      current: db,
      bytes: bytes,
      appSchemaVersion: ColonyDatabase.currentSchemaVersion,
    );
    addTearDown(db.close);
    final restored = ColonyRepositories.create(
      db,
      idGenerator: FixedIdGenerator(['z']),
      clock: () => DateTime.utc(2026, 8, 31, 13),
    );
    expect(await restored.tasks.listAll(profile.id), isEmpty);
  });

  test('older sqlite snapshot migrates on open (update-proof)', () async {
    final oldFile = writeUnmigratedFixture(3, seed: seedProfile);
    addTearDown(() {
      if (oldFile.existsSync()) oldFile.deleteSync();
    });
    final encoded = ColonySqliteBackupCodec.encode(
      ColonySqliteBackup(
        manifest: ColonySqliteBackupManifest(
          schemaVersion: 3,
          exportedAt: DateTime.utc(2026, 8, 1),
        ),
        sqlite: Uint8List.fromList(await oldFile.readAsBytes()),
      ),
    );

    final dest = Directory.systemTemp.createTempSync('colony-bk-old-');
    addTearDown(() {
      if (dest.existsSync()) dest.deleteSync(recursive: true);
    });
    await SqliteBackupStore.install(
      directory: dest.path,
      bytes: encoded,
      appSchemaVersion: ColonyDatabase.currentSchemaVersion,
    );
    final db = await ColonyDatabase.openInDirectory(dest.path);
    addTearDown(db.close);
    final version = await db.customSelect('PRAGMA user_version').getSingle();
    expect(version.data.values.single, ColonyDatabase.currentSchemaVersion);
    final repos = ColonyRepositories.create(
      db,
      idGenerator: FixedIdGenerator(['x']),
      clock: () => DateTime.utc(2026, 8, 31, 12),
    );
    expect((await repos.profiles.getActive())!.displayName, 'Caio');
  });

  test('schema newer than the app is rejected without writing', () async {
    final tooNew = ColonySqliteBackupCodec.encode(
      ColonySqliteBackup(
        manifest: ColonySqliteBackupManifest(
          schemaVersion: ColonyDatabase.currentSchemaVersion + 8,
          exportedAt: DateTime.utc(2026, 8, 31),
        ),
        sqlite: Uint8List.fromList(
          List<int>.filled(200, 0)
            ..setRange(0, 15, 'SQLite format 3'.codeUnits),
        ),
      ),
    );
    expect(
      () => SqliteBackupStore.inspect(
        tooNew,
        appSchemaVersion: ColonyDatabase.currentSchemaVersion,
      ),
      throwsA(isA<ColonySqliteBackupTooNewException>()),
    );
  });
}
