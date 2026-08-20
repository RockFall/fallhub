import 'dart:convert';

import 'google_timeline.dart';

/// Parses on-device Google Timeline JSON (`semanticSegments` / array variant).
/// Drops `wifiScan` MAC records. Throws [FormatException].
abstract final class GoogleTimelineCodec {
  static GoogleTimelineDocument parse(String source) {
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

    Map<String, dynamic>? root;
    List<dynamic> segments = const [];
    List<dynamic> rawSignals = const [];
    Map<String, dynamic>? profile;

    if (decoded is Map<String, dynamic>) {
      root = decoded;
      final sem = decoded['semanticSegments'];
      if (sem is List) {
        segments = sem;
      } else if (decoded['timelineObjects'] is List) {
        throw const FormatException(
          'Este ficheiro é o Takeout antigo (timelineObjects). Exporte a Timeline no telemóvel.',
        );
      } else if (decoded['locations'] is List) {
        throw const FormatException(
          'Este ficheiro é Records.json (pings brutos). Exporte a Timeline no telemóvel.',
        );
      }
      if (decoded['rawSignals'] is List) {
        rawSignals = decoded['rawSignals'] as List;
      }
      if (decoded['userLocationProfile'] is Map<String, dynamic>) {
        profile = decoded['userLocationProfile'] as Map<String, dynamic>;
      }
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
      if (raw is! Map) continue;
      final map = Map<String, dynamic>.from(raw);
      final startAt = _parseTime(map['startTime']);
      final endAt = _parseTime(map['endTime']) ?? startAt;
      if (startAt == null || endAt == null) continue;
      final startOff = _asInt(map['startTimeTimezoneUtcOffsetMinutes']);
      final endOff = _asInt(map['endTimeTimezoneUtcOffsetMinutes']);

      if (map['visit'] is Map) {
        visits.add(
          _parseVisit(
            startAt,
            endAt,
            startOff,
            endOff,
            Map<String, dynamic>.from(map['visit'] as Map),
          ),
        );
      }
      if (map['activity'] is Map) {
        activities.add(
          _parseActivity(
            startAt,
            endAt,
            startOff,
            endOff,
            Map<String, dynamic>.from(map['activity'] as Map),
          ),
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
          ),
        );
      }
      if (map['timelineMemory'] is Map) {
        final memory = Map<String, dynamic>.from(map['timelineMemory'] as Map);
        final tripRaw = memory['trip'] ?? memory;
        if (tripRaw is Map &&
            (tripRaw['destinations'] != null ||
                tripRaw['distanceFromOriginKms'] != null ||
                memory['destinations'] != null)) {
          final dests = <String>[];
          void collect(Object? node) {
            if (node is List) {
              for (final d in node) {
                if (d is Map) {
                  final id = d['identifier'];
                  if (id is Map && id['placeId'] is String) {
                    dests.add(id['placeId'] as String);
                  } else if (d['placeId'] is String) {
                    dests.add(d['placeId'] as String);
                  } else if (id is String) {
                    dests.add(id);
                  }
                }
              }
            }
          }

          collect(tripRaw is Map ? tripRaw['destinations'] : null);
          collect(memory['destinations']);
          trips.add(
            TimelineMemoryTrip(
              startAt: startAt,
              endAt: endAt,
              distanceFromOriginKms: _asInt(
                tripRaw is Map
                    ? tripRaw['distanceFromOriginKms']
                    : memory['distanceFromOriginKms'],
              ),
              destinationPlaceIds: dests,
            ),
          );
        }
        final noteRaw = memory['note'];
        if (noteRaw is Map && noteRaw['note'] is String) {
          notes.add(
            TimelineMemoryNote(
              startAt: startAt,
              endAt: endAt,
              text: (noteRaw['note'] as String).trim(),
            ),
          );
        } else if (noteRaw is String && noteRaw.trim().isNotEmpty) {
          notes.add(
            TimelineMemoryNote(
              startAt: startAt,
              endAt: endAt,
              text: noteRaw.trim(),
            ),
          );
        }
      }
    }

