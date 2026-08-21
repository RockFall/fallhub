import 'package:colony_domain/colony_domain.dart';
import 'package:test/test.dart';

const sample = r'''
{
  "semanticSegments": [
    {
      "startTime": "2026-08-20T08:00:00.000+08:00",
      "endTime": "2026-08-20T10:00:00.000+08:00",
      "startTimeTimezoneUtcOffsetMinutes": 480,
      "endTimeTimezoneUtcOffsetMinutes": 480,
      "timelinePath": [
        {
          "point": "31.2304160°, 121.4737010°",
          "time": "2026-08-20T08:12:15.000+08:00"
        },
        {
          "point": "31.2312000°, 121.4755000°",
          "time": "2026-08-20T08:24:31.000+08:00"
        }
      ]
    },
    {
      "startTime": "2026-08-20T10:00:00.000+08:00",
      "endTime": "2026-08-20T12:00:00.000+08:00",
      "timelinePath": [
        {
          "point": "31.2331000°, 121.4789000°",
          "durationMinutesOffsetFromStartTime": "5"
        },
        {
          "point": "31.2250000°, 121.4900000°",
          "durationMinutesOffsetFromStartTime": "23"
        }
      ]
    },
    {
      "startTime": "2026-08-20T08:10:43.257+08:00",
      "endTime": "2026-08-20T09:35:12.118+08:00",
      "visit": {
        "hierarchyLevel": 0,
        "probability": 0.94,
        "topCandidate": {
          "placeId": "ChIJ_SAMPLE_PLACE_ID_001",
          "semanticType": "UNKNOWN",
          "probability": 0.87,
          "placeLocation": { "latLng": "31.2304160°, 121.4737010°" }
        },
        "isTimelessVisit": false
      }
    },
    {
      "startTime": "2026-08-20T08:10:43.257+08:00",
      "endTime": "2026-08-20T09:35:12.118+08:00",
      "visit": {
        "hierarchyLevel": 1,
        "probability": 0.76,
        "topCandidate": {
          "placeId": "ChIJ_SAMPLE_NESTED_PLACE_ID",
          "semanticType": "UNKNOWN",
          "probability": 0.68,
          "placeLocation": { "latLng": "31.2305000°, 121.4738500°" }
        }
      }
    },
    {
      "startTime": "2026-08-20T09:35:12.118+08:00",
      "endTime": "2026-08-20T10:04:51.441+08:00",
      "activity": {
        "start": { "latLng": "31.2304160°, 121.4737010°" },
        "end": { "latLng": "31.2180000°, 121.5050000°" },
        "distanceMeters": 4278.4,
        "probability": 0.97,
        "topCandidate": { "type": "IN_PASSENGER_VEHICLE", "probability": 0.93 }
      }
    },
    {
      "startTime": "2026-08-20T10:04:51.441+08:00",
      "endTime": "2026-08-20T10:18:22.784+08:00",
      "activity": {
        "start": { "latLng": "31.2180000°, 121.5050000°" },
        "end": { "latLng": "31.2155000°, 121.5092000°" },
        "distanceMeters": 731.2,
        "probability": 0.98,
        "topCandidate": { "type": "WALKING", "probability": 0.96 }
      }
    },
    {
      "startTime": "2026-08-20T14:10:00.000+08:00",
      "endTime": "2026-08-20T14:40:00.000+08:00",
      "activity": {
        "start": { "latLng": "31.2155000°, 121.5092000°" },
        "end": { "latLng": "31.2400000°, 121.5200000°" },
        "distanceMeters": 5634.8,
        "topCandidate": { "type": "IN_PASSENGER_VEHICLE", "probability": 0.91 },
        "parking": {
          "location": { "latLng": "31.2400000°, 121.5200000°" },
          "startTime": "2026-08-20T14:40:00.000+08:00"
        }
      }
    },
    {
      "startTime": "2026-08-18T00:00:00.000+08:00",
      "endTime": "2026-08-22T23:59:59.999+08:00",
      "timelineMemory": {
        "trip": {
          "destinations": [
            { "identifier": { "placeId": "ChIJ_SAMPLE_DESTINATION_SHANGHAI" } },
            { "identifier": { "placeId": "ChIJ_SAMPLE_DESTINATION_SUZHOU" } }
          ],
          "distanceFromOriginKms": 1842
        }
      }
    },
    {
      "startTime": "2026-08-20T18:00:00.000+08:00",
      "endTime": "2026-08-20T23:00:00.000+08:00",
      "timelineMemory": {
        "note": { "note": "Sample timeline memory note" }
      }
    }
  ],
  "rawSignals": [
    {
      "position": {
        "LatLng": "31.2304160°, 121.4737010°",
        "accuracyMeters": 7,
        "source": "GPS",
        "timestamp": "2026-08-20T08:12:15.347+08:00",
        "speedMetersPerSecond": 1.28
      }
    },
    {
      "wifiScan": {
        "deliveryTime": "2026-08-20T08:24:32.000+08:00",
        "devicesRecords": [{ "mac": 70474800562644, "rawRssi": -43 }]
      }
    },
    {
      "activityRecord": {
        "probableActivities": [
          { "type": "ON_FOOT", "confidence": 0.95 },
          { "type": "STILL", "confidence": 0.03 }
        ],
        "timestamp": "2026-08-20T08:27:10.442+08:00"
      }
    }
  ],
  "userLocationProfile": {
    "persona": {
      "travelModeAffinities": [
        { "mode": "WALKING", "affinity": 0.82 },
        { "mode": "DRIVING", "affinity": 0.66 }
      ]
    },
    "frequentPlaces": [
      {
        "placeId": "ChIJ_SAMPLE_HOME_PLACE",
        "placeLocation": "31.2200000°, 121.4600000°",
        "label": "HOME"
      },
      {
        "placeId": "ChIJ_SAMPLE_WORK_PLACE",
        "placeLocation": "31.2400000°, 121.5000000°",
        "label": "WORK"
      }
    ]
  }
}
''';

