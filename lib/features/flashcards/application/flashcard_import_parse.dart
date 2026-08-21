import 'dart:io';
import 'dart:typed_data';

import 'package:colony_domain/colony_domain.dart';

class RandomAccessFileByteSource implements TimelineByteSource {
  RandomAccessFileByteSource(this._file) : length = _file.lengthSync();

  final RandomAccessFile _file;

  @override
  final int length;

  @override
  Uint8List read(int offset, int length) {
    if (length <= 0 || offset >= this.length) return Uint8List(0);
    final take = offset + length > this.length ? this.length - offset : length;
    _file.setPositionSync(offset);
    final buf = Uint8List(take);
    final n = _file.readIntoSync(buf);
    if (n == take) return buf;
    return Uint8List.sublistView(buf, 0, n);
  }
}

/// Isolate entry: path of a flashcard JSON dump → document maps.
/// The UI isolate never `readAsString`s the raw file.
Map<String, dynamic> parseFlashcardJsonFile(String path) {
  final raf = File(path).openSync();
  try {
    final doc = FlashcardJsonCodec.parseSource(RandomAccessFileByteSource(raf));
    return doc.toJson();
  } finally {
    raf.closeSync();
  }
}

/// Isolate entry for pasted JSON (written to a temp file, then streamed).
Map<String, dynamic> parseFlashcardJsonSource(String source) {
  final raw = File(
    '${Directory.systemTemp.path}/colony_flashcards_${DateTime.now().microsecondsSinceEpoch}.json',
  );
  raw.writeAsStringSync(source);
  try {
    return parseFlashcardJsonFile(raw.path);
  } finally {
    try {
      raw.deleteSync();
    } on FileSystemException {
      // Ignore temp cleanup races.
    }
  }
}
