import 'package:equatable/equatable.dart';

import 'domain_event.dart';
import 'enums.dart';
import 'id_generator.dart';
import 'weekly_review.dart';

/// Structured narrative bullet from local rules (ADR-033).
/// [templateId] is resolved to localized text in the app layer.
class NarrativeDigestBullet extends Equatable {
  const NarrativeDigestBullet({
    required this.templateId,
    this.params = const {},
    this.evidenceEventIds = const [],
  });

  final String templateId;
  final Map<String, Object?> params;
  final List<EntityId> evidenceEventIds;

  @override
  List<Object?> get props => [templateId, params, evidenceEventIds];
}

/// Ephemeral weekly narrative digest — rules only, no LLM (ADR-033).
class NarrativeDigest extends Equatable {
  const NarrativeDigest({
    required this.periodStart,
    required this.periodEnd,
    required this.bullets,
    required this.generatedAt,
    this.generator = NarrativeDigestRules.generatorId,
  });

  final DateTime periodStart;
  final DateTime periodEnd;
  final List<NarrativeDigestBullet> bullets;
  final DateTime generatedAt;
  final String generator;

  @override
  List<Object?> get props =>
      [periodStart, periodEnd, bullets, generatedAt, generator];
}

/// Deterministic local rules_v1 generator (ADR-033).
abstract final class NarrativeDigestRules {
  static const generatorId = 'rules_v1';
  static const minBullets = 3;
  static const maxBullets = 7;

