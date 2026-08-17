import 'dart:convert';

import 'package:colony_domain/colony_domain.dart';
import 'package:test/test.dart';

void main() {
  const profileId = 'profile-1';
  final baseJson = {
    'exported_at': '2026-08-06T12:00:00.000Z',
    'profile': {
      'id': profileId,
      'colony_name': 'Test Colony',
      'display_name': 'Caio',
      'timezone': 'UTC',
      'locale': 'pt_BR',
      'base_currency': 'BRL',
      'created_at': '2026-08-01T10:00:00.000Z',
      'updated_at': '2026-08-06T12:00:00.000Z',
    },
    'preferences': {
      'density_mode': 'management',
      'theme_mode': 'dark',
      'week_starts_on_monday': true,
      'use_24_hour_format': true,
      'sectors_enabled': <String>[],
      'onboarding_completed': true,
    },
    'tasks': [
      {
        'id': 'task-1',
        'title': 'Comprar leite',
        'status': 'inbox',
        'source_type': 'manual',
        'created_at': '2026-08-06T12:00:00.000Z',
        'updated_at': '2026-08-06T12:00:00.000Z',
      },
    ],
    'events': [
      {
        'id': 'event-1',
        'aggregate_type': 'task',
        'aggregate_id': 'task-1',
        'event_type': 'taskCreated',
        'occurred_at': '2026-08-06T12:00:00.000Z',
        'payload': {'title': 'Comprar leite'},
      },
    ],
  };

  test('parses v1 minimal export', () {
    final json = Map<String, dynamic>.from(baseJson)..['version'] = 1;
    final snapshot = ExportSnapshot.fromJson(json);

    expect(snapshot.version, 1);
    expect(snapshot.profile.colonyName, 'Test Colony');
    expect(snapshot.tasks, hasLength(1));
    expect(snapshot.quests, isEmpty);
    expect(snapshot.projects, isEmpty);
    expect(snapshot.decisionRecords, isEmpty);
  });

  test('parses v2 with quests', () {
    final json = Map<String, dynamic>.from(baseJson)
      ..['version'] = 2
      ..['quests'] = [
        {
          'id': 'quest-1',
          'title': 'Mudança',
          'purpose': 'Avaliar oferta',
          'success_criteria': ['Salário'],
          'risks': ['Prazo'],
          'status': 'active',
          'created_at': '2026-08-06T12:00:00.000Z',
          'updated_at': '2026-08-06T12:00:00.000Z',
        },
      ];

    final snapshot = ExportSnapshot.fromJson(json);
    expect(snapshot.version, 2);
    expect(snapshot.quests, hasLength(1));
    expect(snapshot.quests.first.title, 'Mudança');
    expect(snapshot.projects, isEmpty);
  });

  test('parses v3 with projects and links', () {
    final json = Map<String, dynamic>.from(baseJson)
      ..['version'] = 3
      ..['quests'] = []
      ..['projects'] = [
        {
          'id': 'project-1',
          'title': 'Viagem',
          'status': 'active',
          'created_at': '2026-08-06T12:00:00.000Z',
          'updated_at': '2026-08-06T12:00:00.000Z',
        },
      ]
      ..['quest_project_links'] = [];

    final snapshot = ExportSnapshot.fromJson(json);
    expect(snapshot.version, 3);
    expect(snapshot.projects, hasLength(1));
    expect(snapshot.decisionRecords, isEmpty);
  });

  test('parses v4 with decisions', () {
    final json = Map<String, dynamic>.from(baseJson)
      ..['version'] = 4
      ..['quests'] = []
      ..['projects'] = []
      ..['quest_project_links'] = []
      ..['decision_records'] = [
        {
          'id': 'decision-1',
          'title': 'Aceitar oferta',
          'context': 'Proposta remota',
          'decision': 'Aceitar',
          'alternatives': [],
          'criteria': [],
          'assumptions': ['Mercado estável'],
          'expected_outcomes': ['Mais tempo livre'],
          'risks': [],
          'reversibility': 'hard',
          'decided_at': '2026-08-06T12:00:00.000Z',
          'review_at': '2027-01-01T00:00:00.000Z',
          'created_at': '2026-08-06T12:00:00.000Z',
          'updated_at': '2026-08-06T12:00:00.000Z',
        },
      ]
      ..['quest_decision_links'] = [];

    final snapshot = ExportSnapshot.fromJson(json);
    expect(snapshot.version, 4);
    expect(snapshot.decisionRecords, hasLength(1));
    expect(snapshot.decisionRecords.first.assumptions, ['Mercado estável']);
    expect(snapshot.decisionRecords.first.reviewAt, isNotNull);
  });

  test('parses v5 with prerequisite links', () {
    final json = Map<String, dynamic>.from(baseJson)
      ..['version'] = 5
      ..['quests'] = [
        {
          'id': 'quest-1',
          'title': 'Main',
          'purpose': 'P',
          'success_criteria': [],
          'risks': [],
          'status': 'draft',
          'created_at': '2026-08-06T12:00:00.000Z',
          'updated_at': '2026-08-06T12:00:00.000Z',
        },
        {
          'id': 'quest-0',
          'title': 'Prereq',
          'purpose': 'P',
          'success_criteria': [],
          'risks': [],
          'status': 'completed',
          'created_at': '2026-08-06T12:00:00.000Z',
          'updated_at': '2026-08-06T12:00:00.000Z',
        },
      ]
      ..['projects'] = []
      ..['quest_project_links'] = []
      ..['decision_records'] = []
      ..['quest_decision_links'] = []
      ..['quest_prerequisite_links'] = [
        {
          'quest_id': 'quest-1',
          'prerequisite_quest_id': 'quest-0',
          'linked_at': '2026-08-06T12:00:00.000Z',
        },
      ];

    final snapshot = ExportSnapshot.fromJson(json);
    expect(snapshot.version, 5);
    expect(snapshot.questPrerequisiteLinks, hasLength(1));
  });

  test('v4 missing prerequisite links defaults to empty', () {
    final json = Map<String, dynamic>.from(baseJson)
      ..['version'] = 4
      ..['quests'] = []
      ..['projects'] = []
      ..['quest_project_links'] = []
      ..['decision_records'] = []
      ..['quest_decision_links'] = [];

    final snapshot = ExportSnapshot.fromJson(json);
    expect(snapshot.questPrerequisiteLinks, isEmpty);
  });

  test('v5 missing pawn keys defaults to empty', () {
    final json = Map<String, dynamic>.from(baseJson)
      ..['version'] = 5
      ..['quests'] = []
      ..['projects'] = []
      ..['quest_project_links'] = []
      ..['decision_records'] = []
      ..['quest_decision_links'] = []
      ..['quest_prerequisite_links'] = [];

    final snapshot = ExportSnapshot.fromJson(json);
    expect(snapshot.dailyReviews, isEmpty);
    expect(snapshot.moodFactors, isEmpty);
    expect(snapshot.weeklyReviews, isEmpty);
  });

  test('parses v6 with daily reviews and mood factors', () {
    final json = Map<String, dynamic>.from(baseJson)
      ..['version'] = 6
      ..['quests'] = []
      ..['projects'] = []
      ..['quest_project_links'] = []
      ..['decision_records'] = []
      ..['quest_decision_links'] = []
      ..['quest_prerequisite_links'] = []
      ..['check_ins'] = [
        {
          'id': 'checkin-1',
          'observed_at': '2026-08-06T08:00:00.000Z',
          'mood': 0.75,
          'energy': 0.5,
          'tension': 0.25,
          'focus': 0.6,
        },
      ]
      ..['daily_reviews'] = [
        {
          'id': 'review-1',
          'review_date': '2026-08-05T00:00:00.000Z',
          'created_at': '2026-08-05T22:00:00.000Z',
          'what_happened': 'Dia intenso',
        },
      ]
      ..['mood_factors'] = [
        {
          'id': 'factor-1',
          'check_in_id': 'checkin-1',
          'label': 'Descanso',
          'kind': 'userConfirmed',
          'impact': 3,
          'uncertain': false,
        },
      ];

    final snapshot = ExportSnapshot.fromJson(json);
    expect(snapshot.version, 6);
    expect(snapshot.dailyReviews, hasLength(1));
    expect(snapshot.dailyReviews.first.whatHappened, 'Dia intenso');
    expect(snapshot.moodFactors, hasLength(1));
    expect(snapshot.moodFactors.first.label, 'Descanso');
  });

  test('v6 round-trip toJson preserves pawn fields', () {
    final json = Map<String, dynamic>.from(baseJson)
      ..['version'] = 6
      ..['quests'] = []
      ..['projects'] = []
      ..['quest_project_links'] = []
      ..['decision_records'] = []
      ..['quest_decision_links'] = []
      ..['quest_prerequisite_links'] = []
      ..['check_ins'] = [
        {
          'id': 'checkin-1',
          'observed_at': '2026-08-06T08:00:00.000Z',
          'mood': 0.5,
          'energy': 0.5,
          'tension': 0.5,
          'focus': 0.5,
        },
      ]
      ..['daily_reviews'] = [
        {
          'id': 'review-1',
          'review_date': '2026-08-05T00:00:00.000Z',
          'created_at': '2026-08-05T22:00:00.000Z',
        },
      ]
      ..['mood_factors'] = [
        {
          'id': 'factor-1',
          'check_in_id': 'checkin-1',
          'label': 'Música',
          'kind': 'suggested',
          'uncertain': true,
        },
      ];

    final snapshot = ExportSnapshot.fromJson(json);
    final encoded = snapshot.toJson();

    expect(encoded['version'], 6);
    expect((encoded['daily_reviews'] as List), hasLength(1));
    expect((encoded['mood_factors'] as List), hasLength(1));
    expect(snapshot.entityCounts['daily_reviews'], 1);
    expect(snapshot.entityCounts['mood_factors'], 1);
  });

  test('parses v7 with weekly reviews', () {
    final json = Map<String, dynamic>.from(baseJson)
      ..['version'] = 7
      ..['quests'] = []
      ..['projects'] = []
      ..['quest_project_links'] = []
      ..['decision_records'] = []
      ..['quest_decision_links'] = []
      ..['quest_prerequisite_links'] = []
      ..['weekly_reviews'] = [
        {
          'id': 'weekly-1',
          'week_start_date': '2026-08-03T00:00:00.000Z',
          'created_at': '2026-08-06T10:00:00.000Z',
          'facts': 'Semana intensa',
          'wins': 'Export v7',
        },
      ];

    final snapshot = ExportSnapshot.fromJson(json);
    expect(snapshot.version, 7);
    expect(snapshot.weeklyReviews, hasLength(1));
    expect(snapshot.weeklyReviews.first.facts, 'Semana intensa');
    expect(snapshot.entityCounts['weekly_reviews'], 1);
  });

  test('v6 export backfills empty weekly reviews', () {
    final json = Map<String, dynamic>.from(baseJson)
      ..['version'] = 6
      ..['quests'] = []
      ..['projects'] = []
      ..['quest_project_links'] = []
      ..['decision_records'] = []
      ..['quest_decision_links'] = []
      ..['quest_prerequisite_links'] = [];

    final snapshot = ExportSnapshot.fromJson(json);
    expect(snapshot.weeklyReviews, isEmpty);
  });

  test('v7 round-trip toJson preserves weekly reviews', () {
    final json = Map<String, dynamic>.from(baseJson)
      ..['version'] = 7
      ..['quests'] = []
      ..['projects'] = []
      ..['quest_project_links'] = []
      ..['decision_records'] = []
      ..['quest_decision_links'] = []
      ..['quest_prerequisite_links'] = []
      ..['weekly_reviews'] = [
        {
          'id': 'weekly-1',
          'week_start_date': '2026-08-03T00:00:00.000Z',
          'created_at': '2026-08-06T10:00:00.000Z',
          'next_week': 'Iter 13',
        },
      ];

    final snapshot = ExportSnapshot.fromJson(json);
    final encoded = snapshot.toJson();

    expect(encoded['version'], 7);
    expect((encoded['weekly_reviews'] as List), hasLength(1));
  });

  test('parses v8 with quest acceptance fields', () {
    final json = Map<String, dynamic>.from(baseJson)
      ..['version'] = 8
      ..['quests'] = [
        {
          'id': 'quest-1',
          'title': 'Aceita',
          'purpose': 'P',
          'success_criteria': [],
          'risks': [],
          'status': 'active',
          'created_at': '2026-08-01T10:00:00.000Z',
          'updated_at': '2026-08-06T12:00:00.000Z',
          'accepted_at': '2026-08-02T14:00:00.000Z',
          'acceptance_deadline': '2026-09-01T00:00:00.000Z',
          'acceptance_assumptions': ['Premissa'],
        },
      ]
      ..['projects'] = []
      ..['quest_project_links'] = []
      ..['decision_records'] = []
      ..['quest_decision_links'] = []
      ..['quest_prerequisite_links'] = []
      ..['weekly_reviews'] = [];

    final snapshot = ExportSnapshot.fromJson(json);
    expect(snapshot.version, 8);
    expect(snapshot.quests.single.acceptedAt, DateTime.utc(2026, 8, 2, 14));
    expect(snapshot.quests.single.acceptanceAssumptions, ['Premissa']);
  });

  test('v7 import backfills empty quest acceptance fields', () {
    final json = Map<String, dynamic>.from(baseJson)
      ..['version'] = 7
      ..['quests'] = [
        {
          'id': 'quest-1',
          'title': 'Legado',
          'purpose': 'P',
          'success_criteria': [],
          'risks': [],
          'status': 'active',
          'created_at': '2026-08-01T10:00:00.000Z',
          'updated_at': '2026-08-06T12:00:00.000Z',
        },
      ]
      ..['projects'] = []
      ..['quest_project_links'] = []
      ..['decision_records'] = []
      ..['quest_decision_links'] = []
      ..['quest_prerequisite_links'] = []
      ..['weekly_reviews'] = [];

    final snapshot = ExportSnapshot.fromJson(json);
    expect(snapshot.quests.single.acceptedAt, isNull);
    expect(snapshot.quests.single.acceptanceAssumptions, isEmpty);
  });

  test('v8 round-trip toJson preserves quest acceptance', () {
    final json = Map<String, dynamic>.from(baseJson)
      ..['version'] = 8
      ..['quests'] = [
        {
          'id': 'quest-1',
          'title': 'Aceita',
          'purpose': 'P',
          'success_criteria': [],
          'risks': [],
          'status': 'active',
          'created_at': '2026-08-01T10:00:00.000Z',
          'updated_at': '2026-08-06T12:00:00.000Z',
          'accepted_at': '2026-08-02T14:00:00.000Z',
          'acceptance_assumptions': ['Premissa'],
        },
      ]
      ..['projects'] = []
      ..['quest_project_links'] = []
      ..['decision_records'] = []
      ..['quest_decision_links'] = []
      ..['quest_prerequisite_links'] = []
      ..['weekly_reviews'] = [];

    final snapshot = ExportSnapshot.fromJson(json);
    final encoded = snapshot.toJson();

    expect(encoded['version'], 8);
    final quest = (encoded['quests'] as List).single as Map<String, dynamic>;
    expect(quest['accepted_at'], '2026-08-02T14:00:00.000Z');
    expect(quest['acceptance_assumptions'], ['Premissa']);
  });

  test('parses v9 with research nodes and backfills v8', () {
    final v8 = Map<String, dynamic>.from(baseJson)..['version'] = 8;
    final v8Snapshot = ExportSnapshot.fromJson(v8);
    expect(v8Snapshot.researchNodes, isEmpty);
    expect(v8Snapshot.researchPrerequisiteLinks, isEmpty);

    final v9 = Map<String, dynamic>.from(baseJson)
      ..['version'] = 9
      ..['research_nodes'] = [
        {
          'id': 'research-1',
          'title': 'Flutter',
          'type': 'knowledge',
          'status': 'available',
          'created_at': '2026-08-06T12:00:00.000Z',
          'updated_at': '2026-08-06T12:00:00.000Z',
        },
      ]
      ..['research_prerequisite_links'] = [];

    final snapshot = ExportSnapshot.fromJson(v9);
    expect(snapshot.version, 9);
    expect(snapshot.researchNodes, hasLength(1));
    expect(snapshot.researchNodes.first.title, 'Flutter');
  });

  test('round-trip toJson preserves key fields', () {
    final json = Map<String, dynamic>.from(baseJson)
      ..['version'] = 4
      ..['quests'] = []
      ..['projects'] = []
      ..['quest_project_links'] = []
      ..['decision_records'] = []
      ..['quest_decision_links'] = [];

    final snapshot = ExportSnapshot.fromJson(json);
    final encoded = snapshot.toJson();

    expect(encoded['version'], 4);
    expect(encoded['profile'], isA<Map>());
    expect((encoded['tasks'] as List), hasLength(1));
  });

  test('rejects malformed JSON string', () {
    expect(
      () => ExportSnapshot.fromJsonString('{not json'),
      throwsA(isA<ExportSnapshotException>()),
    );
  });

  test('rejects missing profile', () {
    final json = Map<String, dynamic>.from(baseJson)
      ..['version'] = 1
      ..remove('profile');

    expect(
      () => ExportSnapshot.fromJson(json),
      throwsA(isA<ExportSnapshotException>()),
    );
  });

  test('parses v10 with sessions and evidence and backfills v9', () {
    final v9 = Map<String, dynamic>.from(baseJson)
      ..['version'] = 9
      ..['research_nodes'] = [
        {
          'id': 'research-1',
          'title': 'Flutter',
          'type': 'knowledge',
          'status': 'available',
          'created_at': '2026-08-06T12:00:00.000Z',
          'updated_at': '2026-08-06T12:00:00.000Z',
        },
      ]
      ..['research_prerequisite_links'] = [];

    final v9Snapshot = ExportSnapshot.fromJson(v9);
    expect(v9Snapshot.learningSessions, isEmpty);
    expect(v9Snapshot.researchEvidence, isEmpty);

    final v10 = Map<String, dynamic>.from(v9)
      ..['version'] = 10
      ..['learning_sessions'] = [
        {
          'id': 'session-1',
          'node_id': 'research-1',
          'started_at': '2026-08-06T10:00:00.000Z',
          'duration_minutes': 30,
          'mode': 'read',
        },
      ]
      ..['research_evidence'] = [
        {
          'id': 'evidence-1',
          'node_id': 'research-1',
          'type': 'note',
          'title': 'Nota',
          'body': 'Corpo',
          'created_at': '2026-08-06T11:00:00.000Z',
        },
      ];

    final snapshot = ExportSnapshot.fromJson(v10);
    expect(snapshot.version, 10);
    expect(snapshot.learningSessions, hasLength(1));
    expect(snapshot.researchEvidence, hasLength(1));
  });

  test('parses export v11 finance arrays', () {
    final v10 = Map<String, dynamic>.from(baseJson)
      ..['version'] = 10
      ..['research_nodes'] = []
      ..['research_prerequisite_links'] = []
      ..['learning_sessions'] = []
      ..['research_evidence'] = [];

    final v10Snapshot = ExportSnapshot.fromJson(v10);
    expect(v10Snapshot.financialEntities, isEmpty);
    expect(v10Snapshot.financialAccounts, isEmpty);
    expect(v10Snapshot.transactions, isEmpty);

    final v11 = Map<String, dynamic>.from(v10)
      ..['version'] = 11
      ..['financial_entities'] = [
        {
          'id': 'entity-1',
          'name': 'Pessoal',
          'kind': 'personal',
          'created_at': '2026-08-06T10:00:00.000Z',
          'updated_at': '2026-08-06T10:00:00.000Z',
        },
      ]
      ..['financial_accounts'] = [
        {
          'id': 'account-1',
          'entity_id': 'entity-1',
          'institution': 'Banco',
          'name': 'Corrente',
          'type': 'checking',
          'currency': 'BRL',
          'current_balance_minor': 0,
          'include_in_net_worth': true,
          'sensitive_display_mode': 'hidden',
          'created_at': '2026-08-06T10:00:00.000Z',
          'updated_at': '2026-08-06T10:00:00.000Z',
        },
      ]
      ..['transactions'] = [
        {
          'id': 'tx-1',
          'account_id': 'account-1',
          'occurred_at': '2026-08-06T12:00:00.000Z',
          'description_original': 'Café',
          'amount_minor': 500,
          'currency': 'BRL',
          'direction': 'outflow',
          'fingerprint': 'abc123',
          'created_at': '2026-08-06T12:00:00.000Z',
          'updated_at': '2026-08-06T12:00:00.000Z',
        },
      ];

    final snapshot = ExportSnapshot.fromJson(v11);
    expect(snapshot.version, 11);
    expect(snapshot.financialEntities, hasLength(1));
    expect(snapshot.financialAccounts, hasLength(1));
    expect(snapshot.transactions, hasLength(1));
  });

  test('parses export v12 quest research links and backfills v11', () {
    final v11 = Map<String, dynamic>.from(baseJson)
      ..['version'] = 11
      ..['research_nodes'] = [
        {
          'id': 'research-1',
          'title': 'Flutter',
          'type': 'knowledge',
          'status': 'available',
          'created_at': '2026-08-06T12:00:00.000Z',
          'updated_at': '2026-08-06T12:00:00.000Z',
        },
      ]
      ..['research_prerequisite_links'] = []
      ..['learning_sessions'] = []
      ..['research_evidence'] = []
      ..['financial_entities'] = []
      ..['financial_accounts'] = []
      ..['transactions'] = [];

    final v11Snapshot = ExportSnapshot.fromJson(v11);
    expect(v11Snapshot.questResearchLinks, isEmpty);

    final v12 = Map<String, dynamic>.from(v11)
      ..['version'] = 12
      ..['quests'] = [
        {
          'id': 'quest-1',
          'title': 'Missão',
          'purpose': 'Propósito',
          'success_criteria': <String>[],
          'risks': <String>[],
          'status': 'active',
          'created_at': '2026-08-06T12:00:00.000Z',
          'updated_at': '2026-08-06T12:00:00.000Z',
        },
      ]
      ..['quest_research_links'] = [
        {
          'quest_id': 'quest-1',
          'research_node_id': 'research-1',
          'linked_at': '2026-08-06T12:30:00.000Z',
        },
      ];

    final snapshot = ExportSnapshot.fromJson(v12);
    expect(snapshot.version, 12);
    expect(snapshot.questResearchLinks, hasLength(1));
    expect(snapshot.questResearchLinks.first.researchNodeId.value, 'research-1');
  });

  test('parses export v13 health conditions and backfills v12', () {
    final v12 = Map<String, dynamic>.from(baseJson)
      ..['version'] = 12
      ..['quest_research_links'] = <Map<String, dynamic>>[]
      ..['financial_entities'] = <Map<String, dynamic>>[]
      ..['financial_accounts'] = <Map<String, dynamic>>[]
      ..['transactions'] = <Map<String, dynamic>>[];

    final backfill = ExportSnapshot.fromJson(v12);
    expect(backfill.healthConditions, isEmpty);

    final v13 = Map<String, dynamic>.from(v12)
      ..['version'] = 13
      ..['health_conditions'] = [
        {
          'id': 'health-1',
          'title': 'Enxaqueca',
          'type': 'symptom',
          'status': 'active',
          'severity_user_reported': 3,
          'body_regions': ['cabeça'],
          'clinician_confirmed': false,
          'created_at': '2026-08-07T12:00:00.000Z',
          'updated_at': '2026-08-07T12:00:00.000Z',
        },
      ];

    final snapshot = ExportSnapshot.fromJson(v13);
    expect(snapshot.version, 13);
    expect(snapshot.healthConditions, hasLength(1));
    expect(snapshot.healthConditions.first.title, 'Enxaqueca');
    expect(snapshot.symptomEntries, isEmpty);
  });

  test('parses export v14 symptom entries and backfills v13', () {
    final v13 = Map<String, dynamic>.from(baseJson)
      ..['version'] = 13
      ..['health_conditions'] = [
        {
          'id': 'health-1',
          'title': 'Enxaqueca',
          'type': 'symptom',
          'status': 'active',
          'body_regions': <String>[],
          'clinician_confirmed': false,
          'created_at': '2026-08-07T12:00:00.000Z',
          'updated_at': '2026-08-07T12:00:00.000Z',
        },
      ]
      ..['quest_research_links'] = <Map<String, dynamic>>[]
      ..['financial_entities'] = <Map<String, dynamic>>[]
      ..['financial_accounts'] = <Map<String, dynamic>>[]
      ..['transactions'] = <Map<String, dynamic>>[];

    final backfill = ExportSnapshot.fromJson(v13);
    expect(backfill.symptomEntries, isEmpty);

    final v14 = Map<String, dynamic>.from(v13)
      ..['version'] = 14
      ..['symptom_entries'] = [
        {
          'id': 'sym-1',
          'condition_id': 'health-1',
          'occurred_at': '2026-08-07T14:00:00.000Z',
          'intensity': 4,
          'note': 'após almoço',
          'body_region': 'cabeça',
          'created_at': '2026-08-07T14:00:00.000Z',
        },
      ];

    final snapshot = ExportSnapshot.fromJson(v14);
    expect(snapshot.version, 14);
    expect(snapshot.symptomEntries, hasLength(1));
    expect(snapshot.symptomEntries.first.intensity, 4);
    expect(snapshot.symptomEntries.first.conditionId?.value, 'health-1');
    expect(snapshot.inventoryItems, isEmpty);

    final v15 = Map<String, dynamic>.from(v14)
      ..['version'] = 15
      ..['inventory_items'] = [
        {
          'id': 'inv-1',
          'name': 'Notebook',
          'category': 'electronics',
          'status': 'active',
          'location_label': 'mesa',
          'tags': <String>['tech'],
          'created_at': '2026-08-07T10:00:00.000Z',
          'updated_at': '2026-08-07T10:00:00.000Z',
        },
      ];

    final v15Snapshot = ExportSnapshot.fromJson(v15);
    expect(v15Snapshot.version, 15);
    expect(v15Snapshot.inventoryItems, hasLength(1));
    expect(v15Snapshot.inventoryItems.first.name, 'Notebook');
    expect(
      v15Snapshot.inventoryItems.first.category,
      InventoryCategory.electronics,
    );
    expect(v15Snapshot.people, isEmpty);

    final v16 = Map<String, dynamic>.from(v15)
      ..['version'] = 16
      ..['people'] = [
        {
          'id': 'person-1',
          'display_name': 'Ana Silva',
          'preferred_name': 'Aninha',
          'relationship_types': <String>['amiga'],
          'created_at': '2026-08-07T10:00:00.000Z',
          'updated_at': '2026-08-07T10:00:00.000Z',
        },
      ];

    final v16Snapshot = ExportSnapshot.fromJson(v16);
    expect(v16Snapshot.version, 16);
    expect(v16Snapshot.people, hasLength(1));
    expect(v16Snapshot.people.first.displayName, 'Ana Silva');
    expect(v16Snapshot.categoryBudgets, isEmpty);

    final v17 = Map<String, dynamic>.from(v16)
      ..['version'] = 17
      ..['category_budgets'] = [
        {
          'id': 'budget-1',
          'category_id': 'cat_food',
          'currency': 'BRL',
          'limit_amount_minor': 50000,
          'created_at': '2026-08-07T10:00:00.000Z',
          'updated_at': '2026-08-07T10:00:00.000Z',
        },
      ];

    final v17Snapshot = ExportSnapshot.fromJson(v17);
    expect(v17Snapshot.version, 17);
    expect(v17Snapshot.categoryBudgets, hasLength(1));
    expect(v17Snapshot.categoryBudgets.first.limitAmountMinor, 50000);
    expect(v17Snapshot.categoryBudgets.first.categoryId.value, 'cat_food');
    expect(v17Snapshot.personInteractions, isEmpty);

    final v18 = Map<String, dynamic>.from(v17)
      ..['version'] = 18
      ..['person_interactions'] = [
        {
          'id': 'ix-1',
          'person_id': 'person-1',
          'kind': 'meeting',
          'occurred_at': '2026-08-06T15:00:00.000Z',
          'note': 'café',
          'created_at': '2026-08-06T15:05:00.000Z',
        },
      ];

    final v18Snapshot = ExportSnapshot.fromJson(v18);
    expect(v18Snapshot.version, 18);
    expect(v18Snapshot.personInteractions, hasLength(1));
    expect(v18Snapshot.personInteractions.first.kind, InteractionKind.meeting);
    expect(v18Snapshot.trips, isEmpty);

    final v19 = Map<String, dynamic>.from(v18)
      ..['version'] = 19
      ..['trips'] = [
        {
          'id': 'trip-1',
          'title': 'Férias SP',
          'destinations': ['São Paulo'],
          'start_at': '2026-09-01T00:00:00.000Z',
          'end_at': '2026-09-07T00:00:00.000Z',
          'purpose': 'descanso',
          'status': 'planned',
          'created_at': '2026-08-07T10:00:00.000Z',
          'updated_at': '2026-08-07T10:00:00.000Z',
        },
      ];

    final v19Snapshot = ExportSnapshot.fromJson(v19);
    expect(v19Snapshot.version, 19);
    expect(v19Snapshot.trips, hasLength(1));
    expect(v19Snapshot.trips.first.title, 'Férias SP');
    expect(v19Snapshot.trips.first.status, TripStatus.planned);
    expect(v19Snapshot.organizations, isEmpty);

    final v20 = Map<String, dynamic>.from(v19)
      ..['version'] = 20
      ..['organizations'] = [
        {
          'id': 'org-1',
          'name': 'Acme Ltd',
          'kind': 'company',
          'notes': 'cliente',
          'created_at': '2026-08-07T10:00:00.000Z',
          'updated_at': '2026-08-07T10:00:00.000Z',
        },
      ];

    final v20Snapshot = ExportSnapshot.fromJson(v20);
    expect(v20Snapshot.version, 20);
    expect(v20Snapshot.organizations, hasLength(1));
    expect(v20Snapshot.organizations.first.name, 'Acme Ltd');
    expect(v20Snapshot.organizations.first.kind, OrganizationKind.company);
    expect(v20Snapshot.personOrganizationLinks, isEmpty);

    final v21 = Map<String, dynamic>.from(v20)
      ..['version'] = 21
      ..['person_organization_links'] = [
        {
          'person_id': 'person-1',
          'organization_id': 'org-1',
          'linked_at': '2026-08-07T11:00:00.000Z',
          'role': 'membro',
        },
      ];

    final v21Snapshot = ExportSnapshot.fromJson(v21);
    expect(v21Snapshot.version, 21);
    expect(v21Snapshot.personOrganizationLinks, hasLength(1));
    expect(v21Snapshot.personOrganizationLinks.first.personId.value, 'person-1');
    expect(
      v21Snapshot.personOrganizationLinks.first.organizationId.value,
      'org-1',
    );
    expect(v21Snapshot.personOrganizationLinks.first.role, 'membro');
    expect(v21Snapshot.homeMaintenanceTasks, isEmpty);

    final v22 = Map<String, dynamic>.from(v21)
      ..['version'] = 22
      ..['home_maintenance_tasks'] = [
        {
          'id': 'hm-1',
          'title': 'Filtro ar',
          'system_or_item': 'HVAC',
          'cadence_days': 90,
          'created_at': '2026-08-07T10:00:00.000Z',
          'updated_at': '2026-08-07T10:00:00.000Z',
        },
      ];

    final v22Snapshot = ExportSnapshot.fromJson(v22);
    expect(v22Snapshot.version, 22);
    expect(v22Snapshot.homeMaintenanceTasks, hasLength(1));
    expect(v22Snapshot.homeMaintenanceTasks.first.title, 'Filtro ar');
    expect(v22Snapshot.homeMaintenanceTasks.first.cadenceDays, 90);
    expect(v22Snapshot.questInventoryLinks, isEmpty);

    final v23 = Map<String, dynamic>.from(v22)
      ..['version'] = 23
      ..['quest_inventory_links'] = [
        {
          'quest_id': 'quest-1',
          'inventory_item_id': 'item-1',
          'linked_at': '2026-08-07T11:00:00.000Z',
        },
      ];

    final v23Snapshot = ExportSnapshot.fromJson(v23);
    expect(v23Snapshot.version, 23);
    expect(v23Snapshot.questInventoryLinks, hasLength(1));
    expect(v23Snapshot.questInventoryLinks.first.questId.value, 'quest-1');
    expect(v23Snapshot.commitments, isEmpty);

    final v24 = Map<String, dynamic>.from(v23)
      ..['version'] = 24
      ..['commitments'] = [
        {
          'id': 'cmt-1',
          'description': 'Ligar amanhã',
          'made_by_label': 'eu',
          'made_to_label': 'Ana',
          'status': 'open',
          'created_at': '2026-08-07T12:00:00.000Z',
          'updated_at': '2026-08-07T12:00:00.000Z',
        },
      ];

    final v24Snapshot = ExportSnapshot.fromJson(v24);
    expect(v24Snapshot.version, 24);
    expect(v24Snapshot.commitments, hasLength(1));
    expect(v24Snapshot.commitments.first.description, 'Ligar amanhã');
    expect(v24Snapshot.commitments.first.madeToLabel, 'Ana');
    expect(v24Snapshot.contextZones, isEmpty);

    final v25 = Map<String, dynamic>.from(v24)
      ..['version'] = 25
      ..['context_zones'] = [
        {
          'id': 'zone-1',
          'name': 'Avião',
          'capabilities': ['read', 'notes'],
          'unavailable_work_types': ['calls'],
          'connectivity': 'offline',
          'created_at': '2026-08-07T12:00:00.000Z',
          'updated_at': '2026-08-07T12:00:00.000Z',
        },
      ];

    final v25Snapshot = ExportSnapshot.fromJson(v25);
    expect(v25Snapshot.version, 25);
    expect(v25Snapshot.contextZones, hasLength(1));
    expect(v25Snapshot.contextZones.first.name, 'Avião');
    expect(v25Snapshot.contextZones.first.connectivity, ZoneConnectivity.offline);
    expect(v25Snapshot.integrationConsents, isEmpty);
    expect(v25Snapshot.externalCalendarEvents, isEmpty);

    final v26 = Map<String, dynamic>.from(v25)
      ..['version'] = 26
      ..['integration_consents'] = [
        {
          'id': 'consent-1',
          'kind': 'calendarIcs',
          'enabled': true,
          'granted_at': '2026-08-07T12:00:00.000Z',
          'created_at': '2026-08-07T12:00:00.000Z',
          'updated_at': '2026-08-07T12:00:00.000Z',
        },
      ]
      ..['external_calendar_events'] = [
        {
          'id': 'evt-1',
          'external_uid': 'uid-1',
          'title': 'Reunião',
          'start_at': '2026-08-07T14:00:00.000Z',
          'end_at': '2026-08-07T15:00:00.000Z',
          'source_type': 'integration',
          'imported_at': '2026-08-07T12:00:00.000Z',
          'created_at': '2026-08-07T12:00:00.000Z',
          'updated_at': '2026-08-07T12:00:00.000Z',
        },
      ];

    final v26Snapshot = ExportSnapshot.fromJson(v26);
    expect(v26Snapshot.version, 26);
    expect(v26Snapshot.integrationConsents, hasLength(1));
    expect(v26Snapshot.integrationConsents.first.kind, IntegrationKind.calendarIcs);
    expect(v26Snapshot.externalCalendarEvents, hasLength(1));
    expect(v26Snapshot.externalCalendarEvents.first.title, 'Reunião');
  });

  test('parses export version 27 with zone_trip_links', () {
    final v27 = Map<String, dynamic>.from(baseJson)
      ..['version'] = 27
      ..['trips'] = [
        {
          'id': 'trip-1',
          'title': 'Lisboa',
          'destinations': <String>[],
          'status': 'planned',
          'created_at': '2026-08-07T10:00:00.000Z',
          'updated_at': '2026-08-07T10:00:00.000Z',
        },
      ]
      ..['context_zones'] = [
        {
          'id': 'zone-1',
          'name': 'Avião',
          'capabilities': <String>[],
          'unavailable_work_types': <String>[],
          'connectivity': 'limited',
          'created_at': '2026-08-07T10:00:00.000Z',
          'updated_at': '2026-08-07T10:00:00.000Z',
        },
      ]
      ..['zone_trip_links'] = [
        {
          'zone_id': 'zone-1',
          'trip_id': 'trip-1',
          'linked_at': '2026-08-07T11:00:00.000Z',
        },
      ];

    final snapshot = ExportSnapshot.fromJson(v27);
    expect(snapshot.version, 27);
    expect(snapshot.zoneTripLinks, hasLength(1));
    expect(snapshot.zoneTripLinks.first.zoneId.value, 'zone-1');
    expect(snapshot.zoneTripLinks.first.tripId.value, 'trip-1');
  });

  test('parses export version 28 with health_appointments', () {
    final v28 = Map<String, dynamic>.from(baseJson)
      ..['version'] = 28
      ..['health_appointments'] = [
        {
          'id': 'appt-1',
          'title': 'Consulta',
          'scheduled_at': '2026-09-01T10:00:00.000Z',
          'status': 'scheduled',
          'created_at': '2026-08-07T10:00:00.000Z',
          'updated_at': '2026-08-07T10:00:00.000Z',
        },
      ];
    final snapshot = ExportSnapshot.fromJson(v28);
    expect(snapshot.version, 28);
    expect(snapshot.healthAppointments, hasLength(1));
    expect(snapshot.healthAppointments.single.title, 'Consulta');
  });

  test('parses export version 29 with trip_inventory_links', () {
    final v29 = Map<String, dynamic>.from(baseJson)
      ..['version'] = 29
      ..['trips'] = [
        {
          'id': 'trip-1',
          'title': 'Lisboa',
          'destinations': <String>[],
          'status': 'planned',
          'created_at': '2026-08-07T10:00:00.000Z',
          'updated_at': '2026-08-07T10:00:00.000Z',
        },
      ]
      ..['inventory_items'] = [
        {
          'id': 'inv-1',
          'name': 'Mochila',
          'category': 'clothing',
          'status': 'active',
          'tags': <String>[],
          'created_at': '2026-08-07T10:00:00.000Z',
          'updated_at': '2026-08-07T10:00:00.000Z',
        },
      ]
      ..['trip_inventory_links'] = [
        {
          'trip_id': 'trip-1',
          'inventory_item_id': 'inv-1',
          'linked_at': '2026-08-07T11:00:00.000Z',
        },
      ];

    final snapshot = ExportSnapshot.fromJson(v29);
    expect(snapshot.version, 29);
    expect(snapshot.tripInventoryLinks, hasLength(1));
    expect(snapshot.tripInventoryLinks.first.tripId.value, 'trip-1');
    expect(snapshot.tripInventoryLinks.first.inventoryItemId.value, 'inv-1');
  });

  test('rejects unsupported version 31', () {
    final json = Map<String, dynamic>.from(baseJson)..['version'] = 31;

    expect(
      () => ExportSnapshot.fromJson(json),
      throwsA(
        predicate<ExportSnapshotException>(
          (e) => e.message.contains('31'),
        ),
      ),
    );
  });

  test('rejects unsupported version 99', () {
    final json = Map<String, dynamic>.from(baseJson)..['version'] = 99;

    expect(
      () => ExportSnapshot.fromJson(json),
      throwsA(
        predicate<ExportSnapshotException>(
          (e) => e.message.contains('99'),
        ),
      ),
    );
  });

  test('fromJsonString parses valid export', () {
    final json = Map<String, dynamic>.from(baseJson)..['version'] = 1;
    final snapshot = ExportSnapshot.fromJsonString(jsonEncode(json));
    expect(snapshot.tasks.first.title, 'Comprar leite');
  });
}
