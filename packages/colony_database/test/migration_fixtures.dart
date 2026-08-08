import 'dart:io';

import 'package:colony_database/colony_database.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:sqlite3/sqlite3.dart';

/// Opens [ColonyDatabase] from a fixture at schema version [fromVersion].
Future<ColonyDatabase> openMigratedFrom(
  int fromVersion, {
  void Function(Database sqliteDb)? seed,
}) async {
  final file = File(
    p.join(
      Directory.systemTemp.path,
      'colony_migration_${fromVersion}_${DateTime.now().microsecondsSinceEpoch}.db',
    ),
  );

  final sqliteDb = sqlite3.open(file.path);
  sqliteDb.execute('PRAGMA foreign_keys = ON');

  _createCoreTables(sqliteDb);

  if (fromVersion >= 2) {
    _createPhase2Tables(sqliteDb);
  }
  if (fromVersion >= 3) {
    _createPhase3Tables(sqliteDb);
  }
  if (fromVersion >= 4) {
    _createPhase4Tables(sqliteDb);
  }
  if (fromVersion >= 5) {
    _createPhase5Tables(sqliteDb);
  }
  if (fromVersion >= 6) {
    _createPhase6Tables(sqliteDb);
  }
  if (fromVersion >= 7) {
    _createPhase7Tables(sqliteDb);
  }
  if (fromVersion >= 8) {
    _createPhase8Tables(sqliteDb);
  }
  if (fromVersion >= 9) {
    _createPhase9Tables(sqliteDb);
  }
  if (fromVersion >= 10) {
    _createPhase10Tables(sqliteDb);
  }
  if (fromVersion >= 11) {
    _createPhase11Tables(sqliteDb);
  }
  if (fromVersion >= 12) {
    _createPhase12Tables(sqliteDb);
  }
  if (fromVersion >= 13) {
    _createPhase13Tables(sqliteDb);
  }
  if (fromVersion >= 14) {
    _createPhase14Tables(sqliteDb);
  }
  if (fromVersion >= 15) {
    _createPhase15Tables(sqliteDb);
  }
  if (fromVersion >= 16) {
    _createPhase16Tables(sqliteDb);
  }
  if (fromVersion >= 17) {
    _createPhase17Tables(sqliteDb);
  }
  if (fromVersion >= 18) {
    _createPhase18Tables(sqliteDb);
  }
  if (fromVersion >= 19) {
    _createPhase19Tables(sqliteDb);
  }
  if (fromVersion >= 20) {
    _createPhase20Tables(sqliteDb);
  }
  if (fromVersion >= 21) {
    _createPhase21Tables(sqliteDb);
  }
  if (fromVersion >= 22) {
    _createPhase22Tables(sqliteDb);
  }
  if (fromVersion >= 23) {
    _createPhase23Tables(sqliteDb);
  }
  if (fromVersion >= 24) {
    _createPhase24Tables(sqliteDb);
  }
  if (fromVersion >= 25) {
    _createPhase25Tables(sqliteDb);
  }
  if (fromVersion >= 26) {
    _createPhase26Tables(sqliteDb);
  }
  if (fromVersion >= 27) {
    _createPhase27Tables(sqliteDb);
  }
  if (fromVersion >= 28) {
    _createPhase28Tables(sqliteDb);
  }
  if (fromVersion >= 29) {
    _createPhase29Tables(sqliteDb);
  }
  if (fromVersion >= 30) {
    _createPhase30Tables(sqliteDb);
  }
  if (fromVersion >= 31) {
    _createPhase31Tables(sqliteDb);
  }
  if (fromVersion >= 32) {
    _createPhase32Tables(sqliteDb);
  }
  if (fromVersion >= 33) {
    _createPhase33Tables(sqliteDb);
  }

  sqliteDb.userVersion = fromVersion;
  seed?.call(sqliteDb);
  sqliteDb.dispose();

  return ColonyDatabase(NativeDatabase(file));
}

void seedProfile(Database db, {String id = 'profile-1'}) {
  db.execute(
    '''
    INSERT INTO profiles (
      id, colony_name, display_name, timezone, locale, base_currency,
      created_at, updated_at, deleted_at, version
    ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, NULL, 1)
    ''',
    [
      id,
      'Test Colony',
      'Caio',
      'UTC',
      'pt_BR',
      'BRL',
      1_720_000_000_000,
      1_720_000_000_000,
    ],
  );
}

