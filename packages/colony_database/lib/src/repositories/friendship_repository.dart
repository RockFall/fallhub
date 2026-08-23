import 'package:colony_domain/colony_domain.dart';
import 'package:drift/drift.dart';

import '../colony_database.dart';
import 'colony_repositories.dart';

class FriendshipRepository {
  FriendshipRepository(this._db, this._ids, this._clock, this._events);

  final ColonyDatabase _db;
  final IdGenerator _ids;
  final DateTime Function() _clock;
  final DomainEventRepository _events;

  Stream<List<Friendship>> watchAll(EntityId profileId) {
    return (_db.select(_db.friendships)
          ..where((t) => t.profileId.equals(profileId.value))
          ..orderBy([(t) => OrderingTerm.desc(t.updatedAt)]))
        .watch()
        .map((rows) => rows.map(ColonyMappers.toFriendship).toList());
  }

  Future<List<Friendship>> listAll(EntityId profileId) async {
    final rows = await (_db.select(_db.friendships)
          ..where((t) => t.profileId.equals(profileId.value)))
        .get();
    return rows.map(ColonyMappers.toFriendship).toList();
  }

  Future<Friendship?> getByPerson(EntityId personId) async {
    final row = await (_db.select(_db.friendships)
          ..where((t) => t.personId.equals(personId.value)))
        .getSingleOrNull();
    return row == null ? null : ColonyMappers.toFriendship(row);
  }

  Stream<List<FriendshipCircle>> watchCircles(EntityId profileId) {
    return (_db.select(_db.friendshipCircles)
          ..where((t) => t.profileId.equals(profileId.value))
          ..orderBy([(t) => OrderingTerm.asc(t.name)]))
        .watch()
        .map((rows) => rows.map(ColonyMappers.toFriendshipCircle).toList());
  }

  Future<List<FriendshipCircle>> listCircles(EntityId profileId) async {
    final rows = await (_db.select(_db.friendshipCircles)
          ..where((t) => t.profileId.equals(profileId.value)))
        .get();
    return rows.map(ColonyMappers.toFriendshipCircle).toList();
  }

  Stream<List<FriendshipCircleMembership>> watchMemberships(EntityId profileId) {
    final query = _db.select(_db.friendshipCircleMemberships).join([
      innerJoin(
        _db.friendshipCircles,
        _db.friendshipCircles.id
            .equalsExp(_db.friendshipCircleMemberships.circleId),
      ),
    ])
      ..where(_db.friendshipCircles.profileId.equals(profileId.value));
    return query.watch().map(
          (rows) => rows
              .map(
                (row) => ColonyMappers.toFriendshipCircleMembership(
                  row.readTable(_db.friendshipCircleMemberships),
                ),
              )
              .toList(),
        );
  }

  Future<List<FriendshipCircleMembership>> listMemberships(
    EntityId profileId,
  ) async {
    final query = _db.select(_db.friendshipCircleMemberships).join([
      innerJoin(
        _db.friendshipCircles,
        _db.friendshipCircles.id
            .equalsExp(_db.friendshipCircleMemberships.circleId),
      ),
    ])
      ..where(_db.friendshipCircles.profileId.equals(profileId.value));
    final rows = await query.get();
    return rows
        .map(
          (row) => ColonyMappers.toFriendshipCircleMembership(
            row.readTable(_db.friendshipCircleMemberships),
          ),
        )
        .toList();
  }

  Future<Friendship> ensureForPerson({
    required EntityId profileId,
    required EntityId personId,
    FriendshipKind kind = FriendshipKind.unspecified,
    FriendshipCadence? cadence,
    String? howWeMet,
    DateTime? startedAt,
    String? notes,
  }) async {
    final existing = await getByPerson(personId);
    if (existing != null && !existing.isArchived) {
      return existing;
    }
    if (existing != null && existing.isArchived) {
      return save(
        existing.copyWith(
          kind: kind,
          cadence: cadence ?? kind.suggestedCadence,
          howWeMet: howWeMet,
          clearHowWeMet: howWeMet == null || howWeMet.trim().isEmpty,
          startedAt: startedAt,
          clearStartedAt: startedAt == null,
          notes: notes,
          clearNotes: notes == null || notes.trim().isEmpty,
          clearArchivedAt: true,
          updatedAt: _clock(),
        ),
      );
    }
    return create(
      profileId: profileId,
      personId: personId,
      kind: kind,
      cadence: cadence,
      howWeMet: howWeMet,
      startedAt: startedAt,
      notes: notes,
    );
  }

