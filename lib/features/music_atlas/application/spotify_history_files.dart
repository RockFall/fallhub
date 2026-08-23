import 'dart:convert';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:colony_domain/colony_domain.dart';

abstract final class SpotifyHistoryFiles {
  static SpotifyHistoryParseResult parsePicked(
    Iterable<({String name, Uint8List bytes})> files,
  ) {
    final documents = <(String, String)>[];
    for (final file in files) {
      final lower = file.name.toLowerCase();
      if (lower.endsWith('.zip')) {
        final archive = ZipDecoder().decodeBytes(file.bytes);
        for (final entry in archive) {
          if (!entry.isFile) continue;
          if (!SpotifyStreamingHistoryPolicy.isHistoryFileName(entry.name)) {
            continue;
          }
          documents.add((
            entry.name,
            utf8.decode(entry.content, allowMalformed: true),
          ));
        }
        continue;
      }
      documents.add((
        file.name,
        utf8.decode(file.bytes, allowMalformed: true),
      ));
    }
    return SpotifyStreamingHistoryCodec.parseMany(documents);
  }
}