void seedTask(
  Database db, {
  String id = 'task-1',
  String profileId = 'profile-1',
  String? questId,
}) {
  if (questId == null) {
    db.execute(
      '''
      INSERT INTO tasks (
        id, profile_id, title, description, status, source_type,
        due_at, scheduled_start, estimated_minutes, actual_minutes,
        energy_requirement, blocked_reason, created_at, updated_at,
        completed_at, deleted_at, version
      ) VALUES (?, ?, ?, NULL, ?, ?, NULL, NULL, NULL, NULL, ?, NULL, ?, ?, NULL, NULL, 1)
      ''',
      [
        id,
        profileId,
        'Renovar passaporte',
        'inbox',
        'manual',
        'unknown',
        1_720_000_000_000,
        1_720_000_000_000,
      ],
    );
  } else {
    db.execute(
      '''
      INSERT INTO tasks (
        id, profile_id, title, description, status, source_type,
        due_at, scheduled_start, estimated_minutes, actual_minutes,
        energy_requirement, blocked_reason, quest_id, created_at, updated_at,
        completed_at, deleted_at, version
      ) VALUES (?, ?, ?, NULL, ?, ?, NULL, NULL, NULL, NULL, ?, NULL, ?, ?, ?, NULL, NULL, 1)
      ''',
      [
        id,
        profileId,
        'Renovar passaporte',
        'inbox',
        'manual',
        'unknown',
        questId,
        1_720_000_000_000,
        1_720_000_000_000,
      ],
    );
  }
}

void seedQuestV4(
  Database db, {
  String id = 'quest-1',
  String profileId = 'profile-1',
  String status = 'active',
  int createdAt = 1_720_000_000_000,
}) {
  db.execute(
    '''
    INSERT INTO quests (
      id, profile_id, title, purpose, success_criteria_json, risks_json,
      deadline, status, exit_reason, created_at, updated_at, completed_at, version
    ) VALUES (?, ?, ?, ?, ?, ?, NULL, ?, NULL, ?, ?, NULL, 1)
    ''',
    [
      id,
      profileId,
      'Viagem internacional',
      'Organizar documentação',
      '["Passaporte válido"]',
      '[]',
      status,
      createdAt,
      createdAt,
    ],
  );
}

void seedQuestV8(
  Database db, {
  String id = 'quest-1',
  String profileId = 'profile-1',
  String status = 'active',
  int createdAt = 1_720_000_000_000,
}) {
  db.execute(
    '''
    INSERT INTO quests (
      id, profile_id, title, purpose, success_criteria_json, risks_json,
      deadline, status, exit_reason, pause_reason, created_at, updated_at,
      completed_at, version
    ) VALUES (?, ?, ?, ?, ?, ?, NULL, ?, NULL, NULL, ?, ?, NULL, 1)
    ''',
    [
      id,
      profileId,
      'Viagem internacional',
      'Organizar documentação',
      '["Passaporte válido"]',
      '[]',
      status,
      createdAt,
      createdAt,
    ],
  );
}

