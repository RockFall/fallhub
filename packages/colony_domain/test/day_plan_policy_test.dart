import 'package:colony_domain/colony_domain.dart';
import 'package:test/test.dart';

void main() {
  group('DayPlanPolicies', () {
    test('isValidLocalDateKey accepts calendar dates', () {
      expect(DayPlanPolicies.isValidLocalDateKey('2026-08-24'), isTrue);
      expect(DayPlanPolicies.isValidLocalDateKey('2026/08/24'), isFalse);
      expect(DayPlanPolicies.isValidLocalDateKey('2026-13-01'), isFalse);
      expect(DayPlanPolicies.isValidLocalDateKey('2026-02-30'), isFalse);
      expect(DayPlanPolicies.isValidLocalDateKey(''), isFalse);
    });

    test('dayPlanLocalDateKey and shift stay on calendar days', () {
      expect(dayPlanLocalDateKey(DateTime(2026, 8, 24, 9, 15)), '2026-08-24');
      expect(dayPlanShiftDate('2026-08-24', -1), '2026-08-23');
      expect(dayPlanShiftDate('2026-08-31', 1), '2026-09-01');
    });

    test('snapshotTitle trims and rejects empty', () {
      expect(DayPlanPolicies.snapshotTitle('  leite  '), 'leite');
      expect(DayPlanPolicies.isValidItemTitle('  '), isFalse);
      expect(DayPlanPolicies.isValidItemTitle('ok'), isTrue);
    });

    test('canPullTask rejects duplicates', () {
      final id = EntityId('t1');
      expect(
        DayPlanPolicies.canPullTask(linkedTaskIds: [id], taskId: id),
        isFalse,
      );
      expect(
        DayPlanPolicies.canPullTask(
          linkedTaskIds: const [],
          taskId: id,
        ),
        isTrue,
      );
    });
  });

  group('complete / uncomplete', () {
    final now = DateTime.utc(2026, 8, 24, 12);
    final adHoc = DayPlanItem.adHoc(
      id: EntityId('i1'),
      dayPlanId: EntityId('p1'),
      title: 'Comprar pão',
      orderIndex: 0,
      createdAt: now,
    );

    ColonyTask task(TaskStatus status) => ColonyTask(
          id: EntityId('task-1'),
          profileId: EntityId('profile-1'),
          title: 'Revisar PR',
          status: status,
          sourceType: SourceType.manual,
          createdAt: now,
          updatedAt: now,
        );

    test('ad-hoc complete does not cascade to a task', () {
      final result = DayPlanPolicies.completeItem(
        item: adHoc,
        linkedTask: null,
        at: now,
      );
      expect(result.isRejected, isFalse);
      expect(result.item.isDone, isTrue);
      expect(result.taskStatusToApply, isNull);
    });

    test('linked next task completes to done', () {
      final item = DayPlanItem.fromTaskPull(
        id: EntityId('i2'),
        dayPlanId: EntityId('p1'),
        task: task(TaskStatus.next),
        orderIndex: 0,
        createdAt: now,
      );
      final result = DayPlanPolicies.completeItem(
        item: item,
        linkedTask: task(TaskStatus.next),
        at: now,
      );
      expect(result.taskStatusToApply, TaskStatus.done);
      expect(result.item.isDone, isTrue);
    });

    test('blocked linked task rejects completion', () {
      final blocked = task(TaskStatus.blocked);
      final item = DayPlanItem.fromTaskPull(
        id: EntityId('i3'),
        dayPlanId: EntityId('p1'),
        task: blocked,
        orderIndex: 0,
        createdAt: now,
      );
      final result = DayPlanPolicies.completeItem(
        item: item,
        linkedTask: blocked,
        at: now,
      );
      expect(result.isRejected, isTrue);
      expect(result.item.isDone, isFalse);
    });

    test('cancelled and archived linked tasks reject completion', () {
      for (final status in [TaskStatus.cancelled, TaskStatus.archived]) {
        final t = task(status);
        final item = DayPlanItem.fromTaskPull(
          id: EntityId('i-$status'),
          dayPlanId: EntityId('p1'),
          task: t,
          orderIndex: 0,
          createdAt: now,
        );
        final result = DayPlanPolicies.completeItem(
          item: item,
          linkedTask: t,
          at: now,
        );
        expect(result.isRejected, isTrue, reason: status.name);
      }
    });

    test('complete is idempotent when already done', () {
      final done = adHoc.copyWith(completedAt: now);
      final result = DayPlanPolicies.completeItem(
        item: done,
        linkedTask: null,
        at: now.add(const Duration(minutes: 1)),
      );
      expect(result.item.completedAt, now);
      expect(result.rejection, DayPlanCompletionRejection.none);
    });

    test('uncomplete reverts linked done task to next', () {
      final doneTask = task(TaskStatus.done);
      final item = DayPlanItem.fromTaskPull(
        id: EntityId('i4'),
        dayPlanId: EntityId('p1'),
        task: doneTask,
        orderIndex: 0,
        createdAt: now,
      ).copyWith(completedAt: now);
      final result = DayPlanPolicies.uncompleteItem(
        item: item,
        linkedTask: doneTask,
        at: now,
      );
      expect(result.item.isDone, isFalse);
      expect(result.taskStatusToApply, TaskStatus.next);
    });

    test('uncomplete does not clobber a diverged task', () {
      final archived = task(TaskStatus.archived);
      final item = DayPlanItem.fromTaskPull(
        id: EntityId('i5'),
        dayPlanId: EntityId('p1'),
        task: archived,
        orderIndex: 0,
        createdAt: now,
      ).copyWith(completedAt: now);
      final result = DayPlanPolicies.uncompleteItem(
        item: item,
        linkedTask: archived,
        at: now,
      );
      expect(result.item.isDone, isFalse);
      expect(result.taskStatusToApply, isNull);
    });
  });

  group('renumber and carry-over', () {
    final now = DateTime.utc(2026, 8, 24, 12);

    test('renumber writes contiguous indexes and preserves identity', () {
      final a = DayPlanItem.adHoc(
        id: EntityId('a'),
        dayPlanId: EntityId('p'),
        title: 'A',
        orderIndex: 4,
        createdAt: now,
      );
      final b = DayPlanItem.adHoc(
        id: EntityId('b'),
        dayPlanId: EntityId('p'),
        title: 'B',
        orderIndex: 0,
        createdAt: now,
      );
      final numbered = DayPlanPolicies.renumber([a, b]);
      expect(numbered.map((e) => e.orderIndex), [0, 1]);
      expect(identical(numbered[1], b), isFalse);
      final already = DayPlanPolicies.renumber([
        a.copyWith(orderIndex: 0),
        b.copyWith(orderIndex: 1),
      ]);
      expect(already[0].orderIndex, 0);
      expect(already[1].orderIndex, 1);
    });

    test('carryOverUnfinished copies open items and is idempotent', () {
      final openAdHoc = DayPlanItem.adHoc(
        id: EntityId('src-1'),
        dayPlanId: EntityId('yesterday'),
        title: 'Leite',
        orderIndex: 0,
        createdAt: now,
      );
      final doneAdHoc = DayPlanItem.adHoc(
        id: EntityId('src-2'),
        dayPlanId: EntityId('yesterday'),
        title: 'Já feito',
        orderIndex: 1,
        createdAt: now,
      ).copyWith(completedAt: now);
      final liveTask = ColonyTask(
        id: EntityId('task-open'),
        profileId: EntityId('profile-1'),
        title: 'PR novo título',
        status: TaskStatus.next,
        sourceType: SourceType.manual,
        createdAt: now,
        updatedAt: now,
      );
      final terminalTask = ColonyTask(
        id: EntityId('task-done'),
        profileId: EntityId('profile-1'),
        title: 'Morta',
        status: TaskStatus.done,
        sourceType: SourceType.manual,
        createdAt: now,
        updatedAt: now,
      );
      final linkedOpen = DayPlanItem.fromTaskPull(
        id: EntityId('src-3'),
        dayPlanId: EntityId('yesterday'),
        task: liveTask.copyWith(title: 'PR antigo'),
        orderIndex: 2,
        createdAt: now,
      );
      // fromTaskPull uses the passed task title; simulate old snapshot:
      final linkedOpenSnapshot = linkedOpen.copyWith(title: 'PR antigo');
      final linkedDone = DayPlanItem.fromTaskPull(
        id: EntityId('src-4'),
        dayPlanId: EntityId('yesterday'),
        task: terminalTask,
        orderIndex: 3,
        createdAt: now,
      );

      final first = DayPlanPolicies.carryOverUnfinished(
        sourceItems: [openAdHoc, doneAdHoc, linkedOpenSnapshot, linkedDone],
        linkedTasksById: {
          liveTask.id.value: liveTask,
          terminalTask.id.value: terminalTask,
        },
        targetExistingItems: const [],
        targetDayPlanId: EntityId('today'),
        newIds: [EntityId('n1'), EntityId('n2'), EntityId('n3'), EntityId('n4')],
        now: now,
      );
      expect(first, hasLength(2));
      expect(first.map((e) => e.title), ['Leite', 'PR novo título']);
      expect(first.every((e) => e.sourceType == SourceType.derived), isTrue);
      expect(first[0].carriedFromItemId, openAdHoc.id);
      expect(first[1].taskId, liveTask.id);

      final second = DayPlanPolicies.carryOverUnfinished(
        sourceItems: [openAdHoc, doneAdHoc, linkedOpenSnapshot, linkedDone],
        linkedTasksById: {
          liveTask.id.value: liveTask,
          terminalTask.id.value: terminalTask,
        },
        targetExistingItems: first,
        targetDayPlanId: EntityId('today'),
        newIds: [EntityId('n5'), EntityId('n6')],
        now: now,
      );
      expect(second, isEmpty);
    });
  });

  test('TaskTransitionPolicy allows completing from inbox and next', () {
    expect(
      TaskTransitionPolicy.canTransition(TaskStatus.inbox, TaskStatus.done),
      isTrue,
    );
    expect(
      TaskTransitionPolicy.canTransition(TaskStatus.next, TaskStatus.done),
      isTrue,
    );
    expect(
      TaskTransitionPolicy.canTransition(TaskStatus.blocked, TaskStatus.done),
      isFalse,
    );
  });
}
