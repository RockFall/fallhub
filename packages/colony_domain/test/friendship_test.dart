import 'package:colony_domain/colony_domain.dart';
import 'package:test/test.dart';

void main() {
  final now = DateTime.utc(2026, 8, 23, 12);

  PersonInteraction encounter({
    required String id,
    required DateTime at,
    InteractionKind kind = InteractionKind.meeting,
  }) {
    return PersonInteraction.create(
      id: EntityId(id),
      profileId: EntityId('profile-1'),
      personId: EntityId('person-1'),
      kind: kind,
      occurredAt: at,
      createdAt: at,
    );
  }

  group('Friendship', () {
    test('create trims notes and defaults cadence from kind', () {
      final friendship = Friendship.create(
        id: EntityId('f-1'),
        profileId: EntityId('profile-1'),
        personId: EntityId('person-1'),
        kind: FriendshipKind.close,
        howWeMet: '  faculdade  ',
        notes: '  mesa de RPG  ',
        createdAt: now,
      );

      expect(friendship.howWeMet, 'faculdade');
      expect(friendship.notes, 'mesa de RPG');
      expect(friendship.cadence, FriendshipCadence.fortnightly);
      expect(friendship.isArchived, isFalse);
    });

    test('empty howWeMet becomes null', () {
      final friendship = Friendship.create(
        id: EntityId('f-1'),
        profileId: EntityId('profile-1'),
        personId: EntityId('person-1'),
        howWeMet: '   ',
        createdAt: now,
      );
      expect(friendship.howWeMet, isNull);
      expect(friendship.kind, FriendshipKind.unspecified);
      expect(friendship.cadence, FriendshipCadence.whenever);
    });
  });

  group('FriendshipCircle', () {
    test('create trims name and rejects empty', () {
      final circle = FriendshipCircle.create(
        id: EntityId('c-1'),
        profileId: EntityId('profile-1'),
        name: '  RPG  ',
        notes: '  sexta  ',
        defaultCadence: FriendshipCadence.monthly,
        createdAt: now,
      );
      expect(circle.name, 'RPG');
      expect(circle.notes, 'sexta');
      expect(
        () => FriendshipCircle.create(
          id: EntityId('c-2'),
          profileId: EntityId('profile-1'),
          name: '  ',
          createdAt: now,
        ),
        throwsArgumentError,
      );
    });
  });

  group('FriendshipRhythm', () {
    test('never met stays neverMet even with cadence', () {
      final rhythm = FriendshipRhythm.from(
        interactions: const [],
        cadence: FriendshipCadence.weekly,
        now: now,
      );
      expect(rhythm.attention, FriendshipAttention.neverMet);
      expect(rhythm.encounterCount, 0);
      expect(rhythm.needsAttention, isFalse);
    });

    test('messages do not count as encounters', () {
      final rhythm = FriendshipRhythm.from(
        interactions: [
          PersonInteraction.create(
            id: EntityId('ix-1'),
            profileId: EntityId('profile-1'),
            personId: EntityId('person-1'),
            kind: InteractionKind.message,
            occurredAt: now.subtract(const Duration(days: 2)),
            createdAt: now,
          ),
        ],
        cadence: FriendshipCadence.weekly,
        now: now,
      );
      expect(rhythm.attention, FriendshipAttention.neverMet);
    });

    test('whenever after an encounter is noCadence, not overdue', () {
      final rhythm = FriendshipRhythm.from(
        interactions: [
          encounter(id: 'e1', at: now.subtract(const Duration(days: 200))),
        ],
        cadence: FriendshipCadence.whenever,
        now: now,
      );
      expect(rhythm.attention, FriendshipAttention.noCadence);
      expect(rhythm.daysSinceLastEncounter, 200);
      expect(rhythm.needsAttention, isFalse);
    });

    test('monthly cadence is overdue after 30 days', () {
      final rhythm = FriendshipRhythm.from(
        interactions: [
          encounter(id: 'e1', at: now.subtract(const Duration(days: 40))),
        ],
        cadence: FriendshipCadence.monthly,
        now: now,
      );
      expect(rhythm.attention, FriendshipAttention.overdue);
      expect(rhythm.needsAttention, isTrue);
    });

    test('monthly cadence is dueSoon at 80% of interval', () {
      final rhythm = FriendshipRhythm.from(
        interactions: [
          encounter(id: 'e1', at: now.subtract(const Duration(days: 26))),
        ],
        cadence: FriendshipCadence.monthly,
        now: now,
      );
      expect(rhythm.attention, FriendshipAttention.dueSoon);
    });

    test('median interval uses the middle gap', () {
      final rhythm = FriendshipRhythm.from(
        interactions: [
          encounter(id: 'e1', at: DateTime.utc(2026, 6, 1)),
          encounter(id: 'e2', at: DateTime.utc(2026, 6, 15)),
          encounter(
            id: 'e3',
            at: DateTime.utc(2026, 7, 15),
            kind: InteractionKind.gathering,
          ),
        ],
        cadence: FriendshipCadence.whenever,
        now: now,
      );
      expect(rhythm.encounterCount, 3);
      expect(rhythm.typicalIntervalDays, 30);
    });
  });

  group('FriendshipOverview', () {
    test('assemble hides archived people and sorts overdue first', () {
      final ana = Person.create(
        id: EntityId('ana'),
        profileId: EntityId('profile-1'),
        displayName: 'Ana',
        createdAt: now,
      );
      final bruno = Person.create(
        id: EntityId('bruno'),
        profileId: EntityId('profile-1'),
        displayName: 'Bruno',
        createdAt: now,
      ).copyWith(archivedAt: now, updatedAt: now);
      final circle = FriendshipCircle.create(
        id: EntityId('rpg'),
        profileId: EntityId('profile-1'),
        name: 'RPG',
        createdAt: now,
      );
      final rows = FriendshipOverview.assemble(
        people: [ana, bruno],
        friendships: [
          Friendship.create(
            id: EntityId('f-ana'),
            profileId: EntityId('profile-1'),
            personId: ana.id,
            kind: FriendshipKind.close,
            cadence: FriendshipCadence.weekly,
            createdAt: now,
          ),
          Friendship.create(
            id: EntityId('f-bruno'),
            profileId: EntityId('profile-1'),
            personId: bruno.id,
            kind: FriendshipKind.regular,
            createdAt: now,
          ),
        ],
        circles: [circle],
        memberships: [
          FriendshipCircleMembership(
            personId: ana.id,
            circleId: circle.id,
            linkedAt: now,
          ),
        ],
        interactions: [
          PersonInteraction.create(
            id: EntityId('e1'),
            profileId: EntityId('profile-1'),
            personId: ana.id,
            kind: InteractionKind.meeting,
            occurredAt: now.subtract(const Duration(days: 20)),
            createdAt: now,
          ),
        ],
        now: now,
      );

      expect(rows, hasLength(1));
      expect(rows.single.person.displayName, 'Ana');
      expect(rows.single.circles.single.name, 'RPG');
      expect(rows.single.rhythm.attention, FriendshipAttention.overdue);
    });
  });
}