  static NarrativeDigest generate({
    required DateTime periodStart,
    required DateTime periodEnd,
    required List<DomainEvent> events,
    WeeklyReview? weeklyReview,
    required DateTime generatedAt,
  }) {
    final start = periodStart.toUtc();
    final end = periodEnd.toUtc();
    final inWindow = events
        .where(
          (e) =>
              !e.occurredAt.isBefore(start) && e.occurredAt.isBefore(end),
        )
        .toList()
      ..sort((a, b) => a.occurredAt.compareTo(b.occurredAt));

    final bullets = <NarrativeDigestBullet>[];

    bullets.add(
      NarrativeDigestBullet(
        templateId: 'chronicle_events',
        params: {'count': inWindow.length},
        evidenceEventIds: inWindow.take(3).map((e) => e.id).toList(),
      ),
    );

    final questEvents = inWindow
        .where(
          (e) =>
              e.eventType == EventType.questCreated ||
              e.eventType == EventType.questStatusChanged ||
              e.eventType == EventType.questAccepted,
        )
        .toList();
    if (questEvents.isNotEmpty) {
      bullets.add(
        NarrativeDigestBullet(
          templateId: 'quest_activity',
          params: {'count': questEvents.length},
          evidenceEventIds: questEvents.take(3).map((e) => e.id).toList(),
        ),
      );
    }

    final taskEvents = inWindow
        .where(
          (e) =>
              e.eventType == EventType.taskCreated ||
              e.eventType == EventType.taskStatusChanged ||
              e.eventType == EventType.captureCreated,
        )
        .toList();
    if (taskEvents.isNotEmpty) {
      bullets.add(
        NarrativeDigestBullet(
          templateId: 'task_activity',
          params: {'count': taskEvents.length},
          evidenceEventIds: taskEvents.take(3).map((e) => e.id).toList(),
        ),
      );
    }

    final checkIns = inWindow
        .where((e) => e.eventType == EventType.checkInRecorded)
        .toList();
    if (checkIns.isNotEmpty) {
      bullets.add(
        NarrativeDigestBullet(
          templateId: 'check_ins',
          params: {'count': checkIns.length},
          evidenceEventIds: checkIns.take(3).map((e) => e.id).toList(),
        ),
      );
    }

    final decisions = inWindow
        .where((e) => e.eventType == EventType.decisionCreated)
        .toList();
    if (decisions.isNotEmpty) {
      bullets.add(
        NarrativeDigestBullet(
          templateId: 'decisions',
          params: {'count': decisions.length},
          evidenceEventIds: decisions.take(3).map((e) => e.id).toList(),
        ),
      );
    }

    final integrations = inWindow
        .where(
          (e) => e.eventType == EventType.externalCalendarEventsImported,
        )
        .toList();
    if (integrations.isNotEmpty) {
      bullets.add(
        NarrativeDigestBullet(
          templateId: 'ics_imports',
          params: {'count': integrations.length},
          evidenceEventIds: integrations.take(3).map((e) => e.id).toList(),
        ),
      );
    }

    final trips = inWindow
        .where(
          (e) =>
              e.eventType == EventType.tripCreated ||
              e.eventType == EventType.tripStatusChanged,
        )
        .toList();
    if (trips.isNotEmpty) {
      bullets.add(
        NarrativeDigestBullet(
          templateId: 'trip_activity',
          params: {'count': trips.length},
          evidenceEventIds: trips.take(3).map((e) => e.id).toList(),
        ),
      );
    }

    final zones = inWindow
        .where(
          (e) =>
              e.eventType == EventType.contextZoneCreated ||
              e.eventType == EventType.contextZoneUpdated,
        )
        .toList();
    if (zones.isNotEmpty) {
      bullets.add(
        NarrativeDigestBullet(
          templateId: 'zone_activity',
          params: {'count': zones.length},
          evidenceEventIds: zones.take(3).map((e) => e.id).toList(),
        ),
      );
    }

    final commitments = inWindow
        .where((e) => e.eventType == EventType.commitmentCreated)
        .toList();
    if (commitments.isNotEmpty) {
      bullets.add(
        NarrativeDigestBullet(
          templateId: 'commitment_activity',
          params: {'count': commitments.length},
          evidenceEventIds: commitments.take(3).map((e) => e.id).toList(),
        ),
      );
    }

    final appointments = inWindow
        .where(
          (e) =>
              e.eventType == EventType.healthAppointmentCreated ||
              e.eventType == EventType.healthAppointmentUpdated,
        )
        .toList();
    if (appointments.isNotEmpty) {
      bullets.add(
        NarrativeDigestBullet(
          templateId: 'health_appointment_activity',
          params: {'count': appointments.length},
          evidenceEventIds: appointments.take(3).map((e) => e.id).toList(),
        ),
      );
    }

    final financeEvents = inWindow
        .where(
          (e) =>
              e.eventType == EventType.transactionCreated ||
              e.eventType == EventType.transactionUpdated ||
              e.eventType == EventType.categoryBudgetCreated ||
              e.eventType == EventType.categoryBudgetUpdated,
        )
        .toList();
    if (financeEvents.isNotEmpty) {
      bullets.add(
        NarrativeDigestBullet(
          templateId: 'finance_activity',
          params: {'count': financeEvents.length},
          evidenceEventIds: financeEvents.take(3).map((e) => e.id).toList(),
        ),
      );
    }

    final researchEvents = inWindow
        .where(
          (e) =>
              e.eventType == EventType.researchNodeCreated ||
              e.eventType == EventType.researchStatusChanged ||
              e.eventType == EventType.researchSessionLogged ||
              e.eventType == EventType.researchEvidenceCreated,
        )
        .toList();
    if (researchEvents.isNotEmpty) {
      bullets.add(
        NarrativeDigestBullet(
          templateId: 'research_activity',
          params: {'count': researchEvents.length},
          evidenceEventIds: researchEvents.take(3).map((e) => e.id).toList(),
        ),
      );
    }

    final musicEvents = inWindow
        .where(
          (e) =>
              e.eventType == EventType.musicEncounterRecorded ||
              e.eventType == EventType.musicExpeditionStarted ||
              e.eventType == EventType.musicExpeditionCompleted ||
              e.eventType == EventType.musicAtlasJsonImported ||
              e.eventType == EventType.spotifyLibraryPulled ||
              e.eventType == EventType.spotifyNowPlayingCaptured,
        )
        .toList();
    if (musicEvents.isNotEmpty) {
      bullets.add(
        NarrativeDigestBullet(
          templateId: 'music_atlas_activity',
          params: {'count': musicEvents.length},
          evidenceEventIds: musicEvents.take(3).map((e) => e.id).toList(),
        ),
      );
    }

    final inventoryEvents = inWindow
        .where(
          (e) =>
              e.eventType == EventType.inventoryItemCreated ||
              e.eventType == EventType.inventoryItemUpdated ||
              e.eventType == EventType.inventoryItemStatusChanged,
        )
        .toList();
    if (inventoryEvents.isNotEmpty) {
      bullets.add(
        NarrativeDigestBullet(
          templateId: 'inventory_activity',
          params: {'count': inventoryEvents.length},
          evidenceEventIds: inventoryEvents.take(3).map((e) => e.id).toList(),
        ),
      );
    }

    if (weeklyReview != null) {
      final wins = weeklyReview.wins?.trim();
      if (wins != null && wins.isNotEmpty) {
        bullets.add(
          const NarrativeDigestBullet(templateId: 'review_wins'),
        );
      }
      final problems = weeklyReview.problems?.trim();
      if (problems != null && problems.isNotEmpty) {
        bullets.add(
          const NarrativeDigestBullet(templateId: 'review_problems'),
        );
      }
      final learning = weeklyReview.learning?.trim();
      if (learning != null && learning.isNotEmpty) {
        bullets.add(
          const NarrativeDigestBullet(templateId: 'review_learning'),
        );
      }
    }

    if (inWindow.isEmpty && bullets.length < minBullets) {
      bullets.add(const NarrativeDigestBullet(templateId: 'quiet_week'));
    }

    // Ensure at least [minBullets] with stable fillers.
    while (bullets.length < minBullets) {
      bullets.add(
        NarrativeDigestBullet(
          templateId: 'period_marker',
          params: {
            'start': start.toIso8601String(),
            'end': end.toIso8601String(),
          },
        ),
      );
    }

    final capped = prioritizeBullets(bullets, maxBullets);
    return NarrativeDigest(
      periodStart: start,
      periodEnd: end,
      bullets: capped,
      generatedAt: generatedAt.toUtc(),
    );
  }