void _createCoreTables(Database db) {
  db.execute('''
    CREATE TABLE profiles (
      id TEXT NOT NULL PRIMARY KEY,
      colony_name TEXT NOT NULL,
      display_name TEXT NOT NULL,
      timezone TEXT NOT NULL,
      locale TEXT NOT NULL,
      base_currency TEXT NOT NULL,
      created_at INTEGER NOT NULL,
      updated_at INTEGER NOT NULL,
      deleted_at INTEGER,
      version INTEGER NOT NULL DEFAULT 1
    )
  ''');

  db.execute('''
    CREATE TABLE domain_events (
      id TEXT NOT NULL PRIMARY KEY,
      aggregate_type TEXT NOT NULL,
      aggregate_id TEXT NOT NULL,
      event_type TEXT NOT NULL,
      occurred_at INTEGER NOT NULL,
      recorded_at INTEGER NOT NULL,
      source_type TEXT NOT NULL,
      payload_version INTEGER NOT NULL,
      payload_json TEXT NOT NULL,
      correlation_id TEXT,
      causation_id TEXT,
      privacy_class TEXT NOT NULL
    )
  ''');

  db.execute('''
    CREATE TABLE tasks (
      id TEXT NOT NULL PRIMARY KEY,
      profile_id TEXT NOT NULL REFERENCES profiles(id),
      title TEXT NOT NULL,
      description TEXT,
      status TEXT NOT NULL,
      source_type TEXT NOT NULL,
      due_at INTEGER,
      scheduled_start INTEGER,
      estimated_minutes INTEGER,
      actual_minutes INTEGER,
      energy_requirement TEXT NOT NULL DEFAULT 'unknown',
      blocked_reason TEXT,
      created_at INTEGER NOT NULL,
      updated_at INTEGER NOT NULL,
      completed_at INTEGER,
      deleted_at INTEGER,
      version INTEGER NOT NULL DEFAULT 1
    )
  ''');

  db.execute('''
    CREATE TABLE preferences (
      id INTEGER NOT NULL PRIMARY KEY,
      density_mode TEXT NOT NULL,
      theme_mode TEXT NOT NULL,
      week_starts_on_monday INTEGER NOT NULL,
      use_24_hour_format INTEGER NOT NULL,
      sectors_enabled_json TEXT NOT NULL,
      onboarding_completed INTEGER NOT NULL,
      biometric_lock_enabled INTEGER NOT NULL,
      session_timeout_minutes INTEGER NOT NULL
    )
  ''');
}

void _createPhase2Tables(Database db) {
  db.execute('''
    CREATE TABLE need_definitions (
      id TEXT NOT NULL PRIMARY KEY,
      profile_id TEXT NOT NULL REFERENCES profiles(id),
      name TEXT NOT NULL,
      slug TEXT NOT NULL,
      calculation_mode TEXT NOT NULL,
      preferred_min REAL NOT NULL DEFAULT 0.5,
      preferred_max REAL NOT NULL DEFAULT 0.85,
      validity_seconds INTEGER NOT NULL DEFAULT 86400,
      privacy_class TEXT NOT NULL,
      is_enabled INTEGER NOT NULL DEFAULT 1,
      is_subjective INTEGER NOT NULL DEFAULT 1,
      sort_order INTEGER NOT NULL DEFAULT 0,
      created_at INTEGER NOT NULL,
      updated_at INTEGER NOT NULL
    )
  ''');

  db.execute('''
    CREATE TABLE need_readings (
      id TEXT NOT NULL PRIMARY KEY,
      need_id TEXT NOT NULL REFERENCES need_definitions(id),
      observed_at INTEGER NOT NULL,
      normalized_value REAL,
      raw_value REAL,
      raw_unit TEXT,
      source_type TEXT NOT NULL,
      source_id TEXT,
      confidence REAL NOT NULL DEFAULT 1.0,
      note TEXT,
      created_at INTEGER NOT NULL
    )
  ''');

  db.execute('''
    CREATE TABLE check_ins (
      id TEXT NOT NULL PRIMARY KEY,
      profile_id TEXT NOT NULL REFERENCES profiles(id),
      observed_at INTEGER NOT NULL,
      created_at INTEGER NOT NULL,
      mood REAL NOT NULL,
      energy REAL NOT NULL,
      tension REAL NOT NULL,
      focus REAL NOT NULL,
      note TEXT,
      context_tags_json TEXT NOT NULL DEFAULT '[]',
      mood_scale TEXT NOT NULL DEFAULT 'five'
    )
  ''');

  db.execute('''
    CREATE TABLE mood_factors (
      id TEXT NOT NULL PRIMARY KEY,
      check_in_id TEXT NOT NULL REFERENCES check_ins(id),
      label TEXT NOT NULL,
      kind TEXT NOT NULL,
      impact INTEGER,
      uncertain INTEGER NOT NULL DEFAULT 0
    )
  ''');

  db.execute('''
    CREATE TABLE daily_reviews (
      id TEXT NOT NULL PRIMARY KEY,
      profile_id TEXT NOT NULL REFERENCES profiles(id),
      review_date INTEGER NOT NULL,
      created_at INTEGER NOT NULL,
      what_happened TEXT,
      current_state TEXT,
      tomorrow_commitments TEXT,
      route_correction TEXT
    )
  ''');
}

