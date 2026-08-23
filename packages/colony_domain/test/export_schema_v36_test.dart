import 'package:colony_domain/colony_domain.dart';
import 'package:test/test.dart';

void main() {
  test('export v36 parses activation collections', () {
    final snapshot = ExportSnapshot.fromJson({
      'version': 36,
      'exported_at': '2026-08-23T12:00:00.000Z',
      'profile': {
        'id': 'p1',
        'colony_name': 'C',
        'display_name': 'D',
        'timezone': 'UTC',
        'locale': 'pt_BR',
        'base_currency': 'BRL',
        'created_at': '2026-08-23T12:00:00.000Z',
        'updated_at': '2026-08-23T12:00:00.000Z',
      },
      'preferences': {
        'density_mode': 'focus',
        'theme_mode': 'dark',
        'week_starts_on_monday': true,
        'use_24_hour_format': true,
        'sectors_enabled': <String>[],
        'onboarding_completed': true,
      },
      'tasks': <Map<String, Object?>>[],
      'events': <Map<String, Object?>>[],
      'activation_protocols': [
        {
          'id': 'ap1',
          'profile_id': 'p1',
          'name': 'Morning Launch — Standard',
          'protocol_type': 'wakeUp',
          'origin_state': {'label': 'cama', 'keys': <String>[]},
          'target_state': {'label': 'mesa', 'keys': <String>[]},
          'active_version': 1,
          'is_enabled': true,
          'seed_key': 'morning_launch_standard',
          'maturity': 'experimental',
          'created_at': '2026-08-23T12:00:00.000Z',
          'updated_at': '2026-08-23T12:00:00.000Z',
        },
      ],
    });
    expect(snapshot.activation.protocols, hasLength(1));
    expect(
      snapshot.activation.protocols.single.seedKey,
      'morning_launch_standard',
    );
    expect(snapshot.version, 36);
  });

  test('export v35 still parses without activation', () {
    final snapshot = ExportSnapshot.fromJson({
      'version': 35,
      'exported_at': '2026-08-23T12:00:00.000Z',
      'profile': {
        'id': 'p1',
        'colony_name': 'C',
        'display_name': 'D',
        'timezone': 'UTC',
        'locale': 'pt_BR',
        'base_currency': 'BRL',
        'created_at': '2026-08-23T12:00:00.000Z',
        'updated_at': '2026-08-23T12:00:00.000Z',
      },
      'preferences': {
        'density_mode': 'focus',
        'theme_mode': 'dark',
        'week_starts_on_monday': true,
        'use_24_hour_format': true,
        'sectors_enabled': <String>[],
        'onboarding_completed': true,
      },
      'tasks': <Map<String, Object?>>[],
      'events': <Map<String, Object?>>[],
    });
    expect(snapshot.activation.protocols, isEmpty);
  });
}
