import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:colony_domain/colony_domain.dart';

class RandomAccessTimelineByteSource implements TimelineByteSource {
  RandomAccessTimelineByteSource(this._file) : length = _file.lengthSync();

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

/// Isolate entry: path of the on-device Timeline dump → compact JSON on disk
/// plus counts. The UI isolate never sees the raw bytes. No file-size cap —
/// `rawSignals` is skipped with a sliding window over the file.
Map<String, dynamic> parseGoogleTimelineFile(String path) {
  final raf = File(path).openSync();
  try {
    final doc = GoogleTimelineCodec.parseSource(
      RandomAccessTimelineByteSource(raf),
    );
    final compact = File(
      '${Directory.systemTemp.path}/colony_timeline_${DateTime.now().microsecondsSinceEpoch}.json',
    );
    compact.writeAsStringSync(jsonEncode(doc.toJson()));
    return <String, dynamic>{
      'compactPath': compact.path,
      'visits': doc.visits.length,
      'activities': doc.activities.length,
      'trips': doc.trips.length,
      'places': doc.visits
          .map((v) => v.placeId)
          .whereType<String>()
          .toSet()
          .length,
    };
  } finally {
    raf.closeSync();
  }
}

/// Isolate entry for pasted JSON (written to a temp file, then streamed).
Map<String, dynamic> parseGoogleTimelineSource(String source) {
  final raw = File(
    '${Directory.systemTemp.path}/colony_timeline_paste_${DateTime.now().microsecondsSinceEpoch}.json',
  );
  raw.writeAsStringSync(source);
  try {
    return parseGoogleTimelineFile(raw.path);
  } finally {
    try {
      raw.deleteSync();
    } on FileSystemException {
      // Compact output lives in a different file.
    }
  }
}
