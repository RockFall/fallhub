import 'package:equatable/equatable.dart';

import 'id_generator.dart';

class GeoPoint extends Equatable {
  const GeoPoint(this.latitude, this.longitude);

  final double latitude;
  final double longitude;

  @override
  List<Object?> get props => [latitude, longitude];
}

class TimelinePathPoint extends Equatable {
  const TimelinePathPoint({required this.point, required this.time});

  final GeoPoint point;
  final DateTime time;

  @override
  List<Object?> get props => [point, time];
}

class TimelinePathSegment extends Equatable {
  const TimelinePathSegment({
    required this.startAt,
    required this.endAt,
    this.startOffsetMinutes,
    this.endOffsetMinutes,
    required this.points,
  });

  final DateTime startAt;
  final DateTime endAt;
  final int? startOffsetMinutes;
  final int? endOffsetMinutes;
  final List<TimelinePathPoint> points;

  @override
  List<Object?> get props =>
      [startAt, endAt, startOffsetMinutes, endOffsetMinutes, points];
}

class TimelineVisit extends Equatable {
  const TimelineVisit({
    required this.startAt,
    required this.endAt,
    this.startOffsetMinutes,
    this.endOffsetMinutes,
    this.placeId,
    this.semanticType,
    this.location,
    this.probability,
    this.candidateProbability,
    this.hierarchyLevel = 0,
    this.isTimeless = false,
  });

  final DateTime startAt;
  final DateTime endAt;
  final int? startOffsetMinutes;
  final int? endOffsetMinutes;
  final String? placeId;
  final String? semanticType;
  final GeoPoint? location;
  final double? probability;
  final double? candidateProbability;
  final int hierarchyLevel;
  final bool isTimeless;

  Duration get duration => endAt.difference(startAt);

  @override
  List<Object?> get props => [
        startAt,
        endAt,
        startOffsetMinutes,
        endOffsetMinutes,
        placeId,
        semanticType,
        location,
        probability,
        candidateProbability,
        hierarchyLevel,
        isTimeless,
      ];
}

class TimelineParking extends Equatable {
  const TimelineParking({required this.location, required this.startAt});

  final GeoPoint location;
  final DateTime startAt;

  @override
  List<Object?> get props => [location, startAt];
}

class TimelineActivity extends Equatable {
  const TimelineActivity({
    required this.startAt,
    required this.endAt,
    this.startOffsetMinutes,
    this.endOffsetMinutes,
    this.startLocation,
    this.endLocation,
    this.distanceMeters,
    this.probability,
    this.activityType,
    this.candidateProbability,
    this.parking,
  });

  final DateTime startAt;
  final DateTime endAt;
  final int? startOffsetMinutes;
  final int? endOffsetMinutes;
  final GeoPoint? startLocation;
  final GeoPoint? endLocation;
  final double? distanceMeters;
  final double? probability;
  final String? activityType;
  final double? candidateProbability;
  final TimelineParking? parking;

  Duration get duration => endAt.difference(startAt);

  @override
  List<Object?> get props => [
        startAt,
        endAt,
        startOffsetMinutes,
        endOffsetMinutes,
        startLocation,
        endLocation,
        distanceMeters,
        probability,
        activityType,
        candidateProbability,
        parking,
      ];
}

class TimelineMemoryTrip extends Equatable {
  const TimelineMemoryTrip({
    required this.startAt,
    required this.endAt,
    this.distanceFromOriginKms,
    this.destinationPlaceIds = const [],
  });

  final DateTime startAt;
  final DateTime endAt;
  final int? distanceFromOriginKms;
  final List<String> destinationPlaceIds;

  Duration get duration => endAt.difference(startAt);

  @override
  List<Object?> get props =>
      [startAt, endAt, distanceFromOriginKms, destinationPlaceIds];
}

class TimelineMemoryNote extends Equatable {
  const TimelineMemoryNote({
    required this.startAt,
    required this.endAt,
    required this.text,
  });

  final DateTime startAt;
  final DateTime endAt;
  final String text;

  @override
  List<Object?> get props => [startAt, endAt, text];
}

class TimelineFrequentPlace extends Equatable {
  const TimelineFrequentPlace({
    this.placeId,
    this.location,
    this.label,
  });

  final String? placeId;
  final GeoPoint? location;
  final String? label;

  @override
  List<Object?> get props => [placeId, location, label];
}

class TimelineModeAffinity extends Equatable {
  const TimelineModeAffinity({required this.mode, required this.affinity});

  final String mode;
  final double affinity;

  @override
  List<Object?> get props => [mode, affinity];
}

