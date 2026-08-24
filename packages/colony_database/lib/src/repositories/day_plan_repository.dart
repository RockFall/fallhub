import 'package:colony_domain/colony_domain.dart';
import 'package:drift/drift.dart';

import '../colony_database.dart';
import 'colony_repositories.dart';

class DayPlanRepository {
  DayPlanRepository(this._db, this._ids, this._clock, this._events, this._tasks);

  final ColonyDatabase _db;
  final IdGenerator _ids;
  final DateTime Function() _clock;
  final DomainEventRepository _events;
  final TaskRepository _tasks;

  Stream<DayPlanWithItems?> watchForDate(
    EntityId profileId,
    String localDate,
  ) {
    final planQuery = _db.select(_db.dayPlans)
      ..where(
        (t) =>
            t.profileId.equals(profileId.value) & t.localDate.equals(localDate),
      );
    return planQuery.watchSingleOrNull().asyncExpand((planRow) {
      if (planRow == null) return Stream<DayPlanWithItems?>.value(null);
      final plan = ColonyMappers.toDayPlan(planRow);
      return (_db.select(_db.dayPlanItems)
            ..where((t) => t.dayPlanId.equals(plan.id.value))
            ..orderBy([(t) => OrderingTerm.asc(t.orderIndex)]))
          .watch()
          .map(
            (rows) => DayPlanWithItems(
              plan: plan,
              items: rows.map(ColonyMappers.toDayPlanItem).toList(),
            ),
          );
    });
  }

  Future<DayPlanWithItems?> getForDate(
    EntityId profileId,
    String localDate,
  ) async {
    final planRow = await (_db.select(_db.dayPlans)
          ..where(
            (t) =>
                t.profileId.equals(profileId.value) &
                t.localDate.equals(localDate),
          ))
        .getSingleOrNull();
    if (planRow == null) return null;
    final plan = ColonyMappers.toDayPlan(planRow);
    return DayPlanWithItems(plan: plan, items: await _itemsFor(plan.id));
  }

  Future<DayPlanWithItems> getOrCreateForDate(
    EntityId profileId,
    String localDate,
  ) async {
    return _db.transaction(() async {
      final existing = await getForDate(profileId, localDate);
      if (existing != null) return existing;
      final now = _clock();
      final plan = DayPlan.forDate(
        id: EntityId(_ids.newId()),
        profileId: profileId,
        localDate: localDate,
        createdAt: now,
      );
      try {
        await _db.into(_db.dayPlans).insert(ColonyMappers.fromDayPlan(plan));
      } catch (_) {
        final raced = await getForDate(profileId, localDate);
        if (raced != null) return raced;
        rethrow;
      }
      await _events.record(
        aggregateType: AggregateType.dayPlan,
        aggregateId: plan.id,
        eventType: EventType.dayPlanCreated,
        payload: {'local_date': localDate},
      );
      return DayPlanWithItems(plan: plan, items: const []);
    });
  }

  Future<DayPlanWithItems> getOrCreateToday(EntityId profileId) {
    return getOrCreateForDate(profileId, dayPlanLocalDateKey(_clock()));
  }

  Future<List<DayPlan>> listPlans(EntityId profileId) async {
    final rows = await (_db.select(_db.dayPlans)
          ..where((t) => t.profileId.equals(profileId.value)))
        .get();
    return rows.map(ColonyMappers.toDayPlan).toList();
  }

  Future<List<DayPlanItem>> listItems(EntityId profileId) async {
    final plans = await listPlans(profileId);
    final items = <DayPlanItem>[];
    for (final plan in plans) {
      items.addAll(await _itemsFor(plan.id));
    }
    return items;
  }

  Future<DayPlanItem?> getItemById(EntityId id) async {
    final row = await (_db.select(_db.dayPlanItems)
          ..where((t) => t.id.equals(id.value)))
        .getSingleOrNull();
    return row == null ? null : ColonyMappers.toDayPlanItem(row);
  }

  Future<DayPlanItem> addAdHoc({
    required EntityId dayPlanId,
    required String title,
  }) async {
    final now = _clock();
    final nextOrder = await _nextOrderIndex(dayPlanId);
    final item = DayPlanItem.adHoc(
      id: EntityId(_ids.newId()),
      dayPlanId: dayPlanId,
      title: title,
      orderIndex: nextOrder,
      createdAt: now,
    );
    await _db.into(_db.dayPlanItems).insert(ColonyMappers.fromDayPlanItem(item));
    await _touchPlan(dayPlanId, now);
    await _events.record(
      aggregateType: AggregateType.dayPlan,
      aggregateId: dayPlanId,
      eventType: EventType.dayPlanItemAdded,
      payload: {
        'item_id': item.id.value,
        'title': item.title,
        'source': 'adHoc',
      },
    );
    return item;
  }

