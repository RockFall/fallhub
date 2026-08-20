import 'package:colony_domain/colony_domain.dart';
import 'package:test/test.dart';

void main() {
  final now = DateTime.utc(2026, 8, 20, 12);

  Map<String, dynamic> base() => {
        'exported_at': now.toIso8601String(),
        'version': 34,
        'profile': {
          'id': 'profile-1',
          'colony_name': 'Schema',
          'display_name': 'Tester',
          'timezone': 'UTC',
          'locale': 'pt_BR',
          'base_currency': 'BRL',
          'created_at': now.toIso8601String(),
          'updated_at': now.toIso8601String(),
        },
        'preferences': {
          'density_mode': 'management',
          'theme_mode': 'dark',
          'week_starts_on_monday': true,
          'use_24_hour_format': true,
          'sectors_enabled': <String>[],
          'onboarding_completed': true,
        },
        'tasks': <Map<String, dynamic>>[],
        'events': <Map<String, dynamic>>[],
        'google_timeline_import': {
          'id': 'tl-1',
          'profile_id': 'profile-1',
          'file_name': 'Linha do tempo.json',
          'imported_at': now.toIso8601String(),
          'document': {
            'visits': [
              {
                'start_at': now.toIso8601String(),
                'end_at': now.add(const Duration(hours: 1)).toIso8601String(),
                'place_id': 'ChIJ_CAFE',
                'lat': -19.9167,
                'lng': -43.9345,
                'hierarchy_level': 0,
                'is_timeless': false,
              },
            ],
            'activities': <Map<String, dynamic>>[],
            'paths': <Map<String, dynamic>>[],
            'trips': <Map<String, dynamic>>[],
            'notes': <Map<String, dynamic>>[],
            'frequent_places': <Map<String, dynamic>>[],
            'affinities': <Map<String, dynamic>>[],
            'positions': <Map<String, dynamic>>[],
            'sensor_activities': <Map<String, dynamic>>[],
          },
        },
        'google_timeline_place_labels': [
          {
            'place_id': 'ChIJ_CAFE',
            'category': 'gastronomy',
            'custom_name': 'Café Central',
          },
        ],
      };

  test('export v34 parses timeline import and labels', () {
    final snapshot = ExportSnapshot.fromJson(base());
    expect(snapshot.version, 34);
    expect(snapshot.googleTimelineImport, isNotNull);
    expect(snapshot.googleTimelineImport!.fileName, 'Linha do tempo.json');
    expect(snapshot.googleTimelineImport!.document.visits, hasLength(1));
    expect(snapshot.googleTimelinePlaceLabels, hasLength(1));
    expect(snapshot.googleTimelinePlaceLabels.single.customName, 'Café Central');
    final json = snapshot.toJson();
    expect(json['google_timeline_import'], isA<Map<String, dynamic>>());
    expect(
      (json['google_timeline_place_labels'] as List),
      hasLength(1),
    );
  });

  test('export v33 has no timeline import', () {
    final json = base()..['version'] = 33;
    json.remove('google_timeline_import');
    json.remove('google_timeline_place_labels');
    final snapshot = ExportSnapshot.fromJson(json);
    expect(snapshot.googleTimelineImport, isNull);
    expect(snapshot.googleTimelinePlaceLabels, isEmpty);
  });
}