void _createPhase3Tables(Database db) {
  db.execute('''
    CREATE TABLE work_priorities (
      profile_id TEXT NOT NULL REFERENCES profiles(id),
      work_type TEXT NOT NULL,
      level TEXT NOT NULL,
      updated_at INTEGER NOT NULL,
      PRIMARY KEY (profile_id, work_type)
    )
  ''');

  db.execute('''
    CREATE TABLE bills (
      id TEXT NOT NULL PRIMARY KEY,
      profile_id TEXT NOT NULL REFERENCES profiles(id),
      title TEXT NOT NULL,
      repeat_mode TEXT NOT NULL,
      target TEXT NOT NULL,
      created_at INTEGER NOT NULL,
      updated_at INTEGER NOT NULL
    )
  ''');

  db.execute('''
    CREATE TABLE schedule_blocks (
      id TEXT NOT NULL PRIMARY KEY,
      profile_id TEXT NOT NULL REFERENCES profiles(id),
      start_at INTEGER NOT NULL,
      end_at INTEGER NOT NULL,
      mode TEXT NOT NULL,
      created_at INTEGER NOT NULL,
      updated_at INTEGER NOT NULL
    )
  ''');
}

void _createPhase4Tables(Database db) {
  db.execute('''
    CREATE TABLE quests (
      id TEXT NOT NULL PRIMARY KEY,
      profile_id TEXT NOT NULL REFERENCES profiles(id),
      title TEXT NOT NULL,
      purpose TEXT NOT NULL,
      success_criteria_json TEXT NOT NULL DEFAULT '[]',
      risks_json TEXT NOT NULL DEFAULT '[]',
      deadline INTEGER,
      status TEXT NOT NULL,
      exit_reason TEXT,
      created_at INTEGER NOT NULL,
      updated_at INTEGER NOT NULL,
      completed_at INTEGER,
      version INTEGER NOT NULL DEFAULT 1
    )
  ''');

  db.execute('ALTER TABLE tasks ADD COLUMN quest_id TEXT');
}

void _createPhase5Tables(Database db) {
  db.execute('''
    CREATE TABLE projects (
      id TEXT NOT NULL PRIMARY KEY,
      profile_id TEXT NOT NULL REFERENCES profiles(id),
      title TEXT NOT NULL,
      purpose TEXT,
      status TEXT NOT NULL,
      created_at INTEGER NOT NULL,
      updated_at INTEGER NOT NULL,
      version INTEGER NOT NULL DEFAULT 1
    )
  ''');

  db.execute('''
    CREATE TABLE quest_projects (
      quest_id TEXT NOT NULL REFERENCES quests(id),
      project_id TEXT NOT NULL REFERENCES projects(id),
      linked_at INTEGER NOT NULL,
      PRIMARY KEY (quest_id, project_id)
    )
  ''');

  db.execute('ALTER TABLE quests ADD COLUMN pause_reason TEXT');
}

void _createPhase6Tables(Database db) {
  db.execute('''
    CREATE TABLE decision_records (
      id TEXT NOT NULL PRIMARY KEY,
      profile_id TEXT NOT NULL REFERENCES profiles(id),
      title TEXT NOT NULL,
      context TEXT NOT NULL,
      decision TEXT NOT NULL,
      alternatives_json TEXT NOT NULL DEFAULT '[]',
      criteria_json TEXT NOT NULL DEFAULT '[]',
      assumptions_json TEXT NOT NULL DEFAULT '[]',
      expected_outcomes_json TEXT NOT NULL DEFAULT '[]',
      risks_json TEXT NOT NULL DEFAULT '[]',
      reversibility TEXT NOT NULL,
      decided_at INTEGER NOT NULL,
      review_at INTEGER,
      outcome_review TEXT,
      created_at INTEGER NOT NULL,
      updated_at INTEGER NOT NULL,
      version INTEGER NOT NULL DEFAULT 1
    )
  ''');

  db.execute('''
    CREATE TABLE quest_decisions (
      quest_id TEXT NOT NULL REFERENCES quests(id),
      decision_id TEXT NOT NULL REFERENCES decision_records(id),
      linked_at INTEGER NOT NULL,
      PRIMARY KEY (quest_id, decision_id)
    )
  ''');
}