  Future<DayPlanItem> pullTask({
    required EntityId dayPlanId,
    required ColonyTask task,
  }) async {
    final linkedIds = await _linkedTaskIds(dayPlanId);
    if (!DayPlanPolicies.canPullTask(
      linkedTaskIds: linkedIds,
      taskId: task.id,
    )) {
      throw DuplicateLinkedTaskException(task.id);
    }
    final now = _clock();
    final nextOrder = await _nextOrderIndex(dayPlanId);
    final item = DayPlanItem.fromTaskPull(
      id: EntityId(_ids.newId()),
      dayPlanId: dayPlanId,
      task: task,
      orderIndex: nextOrder,
      createdAt: now,
    );
    await _db.into(_db.dayPlanItems).insert(ColonyMappers.fromDayPlanItem(item));
    await _touchPlan(dayPlanId, now);
    await _events.record(
      aggregateType: AggregateType.dayPlan,
      aggregateId: dayPlanId,
      eventType: EventType.dayPlanItemPulled,
      payload: {'item_id': item.id.value, 'task_id': task.id.value},
    );
    return item;
  }

  Future<DayPlanItem?> findLinkedItem({
    required EntityId dayPlanId,
    required EntityId taskId,
  }) async {
    final row = await (_db.select(_db.dayPlanItems)
          ..where(
            (t) =>
                t.dayPlanId.equals(dayPlanId.value) &
                t.taskId.equals(taskId.value),
          ))
        .getSingleOrNull();
    return row == null ? null : ColonyMappers.toDayPlanItem(row);
  }

  Future<DayPlanCompletionResult> toggleComplete(EntityId dayPlanItemId) async {
    return _db.transaction(() async {
      final row = await (_db.select(_db.dayPlanItems)
            ..where((t) => t.id.equals(dayPlanItemId.value)))
          .getSingle();
      final item = ColonyMappers.toDayPlanItem(row);
      final task =
          item.taskId == null ? null : await _tasks.getById(item.taskId!);
      final now = _clock();

      final visuallyDone = DayPlanPolicies.isVisuallyDone(
        item,
        linkedTask: task,
      );
      final result = visuallyDone
          ? DayPlanPolicies.uncompleteItem(
              item: item.isDone
                  ? item
                  : item.copyWith(completedAt: now, updatedAt: now),
              linkedTask: task,
              at: now,
            )
          : DayPlanPolicies.completeItem(
              item: item,
              linkedTask: task,
              at: now,
            );

      if (result.isRejected) return result;

      await _db.into(_db.dayPlanItems).insertOnConflictUpdate(
            ColonyMappers.fromDayPlanItem(result.item),
          );
      if (result.taskStatusToApply != null && task != null) {
        await _tasks.updateStatus(task, result.taskStatusToApply!);
      }
      await _touchPlan(item.dayPlanId, now);
      await _events.record(
        aggregateType: AggregateType.dayPlan,
        aggregateId: item.dayPlanId,
        eventType: result.item.isDone
            ? EventType.dayPlanItemCompleted
            : EventType.dayPlanItemUncompleted,
        payload: {'item_id': item.id.value},
      );
      return result;
    });
  }

  Future<void> removeItem(EntityId dayPlanItemId) async {
    final row = await (_db.select(_db.dayPlanItems)
          ..where((t) => t.id.equals(dayPlanItemId.value)))
        .getSingle();
    final item = ColonyMappers.toDayPlanItem(row);
    await (_db.delete(_db.dayPlanItems)
          ..where((t) => t.id.equals(dayPlanItemId.value)))
        .go();
    await _touchPlan(item.dayPlanId, _clock());
    await _events.record(
      aggregateType: AggregateType.dayPlan,
      aggregateId: item.dayPlanId,
      eventType: EventType.dayPlanItemRemoved,
      payload: {
        'item_id': item.id.value,
        'title': item.title,
        'task_id': item.taskId?.value,
      },
    );
  }

  Future<DayPlanItem> reinsert(DayPlanItem item) async {
    await _db
        .into(_db.dayPlanItems)
        .insertOnConflictUpdate(ColonyMappers.fromDayPlanItem(item));
    return item;
  }

  Future<DayPlanItem> overwrite(DayPlanItem item) => reinsert(item);