  Future<Friendship> create({
    required EntityId profileId,
    required EntityId personId,
    FriendshipKind kind = FriendshipKind.unspecified,
    FriendshipCadence? cadence,
    String? howWeMet,
    DateTime? startedAt,
    String? notes,
  }) async {
    final existing = await getByPerson(personId);
    if (existing != null) {
      throw StateError('Já existe uma amizade para esta pessoa');
    }
    final now = _clock();
    final friendship = Friendship.create(
      id: EntityId(_ids.newId()),
      profileId: profileId,
      personId: personId,
      kind: kind,
      cadence: cadence,
      howWeMet: howWeMet,
      startedAt: startedAt,
      notes: notes,
      createdAt: now,
    );
    await _db.transaction(() async {
      await _db.into(_db.friendships).insert(
            ColonyMappers.fromFriendship(friendship),
          );
      await _events.record(
        aggregateType: AggregateType.friendship,
        aggregateId: friendship.id,
        eventType: EventType.friendshipCreated,
        payload: {
          'person_id': personId.value,
          'kind': kind.name,
        },
        sourceType: SourceType.manual,
      );
    });
    return friendship;
  }

  Future<Friendship> save(Friendship friendship) async {
    final updated = friendship.copyWith(updatedAt: _clock());
    await _db.into(_db.friendships).insertOnConflictUpdate(
          ColonyMappers.fromFriendship(updated),
        );
    await _events.record(
      aggregateType: AggregateType.friendship,
      aggregateId: updated.id,
      eventType: EventType.friendshipUpdated,
      payload: {
        'person_id': updated.personId.value,
        'kind': updated.kind.name,
      },
      sourceType: SourceType.manual,
    );
    return updated;
  }

  Future<Friendship> archive(Friendship friendship) async {
    final now = _clock();
    final updated = friendship.copyWith(archivedAt: now, updatedAt: now);
    await _db.into(_db.friendships).insertOnConflictUpdate(
          ColonyMappers.fromFriendship(updated),
        );
    await _events.record(
      aggregateType: AggregateType.friendship,
      aggregateId: updated.id,
      eventType: EventType.friendshipArchived,
      payload: {
        'person_id': updated.personId.value,
      },
      sourceType: SourceType.manual,
    );
    return updated;
  }

  Future<FriendshipCircle> createCircle({
    required EntityId profileId,
    required String name,
    String? notes,
    FriendshipCadence? defaultCadence,
  }) async {
    final now = _clock();
    final circle = FriendshipCircle.create(
      id: EntityId(_ids.newId()),
      profileId: profileId,
      name: name,
      notes: notes,
      defaultCadence: defaultCadence,
      createdAt: now,
    );
    await _db.transaction(() async {
      await _db.into(_db.friendshipCircles).insert(
            ColonyMappers.fromFriendshipCircle(circle),
          );
      await _events.record(
        aggregateType: AggregateType.friendshipCircle,
        aggregateId: circle.id,
        eventType: EventType.friendshipCircleCreated,
        payload: {'name': circle.name},
        sourceType: SourceType.manual,
      );
    });
    return circle;
  }

  Future<FriendshipCircle> saveCircle(FriendshipCircle circle) async {
    final updated = circle.copyWith(updatedAt: _clock());
    await _db.into(_db.friendshipCircles).insertOnConflictUpdate(
          ColonyMappers.fromFriendshipCircle(updated),
        );
    await _events.record(
      aggregateType: AggregateType.friendshipCircle,
      aggregateId: updated.id,
      eventType: EventType.friendshipCircleUpdated,
      payload: {'name': updated.name},
      sourceType: SourceType.manual,
    );
    return updated;
  }

  Future<FriendshipCircle> archiveCircle(FriendshipCircle circle) async {
    final now = _clock();
    final updated = circle.copyWith(archivedAt: now, updatedAt: now);
    await _db.into(_db.friendshipCircles).insertOnConflictUpdate(
          ColonyMappers.fromFriendshipCircle(updated),
        );
    await _events.record(
      aggregateType: AggregateType.friendshipCircle,
      aggregateId: updated.id,
      eventType: EventType.friendshipCircleArchived,
      payload: {'name': updated.name},
      sourceType: SourceType.manual,
    );
    return updated;
  }

  Future<void> linkPersonToCircle({
    required EntityId personId,
    required EntityId circleId,
  }) async {
    final now = _clock();
    await _db.into(_db.friendshipCircleMemberships).insertOnConflictUpdate(
          ColonyMappers.fromFriendshipCircleMembership(
            FriendshipCircleMembership(
              personId: personId,
              circleId: circleId,
              linkedAt: now,
            ),
          ),
        );
  }

  Future<void> unlinkPersonFromCircle({
    required EntityId personId,
    required EntityId circleId,
  }) async {
    await (_db.delete(_db.friendshipCircleMemberships)
          ..where(
            (t) =>
                t.personId.equals(personId.value) &
                t.circleId.equals(circleId.value),
          ))
        .go();
  }

  Future<void> replacePersonCircles({
    required EntityId personId,
    required Iterable<EntityId> circleIds,
  }) async {
    await _db.transaction(() async {
      await (_db.delete(_db.friendshipCircleMemberships)
            ..where((t) => t.personId.equals(personId.value)))
          .go();
      for (final circleId in circleIds) {
        await linkPersonToCircle(personId: personId, circleId: circleId);
      }
    });
  }
}