void _createPhase7Tables(Database db) {
  db.execute('''
    CREATE TABLE quest_prerequisites (
      quest_id TEXT NOT NULL REFERENCES quests(id),
      prerequisite_quest_id TEXT NOT NULL REFERENCES quests(id),
      linked_at INTEGER NOT NULL,
      PRIMARY KEY (quest_id, prerequisite_quest_id)
    )
  ''');
}

void _createPhase8Tables(Database db) {
  db.execute('''
    CREATE TABLE weekly_reviews (
      id TEXT NOT NULL PRIMARY KEY,
      profile_id TEXT NOT NULL REFERENCES profiles(id),
      week_start_date INTEGER NOT NULL,
      created_at INTEGER NOT NULL,
      facts TEXT,
      wins TEXT,
      problems TEXT,
      projects TEXT,
      learning TEXT,
      next_week TEXT
    )
  ''');
}

void _createPhase9Tables(Database db) {
  db.execute('ALTER TABLE quests ADD COLUMN accepted_at INTEGER');
  db.execute('ALTER TABLE quests ADD COLUMN acceptance_deadline INTEGER');
  db.execute(
    "ALTER TABLE quests ADD COLUMN acceptance_assumptions_json TEXT NOT NULL DEFAULT '[]'",
  );
}

void _createPhase10Tables(Database db) {
  db.execute('''
    CREATE TABLE research_nodes (
      id TEXT NOT NULL PRIMARY KEY,
      profile_id TEXT NOT NULL REFERENCES profiles(id),
      title TEXT NOT NULL,
      description TEXT,
      type TEXT NOT NULL,
      status TEXT NOT NULL,
      created_at INTEGER NOT NULL,
      updated_at INTEGER NOT NULL,
      demonstrated_note TEXT,
      version INTEGER NOT NULL DEFAULT 1
    )
  ''');

  db.execute('''
    CREATE TABLE research_prerequisites (
      node_id TEXT NOT NULL REFERENCES research_nodes(id),
      prerequisite_node_id TEXT NOT NULL REFERENCES research_nodes(id),
      linked_at INTEGER NOT NULL,
      PRIMARY KEY (node_id, prerequisite_node_id)
    )
  ''');
}

void _createPhase11Tables(Database db) {
  db.execute('''
    CREATE TABLE learning_sessions (
      id TEXT NOT NULL PRIMARY KEY,
      profile_id TEXT NOT NULL REFERENCES profiles(id),
      node_id TEXT NOT NULL REFERENCES research_nodes(id),
      started_at INTEGER NOT NULL,
      duration_minutes INTEGER NOT NULL,
      mode TEXT NOT NULL,
      notes TEXT
    )
  ''');

  db.execute('''
    CREATE TABLE research_evidence (
      id TEXT NOT NULL PRIMARY KEY,
      profile_id TEXT NOT NULL REFERENCES profiles(id),
      node_id TEXT NOT NULL REFERENCES research_nodes(id),
      session_id TEXT REFERENCES learning_sessions(id),
      type TEXT NOT NULL,
      title TEXT NOT NULL,
      body TEXT NOT NULL,
      created_at INTEGER NOT NULL
    )
  ''');
}

void _createPhase12Tables(Database db) {
  db.execute('''
    CREATE TABLE financial_entities (
      id TEXT NOT NULL PRIMARY KEY,
      profile_id TEXT NOT NULL REFERENCES profiles(id),
      name TEXT NOT NULL,
      kind TEXT NOT NULL,
      created_at INTEGER NOT NULL,
      updated_at INTEGER NOT NULL
    )
  ''');
  db.execute('''
    CREATE TABLE financial_accounts (
      id TEXT NOT NULL PRIMARY KEY,
      profile_id TEXT NOT NULL REFERENCES profiles(id),
      entity_id TEXT NOT NULL REFERENCES financial_entities(id),
      institution TEXT NOT NULL,
      name TEXT NOT NULL,
      type TEXT NOT NULL,
      currency TEXT NOT NULL,
      current_balance_minor INTEGER NOT NULL,
      balance_as_of INTEGER,
      include_in_net_worth INTEGER NOT NULL DEFAULT 1
        CHECK (include_in_net_worth IN (0, 1)),
      sensitive_display_mode TEXT NOT NULL,
      created_at INTEGER NOT NULL,
      updated_at INTEGER NOT NULL
    )
  ''');
  db.execute('''
    CREATE TABLE ledger_transactions (
      id TEXT NOT NULL PRIMARY KEY,
      profile_id TEXT NOT NULL REFERENCES profiles(id),
      account_id TEXT NOT NULL REFERENCES financial_accounts(id),
      occurred_at INTEGER NOT NULL,
      description_original TEXT NOT NULL,
      amount_minor INTEGER NOT NULL,
      currency TEXT NOT NULL,
      direction TEXT NOT NULL,
      category_id TEXT,
      notes TEXT,
      fingerprint TEXT NOT NULL,
      created_at INTEGER NOT NULL,
      updated_at INTEGER NOT NULL
    )
  ''');
}

