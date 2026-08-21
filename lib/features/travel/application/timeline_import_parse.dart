import 'dart:io';

import 'package:colony_domain/colony_domain.dart';

/// Real on-device Timeline dumps often exceed 50 MB (mostly `rawSignals`).
/// Above this we refuse rather than let the OS kill the app.
const timelineImportMaxBytes = 150 * 1024 * 1024;

class TimelineImportTooLarge implements Exception {
  TimelineImportTooLarge(this.bytes);
  final int bytes;

  int get megaBytes => (bytes / (1024 * 1024)).ceil();

  @override
  String toString() => 'Timeline JSON too large ($megaBytes MB)';
}

/// Isolate entry: file path → normalized JSON maps (no Equatable / records).
Map<String, dynamic> parseGoogleTimelineFile(String path) {
  final file = File(path);
  final length = file.lengthSync();
  if (length > timelineImportMaxBytes) {
    throw TimelineImportTooLarge(length);
  }
  final source = GoogleTimelineCodec.stripRawSignals(file.readAsStringSync());
  return GoogleTimelineCodec.parseToJson(source);
}

/// Isolate entry for pasted JSON.
Map<String, dynamic> parseGoogleTimelineSource(String source) {
  if (source.length > timelineImportMaxBytes) {
    throw TimelineImportTooLarge(source.length);
  }
  return GoogleTimelineCodec.parseToJson(
    GoogleTimelineCodec.stripRawSignals(source),
  );
}
