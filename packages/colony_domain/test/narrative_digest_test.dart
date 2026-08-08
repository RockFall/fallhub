import 'package:colony_domain/colony_domain.dart';
import 'package:test/test.dart';

DomainEvent _event({
  required String id,
  required EventType type,
  required DateTime at,
}) {
  return DomainEvent.record(
    id: EntityId(id),
    aggregateType: AggregateType.task,
    aggregateId: EntityId('agg-$id'),
    eventType: type,
    occurredAt: at,
    recordedAt: at,
    sourceType: SourceType.manual,
    payload: const {},
  );
}

void main() {
  final weekStart = DateTime.utc(2026, 8, 3);
  final weekEnd = weekStart.add(const Duration(days: 7));
  final now = DateTime.utc(2026, 8, 7, 12);

  test('rules_v1 produces 3–7 bullets with generator id', () {
    final events = [
      _event(
        id: 'e1',
        type: EventType.taskCreated,
        at: DateTime.utc(2026, 8, 4, 10),
      ),
      _event(
        id: 'e2',
        type: EventType.questCreated,
        at: DateTime.utc(2026, 8, 5, 10),
      ),
      _event(
        id: 'e3',
        type: EventType.checkInRecorded,
        at: DateTime.utc(2026, 8, 6, 10),
      ),
    ];

    final digest = NarrativeDigestRules.generate(
      periodStart: weekStart,
      periodEnd: weekEnd,
      events: events,
      weeklyReview: WeeklyReview(
        id: EntityId('wr1'),
        profileId: EntityId('p1'),
        weekStartDate: weekStart,
        createdAt: now,
        wins: 'Fechei a missão',
        problems: 'Atraso no projeto',
      ),
      generatedAt: now,
    );

    expect(digest.generator, 'rules_v1');
    expect(digest.bullets.length, inInclusiveRange(3, 7));
    expect(
      digest.bullets.any((b) => b.templateId == 'chronicle_events'),
      isTrue,
    );
    expect(
      digest.bullets.any((b) => b.templateId == 'quest_activity'),
      isTrue,
    );
    expect(
      digest.bullets.any((b) => b.templateId == 'review_wins'),
      isTrue,
    );
    expect(digest.bullets.first.evidenceEventIds, isNotEmpty);
  });

  test('quiet week still reaches min bullets', () {
    final digest = NarrativeDigestRules.generate(
      periodStart: weekStart,
      periodEnd: weekEnd,
      events: const [],
      generatedAt: now,
    );
    expect(digest.bullets.length, greaterThanOrEqualTo(3));
    expect(
      digest.bullets.any((b) => b.templateId == 'quiet_week'),
      isTrue,
    );
  });

  test('rules include trip zone and commitment signals', () {
    final digest = NarrativeDigestRules.generate(
      periodStart: weekStart,
      periodEnd: weekEnd,
      events: [
        _event(
          id: 't1',
          type: EventType.tripCreated,
          at: DateTime.utc(2026, 8, 4, 10),
        ),
        _event(
          id: 'z1',
          type: EventType.contextZoneCreated,
          at: DateTime.utc(2026, 8, 5, 10),
        ),
        _event(
          id: 'c1',
          type: EventType.commitmentCreated,
          at: DateTime.utc(2026, 8, 6, 10),
        ),
      ],
      generatedAt: now,
    );
    expect(
      digest.bullets.any((b) => b.templateId == 'trip_activity'),
      isTrue,
    );
    expect(
      digest.bullets.any((b) => b.templateId == 'zone_activity'),
      isTrue,
    );
    expect(
      digest.bullets.any((b) => b.templateId == 'commitment_activity'),
      isTrue,
    );
  });

  test('rules_v1 emits health_appointment_activity signal', () {
    final digest = NarrativeDigestRules.generate(
      periodStart: weekStart,
      periodEnd: weekEnd,
      events: [
        _event(
          id: 'a1',
          type: EventType.healthAppointmentCreated,
          at: DateTime.utc(2026, 8, 5, 10),
        ),
      ],
      generatedAt: now,
    );
    expect(
      digest.bullets.any((b) => b.templateId == 'health_appointment_activity'),
      isTrue,
    );
  });

  test('ignores events outside period', () {
    final digest = NarrativeDigestRules.generate(
      periodStart: weekStart,
      periodEnd: weekEnd,
      events: [
        _event(
          id: 'old',
          type: EventType.taskCreated,
          at: DateTime.utc(2026, 7, 1),
        ),
      ],
      generatedAt: now,
    );
    final chronicle = digest.bullets
        .firstWhere((b) => b.templateId == 'chronicle_events');
    expect(chronicle.params['count'], 0);
  });

  test('rules include finance research inventory signals', () {
    final digest = NarrativeDigestRules.generate(
      periodStart: weekStart,
      periodEnd: weekEnd,
      events: [
        _event(
          id: 'f1',
          type: EventType.transactionCreated,
          at: DateTime.utc(2026, 8, 4, 10),
        ),
        _event(
          id: 'r1',
          type: EventType.researchEvidenceCreated,
          at: DateTime.utc(2026, 8, 5, 10),
        ),
        _event(
          id: 'i1',
          type: EventType.inventoryItemCreated,
          at: DateTime.utc(2026, 8, 6, 10),
        ),
      ],
      generatedAt: now,
    );
    expect(
      digest.bullets.any((b) => b.templateId == 'finance_activity'),
      isTrue,
    );
    expect(
      digest.bullets.any((b) => b.templateId == 'research_activity'),
      isTrue,
    );
    expect(
      digest.bullets.any((b) => b.templateId == 'inventory_activity'),
      isTrue,
    );
  });

  test('priority ranking keeps high-value bullets when over max', () {
    final many = <DomainEvent>[
      for (var i = 0; i < 3; i++)
        _event(
          id: 'q$i',
          type: EventType.questCreated,
          at: DateTime.utc(2026, 8, 4, i + 1),
        ),
      _event(
        id: 'dec',
        type: EventType.decisionCreated,
        at: DateTime.utc(2026, 8, 4, 12),
      ),
      _event(
        id: 'appt',
        type: EventType.healthAppointmentCreated,
        at: DateTime.utc(2026, 8, 4, 13),
      ),
      _event(
        id: 'fin',
        type: EventType.transactionCreated,
        at: DateTime.utc(2026, 8, 4, 14),
      ),
      _event(
        id: 'res',
        type: EventType.researchNodeCreated,
        at: DateTime.utc(2026, 8, 4, 15),
      ),
      _event(
        id: 'inv',
        type: EventType.inventoryItemCreated,
        at: DateTime.utc(2026, 8, 4, 16),
      ),
      _event(
        id: 'zone',
        type: EventType.contextZoneCreated,
        at: DateTime.utc(2026, 8, 4, 17),
      ),
      _event(
        id: 'ics',
        type: EventType.externalCalendarEventsImported,
        at: DateTime.utc(2026, 8, 4, 18),
      ),
      _event(
        id: 'task',
        type: EventType.taskCreated,
        at: DateTime.utc(2026, 8, 4, 19),
      ),
    ];

    final digest = NarrativeDigestRules.generate(
      periodStart: weekStart,
      periodEnd: weekEnd,
      events: many,
      weeklyReview: WeeklyReview(
        id: EntityId('wr2'),
        profileId: EntityId('p1'),
        weekStartDate: weekStart,
        createdAt: now,
        wins: 'Ok',
        problems: 'Bloqueio',
        learning: 'Nota',
      ),
      generatedAt: now,
    );

    expect(digest.bullets.length, NarrativeDigestRules.maxBullets);
    final ids = digest.bullets.map((b) => b.templateId).toSet();
    expect(ids.contains('chronicle_events'), isTrue);
    expect(ids.contains('review_problems'), isTrue);
    expect(ids.contains('health_appointment_activity'), isTrue);
    // Low-priority filler should be dropped when over cap.
    expect(ids.contains('zone_activity'), isFalse);
  });
}