void _createPhase13Tables(Database db) {
  db.execute('''
    CREATE TABLE quest_research (
      quest_id TEXT NOT NULL REFERENCES quests(id),
      research_node_id TEXT NOT NULL REFERENCES research_nodes(id),
      linked_at INTEGER NOT NULL,
      PRIMARY KEY (quest_id, research_node_id)
    )
  ''');
}

void _createPhase14Tables(Database db) {
  db.execute('''
    CREATE TABLE health_conditions (
      id TEXT NOT NULL PRIMARY KEY,
      profile_id TEXT NOT NULL REFERENCES profiles(id),
      title TEXT NOT NULL,
      type TEXT NOT NULL,
      status TEXT NOT NULL,
      onset_at INTEGER,
      resolved_at INTEGER,
      severity_user_reported INTEGER,
      body_regions_json TEXT NOT NULL DEFAULT '[]',
      clinician_confirmed INTEGER NOT NULL DEFAULT 0
        CHECK (clinician_confirmed IN (0, 1)),
      notes TEXT,
      created_at INTEGER NOT NULL,
      updated_at INTEGER NOT NULL
    )
  ''');
}

void _createPhase15Tables(Database db) {
  db.execute('''
    CREATE TABLE symptom_entries (
      id TEXT NOT NULL PRIMARY KEY,
      profile_id TEXT NOT NULL REFERENCES profiles(id),
      condition_id TEXT REFERENCES health_conditions(id),
      occurred_at INTEGER NOT NULL,
      intensity INTEGER NOT NULL,
      note TEXT,
      body_region TEXT,
      created_at INTEGER NOT NULL
    )
  ''');
}

void _createPhase16Tables(Database db) {
  db.execute('''
    ALTER TABLE financial_accounts
    ADD COLUMN is_archived INTEGER NOT NULL DEFAULT 0
      CHECK (is_archived IN (0, 1))
  ''');
}

void _createPhase17Tables(Database db) {
  db.execute('''
    CREATE TABLE inventory_items (
      id TEXT NOT NULL PRIMARY KEY,
      profile_id TEXT NOT NULL REFERENCES profiles(id),
      name TEXT NOT NULL,
      category TEXT NOT NULL,
      status TEXT NOT NULL,
      location_label TEXT,
      notes TEXT,
      tags_json TEXT NOT NULL DEFAULT '[]',
      purchase_date INTEGER,
      purchase_price_minor INTEGER,
      purchase_currency TEXT,
      warranty_end INTEGER,
      created_at INTEGER NOT NULL,
      updated_at INTEGER NOT NULL
    )
  ''');
}

void _createPhase18Tables(Database db) {
  db.execute('''
    CREATE TABLE people (
      id TEXT NOT NULL PRIMARY KEY,
      profile_id TEXT NOT NULL REFERENCES profiles(id),
      display_name TEXT NOT NULL,
      preferred_name TEXT,
      relationship_types_json TEXT NOT NULL DEFAULT '[]',
      notes TEXT,
      birthday INTEGER,
      last_interaction_at INTEGER,
      next_follow_up_at INTEGER,
      archived_at INTEGER,
      created_at INTEGER NOT NULL,
      updated_at INTEGER NOT NULL
    )
  ''');
}

void _createPhase19Tables(Database db) {
  db.execute('''
    CREATE TABLE category_budgets (
      id TEXT NOT NULL PRIMARY KEY,
      profile_id TEXT NOT NULL REFERENCES profiles(id),
      category_id TEXT NOT NULL,
      currency TEXT NOT NULL,
      limit_amount_minor INTEGER NOT NULL,
      created_at INTEGER NOT NULL,
      updated_at INTEGER NOT NULL
    )
  ''');
}

