import 'city_gazetteer.dart';
import 'google_timeline.dart';

class TransportBucket {
  const TransportBucket({
    required this.id,
    required this.meters,
    required this.duration,
    required this.legs,
  });

  final String id;
  final double meters;
  final Duration duration;
  final int legs;

  double get km => meters / 1000;
}

class MonthTransportStats {
  const MonthTransportStats({required this.yearMonth, required this.buckets});

  final String yearMonth;
  final Map<String, TransportBucket> buckets;
}

class PlaceRollup {
  const PlaceRollup({
    required this.key,
    this.placeId,
    this.location,
    required this.category,
    required this.visitCount,
    required this.total,
    required this.lastVisit,
    this.semanticType,
    this.customName,
    this.city,
    this.countryCode,
  });

  final String key;
  final String? placeId;
  final GeoPoint? location;
  final TimelinePlaceCategory category;
  final int visitCount;
  final Duration total;
  final DateTime lastVisit;
  final String? semanticType;
  final String? customName;
  final GazetteerCity? city;
  final String? countryCode;
}

class CityRollup {
  const CityRollup({
    required this.city,
    required this.placeCount,
    required this.visitCount,
    required this.total,
    required this.lastVisit,
  });

  final GazetteerCity city;
  final int placeCount;
  final int visitCount;
  final Duration total;
  final DateTime lastVisit;
}

class CountryRollup {
  const CountryRollup({
    required this.countryCode,
    required this.cityCount,
    required this.placeCount,
    required this.lastVisit,
  });

  final String countryCode;
  final int cityCount;
  final int placeCount;
  final DateTime lastVisit;
}

class DayItem {
  const DayItem({
    required this.startAt,
    required this.endAt,
    required this.kind,
    required this.title,
    this.subtitle,
    this.mode,
    this.category,
    this.location,
    this.distanceMeters,
    this.probability,
    this.hierarchyLevel = 0,
    this.placeId,
  });

  final DateTime startAt;
  final DateTime endAt;
  final String kind; // visit | activity | path | note | parking
  final String title;
  final String? subtitle;
  final String? mode;
  final TimelinePlaceCategory? category;
  final GeoPoint? location;
  final double? distanceMeters;
  final double? probability;
  final int hierarchyLevel;
  final String? placeId;
}

class MonthVisitStats {
  const MonthVisitStats({
    required this.yearMonth,
    required this.total,
    required this.visits,
  });

  final String yearMonth;
  final Duration total;
  final int visits;
}

class TimelineInsights {
  const TimelineInsights({
    required this.document,
    required this.labels,
    required this.places,
    required this.cities,
    required this.countries,
    required this.transportByMonth,
    required this.visitHoursByMonth,
    required this.categoryHours,
    required this.parking,
    required this.nightsAway,
    required this.radiusKm,
    required this.homeHours,
    required this.workHours,
    required this.walkKm,
    required this.driveKm,
    required this.transitKm,
    required this.flyKm,
    required this.cyclingKm,
    required this.otherKm,
    required this.actualModeShare,
    required this.gaps,
    required this.implausibleLegs,
    required this.hourHeatmapMinutes,
    required this.commuteDays,
    this.firstAt,
    this.lastAt,
  });

  final GoogleTimelineDocument document;
  final Map<String, TimelinePlaceLabel> labels;
  final List<PlaceRollup> places;
  final List<CityRollup> cities;
  final List<CountryRollup> countries;
  final List<MonthTransportStats> transportByMonth;
  final List<MonthVisitStats> visitHoursByMonth;
  final Map<TimelinePlaceCategory, Duration> categoryHours;
  final List<TimelineParking> parking;
  final int nightsAway;
  final double radiusKm;
  final Duration homeHours;
  final Duration workHours;
  final double walkKm;
  final double driveKm;
  final double transitKm;
  final double flyKm;
  final double cyclingKm;
  final double otherKm;
  final Map<String, double> actualModeShare;
  final int gaps;
  final int implausibleLegs;

  /// 7 weekdays × 24 hours of visit minutes (Monday = 0).
  final List<int> hourHeatmapMinutes;
  final int commuteDays;
  final DateTime? firstAt;
  final DateTime? lastAt;

  int get placeCount => places.length;
  int get cityCount => cities.length;
  int get countryCount => countries.length;
  double get totalKm =>
      walkKm + driveKm + transitKm + flyKm + cyclingKm + otherKm;
}

