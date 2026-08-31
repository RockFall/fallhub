import 'dart:io';
import 'dart:typed_data';

import 'package:colony_domain/colony_domain.dart';
import 'package:path/path.dart' as p;

import 'colony_database.dart';

/// Restore closed the live connection, wrote a bad file, then reopened the
/// previous copy. [recovered] is the database the UI must adopt.
class ColonySqliteRestoreFailedException implements Exception {
  const ColonySqliteRestoreFailedException({
    required this.recovered,
    required this.cause,
  });

  final ColonyDatabase recovered;
  final Object cause;

  @override
  String toString() => 'Falha ao restaurar o backup: $cause';
}

/// File-backed SQLite snapshot (ADR-051). Uses `VACUUM INTO` so the live
/// connection can keep running while a consistent copy is made.
abstract final class SqliteBackupStore {
  static Future<Uint8List> export(ColonyDatabase db) async {
    final dir = db.dataDirectory;
    if (dir == null) {
      throw const ColonySqliteBackupException(
        'Backup SQLite exige banco em arquivo',
      );
    }
    final stamp = DateTime.now().toUtc().microsecondsSinceEpoch;
    final tmp = File(p.join(dir, 'colony_vacuum_$stamp.db'));
    if (tmp.existsSync()) await tmp.delete();
    try {
      await _vacuumInto(db, tmp.path);
    } catch (_) {
      await db.customStatement('PRAGMA wal_checkpoint(TRUNCATE)');
      final live = File(p.join(dir, ColonyDatabase.defaultFileName));
      if (!live.existsSync()) {
        throw const ColonySqliteBackupException(
          'Não foi possível copiar o banco local',
        );
      }
      await live.copy(tmp.path);
    }
    final sqlite = Uint8List.fromList(await tmp.readAsBytes());
    try {
      await tmp.delete();
    } on FileSystemException {
      // Temp leftovers are ok.
    }
    if (sqlite.isEmpty) {
      throw const ColonySqliteBackupException('Backup SQLite vazio');
    }
    return ColonySqliteBackupCodec.encode(
      ColonySqliteBackup(
        manifest: ColonySqliteBackupManifest(
          schemaVersion: db.schemaVersion,
          exportedAt: DateTime.now().toUtc(),
          dbFileName: ColonyDatabase.defaultFileName,
        ),
        sqlite: sqlite,
        sidecars: await _collectSidecars(dir),
      ),
    );
  }

  static Future<ColonySqliteBackup> inspect(
    Uint8List bytes, {
    required int appSchemaVersion,
  }) async {
    final backup = ColonySqliteBackupCodec.decode(bytes);
    ColonySqliteBackupCodec.assertRestorable(
      backupSchemaVersion: backup.manifest.schemaVersion,
      appSchemaVersion: appSchemaVersion,
    );
    return backup;
  }

  static Future<void> install({
    required String directory,
    required Uint8List bytes,
    required int appSchemaVersion,
    String fileName = ColonyDatabase.defaultFileName,
  }) async {
    final backup = await inspect(bytes, appSchemaVersion: appSchemaVersion);
    final dbPath = p.join(directory, fileName);
    await Directory(directory).create(recursive: true);
    await _deleteSqliteExtras(dbPath);
    await File(dbPath).writeAsBytes(backup.sqlite, flush: true);
    await _replaceSidecars(directory, backup.sidecars);
  }

  /// Closes [current], installs [bytes], and opens the restored file.
  ///
  /// Invalid / too-new files throw before closing. If install or reopen fails,
  /// the previous file is rolled back and
  /// [ColonySqliteRestoreFailedException.recovered] must be adopted.
  static Future<ColonyDatabase> restoreReplacing({
    required ColonyDatabase current,
    required Uint8List bytes,
    required int appSchemaVersion,
    String fileName = ColonyDatabase.defaultFileName,
  }) async {
    final dir = current.dataDirectory;
    if (dir == null) {
      throw const ColonySqliteBackupException(
        'Backup SQLite exige banco em arquivo',
      );
    }
    await inspect(bytes, appSchemaVersion: appSchemaVersion);

    final dbPath = p.join(dir, fileName);
    final bakPath = '$dbPath.bak';
    try {
      await current.customStatement('PRAGMA wal_checkpoint(TRUNCATE)');
    } catch (_) {
      // Best-effort; copy still captures the main db file.
    }
    await current.close();

    final live = File(dbPath);
    if (live.existsSync()) {
      await live.copy(bakPath);
    }

    try {
      await install(
        directory: dir,
        bytes: bytes,
        appSchemaVersion: appSchemaVersion,
        fileName: fileName,
      );
      final next = await ColonyDatabase.openInDirectory(
        dir,
        fileName: fileName,
      );
      await _tryDelete(File(bakPath));
      return next;
    } catch (error, stack) {
      await _rollback(dbPath: dbPath, bakPath: bakPath);
      final recovered = await ColonyDatabase.openInDirectory(
        dir,
        fileName: fileName,
      );
      Error.throwWithStackTrace(
        ColonySqliteRestoreFailedException(recovered: recovered, cause: error),
        stack,
      );
    }
  }

  static Future<void> _vacuumInto(ColonyDatabase db, String destPath) async {
    final escaped = destPath.replaceAll("'", "''");
    await db.customStatement("VACUUM INTO '$escaped'");
  }

  static Future<Map<String, Uint8List>> _collectSidecars(
    String directory,
  ) async {
    final dir = Directory(directory);
    if (!dir.existsSync()) return const {};
    final out = <String, Uint8List>{};
    await for (final entity in dir.list()) {
      if (entity is! File) continue;
      final name = p.basename(entity.path);
      if (!name.startsWith('google_timeline_') || !name.endsWith('.json')) {
        continue;
      }
      out[name] = Uint8List.fromList(await entity.readAsBytes());
    }
    return out;
  }

  static Future<void> _replaceSidecars(
    String directory,
    Map<String, Uint8List> sidecars,
  ) async {
    final dir = Directory(directory);
    if (dir.existsSync()) {
      await for (final entity in dir.list()) {
        if (entity is! File) continue;
        final name = p.basename(entity.path);
        if (name.startsWith('google_timeline_') && name.endsWith('.json')) {
          await _tryDelete(entity);
        }
      }
    }
    for (final entry in sidecars.entries) {
      final dest = File(p.join(directory, entry.key));
      await dest.writeAsBytes(entry.value, flush: true);
    }
  }

  static Future<void> _rollback({
    required String dbPath,
    required String bakPath,
  }) async {
    await _deleteSqliteExtras(dbPath);
    final live = File(dbPath);
    final bak = File(bakPath);
    if (live.existsSync()) {
      await _tryDelete(live);
    }
    if (bak.existsSync()) {
      await bak.copy(dbPath);
    }
  }

  static Future<void> _deleteSqliteExtras(String dbPath) async {
    for (final suffix in const ['-wal', '-shm', '-journal']) {
      await _tryDelete(File('$dbPath$suffix'));
    }
  }

  static Future<void> _tryDelete(File file) async {
    if (!file.existsSync()) return;
    try {
      await file.delete();
    } on FileSystemException {
      // Best-effort.
    }
  }
}