  /// Higher = more valuable when capping above [maxBullets].
  static int bulletPriority(String templateId) => switch (templateId) {
        'chronicle_events' => 100,
        'review_problems' => 90,
        'review_wins' => 85,
        'health_appointment_activity' => 80,
        'decisions' => 75,
        'quest_activity' => 70,
        'finance_activity' => 65,
        'research_activity' => 60,
        'music_atlas_activity' => 58,
        'commitment_activity' => 55,
        'trip_activity' => 50,
        'task_activity' => 45,
        'check_ins' => 40,
        'inventory_activity' => 35,
        'ics_imports' => 30,
        'zone_activity' => 25,
        'review_learning' => 20,
        'quiet_week' => 10,
        'period_marker' => 5,
        _ => 0,
      };

  /// Keeps highest-priority bullets (stable among equals) up to [limit].
  static List<NarrativeDigestBullet> prioritizeBullets(
    List<NarrativeDigestBullet> bullets,
    int limit,
  ) {
    if (bullets.length <= limit) return List.of(bullets);
    final indexed = [
      for (var i = 0; i < bullets.length; i++) (i, bullets[i]),
    ];
    indexed.sort((a, b) {
      final byPriority =
          bulletPriority(b.$2.templateId) - bulletPriority(a.$2.templateId);
      if (byPriority != 0) return byPriority;
      return a.$1.compareTo(b.$1);
    });
    final kept = indexed.take(limit).toList()
      ..sort((a, b) => a.$1.compareTo(b.$1));
    return kept.map((e) => e.$2).toList();
  }
}
