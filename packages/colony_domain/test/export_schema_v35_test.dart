import 'package:colony_domain/colony_domain.dart';
import 'package:test/test.dart';

void main() {
  test('export v35 parses music atlas collections', () {
    final now = DateTime.utc(2026, 8, 23, 12);
    final json = {
      'exported_at': now.toIso8601String(),
      'version': 35,
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
      'music_nodes': [
        {
          'id': 'n1',
          'node_type': 'releaseGroup',
          'canonical_name': 'Kind of Blue',
          'sort_name': 'Kind of Blue',
          'begin_year': 1959,
          'provenance_json': '{}',
          'created_at': now.toIso8601String(),
          'updated_at': now.toIso8601String(),
        },
      ],
      'music_encounters': [
        {
          'id': 'e1',
          'node_id': 'n1',
          'encounter_type': 'contact',
          'occurred_at': now.toIso8601String(),
          'source_type': 'import',
          'provenance_json': '{}',
          'created_at': now.toIso8601String(),
          'updated_at': now.toIso8601String(),
        },
      ],
    };

    final snapshot = ExportSnapshot.fromJson(json);
    expect(snapshot.version, 35);
    expect(snapshot.musicNodes, hasLength(1));
    expect(snapshot.musicEncounters.single.encounterType, MusicEncounterType.contact);
  });
}