class TimelineRawPosition extends Equatable {
  const TimelineRawPosition({
    required this.location,
    required this.timestamp,
    this.accuracyMeters,
    this.altitudeMeters,
    this.source,
    this.speedMetersPerSecond,
  });

  final GeoPoint location;
  final DateTime timestamp;
  final double? accuracyMeters;
  final double? altitudeMeters;
  final String? source;
  final double? speedMetersPerSecond;

  @override
  List<Object?> get props => [
        location,
        timestamp,
        accuracyMeters,
        altitudeMeters,
        source,
        speedMetersPerSecond,
      ];
}

class TimelineSensorActivity extends Equatable {
  const TimelineSensorActivity({
    required this.timestamp,
    required this.activities,
  });

  final DateTime timestamp;
  final List<({String type, double confidence})> activities;

  String? get topType => activities.isEmpty ? null : activities.first.type;

  @override
  List<Object?> get props => [timestamp, activities];
}

class GoogleTimelineDocument extends Equatable {
  const GoogleTimelineDocument({
    this.visits = const [],
    this.activities = const [],
    this.paths = const [],
    this.trips = const [],
    this.notes = const [],
    this.frequentPlaces = const [],
    this.affinities = const [],
    this.positions = const [],
    this.sensorActivities = const [],
  });

  final List<TimelineVisit> visits;
  final List<TimelineActivity> activities;
  final List<TimelinePathSegment> paths;
  final List<TimelineMemoryTrip> trips;
  final List<TimelineMemoryNote> notes;
  final List<TimelineFrequentPlace> frequentPlaces;
  final List<TimelineModeAffinity> affinities;
  final List<TimelineRawPosition> positions;
  final List<TimelineSensorActivity> sensorActivities;

  bool get isEmpty =>
      visits.isEmpty &&
      activities.isEmpty &&
      paths.isEmpty &&
      trips.isEmpty &&
      notes.isEmpty &&
      frequentPlaces.isEmpty;

  int get segmentCount =>
      visits.length + activities.length + paths.length + trips.length;

  Map<String, dynamic> toJson() => {
        'visits': visits.map(_visitJson).toList(),
        'activities': activities.map(_activityJson).toList(),
        'paths': paths.map(_pathJson).toList(),
        'trips': trips.map(_tripJson).toList(),
        'notes': notes
            .map(
              (n) => {
                'start_at': n.startAt.toUtc().toIso8601String(),
                'end_at': n.endAt.toUtc().toIso8601String(),
                'text': n.text,
              },
            )
            .toList(),
        'frequent_places': frequentPlaces
            .map(
              (p) => {
                if (p.placeId != null) 'place_id': p.placeId,
                if (p.location != null) 'lat': p.location!.latitude,
                if (p.location != null) 'lng': p.location!.longitude,
                if (p.label != null) 'label': p.label,
              },
            )
            .toList(),
        'affinities': affinities
            .map((a) => {'mode': a.mode, 'affinity': a.affinity})
            .toList(),
        'positions': positions.map(_positionJson).toList(),
        'sensor_activities': sensorActivities
            .map(
              (s) => {
                'timestamp': s.timestamp.toUtc().toIso8601String(),
                'activities': s.activities
                    .map((a) => {'type': a.type, 'confidence': a.confidence})
                    .toList(),
              },
            )
            .toList(),
      };