void _createPhase20Tables(Database db) {
  db.execute('''
    CREATE TABLE person_interactions (
      id TEXT NOT NULL PRIMARY KEY,
      profile_id TEXT NOT NULL REFERENCES profiles(id),
      person_id TEXT NOT NULL REFERENCES people(id),
      kind TEXT NOT NULL,
      occurred_at INTEGER NOT NULL,
      note TEXT,
      created_at INTEGER NOT NULL
    )
  ''');
}

void _createPhase21Tables(Database db) {
  db.execute('''
    CREATE TABLE trips (
      id TEXT NOT NULL PRIMARY KEY,
      profile_id TEXT NOT NULL REFERENCES profiles(id),
      title TEXT NOT NULL,
      destinations_json TEXT NOT NULL DEFAULT '[]',
      start_at INTEGER,
      end_at INTEGER,
      purpose TEXT,
      notes TEXT,
      status TEXT NOT NULL,
      created_at INTEGER NOT NULL,
      updated_at INTEGER NOT NULL
    )
  ''');
}

void _createPhase22Tables(Database db) {
  db.execute('''
    CREATE TABLE organizations (
      id TEXT NOT NULL PRIMARY KEY,
      profile_id TEXT NOT NULL REFERENCES profiles(id),
      name TEXT NOT NULL,
      kind TEXT NOT NULL,
      notes TEXT,
      archived_at INTEGER,
      created_at INTEGER NOT NULL,
      updated_at INTEGER NOT NULL
    )
  ''');
}

void _createPhase23Tables(Database db) {
  db.execute('''
    CREATE TABLE person_organizations (
      person_id TEXT NOT NULL REFERENCES people(id),
      organization_id TEXT NOT NULL REFERENCES organizations(id),
      role TEXT,
      linked_at INTEGER NOT NULL,
      PRIMARY KEY (person_id, organization_id)
    )
  ''');
}

void _createPhase24Tables(Database db) {
  db.execute('''
    CREATE TABLE home_maintenance_tasks (
      id TEXT NOT NULL PRIMARY KEY,
      profile_id TEXT NOT NULL REFERENCES profiles(id),
      title TEXT NOT NULL,
      system_or_item TEXT NOT NULL,
      cadence_days INTEGER,
      next_due_at INTEGER,
      last_done_at INTEGER,
      vendor_label TEXT,
      estimated_cost_minor INTEGER,
      currency TEXT,
      notes TEXT,
      linked_inventory_item_id TEXT REFERENCES inventory_items(id),
      archived_at INTEGER,
      created_at INTEGER NOT NULL,
      updated_at INTEGER NOT NULL
    )
  ''');
}

void _createPhase25Tables(Database db) {
  db.execute('''
    CREATE TABLE quest_inventory (
      quest_id TEXT NOT NULL REFERENCES quests(id),
      inventory_item_id TEXT NOT NULL REFERENCES inventory_items(id),
      linked_at INTEGER NOT NULL,
      PRIMARY KEY (quest_id, inventory_item_id)
    )
  ''');
}

void _createPhase26Tables(Database db) {
  db.execute('''
    CREATE TABLE commitments (
      id TEXT NOT NULL PRIMARY KEY,
      profile_id TEXT NOT NULL REFERENCES profiles(id),
      description TEXT NOT NULL,
      made_by_label TEXT NOT NULL,
      made_to_person_id TEXT REFERENCES people(id),
      made_to_organization_id TEXT REFERENCES organizations(id),
      made_to_label TEXT,
      due_at INTEGER,
      status TEXT NOT NULL,
      notes TEXT,
      created_at INTEGER NOT NULL,
      updated_at INTEGER NOT NULL
    )
  ''');
}

void _createPhase27Tables(Database db) {
  db.execute('''
    CREATE TABLE device_identities (
      id TEXT NOT NULL PRIMARY KEY,
      label TEXT NOT NULL,
      created_at INTEGER NOT NULL,
      last_seen_at INTEGER
    )
  ''');
  db.execute('''
    CREATE TABLE sync_operations (
      id TEXT NOT NULL PRIMARY KEY,
      entity_type TEXT NOT NULL,
      entity_id TEXT NOT NULL,
      operation TEXT NOT NULL,
      base_version INTEGER,
      payload_json TEXT NOT NULL,
      status TEXT NOT NULL,
      attempts INTEGER NOT NULL DEFAULT 0,
      next_attempt_at INTEGER,
      created_at INTEGER NOT NULL,
      updated_at INTEGER NOT NULL
    )
  ''');
}

