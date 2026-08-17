import 'package:colony_domain/colony_domain.dart';
import 'package:test/test.dart';

const exportV26RequiredKeys = <String>{
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
};

void main() {
  test('export v26 toJson exposes golden schema keys', () {
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
      version: 26,
      profile: profile,
      preferences: AppPreferences.defaults(),
      tasks: const [],
      events: const [],
    );

    final json = snapshot.toJson();
    expect(json.keys.toSet(), exportV26RequiredKeys);
    expect(json['version'], 26);
    expect(json['integration_consents'], isA<List>());
    expect(json['external_calendar_events'], isA<List>());
  });

  test('export v25 still parses without integration keys', () {
    final now = DateTime.utc(2026, 8, 7, 12);
    final json = {
      'exported_at': now.toIso8601String(),
      'version': 25,
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
      'context_zones': [],
    };
    final snapshot = ExportSnapshot.fromJson(json);
    expect(snapshot.version, 25);
    expect(snapshot.integrationConsents, isEmpty);
    expect(snapshot.externalCalendarEvents, isEmpty);
  });
}
