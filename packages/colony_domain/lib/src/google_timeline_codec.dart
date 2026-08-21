import 'dart:convert';

import 'google_timeline.dart';

/// Parses on-device Google Timeline JSON (`semanticSegments` / array variant).
/// Drops `wifiScan` MAC records. Throws [FormatException].
abstract final class GoogleTimelineCodec {
  /// Default cap for `timelinePath` points persisted per segment.
  static const defaultMaxPathPoints = 16;

  /// Isolate-safe parse: returns JSON maps/lists, never Equatable or records.
  static Map<String, dynamic> parseToJson(
    String source, {
    bool includeRawSignals = false,
    int maxPathPoints = defaultMaxPathPoints,
  }) {
    return parse(
      source,
      includeRawSignals: includeRawSignals,
      maxPathPoints: maxPathPoints,
    ).toJson();
  }

  /// Removes the `rawSignals` property (GPS / wifi MACs) before [jsonDecode]
  /// so a real on-device export does not allocate hundreds of MB. ADR-042.
  static String stripRawSignals(String source) {
    return omitJsonProperty(source, 'rawSignals');
  }

  /// Drops a JSON object property by key. Best-effort; returns [source] unchanged
  /// if the value cannot be skipped.
  static String omitJsonProperty(String source, String key) {
    final needle = '"$key"';
    var from = 0;
    while (true) {
      final keyAt = source.indexOf(needle, from);
      if (keyAt < 0) return source;
      var i = _skipWs(source, keyAt + needle.length);
      if (i >= source.length || source.codeUnitAt(i) != 0x3A) {
        from = keyAt + 1;
        continue;
      }
      i = _skipWs(source, i + 1);
      final valueEnd = _skipJsonValue(source, i);
      if (valueEnd < 0) return source;
      var start = keyAt;
      var end = valueEnd;
      final before = _rskipWs(source, start - 1);
      final after = _skipWs(source, end);
      if (before >= 0 && source.codeUnitAt(before) == 0x2C) {
        start = before;
      } else if (after < source.length && source.codeUnitAt(after) == 0x2C) {
        end = after + 1;
      }
      source = '${source.substring(0, start)}${source.substring(end)}';
      from = start;
    }
  }