void _createPhase28Tables(Database db) {
  db.execute('''
    CREATE TABLE context_zones (
      id TEXT NOT NULL PRIMARY KEY,
      profile_id TEXT NOT NULL REFERENCES profiles(id),
      name TEXT NOT NULL,
      location_label TEXT,
      capabilities_json TEXT NOT NULL DEFAULT '[]',
      unavailable_work_types_json TEXT NOT NULL DEFAULT '[]',
      connectivity TEXT NOT NULL,
      notes TEXT,
      archived_at INTEGER,
      created_at INTEGER NOT NULL,
      updated_at INTEGER NOT NULL
    )
  ''');
}

void _createPhase29Tables(Database db) {
  db.execute('''
    CREATE TABLE integration_consents (
      id TEXT NOT NULL PRIMARY KEY,
      profile_id TEXT NOT NULL REFERENCES profiles(id),
      kind TEXT NOT NULL,
      enabled INTEGER NOT NULL CHECK ("enabled" IN (0, 1)),
      granted_at INTEGER,
      revoked_at INTEGER,
      created_at INTEGER NOT NULL,
      updated_at INTEGER NOT NULL
    )
  ''');
  db.execute('''
    CREATE TABLE external_calendar_events (
      id TEXT NOT NULL PRIMARY KEY,
      profile_id TEXT NOT NULL REFERENCES profiles(id),
      external_uid TEXT,
      title TEXT NOT NULL,
      start_at INTEGER NOT NULL,
      end_at INTEGER NOT NULL,
      source_type TEXT NOT NULL,
      imported_at INTEGER NOT NULL,
      created_at INTEGER NOT NULL,
      updated_at INTEGER NOT NULL
    )
  ''');
}

void _createPhase30Tables(Database db) {
  db.execute('''
    CREATE TABLE zone_trips (
      zone_id TEXT NOT NULL REFERENCES context_zones(id),
      trip_id TEXT NOT NULL REFERENCES trips(id),
      linked_at INTEGER NOT NULL,
      PRIMARY KEY (zone_id, trip_id)
    )
  ''');
}

void _createPhase31Tables(Database db) {
  db.execute(
    'ALTER TABLE commitments ADD COLUMN linked_quest_id TEXT REFERENCES quests(id)',
  );
}

void _createPhase32Tables(Database db) {
  db.execute('''
    CREATE TABLE health_appointments (
      id TEXT NOT NULL PRIMARY KEY,
      profile_id TEXT NOT NULL REFERENCES profiles(id),
      title TEXT NOT NULL,
      scheduled_at INTEGER NOT NULL,
      location_label TEXT,
      clinician_label TEXT,
      notes TEXT,
      status TEXT NOT NULL,
      created_at INTEGER NOT NULL,
      updated_at INTEGER NOT NULL
    )
  ''');
}

void _createPhase33Tables(Database db) {
  db.execute('''
    CREATE TABLE trip_inventory (
      trip_id TEXT NOT NULL REFERENCES trips(id),
      inventory_item_id TEXT NOT NULL REFERENCES inventory_items(id),
      linked_at INTEGER NOT NULL,
      PRIMARY KEY (trip_id, inventory_item_id)
    )
  ''');
}

void seedResearchNodeV10(
  Database db, {
  String id = 'research-1',
  String profileId = 'profile-1',
  String status = 'available',
  String? demonstratedNote,
  int updatedAt = 1_720_000_000_000,
}) {
  db.execute(
    '''
    INSERT INTO research_nodes (
      id, profile_id, title, description, type, status,
      created_at, updated_at, demonstrated_note, version
    ) VALUES (?, ?, ?, NULL, 'knowledge', ?, ?, ?, ?, 1)
    ''',
    [
      id,
      profileId,
      'Nó $id',
      status,
      updatedAt,
      updatedAt,
      demonstratedNote,
    ],
  );
}