  factory GoogleTimelineDocument.fromJson(Map<String, dynamic> json) {
    GeoPoint? point(Object? lat, Object? lng) {
      if (lat is num && lng is num) {
        return GeoPoint(lat.toDouble(), lng.toDouble());
      }
      return null;
    }

    DateTime dt(Object? raw) => DateTime.parse(raw! as String).toUtc();

    return GoogleTimelineDocument(
      visits: [
        for (final item in (json['visits'] as List? ?? const []))
          if (item is Map<String, dynamic>)
            TimelineVisit(
              startAt: dt(item['start_at']),
              endAt: dt(item['end_at']),
              startOffsetMinutes: (item['start_offset'] as num?)?.toInt(),
              endOffsetMinutes: (item['end_offset'] as num?)?.toInt(),
              placeId: item['place_id'] as String?,
              semanticType: item['semantic_type'] as String?,
              location: point(item['lat'], item['lng']),
              probability: (item['probability'] as num?)?.toDouble(),
              candidateProbability:
                  (item['candidate_probability'] as num?)?.toDouble(),
              hierarchyLevel: (item['hierarchy_level'] as num?)?.toInt() ?? 0,
              isTimeless: item['is_timeless'] == true,
            ),
      ],
      activities: [
        for (final item in (json['activities'] as List? ?? const []))
          if (item is Map<String, dynamic>)
            TimelineActivity(
              startAt: dt(item['start_at']),
              endAt: dt(item['end_at']),
              startOffsetMinutes: (item['start_offset'] as num?)?.toInt(),
              endOffsetMinutes: (item['end_offset'] as num?)?.toInt(),
              startLocation: point(item['start_lat'], item['start_lng']),
              endLocation: point(item['end_lat'], item['end_lng']),
              distanceMeters: (item['distance_meters'] as num?)?.toDouble(),
              probability: (item['probability'] as num?)?.toDouble(),
              activityType: item['activity_type'] as String?,
              candidateProbability:
                  (item['candidate_probability'] as num?)?.toDouble(),
              parking: item['parking_lat'] is num
                  ? TimelineParking(
                      location: GeoPoint(
                        (item['parking_lat'] as num).toDouble(),
                        (item['parking_lng'] as num).toDouble(),
                      ),
                      startAt: dt(item['parking_start_at']),
                    )
                  : null,
            ),
      ],
      paths: [
        for (final item in (json['paths'] as List? ?? const []))
          if (item is Map<String, dynamic>)
            TimelinePathSegment(
              startAt: dt(item['start_at']),
              endAt: dt(item['end_at']),
              startOffsetMinutes: (item['start_offset'] as num?)?.toInt(),
              endOffsetMinutes: (item['end_offset'] as num?)?.toInt(),
              points: [
                for (final p in (item['points'] as List? ?? const []))
                  if (p is Map<String, dynamic> &&
                      p['lat'] is num &&
                      p['lng'] is num)
                    TimelinePathPoint(
                      point: GeoPoint(
                        (p['lat'] as num).toDouble(),
                        (p['lng'] as num).toDouble(),
                      ),
                      time: dt(p['time']),
                    ),
              ],
            ),
      ],
      trips: [
        for (final item in (json['trips'] as List? ?? const []))
          if (item is Map<String, dynamic>)
            TimelineMemoryTrip(
              startAt: dt(item['start_at']),
              endAt: dt(item['end_at']),
              distanceFromOriginKms:
                  (item['distance_from_origin_kms'] as num?)?.toInt(),
              destinationPlaceIds: [
                for (final id in (item['destination_place_ids'] as List? ??
                    const []))
                  id.toString(),
              ],
            ),
      ],
      notes: [
        for (final item in (json['notes'] as List? ?? const []))
          if (item is Map<String, dynamic>)
            TimelineMemoryNote(
              startAt: dt(item['start_at']),
              endAt: dt(item['end_at']),
              text: (item['text'] as String?) ?? '',
            ),
      ],
      frequentPlaces: [
        for (final item in (json['frequent_places'] as List? ?? const []))
          if (item is Map<String, dynamic>)
            TimelineFrequentPlace(
              placeId: item['place_id'] as String?,
              location: point(item['lat'], item['lng']),
              label: item['label'] as String?,
            ),
      ],
      affinities: [
        for (final item in (json['affinities'] as List? ?? const []))
          if (item is Map<String, dynamic>)
            TimelineModeAffinity(
              mode: (item['mode'] as String?) ?? 'UNKNOWN',
              affinity: (item['affinity'] as num?)?.toDouble() ?? 0,
            ),
      ],
      positions: [
        for (final item in (json['positions'] as List? ?? const []))
          if (item is Map<String, dynamic>)
            TimelineRawPosition(
              location: point(item['lat'], item['lng']) ?? const GeoPoint(0, 0),
              timestamp: dt(item['timestamp']),
              accuracyMeters: (item['accuracy_meters'] as num?)?.toDouble(),
              altitudeMeters: (item['altitude_meters'] as num?)?.toDouble(),
              source: item['source'] as String?,
              speedMetersPerSecond:
                  (item['speed_meters_per_second'] as num?)?.toDouble(),
            ),
      ],
      sensorActivities: [
        for (final item in (json['sensor_activities'] as List? ?? const []))
          if (item is Map<String, dynamic>)
            TimelineSensorActivity(
              timestamp: dt(item['timestamp']),
              activities: [
                for (final a in (item['activities'] as List? ?? const []))
                  if (a is Map<String, dynamic>)
                    (
                      type: (a['type'] as String?) ?? 'UNKNOWN',
                      confidence: (a['confidence'] as num?)?.toDouble() ?? 0,
                    ),
              ],
            ),
      ],
    );
  }

