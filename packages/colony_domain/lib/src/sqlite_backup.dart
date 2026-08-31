import 'dart:convert';
import 'dart:typed_data';

/// Kind of a picked backup file. Sniff SQLite before JSON so a `.colonybk`
/// is never parsed as text.
enum ColonyBackupKind { sqliteContainer, sqliteRaw, json, unknown }

class ColonySqliteBackupTooNewException implements Exception {
  const ColonySqliteBackupTooNewException({
    required this.backupSchemaVersion,
    required this.appSchemaVersion,
  });

  final int backupSchemaVersion;
  final int appSchemaVersion;

  @override
  String toString() =>
      'Backup schema v$backupSchemaVersion is newer than this app (v$appSchemaVersion).';
}

class ColonySqliteBackupException implements Exception {
  const ColonySqliteBackupException(this.message);
  final String message;

  @override
  String toString() => message;
}

class ColonySqliteBackupManifest {
  const ColonySqliteBackupManifest({
    required this.schemaVersion,
    required this.exportedAt,
    this.dbFileName = 'colony.db',
  });

  final int schemaVersion;
  final DateTime exportedAt;
  final String dbFileName;

  Map<String, Object?> toJson() => {
    'schemaVersion': schemaVersion,
    'exportedAt': exportedAt.toUtc().toIso8601String(),
    'dbFileName': dbFileName,
  };

  factory ColonySqliteBackupManifest.fromJson(Map<dynamic, dynamic> json) {
    final version = json['schemaVersion'];
    if (version is! int || version < 1) {
      throw const ColonySqliteBackupException('Manifest sem schemaVersion');
    }
    final rawAt = json['exportedAt']?.toString();
    final exportedAt =
        DateTime.tryParse(rawAt ?? '')?.toUtc() ?? DateTime.now().toUtc();
    final name = json['dbFileName']?.toString().trim();
    return ColonySqliteBackupManifest(
      schemaVersion: version,
      exportedAt: exportedAt,
      dbFileName: (name == null || name.isEmpty) ? 'colony.db' : name,
    );
  }
}

/// Full SQLite snapshot plus optional sidecars (ADR-051). Newer apps open the
/// file and run Drift `onUpgrade` when `user_version` is older.
class ColonySqliteBackup {
  const ColonySqliteBackup({
    required this.manifest,
    required this.sqlite,
    this.sidecars = const {},
  });

  final ColonySqliteBackupManifest manifest;
  final Uint8List sqlite;
  final Map<String, Uint8List> sidecars;
}

/// TLV container `COLNYBK1`. Unknown sections are ignored so new app versions
/// can add attachments without breaking old restore (and vice-versa for sqlite).
abstract final class ColonySqliteBackupCodec {
  static const magic = 'COLNYBK1';
  static const sectionManifest = 1;
  static const sectionSqlite = 2;
  static const sectionSidecar = 3;
  static const sqliteHeader = 'SQLite format 3';

  static bool looksLikeContainer(Uint8List bytes) {
    if (bytes.length < 8) return false;
    return ascii.decode(bytes.sublist(0, 8), allowInvalid: true) == magic;
  }

  static bool looksLikeSqlite(Uint8List bytes) {
    if (bytes.length < 100) return false;
    return ascii.decode(bytes.sublist(0, 15), allowInvalid: true) ==
        sqliteHeader;
  }

  static bool looksLikeJsonObject(Uint8List bytes) {
    var i = 0;
    if (bytes.length >= 3 &&
        bytes[0] == 0xEF &&
        bytes[1] == 0xBB &&
        bytes[2] == 0xBF) {
      i = 3;
    }
    while (i < bytes.length) {
      final b = bytes[i];
      if (b == 0x20 || b == 0x09 || b == 0x0A || b == 0x0D) {
        i++;
        continue;
      }
      return b == 0x7B; // '{'
    }
    return false;
  }

  static ColonyBackupKind sniff(Uint8List bytes) {
    if (looksLikeContainer(bytes)) return ColonyBackupKind.sqliteContainer;
    if (looksLikeSqlite(bytes)) return ColonyBackupKind.sqliteRaw;
    if (looksLikeJsonObject(bytes)) return ColonyBackupKind.json;
    return ColonyBackupKind.unknown;
  }

  /// SQLite database header offset 60: `PRAGMA user_version` (big-endian).
  static int? sqliteUserVersion(Uint8List bytes) {
    if (!looksLikeSqlite(bytes)) return null;
    return ByteData.sublistView(bytes).getUint32(60, Endian.big);
  }