abstract final class GoogleTimelineAnalytics {
  static const walkingTypes = {
    'WALKING',
    'WALKING_NORDIC',
    'RUNNING',
    'HIKING',
    'ON_FOOT',
  };
  static const drivingTypes = {
    'IN_PASSENGER_VEHICLE',
    'IN_TAXI',
    'MOTORCYCLING',
    'IN_VEHICLE',
    'IN_ROAD_VEHICLE',
    'DRIVING',
  };
  static const transitTypes = {
    'IN_BUS',
    'IN_TRAIN',
    'IN_SUBWAY',
    'IN_TRAM',
    'IN_FERRY',
    'IN_CABLECAR',
    'IN_FUNICULAR',
    'IN_GONDOLA_LIFT',
    'TRANSIT',
  };
  static const flyingTypes = {'FLYING'};

  static String transportBucket(String? type) {
    final t = (type ?? '').toUpperCase();
    if (walkingTypes.contains(t)) return 'walking';
    if (drivingTypes.contains(t)) return 'driving';
    if (transitTypes.contains(t)) return 'transit';
    if (flyingTypes.contains(t)) return 'flying';
    if (t == 'CYCLING' || t == 'ON_BICYCLE') return 'cycling';
    if (t.isEmpty) return 'unknown';
    return 'other';
  }

  static GeoPoint? homeOf(GoogleTimelineDocument doc) {
    for (final p in doc.frequentPlaces) {
      if ((p.label ?? '').toUpperCase() == 'HOME' && p.location != null) {
        return p.location;
      }
    }
    for (final v in doc.visits) {
      if (_isHomeType(v.semanticType) && v.location != null) return v.location;
    }
    return null;
  }

  static bool _isHomeType(String? t) {
    final u = (t ?? '').toUpperCase();
    return u == 'HOME' || u == 'TYPE_HOME';
  }

  static bool _isWorkType(String? t) {
    final u = (t ?? '').toUpperCase();
    return u == 'WORK' || u == 'TYPE_WORK';
  }

  static List<GeoPoint> flyingAnchors(GoogleTimelineDocument doc) {
    final out = <GeoPoint>[];
    for (final a in doc.activities) {
      final type = a.activityType;
      if (type == null || !flyingTypes.contains(type.toUpperCase())) continue;
      if (a.startLocation != null) out.add(a.startLocation!);
      if (a.endLocation != null) out.add(a.endLocation!);
    }
    return out;
  }

  static TimelinePlaceCategory categoryFor(
    TimelineVisit visit, {
    required GoogleTimelineDocument doc,
    required Map<String, TimelinePlaceLabel> labels,
    GeoPoint? home,
    List<GeoPoint>? flyingAnchors,
  }) {
    final placeId = visit.placeId;
    if (placeId != null && labels[placeId] != null) {
      return labels[placeId]!.category;
    }
    if (_isHomeType(visit.semanticType)) return TimelinePlaceCategory.home;
    if (_isWorkType(visit.semanticType)) return TimelinePlaceCategory.work;
    for (final p in doc.frequentPlaces) {
      if (p.placeId != null && p.placeId == placeId) {
        final lab = (p.label ?? '').toUpperCase();
        if (lab == 'HOME') return TimelinePlaceCategory.home;
        if (lab == 'WORK') return TimelinePlaceCategory.work;
      }
    }
    final loc = visit.location;
    final anchors = flyingAnchors ?? GoogleTimelineAnalytics.flyingAnchors(doc);
    if (loc != null) {
      for (final anchor in anchors) {
        if (CityGazetteer.distanceKm(loc, anchor) < 3) {
          return TimelinePlaceCategory.airports;
        }
      }
    }
    final overnight =
        (visit.duration >= const Duration(hours: 8) &&
            visit.startAt.toUtc().hour >= 20) ||
        (visit.endAt.toUtc().hour <= 8 &&
            visit.duration >= const Duration(hours: 6));
    if (overnight &&
        home != null &&
        loc != null &&
        CityGazetteer.distanceKm(home, loc) > 30) {
      return TimelinePlaceCategory.hotels;
    }
    final minutes = visit.duration.inMinutes;
    final hour = visit.startAt.toLocal().hour;
    if (minutes >= 20 &&
        minutes <= 150 &&
        ((hour >= 11 && hour <= 15) || (hour >= 18 && hour <= 22))) {
      return TimelinePlaceCategory.gastronomy;
    }
    if (minutes >= 20 && minutes <= 180 && hour >= 10 && hour <= 19) {
      return TimelinePlaceCategory.shopping;
    }
    if (minutes >= 90) return TimelinePlaceCategory.culture;
    return TimelinePlaceCategory.other;
  }