  static GoogleTimelineDocument parse(
    String source, {
    bool includeRawSignals = false,
    int maxPathPoints = defaultMaxPathPoints,
  }) {
    final trimmed = source.trim();
    if (trimmed.isEmpty) {
      throw const FormatException('JSON da Timeline vazio');
    }
    final Object decoded;
    try {
      decoded = jsonDecode(trimmed);
    } on FormatException catch (e) {
      throw FormatException('JSON inválido: ${e.message}');
    }

    List<dynamic> segments = const [];
    List<dynamic> rawSignals = const [];
    Map<String, dynamic>? profile;

    final root = _asStringMap(decoded);
    if (root != null) {
      final sem = root['semanticSegments'];
      if (sem is List) {
        segments = sem;
      } else if (root['timelineObjects'] is List) {
        throw const FormatException(
          'Este ficheiro é o Takeout antigo (timelineObjects). Exporte a Timeline no telemóvel.',
        );
      } else if (root['locations'] is List) {
        throw const FormatException(
          'Este ficheiro é Records.json (pings brutos). Exporte a Timeline no telemóvel.',
        );
      }
      if (includeRawSignals && root['rawSignals'] is List) {
        rawSignals = root['rawSignals'] as List;
      }
      profile = _asStringMap(root['userLocationProfile']);
    } else if (decoded is List) {
      segments = decoded;
    } else {
      throw const FormatException('JSON raiz deve ser objeto ou lista');
    }

    if (segments.isEmpty &&
        rawSignals.isEmpty &&
        (profile == null || profile.isEmpty)) {
      throw const FormatException(
        'Nenhum semanticSegments encontrado. Confirme que é um export da Timeline.',
      );
    }

    final visits = <TimelineVisit>[];
    final activities = <TimelineActivity>[];
    final paths = <TimelinePathSegment>[];
    final trips = <TimelineMemoryTrip>[];
    final notes = <TimelineMemoryNote>[];

    for (final raw in segments) {
      final map = _asStringMap(raw);
      if (map == null) continue;
      final startAt = _parseTime(map['startTime']);
      final endAt = _parseTime(map['endTime']) ?? startAt;
      if (startAt == null || endAt == null) continue;
      final startOff = _asInt(map['startTimeTimezoneUtcOffsetMinutes']);
      final endOff = _asInt(map['endTimeTimezoneUtcOffsetMinutes']);

      final visitMap = _asStringMap(map['visit']);
      if (visitMap != null) {
        visits.add(_parseVisit(startAt, endAt, startOff, endOff, visitMap));
      }
      final activityMap = _asStringMap(map['activity']);
      if (activityMap != null) {
        activities.add(
          _parseActivity(startAt, endAt, startOff, endOff, activityMap),
        );
      }
      if (map['timelinePath'] is List) {
        paths.add(
          _parsePath(
            startAt,
            endAt,
            startOff,
            endOff,
            map['timelinePath'] as List,
            maxPathPoints,
          ),
        );
      }
      final memory = _asStringMap(map['timelineMemory']);
      if (memory != null) {
        final tripMap = _asStringMap(memory['trip']) ?? memory;
        if (tripMap['destinations'] != null ||
            tripMap['distanceFromOriginKms'] != null ||
            memory['destinations'] != null) {
          final dests = <String>[];
          void collect(Object? node) {
            if (node is List) {
              for (final d in node) {
                final dest = _asStringMap(d);
                if (dest == null) continue;
                final id = dest['identifier'];
                final idMap = _asStringMap(id);
                final placeId =
                    _asString(idMap?['placeId']) ??
                    _asString(dest['placeId']) ??
                    _asString(id);
                if (placeId != null && placeId.isNotEmpty) {
                  dests.add(placeId);
                }
              }
            }
          }

          collect(tripMap['destinations']);
          collect(memory['destinations']);
          trips.add(
            TimelineMemoryTrip(
              startAt: startAt,
              endAt: endAt,
              distanceFromOriginKms: _asInt(tripMap['distanceFromOriginKms']),
              destinationPlaceIds: dests,
            ),
          );
        }
        final noteRaw = memory['note'];
        final noteMap = _asStringMap(noteRaw);
        final noteText = _asString(noteMap?['note']) ?? _asString(noteRaw);
        if (noteText != null && noteText.trim().isNotEmpty) {
          notes.add(
            TimelineMemoryNote(
              startAt: startAt,
              endAt: endAt,
              text: noteText.trim(),
            ),
          );
        }
      }
    }

    final positions = <TimelineRawPosition>[];
    final sensors = <TimelineSensorActivity>[];
    for (final raw in rawSignals) {
      final map = _asStringMap(raw);
      if (map == null) continue;
      final pos = _asStringMap(map['position']);
      if (pos != null) {
        final point = parseLatLng(pos['LatLng'] ?? pos['latLng']);
        final time = _parseTime(pos['timestamp']);
        if (point != null && time != null) {
          positions.add(
            TimelineRawPosition(
              location: point,
              timestamp: time,
              accuracyMeters: _asDouble(pos['accuracyMeters']),
              altitudeMeters: _asDouble(pos['altitudeMeters']),
              source: _asString(pos['source']),
              speedMetersPerSecond: _asDouble(pos['speedMetersPerSecond']),
            ),
          );
        }
      }
      final rec = _asStringMap(map['activityRecord']);
      if (rec != null) {
        final time = _parseTime(rec['timestamp']);
        final list = rec['probableActivities'];
        if (time != null && list is List) {
          final acts = <({String type, double confidence})>[
            for (final a in list)
              if (a is Map)
                (
                  type: _asString(a['type']) ?? 'UNKNOWN',
                  confidence: _asDouble(a['confidence']) ?? 0,
                ),
          ];
          acts.sort((a, b) => b.confidence.compareTo(a.confidence));
          sensors.add(
            TimelineSensorActivity(timestamp: time, activities: acts),
          );
        }
      }
      // wifiScan intentionally ignored.
    }

    final frequent = <TimelineFrequentPlace>[];
    final affinities = <TimelineModeAffinity>[];
    if (profile != null) {
      final places = profile['frequentPlaces'];
      if (places is List) {
        for (final p in places) {
          final place = _asStringMap(p);
          if (place == null) continue;
          frequent.add(
            TimelineFrequentPlace(
              placeId: _asString(place['placeId']),
              location: parseLatLng(place['placeLocation']),
              label: _asString(place['label']),
            ),
          );
        }
      }
      final persona = _asStringMap(profile['persona']);
      final affinitiesRaw = persona?['travelModeAffinities'];
      if (affinitiesRaw is List) {
        for (final a in affinitiesRaw) {
          final aff = _asStringMap(a);
          if (aff == null) continue;
          affinities.add(
            TimelineModeAffinity(
              mode: _asString(aff['mode']) ?? 'UNKNOWN',
              affinity: _asDouble(aff['affinity']) ?? 0,
            ),
          );
        }
      }
    }

    final doc = GoogleTimelineDocument(
      visits: visits,
      activities: activities,
      paths: paths,
      trips: trips,
      notes: notes.where((n) => n.text.isNotEmpty).toList(),
      frequentPlaces: frequent,
      affinities: affinities,
      positions: positions,
      sensorActivities: sensors,
    );
    if (doc.isEmpty) {
      throw const FormatException('Nenhum segmento útil na Timeline');
    }
    return doc;
  }