  static Uint8List encode(ColonySqliteBackup backup) {
    final sections = <({int type, Uint8List body})>[
      (
        type: sectionManifest,
        body: Uint8List.fromList(
          utf8.encode(jsonEncode(backup.manifest.toJson())),
        ),
      ),
      (type: sectionSqlite, body: backup.sqlite),
    ];
    final names = backup.sidecars.keys.toList()..sort();
    for (final name in names) {
      sections.add((
        type: sectionSidecar,
        body: _encodeSidecar(name, backup.sidecars[name]!),
      ));
    }

    var size = 16; // magic + version + count
    for (final section in sections) {
      size += 12 + section.body.length;
    }
    final out = Uint8List(size);
    final data = ByteData.sublistView(out);
    out.setRange(0, 8, ascii.encode(magic));
    data.setUint32(8, 1, Endian.big); // container version
    data.setUint32(12, sections.length, Endian.big);
    var cursor = 16;
    for (final section in sections) {
      data.setUint32(cursor, section.type, Endian.big);
      data.setUint64(cursor + 4, section.body.length, Endian.big);
      out.setRange(
        cursor + 12,
        cursor + 12 + section.body.length,
        section.body,
      );
      cursor += 12 + section.body.length;
    }
    return out;
  }

  static ColonySqliteBackup decode(Uint8List bytes) {
    if (looksLikeSqlite(bytes)) {
      final version = sqliteUserVersion(bytes);
      if (version == null || version < 1) {
        throw const ColonySqliteBackupException(
          'Arquivo SQLite sem user_version',
        );
      }
      return ColonySqliteBackup(
        manifest: ColonySqliteBackupManifest(
          schemaVersion: version,
          exportedAt: DateTime.now().toUtc(),
        ),
        sqlite: bytes,
      );
    }
    if (!looksLikeContainer(bytes)) {
      throw const ColonySqliteBackupException('Arquivo não é um backup Colony');
    }
    if (bytes.length < 16) {
      throw const ColonySqliteBackupException('Backup truncado');
    }
    final data = ByteData.sublistView(bytes);
    final sectionCount = data.getUint32(12, Endian.big);
    if (sectionCount < 1 || sectionCount > 256) {
      throw const ColonySqliteBackupException('Backup com seções inválidas');
    }
    var cursor = 16;
    ColonySqliteBackupManifest? manifest;
    Uint8List? sqlite;
    final sidecars = <String, Uint8List>{};
    for (var i = 0; i < sectionCount; i++) {
      if (cursor + 12 > bytes.length) {
        throw const ColonySqliteBackupException('Backup truncado');
      }
      final type = data.getUint32(cursor, Endian.big);
      final length = data.getUint64(cursor + 4, Endian.big);
      cursor += 12;
      if (length < 0 || cursor + length > bytes.length) {
        throw const ColonySqliteBackupException('Backup truncado');
      }
      final body = Uint8List.fromList(bytes.sublist(cursor, cursor + length));
      cursor += length;
      switch (type) {
        case sectionManifest:
          final decoded = jsonDecode(utf8.decode(body));
          if (decoded is Map) {
            manifest = ColonySqliteBackupManifest.fromJson(decoded);
          }
        case sectionSqlite:
          sqlite = body;
        case sectionSidecar:
          final parsed = _decodeSidecar(body);
          if (parsed != null) sidecars[parsed.$1] = parsed.$2;
        default:
          break;
      }
    }
    if (sqlite == null || sqlite.isEmpty) {
      throw const ColonySqliteBackupException('Backup sem banco SQLite');
    }
    final version = manifest?.schemaVersion ?? sqliteUserVersion(sqlite);
    if (version == null || version < 1) {
      throw const ColonySqliteBackupException('Backup sem versão de schema');
    }
    return ColonySqliteBackup(
      manifest:
          manifest ??
          ColonySqliteBackupManifest(
            schemaVersion: version,
            exportedAt: DateTime.now().toUtc(),
          ),
      sqlite: sqlite,
      sidecars: sidecars,
    );
  }

  static void assertRestorable({
    required int backupSchemaVersion,
    required int appSchemaVersion,
  }) {
    if (backupSchemaVersion < 1) {
      throw const ColonySqliteBackupException('Schema do backup inválido');
    }
    if (backupSchemaVersion > appSchemaVersion) {
      throw ColonySqliteBackupTooNewException(
        backupSchemaVersion: backupSchemaVersion,
        appSchemaVersion: appSchemaVersion,
      );
    }
  }

  static Uint8List _encodeSidecar(String name, Uint8List file) {
    final nameBytes = utf8.encode(name);
    if (nameBytes.length > 0xffff) {
      throw const ColonySqliteBackupException('Nome de anexo longo demais');
    }
    final out = Uint8List(2 + nameBytes.length + file.length);
    final data = ByteData.sublistView(out);
    data.setUint16(0, nameBytes.length, Endian.big);
    out.setRange(2, 2 + nameBytes.length, nameBytes);
    out.setRange(2 + nameBytes.length, out.length, file);
    return out;
  }

  static (String, Uint8List)? _decodeSidecar(Uint8List body) {
    if (body.length < 2) return null;
    final nameLen = ByteData.sublistView(body).getUint16(0, Endian.big);
    if (nameLen < 1 || 2 + nameLen > body.length) return null;
    final name = utf8.decode(body.sublist(2, 2 + nameLen));
    if (name.contains('/') || name.contains('\\') || name == '..') return null;
    return (name, Uint8List.fromList(body.sublist(2 + nameLen)));
  }
}