  static TimelineInsights analyze(
    GoogleTimelineDocument doc, {
    Map<String, TimelinePlaceLabel> labels = const {},
  }) {
    final home = homeOf(doc);
    final flyAnchors = flyingAnchors(doc);
    final places = <String, PlaceRollup>{};
    var homeHours = Duration.zero;
    var workHours = Duration.zero;
    var nightsAway = 0;
    final categoryHours = <TimelinePlaceCategory, Duration>{};
    final heatmap = List<int>.filled(7 * 24, 0);
    final visitMonthAcc = <String, _VisitAcc>{};
    final homeDays = <String>{};
    final workDays = <String>{};
    DateTime? firstAt;
    DateTime? lastAt;

    void span(DateTime a, DateTime b) {
      if (firstAt == null || a.isBefore(firstAt!)) firstAt = a;
      if (lastAt == null || b.isAfter(lastAt!)) lastAt = b;
    }

    for (final visit in doc.visits) {
      span(visit.startAt, visit.endAt);
      final cat = categoryFor(
        visit,
        doc: doc,
        labels: labels,
        home: home,
        flyingAnchors: flyAnchors,
      );
      categoryHours[cat] =
          (categoryHours[cat] ?? Duration.zero) + visit.duration;
      if (cat == TimelinePlaceCategory.home) {
        homeHours += visit.duration;
        homeDays.add(_dayKey(visit.startAt));
      }
      if (cat == TimelinePlaceCategory.work) {
        workHours += visit.duration;
        workDays.add(_dayKey(visit.startAt));
      }
      if (cat == TimelinePlaceCategory.hotels) nightsAway += 1;
      final ym =
          '${visit.startAt.toUtc().year}-${visit.startAt.toUtc().month.toString().padLeft(2, '0')}';
      final vacc = visitMonthAcc.putIfAbsent(ym, _VisitAcc.new);
      vacc.total += visit.duration;
      vacc.visits += 1;
      _addHeat(heatmap, visit.startAt, visit.endAt);
      final key =
          visit.placeId ??
          (visit.location == null
              ? '${visit.startAt.toIso8601String()}'
              : '${visit.location!.latitude.toStringAsFixed(4)},${visit.location!.longitude.toStringAsFixed(4)}');
      final city = visit.location == null
          ? null
          : CityGazetteer.nearest(visit.location!);
      final existing = places[key];
      if (existing == null) {
        places[key] = PlaceRollup(
          key: key,
          placeId: visit.placeId,
          location: visit.location,
          category: cat,
          visitCount: 1,
          total: visit.duration,
          lastVisit: visit.endAt,
          semanticType: visit.semanticType,
          customName: visit.placeId == null
              ? null
              : labels[visit.placeId]?.customName,
          city: city,
          countryCode: city?.countryCode,
        );
      } else {
        places[key] = PlaceRollup(
          key: key,
          placeId: existing.placeId,
          location: existing.location ?? visit.location,
          category: existing.category,
          visitCount: existing.visitCount + 1,
          total: existing.total + visit.duration,
          lastVisit: visit.endAt.isAfter(existing.lastVisit)
              ? visit.endAt
              : existing.lastVisit,
          semanticType: existing.semanticType ?? visit.semanticType,
          customName: existing.customName,
          city: existing.city ?? city,
          countryCode: existing.countryCode ?? city?.countryCode,
        );
      }
    }

    final cityMap = <String, CityRollup>{};
    for (final place in places.values) {
      final city = place.city;
      if (city == null) continue;
      final k = '${city.name}|${city.countryCode}';
      final prev = cityMap[k];
      if (prev == null) {
        cityMap[k] = CityRollup(
          city: city,
          placeCount: 1,
          visitCount: place.visitCount,
          total: place.total,
          lastVisit: place.lastVisit,
        );
      } else {
        cityMap[k] = CityRollup(
          city: city,
          placeCount: prev.placeCount + 1,
          visitCount: prev.visitCount + place.visitCount,
          total: prev.total + place.total,
          lastVisit: place.lastVisit.isAfter(prev.lastVisit)
              ? place.lastVisit
              : prev.lastVisit,
        );
      }
    }

    final countryAcc = <String, List<CityRollup>>{};
    for (final c in cityMap.values) {
      countryAcc.putIfAbsent(c.city.countryCode, () => []).add(c);
    }
    final countries = [
      for (final e in countryAcc.entries)
        CountryRollup(
          countryCode: e.key,
          cityCount: e.value.length,
          placeCount: e.value.fold(0, (s, c) => s + c.placeCount),
          lastVisit: e.value
              .map((c) => c.lastVisit)
              .reduce((a, b) => a.isAfter(b) ? a : b),
        ),
    ]..sort((a, b) => b.lastVisit.compareTo(a.lastVisit));

    final monthBuckets = <String, Map<String, _Acc>>{};
    var walk = 0.0, drive = 0.0, transit = 0.0, fly = 0.0;
    var cycling = 0.0, other = 0.0;
    var implausible = 0;
    for (final a in doc.activities) {
      span(a.startAt, a.endAt);
      final bucket = transportBucket(a.activityType);
      final meters = a.distanceMeters ?? 0;
      if (bucket == 'walking') walk += meters;
      if (bucket == 'driving') drive += meters;
      if (bucket == 'transit') transit += meters;
      if (bucket == 'flying') fly += meters;
      if (bucket == 'cycling') cycling += meters;
      if (bucket == 'other' || bucket == 'unknown') other += meters;
      if (a.distanceMeters != null && a.duration.inSeconds > 0) {
        final kmh = (a.distanceMeters! / 1000) / (a.duration.inSeconds / 3600);
        if (bucket == 'walking' && kmh > 15) implausible += 1;
        if (bucket == 'flying' && kmh < 80 && a.duration.inMinutes > 20) {
          implausible += 1;
        }
      }
      final ym =
          '${a.startAt.toUtc().year}-${a.startAt.toUtc().month.toString().padLeft(2, '0')}';
      final map = monthBuckets.putIfAbsent(ym, () => {});
      final acc = map.putIfAbsent(bucket, () => _Acc());
      acc.meters += meters;
      acc.duration += a.duration;
      acc.legs += 1;
    }

    final transportByMonth = [
      for (final e
          in (monthBuckets.entries.toList()
            ..sort((a, b) => a.key.compareTo(b.key))))
        MonthTransportStats(
          yearMonth: e.key,
          buckets: {
            for (final b in e.value.entries)
              b.key: TransportBucket(
                id: b.key,
                meters: b.value.meters,
                duration: b.value.duration,
                legs: b.value.legs,
              ),
          },
        ),
    ];

    final totalMode = walk + drive + transit + fly + cycling + other;
    final share = <String, double>{
      'walking': totalMode == 0 ? 0 : walk / totalMode,
      'driving': totalMode == 0 ? 0 : drive / totalMode,
      'transit': totalMode == 0 ? 0 : transit / totalMode,
      'flying': totalMode == 0 ? 0 : fly / totalMode,
      'cycling': totalMode == 0 ? 0 : cycling / totalMode,
      'other': totalMode == 0 ? 0 : other / totalMode,
    };

    final visitHoursByMonth = [
      for (final e
          in (visitMonthAcc.entries.toList()
            ..sort((a, b) => a.key.compareTo(b.key))))
        MonthVisitStats(
          yearMonth: e.key,
          total: e.value.total,
          visits: e.value.visits,
        ),
    ];
    final commuteDays = homeDays.intersection(workDays).length;

    var radius = 0.0;
    if (home != null) {
      for (final v in doc.visits) {
        if (v.location == null) continue;
        final d = CityGazetteer.distanceKm(home, v.location!);
        if (d > radius) radius = d;
      }
    }

    var gaps = 0;
    final timed = [
      ...doc.visits.map((v) => (v.startAt, v.endAt)),
      ...doc.activities.map((a) => (a.startAt, a.endAt)),
    ]..sort((a, b) => a.$1.compareTo(b.$1));
    for (var i = 1; i < timed.length; i++) {
      final hole = timed[i].$1.difference(timed[i - 1].$2);
      if (hole > const Duration(hours: 2)) gaps += 1;
    }

    final parking = [
      for (final a in doc.activities)
        if (a.parking != null) a.parking!,
    ];

    final placeList = places.values.toList()
      ..sort((a, b) => b.total.compareTo(a.total));
    final cityList = cityMap.values.toList()
      ..sort((a, b) => b.lastVisit.compareTo(a.lastVisit));

    return TimelineInsights(
      document: doc,
      labels: labels,
      places: placeList,
      cities: cityList,
      countries: countries,
      transportByMonth: transportByMonth,
      visitHoursByMonth: visitHoursByMonth,
      categoryHours: categoryHours,
      parking: parking,
      nightsAway: nightsAway,
      radiusKm: radius,
      homeHours: homeHours,
      workHours: workHours,
      walkKm: walk / 1000,
      driveKm: drive / 1000,
      transitKm: transit / 1000,
      flyKm: fly / 1000,
      cyclingKm: cycling / 1000,
      otherKm: other / 1000,
      actualModeShare: share,
      gaps: gaps,
      implausibleLegs: implausible,
      hourHeatmapMinutes: heatmap,
      commuteDays: commuteDays,
      firstAt: firstAt,
      lastAt: lastAt,
    );
  }