  Future<void> reorder({
    required EntityId dayPlanId,
    required List<EntityId> orderedItemIds,
  }) async {
    final rows = await (_db.select(_db.dayPlanItems)
          ..where((t) => t.dayPlanId.equals(dayPlanId.value)))
        .get();
    final byId = {
      for (final r in rows) r.id: ColonyMappers.toDayPlanItem(r),
    };
    if (byId.length != orderedItemIds.length ||
        !orderedItemIds.every((id) => byId.containsKey(id.value))) {
      throw ArgumentError(
        'orderedItemIds deve conter exatamente os itens do plano',
      );
    }
    final renumbered = DayPlanPolicies.renumber([
      for (final id in orderedItemIds) byId[id.value]!,
    ]);
    await _db.transaction(() async {
      for (final item in renumbered) {
        await (_db.update(_db.dayPlanItems)
              ..where((t) => t.id.equals(item.id.value)))
            .write(DayPlanItemsCompanion(orderIndex: Value(item.orderIndex)));
      }
    });
    await _events.record(
      aggregateType: AggregateType.dayPlan,
      aggregateId: dayPlanId,
      eventType: EventType.dayPlanItemReordered,
      payload: {'item_ids': orderedItemIds.map((e) => e.value).toList()},
    );
  }

  Future<List<DayPlanItem>> carryOverFrom({
    required EntityId sourceDayPlanId,
    required EntityId targetDayPlanId,
  }) {
    return _itemsFor(sourceDayPlanId).then(
      (sourceItems) => carryOverItems(
        sourceItems: sourceItems,
        targetDayPlanId: targetDayPlanId,
      ),
    );
  }

  Future<List<DayPlanItem>> carryOverItems({
    required List<DayPlanItem> sourceItems,
    required EntityId targetDayPlanId,
  }) async {
    final targetItems = await _itemsFor(targetDayPlanId);
    final linkedTaskIds =
        sourceItems.map((e) => e.taskId).whereType<EntityId>().toList();
    final linkedTasksById = <String, ColonyTask>{};
    for (final id in linkedTaskIds) {
      final task = await _tasks.getById(id);
      if (task != null) linkedTasksById[id.value] = task;
    }
    final carried = DayPlanPolicies.carryOverUnfinished(
      sourceItems: sourceItems,
      linkedTasksById: linkedTasksById,
      targetExistingItems: targetItems,
      targetDayPlanId: targetDayPlanId,
      newIds: [
        for (var i = 0; i < sourceItems.length; i++) EntityId(_ids.newId()),
      ],
      now: _clock(),
    );
    if (carried.isEmpty) return const [];
    await _db.transaction(() async {
      for (final item in carried) {
        await _db
            .into(_db.dayPlanItems)
            .insert(ColonyMappers.fromDayPlanItem(item));
      }
    });
    await _touchPlan(targetDayPlanId, _clock());
    await _events.record(
      aggregateType: AggregateType.dayPlan,
      aggregateId: targetDayPlanId,
      eventType: EventType.dayPlanItemsCarriedOver,
      payload: {
        'source_day_plan_id': sourceDayPlanId.value,
        'item_ids': carried.map((e) => e.id.value).toList(),
      },
    );
    return carried;
  }

  Future<DayPlanItem> updateTitle({
    required EntityId dayPlanItemId,
    required String title,
  }) async {
    final trimmed = DayPlanPolicies.snapshotTitle(title);
    if (!DayPlanPolicies.isValidItemTitle(trimmed)) {
      throw ArgumentError('title vazio');
    }
    final row = await (_db.select(_db.dayPlanItems)
          ..where((t) => t.id.equals(dayPlanItemId.value)))
        .getSingle();
    final item = ColonyMappers.toDayPlanItem(row);
    final updated = item.copyWith(
      title: trimmed,
      updatedAt: _clock(),
      version: item.version + 1,
    );
    await _db
        .into(_db.dayPlanItems)
        .insertOnConflictUpdate(ColonyMappers.fromDayPlanItem(updated));
    return updated;
  }

  Future<List<DayPlanItem>> _itemsFor(EntityId dayPlanId) async {
    final rows = await (_db.select(_db.dayPlanItems)
          ..where((t) => t.dayPlanId.equals(dayPlanId.value))
          ..orderBy([(t) => OrderingTerm.asc(t.orderIndex)]))
        .get();
    return rows.map(ColonyMappers.toDayPlanItem).toList();
  }

  Future<List<EntityId>> _linkedTaskIds(EntityId dayPlanId) async =>
      (await _itemsFor(dayPlanId))
          .map((e) => e.taskId)
          .whereType<EntityId>()
          .toList();

  Future<int> _nextOrderIndex(EntityId dayPlanId) async =>
      (await _itemsFor(dayPlanId)).length;

  Future<void> _touchPlan(EntityId dayPlanId, DateTime at) async {
    await (_db.update(_db.dayPlans)..where((t) => t.id.equals(dayPlanId.value)))
        .write(
      DayPlansCompanion(
        updatedAt: Value(at.millisecondsSinceEpoch),
      ),
    );
  }
}