  static TimelineVisit _parseVisit(
    DateTime startAt,
    DateTime endAt,
    int? startOff,
    int? endOff,
    Map<String, dynamic> visit,
  ) {
    final top =
        _asStringMap(visit['topCandidate']) ?? const <String, dynamic>{};
    final placeLocation = top['placeLocation'];
    final placeMap = _asStringMap(placeLocation);
    return TimelineVisit(
      startAt: startAt,
      endAt: endAt,
      startOffsetMinutes: startOff,
      endOffsetMinutes: endOff,
      placeId: _asString(top['placeId'] ?? top['placeID']),
      semanticType: _asString(top['semanticType']),
      location: parseLatLng(
        placeMap != null
            ? placeMap['latLng'] ?? placeMap['LatLng']
            : placeLocation,
      ),
      probability: _asDouble(visit['probability']),
      candidateProbability: _asDouble(top['probability']),
      hierarchyLevel: _asInt(visit['hierarchyLevel']) ?? 0,
      isTimeless:
          visit['isTimelessVisit'] == true ||
          visit['isTimelessVisit'] == 'true',
    );
  }

  static TimelineActivity _parseActivity(
    DateTime startAt,
    DateTime endAt,
    int? startOff,
    int? endOff,
    Map<String, dynamic> activity,
  ) {
    final top =
        _asStringMap(activity['topCandidate']) ?? const <String, dynamic>{};
    TimelineParking? parking;
    final parkingMap = _asStringMap(activity['parking']);
    if (parkingMap != null) {
      final locRaw = parkingMap['location'];
      final locMap = _asStringMap(locRaw);
      final loc = locMap != null
          ? parseLatLng(locMap['latLng'] ?? locMap['LatLng'])
          : parseLatLng(locRaw);
      final time = _parseTime(parkingMap['startTime']);
      if (loc != null && time != null) {
        parking = TimelineParking(location: loc, startAt: time);
      }
    }
    final startMap = _asStringMap(activity['start']);
    final endMap = _asStringMap(activity['end']);
    return TimelineActivity(
      startAt: startAt,
      endAt: endAt,
      startOffsetMinutes: startOff,
      endOffsetMinutes: endOff,
      startLocation: startMap == null
          ? null
          : parseLatLng(startMap['latLng'] ?? startMap['LatLng']),
      endLocation: endMap == null
          ? null
          : parseLatLng(endMap['latLng'] ?? endMap['LatLng']),
      distanceMeters: _asDouble(activity['distanceMeters']),
      probability: _asDouble(activity['probability']),
      activityType: _asString(top['type']),
      candidateProbability: _asDouble(top['probability']),
      parking: parking,
    );
  }

  static TimelinePathSegment _parsePath(
    DateTime startAt,
    DateTime endAt,
    int? startOff,
    int? endOff,
    List<dynamic> rawPoints,
    int maxPathPoints,
  ) {
    final points = <TimelinePathPoint>[];
    for (final p in rawPoints) {
      final map = _asStringMap(p);
      if (map == null) continue;
      final point = parseLatLng(map['point']);
      if (point == null) continue;
      final explicit = _parseTime(map['time']);
      final offset = _asInt(map['durationMinutesOffsetFromStartTime']);
      final time =
          explicit ??
          (offset != null ? startAt.add(Duration(minutes: offset)) : startAt);
      points.add(TimelinePathPoint(point: point, time: time));
    }
    return TimelinePathSegment(
      startAt: startAt,
      endAt: endAt,
      startOffsetMinutes: startOff,
      endOffsetMinutes: endOff,
      points: _downsamplePath(points, maxPathPoints),
    );
  }