void main() {
  test('parses on-device Timeline sample', () {
    final doc = GoogleTimelineCodec.parse(sample, includeRawSignals: true);
    expect(doc.visits, hasLength(2));
    expect(doc.visits.first.hierarchyLevel, 0);
    expect(doc.visits.last.hierarchyLevel, 1);
    expect(doc.activities, hasLength(3));
    expect(doc.activities.first.activityType, 'IN_PASSENGER_VEHICLE');
    expect(doc.activities[1].activityType, 'WALKING');
    expect(doc.activities.last.parking, isNotNull);
    expect(doc.paths, hasLength(2));
    expect(
      doc.paths.last.points.first.time.isAfter(doc.paths.last.startAt),
      isTrue,
    );
    expect(doc.trips, hasLength(1));
    expect(doc.trips.single.distanceFromOriginKms, 1842);
    expect(doc.trips.single.destinationPlaceIds, hasLength(2));
    expect(doc.notes.single.text, 'Sample timeline memory note');
    expect(doc.frequentPlaces, hasLength(2));
    expect(doc.affinities.first.mode, 'WALKING');
    expect(doc.positions, hasLength(1));
    expect(doc.sensorActivities, hasLength(1));
  });

  test('round-trips normalized document JSON', () {
    final doc = GoogleTimelineCodec.parse(sample, includeRawSignals: true);
    final again = GoogleTimelineDocument.fromJson(doc.toJson());
    expect(again.visits.length, doc.visits.length);
    expect(again.activities.length, doc.activities.length);
    expect(again.trips.single.distanceFromOriginKms, 1842);
  });

  test('analytics resolve Shanghai and transport mix', () {
    final doc = GoogleTimelineCodec.parse(sample);
    final insights = GoogleTimelineAnalytics.analyze(doc);
    expect(insights.cities, isNotEmpty);
    expect(insights.cities.first.city.name, 'Xangai');
    expect(insights.countries.first.countryCode, 'CN');
    expect(insights.driveKm, greaterThan(9));
    expect(insights.walkKm, closeTo(0.7312, 0.01));
    expect(insights.parking, hasLength(1));
    expect(insights.hourHeatmapMinutes, hasLength(168));
    expect(insights.hourHeatmapMinutes.any((m) => m > 0), isTrue);
    expect(insights.visitHoursByMonth, isNotEmpty);
  });

  test('rejects empty and Records.json', () {
    expect(() => GoogleTimelineCodec.parse('{}'), throwsFormatException);
    expect(
      () => GoogleTimelineCodec.parse('{"locations":[]}'),
      throwsFormatException,
    );
  });

  test('default parse drops rawSignals and still keeps visits', () {
    final doc = GoogleTimelineCodec.parse(sample);
    expect(doc.visits, hasLength(2));
    expect(doc.activities, hasLength(3));
    expect(doc.positions, isEmpty);
    expect(doc.sensorActivities, isEmpty);
  });

  test('stripRawSignals omits GPS array before decode', () {
    final stripped = GoogleTimelineCodec.stripRawSignals(sample);
    expect(stripped.contains('"rawSignals"'), isFalse);
    expect(stripped.contains('"semanticSegments"'), isTrue);
    final doc = GoogleTimelineCodec.parse(stripped, includeRawSignals: true);
    expect(doc.positions, isEmpty);
    expect(doc.visits, hasLength(2));
  });

  test('parseToJson is isolate-safe maps and lists', () {
    final json = GoogleTimelineCodec.parseToJson(sample);
    expect(json['visits'], isA<List>());
    expect(json['activities'], isA<List>());
    final again = GoogleTimelineDocument.fromJson(json);
    expect(again.visits, hasLength(2));
  });

  test('non-string placeId does not throw', () {
    const weird = '''
{
  "semanticSegments": [
    {
      "startTime": "2026-08-20T08:00:00.000Z",
      "endTime": "2026-08-20T09:00:00.000Z",
      "visit": {
        "topCandidate": {
          "placeId": {"id": "not-a-string"},
          "semanticType": 1,
          "placeLocation": { "latLng": "-19.91°, -43.93°" }
        }
      }
    }
  ]
}
''';
    final doc = GoogleTimelineCodec.parse(weird);
    expect(doc.visits, hasLength(1));
    expect(doc.visits.single.placeId, isNull);
    expect(doc.visits.single.semanticType, isNull);
    expect(doc.visits.single.location, isNotNull);
  });
}
