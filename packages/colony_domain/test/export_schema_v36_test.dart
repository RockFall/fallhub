import 'package:colony_domain/colony_domain.dart';
import 'package:test/test.dart';

void main() {
  test('export v36 parses friendships and circles', () {
    final now = DateTime.utc(2026, 8, 23, 12);
    final json = {
      'exported_at': now.toIso8601String(),
      'version': 36,
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
      'people': [
        {
          'id': 'person-1',
          'display_name': 'Ana',
          'relationship_types': <String>['amiga'],
          'created_at': now.toIso8601String(),
          'updated_at': now.toIso8601String(),
        },
      ],
      'friendships': [
        {
          'id': 'f1',
          'person_id': 'person-1',
          'kind': 'close',
          'cadence': 'fortnightly',
          'how_we_met': 'faculdade',
          'created_at': now.toIso8601String(),
          'updated_at': now.toIso8601String(),
        },
      ],
      'friendship_circles': [
        {
          'id': 'c1',
          'name': 'RPG',
          'default_cadence': 'monthly',
          'created_at': now.toIso8601String(),
          'updated_at': now.toIso8601String(),
        },
      ],
      'friendship_circle_memberships': [
        {
          'person_id': 'person-1',
          'circle_id': 'c1',
          'linked_at': now.toIso8601String(),
        },
      ],
    };

    final snapshot = ExportSnapshot.fromJson(json);
    expect(snapshot.version, 36);
    expect(snapshot.friendships, hasLength(1));
    expect(snapshot.friendships.single.kind, FriendshipKind.close);
    expect(snapshot.friendships.single.cadence, FriendshipCadence.fortnightly);
    expect(snapshot.friendshipCircles.single.name, 'RPG');
    expect(snapshot.friendshipCircleMemberships, hasLength(1));
  });

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

  test('export v35 still parses without activation or friendships', () {
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
    expect(snapshot.friendships, isEmpty);
  });
}