  static List<TimelinePathPoint> _downsamplePath(
    List<TimelinePathPoint> points,
    int maxPoints,
  ) {
    if (maxPoints <= 0 || points.length <= maxPoints) return points;
    if (maxPoints == 1) return [points.first];
    final out = <TimelinePathPoint>[];
    for (var i = 0; i < maxPoints; i++) {
      final idx = i == maxPoints - 1
          ? points.length - 1
          : ((i * (points.length - 1)) / (maxPoints - 1)).round();
      if (out.isEmpty || out.last != points[idx]) {
        out.add(points[idx]);
      }
    }
    return out;
  }

  static GeoPoint? parseLatLng(Object? raw) {
    if (raw == null) return null;
    if (raw is Map) {
      return parseLatLng(raw['latLng'] ?? raw['LatLng']);
    }
    if (raw is! String) return null;
    final cleaned = raw.replaceAll('°', '').trim();
    final parts = cleaned.split(',');
    if (parts.length < 2) return null;
    final lat = double.tryParse(parts[0].trim());
    final lng = double.tryParse(parts[1].trim());
    if (lat == null || lng == null) return null;
    if (lat.abs() > 90 || lng.abs() > 180) return null;
    return GeoPoint(lat, lng);
  }

  static DateTime? _parseTime(Object? raw) {
    if (raw is! String || raw.isEmpty) return null;
    try {
      return DateTime.parse(raw).toUtc();
    } catch (_) {
      return null;
    }
  }

  static Map<String, dynamic>? _asStringMap(Object? raw) {
    if (raw is Map<String, dynamic>) return raw;
    if (raw is Map) return Map<String, dynamic>.from(raw);
    return null;
  }

  static String? _asString(Object? raw) {
    if (raw is String) return raw;
    return null;
  }

  static int? _asInt(Object? raw) {
    if (raw == null) return null;
    if (raw is int) return raw;
    if (raw is num) return raw.toInt();
    return int.tryParse(raw.toString());
  }

  static double? _asDouble(Object? raw) {
    if (raw == null) return null;
    if (raw is double) return raw;
    if (raw is num) return raw.toDouble();
    return double.tryParse(raw.toString());
  }

  static bool _isWs(int code) =>
      code == 0x20 || code == 0x09 || code == 0x0A || code == 0x0D;

  static int _skipWs(String s, int i) {
    while (i < s.length && _isWs(s.codeUnitAt(i))) {
      i++;
    }
    return i;
  }

  static int _rskipWs(String s, int i) {
    while (i >= 0 && _isWs(s.codeUnitAt(i))) {
      i--;
    }
    return i;
  }

  /// Returns the index after a JSON value starting at [i], or -1.
  static int _skipJsonValue(String s, int i) {
    if (i >= s.length) return -1;
    i = _skipWs(s, i);
    if (i >= s.length) return -1;
    final c = s.codeUnitAt(i);
    if (c == 0x22) {
      i++;
      while (i < s.length) {
        final ch = s.codeUnitAt(i);
        if (ch == 0x5C) {
          i += 2;
          continue;
        }
        if (ch == 0x22) return i + 1;
        i++;
      }
      return -1;
    }
    if (c == 0x7B || c == 0x5B) {
      final stack = <int>[c];
      i++;
      var inStr = false;
      while (i < s.length && stack.isNotEmpty) {
        final ch = s.codeUnitAt(i);
        if (inStr) {
          if (ch == 0x5C) {
            i += 2;
            continue;
          }
          if (ch == 0x22) inStr = false;
          i++;
          continue;
        }
        if (ch == 0x22) {
          inStr = true;
          i++;
          continue;
        }
        if (ch == 0x7B || ch == 0x5B) {
          stack.add(ch);
          i++;
          continue;
        }
        if (ch == 0x7D) {
          if (stack.last != 0x7B) return -1;
          stack.removeLast();
          i++;
          continue;
        }
        if (ch == 0x5D) {
          if (stack.last != 0x5B) return -1;
          stack.removeLast();
          i++;
          continue;
        }
        i++;
      }
      return stack.isEmpty ? i : -1;
    }
    while (i < s.length) {
      final ch = s.codeUnitAt(i);
      if (ch == 0x2C || ch == 0x7D || ch == 0x5D || _isWs(ch)) break;
      i++;
    }
    return i;
  }
}