  static Map<String, dynamic> _visitJson(TimelineVisit v) => {
        'start_at': v.startAt.toUtc().toIso8601String(),
        'end_at': v.endAt.toUtc().toIso8601String(),
        if (v.startOffsetMinutes != null) 'start_offset': v.startOffsetMinutes,
        if (v.endOffsetMinutes != null) 'end_offset': v.endOffsetMinutes,
        if (v.placeId != null) 'place_id': v.placeId,
        if (v.semanticType != null) 'semantic_type': v.semanticType,
        if (v.location != null) 'lat': v.location!.latitude,
        if (v.location != null) 'lng': v.location!.longitude,
        if (v.probability != null) 'probability': v.probability,
        if (v.candidateProbability != null)
          'candidate_probability': v.candidateProbability,
        'hierarchy_level': v.hierarchyLevel,
        'is_timeless': v.isTimeless,
      };

  static Map<String, dynamic> _activityJson(TimelineActivity a) => {
        'start_at': a.startAt.toUtc().toIso8601String(),
        'end_at': a.endAt.toUtc().toIso8601String(),
        if (a.startOffsetMinutes != null) 'start_offset': a.startOffsetMinutes,
        if (a.endOffsetMinutes != null) 'end_offset': a.endOffsetMinutes,
        if (a.startLocation != null) 'start_lat': a.startLocation!.latitude,
        if (a.startLocation != null) 'start_lng': a.startLocation!.longitude,
        if (a.endLocation != null) 'end_lat': a.endLocation!.latitude,
        if (a.endLocation != null) 'end_lng': a.endLocation!.longitude,
        if (a.distanceMeters != null) 'distance_meters': a.distanceMeters,
        if (a.probability != null) 'probability': a.probability,
        if (a.activityType != null) 'activity_type': a.activityType,
        if (a.candidateProbability != null)
          'candidate_probability': a.candidateProbability,
        if (a.parking != null) 'parking_lat': a.parking!.location.latitude,
        if (a.parking != null) 'parking_lng': a.parking!.location.longitude,
        if (a.parking != null)
          'parking_start_at': a.parking!.startAt.toUtc().toIso8601String(),
      };

  static Map<String, dynamic> _pathJson(TimelinePathSegment p) => {
        'start_at': p.startAt.toUtc().toIso8601String(),
        'end_at': p.endAt.toUtc().toIso8601String(),
        if (p.startOffsetMinutes != null) 'start_offset': p.startOffsetMinutes,
        if (p.endOffsetMinutes != null) 'end_offset': p.endOffsetMinutes,
        'points': [
          for (final pt in p.points)
            {
              'lat': pt.point.latitude,
              'lng': pt.point.longitude,
              'time': pt.time.toUtc().toIso8601String(),
            },
        ],
      };

  static Map<String, dynamic> _tripJson(TimelineMemoryTrip t) => {
        'start_at': t.startAt.toUtc().toIso8601String(),
        'end_at': t.endAt.toUtc().toIso8601String(),
        if (t.distanceFromOriginKms != null)
          'distance_from_origin_kms': t.distanceFromOriginKms,
        'destination_place_ids': t.destinationPlaceIds,
      };

  static Map<String, dynamic> _positionJson(TimelineRawPosition p) => {
        'lat': p.location.latitude,
        'lng': p.location.longitude,
        'timestamp': p.timestamp.toUtc().toIso8601String(),
        if (p.accuracyMeters != null) 'accuracy_meters': p.accuracyMeters,
        if (p.altitudeMeters != null) 'altitude_meters': p.altitudeMeters,
        if (p.source != null) 'source': p.source,
        if (p.speedMetersPerSecond != null)
          'speed_meters_per_second': p.speedMetersPerSecond,
      };

  @override
  List<Object?> get props => [
        visits,
        activities,
        paths,
        trips,
        notes,
        frequentPlaces,
        affinities,
        positions,
        sensorActivities,
      ];
}

class GoogleTimelineImport extends Equatable {
  const GoogleTimelineImport({
    required this.id,
    required this.profileId,
    required this.fileName,
    required this.importedAt,
    required this.document,
  });

  final EntityId id;
  final EntityId profileId;
  final String fileName;
  final DateTime importedAt;
  final GoogleTimelineDocument document;

  @override
  List<Object?> get props => [id, profileId, fileName, importedAt, document];
}

enum TimelinePlaceCategory {
  home,
  work,
  gastronomy,
  shopping,
  hotels,
  culture,
  attractions,
  airports,
  transit,
  other,
}

class TimelinePlaceLabel extends Equatable {
  const TimelinePlaceLabel({
    required this.placeId,
    required this.category,
    this.customName,
  });

  final String placeId;
  final TimelinePlaceCategory category;
  final String? customName;

  @override
  List<Object?> get props => [placeId, category, customName];
}
