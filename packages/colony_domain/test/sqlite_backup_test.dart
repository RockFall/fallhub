import 'dart:convert';
import 'dart:typed_data';

import 'package:colony_domain/colony_domain.dart';
import 'package:test/test.dart';

void main() {
  Uint8List fakeSqlite({required int userVersion, int length = 200}) {
    final bytes = Uint8List(length);
    final header = ascii.encode('SQLite format 3');
    bytes.setRange(0, header.length, header);
    bytes[15] = 0;
    ByteData.sublistView(bytes).setUint32(60, userVersion, Endian.big);
    return bytes;
  }

  Uint8List encodeSections(List<({int type, List<int> body})> sections) {
    var size = 16;
    for (final section in sections) {
      size += 12 + section.body.length;
    }
    final out = Uint8List(size);
    final data = ByteData.sublistView(out);
    out.setRange(0, 8, ascii.encode(ColonySqliteBackupCodec.magic));
    data.setUint32(8, 1, Endian.big);
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

  test('roundtrip preserves sqlite bytes and sidecars', () {
    final sqlite = fakeSqlite(userVersion: 12);
    final encoded = ColonySqliteBackupCodec.encode(
      ColonySqliteBackup(
        manifest: ColonySqliteBackupManifest(
          schemaVersion: 12,
          exportedAt: DateTime.utc(2026, 8, 31, 12),
        ),
        sqlite: sqlite,
        sidecars: {
          'google_timeline_p.json': Uint8List.fromList(utf8.encode('{"v":1}')),
        },
      ),
    );
    expect(ColonySqliteBackupCodec.looksLikeContainer(encoded), isTrue);
    expect(
      ColonySqliteBackupCodec.sniff(encoded),
      ColonyBackupKind.sqliteContainer,
    );

    final decoded = ColonySqliteBackupCodec.decode(encoded);
    expect(decoded.manifest.schemaVersion, 12);
    expect(decoded.sqlite, sqlite);
    expect(utf8.decode(decoded.sidecars['google_timeline_p.json']!), '{"v":1}');
  });

  test('unknown TLV sections are skipped', () {
    final sqlite = fakeSqlite(userVersion: 8);
    final manifest = utf8.encode(
      jsonEncode({
        'schemaVersion': 8,
        'exportedAt': '2026-08-31T12:00:00.000Z',
        'dbFileName': 'colony.db',
      }),
    );
    final bytes = encodeSections([
      (type: ColonySqliteBackupCodec.sectionManifest, body: manifest),
      (type: 99, body: utf8.encode('future-attachment')),
      (type: ColonySqliteBackupCodec.sectionSqlite, body: sqlite),
    ]);
    final decoded = ColonySqliteBackupCodec.decode(bytes);
    expect(decoded.manifest.schemaVersion, 8);
    expect(decoded.sqlite, sqlite);
    expect(decoded.sidecars, isEmpty);
  });

  test('raw sqlite uses header user_version', () {
    final sqlite = fakeSqlite(userVersion: 41);
    expect(ColonySqliteBackupCodec.sniff(sqlite), ColonyBackupKind.sqliteRaw);
    expect(ColonySqliteBackupCodec.sqliteUserVersion(sqlite), 41);
    final decoded = ColonySqliteBackupCodec.decode(sqlite);
    expect(decoded.manifest.schemaVersion, 41);
    expect(decoded.sqlite, sqlite);
  });

  test('sniff prefers sqlite over JSON and accepts BOM JSON', () {
    expect(
      ColonySqliteBackupCodec.sniff(Uint8List.fromList(utf8.encode('{"v":1}'))),
      ColonyBackupKind.json,
    );
    expect(
      ColonySqliteBackupCodec.sniff(
        Uint8List.fromList([0xEF, 0xBB, 0xBF, ...utf8.encode('{"v":1}')]),
      ),
      ColonyBackupKind.json,
    );
    expect(
      ColonySqliteBackupCodec.sniff(Uint8List.fromList(utf8.encode('nope'))),
      ColonyBackupKind.unknown,
    );
  });

  test('sidecar names with path separators are ignored', () {
    final sqlite = fakeSqlite(userVersion: 5);
    final name = utf8.encode('../evil.json');
    final body = Uint8List(2 + name.length + 1);
    ByteData.sublistView(body).setUint16(0, name.length, Endian.big);
    body.setRange(2, 2 + name.length, name);
    body[body.length - 1] = 1;
    final encoded = encodeSections([
      (
        type: ColonySqliteBackupCodec.sectionManifest,
        body: utf8.encode(
          jsonEncode({
            'schemaVersion': 5,
            'exportedAt': '2026-08-31T12:00:00.000Z',
          }),
        ),
      ),
      (type: ColonySqliteBackupCodec.sectionSqlite, body: sqlite),
      (type: ColonySqliteBackupCodec.sectionSidecar, body: body),
    ]);
    expect(ColonySqliteBackupCodec.decode(encoded).sidecars, isEmpty);
  });

  test('too-new schema is rejected before restore', () {
    expect(
      () => ColonySqliteBackupCodec.assertRestorable(
        backupSchemaVersion: 99,
        appSchemaVersion: 45,
      ),
      throwsA(isA<ColonySqliteBackupTooNewException>()),
    );
    expect(
      () => ColonySqliteBackupCodec.assertRestorable(
        backupSchemaVersion: 12,
        appSchemaVersion: 45,
      ),
      returnsNormally,
    );
  });

  test('truncated container throws', () {
    expect(
      () => ColonySqliteBackupCodec.decode(
        Uint8List.fromList(ascii.encode('COLNYBK1')),
      ),
      throwsA(isA<ColonySqliteBackupException>()),
    );
  });
}