  static String _dayKey(DateTime t) {
    final u = t.toUtc();
    return '${u.year}-${u.month.toString().padLeft(2, '0')}-${u.day.toString().padLeft(2, '0')}';
  }

  static void _addHeat(List<int> heatmap, DateTime start, DateTime end) {
    var cursor = start.toUtc();
    final stop = end.toUtc();
    if (!cursor.isBefore(stop)) return;
    var guard = 0;
    while (cursor.isBefore(stop) && guard < 24 * 14) {
      guard += 1;
      final nextHour = DateTime.utc(
        cursor.year,
        cursor.month,
        cursor.day,
        cursor.hour,
      ).add(const Duration(hours: 1));
      final sliceEnd = nextHour.isBefore(stop) ? nextHour : stop;
      final minutes = sliceEnd.difference(cursor).inMinutes;
      if (minutes > 0) {
        final weekday = cursor.weekday - 1; // Monday = 0
        final idx = weekday * 24 + cursor.hour;
        if (idx >= 0 && idx < heatmap.length) {
          heatmap[idx] += minutes;
        }
      }
      cursor = sliceEnd;
    }
  }

  static List<DayItem> dayItems(
    GoogleTimelineDocument doc,
    DateTime dayUtc, {
    Map<String, TimelinePlaceLabel> labels = const {},
  }) {
    final start = DateTime.utc(dayUtc.year, dayUtc.month, dayUtc.day);
    final end = start.add(const Duration(days: 1));
    bool overlaps(DateTime a, DateTime b) =>
        a.isBefore(end) && b.isAfter(start);
    final items = <DayItem>[];
    final flyAnchors = flyingAnchors(doc);

    for (final v in doc.visits) {
      if (!overlaps(v.startAt, v.endAt)) continue;
      final cat = categoryFor(
        v,
        doc: doc,
        labels: labels,
        flyingAnchors: flyAnchors,
      );
      final city = v.location == null
          ? null
          : CityGazetteer.nearest(v.location!);
      items.add(
        DayItem(
          startAt: v.startAt,
          endAt: v.endAt,
          kind: 'visit',
          title:
              labels[v.placeId]?.customName ??
              city?.name ??
              v.semanticType ??
              'Visita',
          subtitle: [
            if (city != null) city.name,
            if (v.semanticType != null) v.semanticType,
          ].join(' · '),
          category: cat,
          location: v.location,
          probability: v.probability,
          hierarchyLevel: v.hierarchyLevel,
          placeId: v.placeId,
        ),
      );
    }
    for (final a in doc.activities) {
      if (!overlaps(a.startAt, a.endAt)) continue;
      items.add(
        DayItem(
          startAt: a.startAt,
          endAt: a.endAt,
          kind: 'activity',
          title: a.activityType ?? 'Deslocamento',
          subtitle: a.distanceMeters == null
              ? null
              : '${(a.distanceMeters! / 1000).toStringAsFixed(1)} km',
          mode: transportBucket(a.activityType),
          location: a.startLocation,
          distanceMeters: a.distanceMeters,
          probability: a.candidateProbability ?? a.probability,
        ),
      );
      if (a.parking != null &&
          overlaps(a.parking!.startAt, a.parking!.startAt)) {
        items.add(
          DayItem(
            startAt: a.parking!.startAt,
            endAt: a.parking!.startAt,
            kind: 'parking',
            title: 'Estacionamento',
            location: a.parking!.location,
          ),
        );
      }
    }
    for (final n in doc.notes) {
      if (!overlaps(n.startAt, n.endAt)) continue;
      items.add(
        DayItem(
          startAt: n.startAt,
          endAt: n.endAt,
          kind: 'note',
          title: n.text,
        ),
      );
    }
    items.sort((a, b) => a.startAt.compareTo(b.startAt));
    return items;
  }

  static List<DateTime> daysWithData(GoogleTimelineDocument doc) {
    final set = <String, DateTime>{};
    void add(DateTime t) {
      final d = DateTime.utc(t.year, t.month, t.day);
      set[d.toIso8601String()] = d;
    }

    for (final v in doc.visits) {
      add(v.startAt);
    }
    for (final a in doc.activities) {
      add(a.startAt);
    }
    for (final p in doc.paths) {
      add(p.startAt);
    }
    final list = set.values.toList()..sort();
    return list;
  }
}

class _Acc {
  double meters = 0;
  Duration duration = Duration.zero;
  int legs = 0;
}

class _VisitAcc {
  Duration total = Duration.zero;
  int visits = 0;
}
