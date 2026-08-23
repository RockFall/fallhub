import 'dart:io';

import 'package:colony_domain/colony_domain.dart';

import '../../flashcards/application/flashcard_import_parse.dart';

/// Isolate entry: path of an Atlas JSON dump → document map.
/// The UI isolate never `readAsString`s the raw file.
Map<String, dynamic> parseMusicAtlasJsonFile(String path) {
  final raf = File(path).openSync();
  try {
    final doc = MusicAtlasJsonCodec.parseSource(RandomAccessFileByteSource(raf));
    return doc.toJson();
  } finally {
    raf.closeSync();
  }
}

/// Isolate entry for pasted JSON (written to a temp file, then streamed).
Map<String, dynamic> parseMusicAtlasJsonSource(String source) {
  final raw = File(
    '${Directory.systemTemp.path}/colony_music_atlas_${DateTime.now().microsecondsSinceEpoch}.json',
  );
  raw.writeAsStringSync(source);
  try {
    return parseMusicAtlasJsonFile(raw.path);
  } finally {
    try {
      raw.deleteSync();
    } on FileSystemException {
      // Ignore temp cleanup races.
    }
  }
}
