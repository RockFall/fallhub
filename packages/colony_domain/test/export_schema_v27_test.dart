import 'package:colony_domain/colony_domain.dart';
import 'package:test/test.dart';

const exportV27RequiredKeys = <String>{
  'exported_at',
  'version',
  'profile',
  'preferences',
  'tasks',
  'events',
  'quests',
  'projects',
  'quest_project_links',
  'decision_records',
  'quest_decision_links',
  'quest_prerequisite_links',
  'work_priorities',
  'bills',
  'schedule_blocks',
  'need_definitions',
  'need_readings',
  'check_ins',
  'daily_reviews',
  'mood_factors',
  'weekly_reviews',
  'research_nodes',
  'research_prerequisite_links',
  'quest_research_links',
  'learning_sessions',
  'research_evidence',
  'financial_entities',
  'financial_accounts',
  'transactions',
  'health_conditions',
  'symptom_entries',
  'inventory_items',
  'people',
  'category_budgets',
  'person_interactions',
  'trips',
  'organizations',
  'person_organization_links',
  'home_maintenance_tasks',
  'quest_inventory_links',
  'commitments',
  'context_zones',
  'integration_consents',
  'external_calendar_events',
  'zone_trip_links',
  'health_appointments',
  'trip_inventory_links',
  'knowledge_areas',
  'flashcard_decks',
  'flashcards',
  'flashcard_srs',
  'flashcard_review_logs',
  'knowledge_area_placements',
  'research_knowledge_links',
  'flashcard_tags',
  'flashcard_tag_links',
};

void main() {
  test('export v27 toJson exposes golden schema keys', () {
    final now = DateTime.utc(2026, 8, 7, 12);
    final profile = ColonyProfile(
      id: EntityId('profile-1'),
      colonyName: 'Schema',
      displayName: 'Tester',
      timezone: 'UTC',
      locale: 'pt_BR',
      baseCurrency: 'BRL',
      createdAt: now,
      updatedAt: now,
    );

    final snapshot = ExportSnapshot(
      exportedAt: now,
      version: 27,
      profile: profile,
      preferences: AppPreferences.defaults(),
      tasks: const [],
      events: const [],
    );

    final json = snapshot.toJson();
    expect(json.keys.toSet(), exportV27RequiredKeys);
    expect(json['version'], 27);
    expect(json['zone_trip_links'], isA<List>());
  });

  test('export v28 toJson includes health_appointments', () {
    final now = DateTime.utc(2026, 8, 7, 12);
    final profile = ColonyProfile(
      id: EntityId('profile-1'),
      colonyName: 'Schema',
      displayName: 'Tester',
      timezone: 'UTC',
      locale: 'pt_BR',
      baseCurrency: 'BRL',
      createdAt: now,
      updatedAt: now,
    );
    final snapshot = ExportSnapshot(
      exportedAt: now,
      version: 28,
      profile: profile,
      preferences: AppPreferences.defaults(),
      tasks: const [],
      events: const [],
      healthAppointments: [
        HealthAppointment.create(
          id: EntityId('appt-1'),
          profileId: profile.id,
          title: 'Check-up',
          scheduledAt: DateTime.utc(2026, 9, 1, 10),
          createdAt: now,
        ),
      ],
    );
    final json = snapshot.toJson();
    expect(json['version'], 28);
    expect(json['health_appointments'], isA<List>());
    expect((json['health_appointments'] as List), hasLength(1));
  });

  test('export v29 toJson includes trip_inventory_links', () {
    final now = DateTime.utc(2026, 8, 7, 12);
    final profile = ColonyProfile(
      id: EntityId('profile-1'),
      colonyName: 'Schema',
      displayName: 'Tester',
      timezone: 'UTC',
      locale: 'pt_BR',
      baseCurrency: 'BRL',
      createdAt: now,
      updatedAt: now,
    );
    final snapshot = ExportSnapshot(
      exportedAt: now,
      version: 29,
      profile: profile,
      preferences: AppPreferences.defaults(),
      tasks: const [],
      events: const [],
      tripInventoryLinks: [
        TripInventoryLink(
          tripId: EntityId('trip-1'),
          inventoryItemId: EntityId('inv-1'),
          linkedAt: now,
        ),
      ],
    );
    final json = snapshot.toJson();
    expect(json.keys.toSet(), exportV27RequiredKeys);
    expect(json['version'], 29);
    expect(json['trip_inventory_links'], isA<List>());
    expect((json['trip_inventory_links'] as List), hasLength(1));
  });

  test('export v26 still parses without zone_trip_links', () {
    final now = DateTime.utc(2026, 8, 7, 12);
    final json = {
      'exported_at': now.toIso8601String(),
      'version': 26,
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
      'tasks': [],
      'events': [],
      'integration_consents': [],
      'external_calendar_events': [],
    };
    final snapshot = ExportSnapshot.fromJson(json);
    expect(snapshot.version, 26);
    expect(snapshot.zoneTripLinks, isEmpty);
  });
}