    final positions = <TimelineRawPosition>[];
    final sensors = <TimelineSensorActivity>[];
    for (final raw in rawSignals) {
      if (raw is! Map) continue;
      final map = Map<String, dynamic>.from(raw);
      if (map['position'] is Map) {
        final pos = Map<String, dynamic>.from(map['position'] as Map);
        final point = parseLatLng(pos['LatLng'] ?? pos['latLng']);
        final time = _parseTime(pos['timestamp']);
        if (point != null && time != null) {
          positions.add(
            TimelineRawPosition(
              location: point,
              timestamp: time,
              accuracyMeters: _asDouble(pos['accuracyMeters']),
              altitudeMeters: _asDouble(pos['altitudeMeters']),
              source: pos['source'] as String?,
              speedMetersPerSecond: _asDouble(pos['speedMetersPerSecond']),
            ),
          );
        }
      }
      if (map['activityRecord'] is Map) {
        final rec = Map<String, dynamic>.from(map['activityRecord'] as Map);
        final time = _parseTime(rec['timestamp']);
        final list = rec['probableActivities'];
        if (time != null && list is List) {
          final acts = <({String type, double confidence})>[
            for (final a in list)
              if (a is Map)
                (
                  type: (a['type'] as String?) ?? 'UNKNOWN',
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
          if (p is! Map) continue;
          frequent.add(
            TimelineFrequentPlace(
              placeId: p['placeId'] as String?,
              location: parseLatLng(p['placeLocation']),
              label: p['label'] as String?,
            ),
          );
        }
      }
      final persona = profile['persona'];
      if (persona is Map && persona['travelModeAffinities'] is List) {
        for (final a in persona['travelModeAffinities'] as List) {
          if (a is! Map) continue;
          affinities.add(
            TimelineModeAffinity(
              mode: (a['mode'] as String?) ?? 'UNKNOWN',
              affinity: _asDouble(a['affinity']) ?? 0,
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
    final top = visit['topCandidate'] is Map
        ? Map<String, dynamic>.from(visit['topCandidate'] as Map)
        : const <String, dynamic>{};
    return TimelineVisit(
      startAt: startAt,
      endAt: endAt,
      startOffsetMinutes: startOff,
      endOffsetMinutes: endOff,
      placeId: (top['placeId'] ?? top['placeID']) as String?,
      semanticType: top['semanticType'] as String?,
      location: parseLatLng(
        top['placeLocation'] is Map
            ? (top['placeLocation'] as Map)['latLng']
            : top['placeLocation'],
      ),
      probability: _asDouble(visit['probability']),
      candidateProbability: _asDouble(top['probability']),
      hierarchyLevel: _asInt(visit['hierarchyLevel']) ?? 0,
      isTimeless: visit['isTimelessVisit'] == true ||
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
    final top = activity['topCandidate'] is Map
        ? Map<String, dynamic>.from(activity['topCandidate'] as Map)
        : const <String, dynamic>{};
    TimelineParking? parking;
    if (activity['parking'] is Map) {
      final p = Map<String, dynamic>.from(activity['parking'] as Map);
      final loc = p['location'] is Map
          ? parseLatLng((p['location'] as Map)['latLng'])
          : parseLatLng(p['location']);
      final time = _parseTime(p['startTime']);
      if (loc != null && time != null) {
        parking = TimelineParking(location: loc, startAt: time);
      }
    }
    return TimelineActivity(
      startAt: startAt,
      endAt: endAt,
      startOffsetMinutes: startOff,
      endOffsetMinutes: endOff,
      startLocation: activity['start'] is Map
          ? parseLatLng((activity['start'] as Map)['latLng'])
          : null,
      endLocation: activity['end'] is Map
          ? parseLatLng((activity['end'] as Map)['latLng'])
          : null,
      distanceMeters: _asDouble(activity['distanceMeters']),
      probability: _asDouble(activity['probability']),
      activityType: top['type'] as String?,
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
  ) {
    final points = <TimelinePathPoint>[];
    for (final p in rawPoints) {
      if (p is! Map) continue;
      final point = parseLatLng(p['point']);
      if (point == null) continue;
      final explicit = _parseTime(p['time']);
      final offset = _asInt(p['durationMinutesOffsetFromStartTime']);
      final time = explicit ??
          (offset != null
              ? startAt.add(Duration(minutes: offset))
              : startAt);
      points.add(TimelinePathPoint(point: point, time: time));
    }
    return TimelinePathSegment(
      startAt: startAt,
      endAt: endAt,
      startOffsetMinutes: startOff,
      endOffsetMinutes: endOff,
      points: points,
    );
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
}
