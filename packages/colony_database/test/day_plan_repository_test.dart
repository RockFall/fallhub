import 'package:colony_database/colony_database.dart';
import 'package:colony_domain/colony_domain.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late ColonyDatabase db;
  late ColonyRepositories repos;
  final clock = DateTime.utc(2026, 8, 24, 12);

  setUp(() {
    db = ColonyDatabase.inMemory();
    repos = ColonyRepositories.create(
      db,
      idGenerator: FixedIdGenerator([
        for (var i = 0; i < 80; i++) 'dp-$i',
      ]),
      clock: () => clock,
    );
  });

  tearDown(() async {
    await db.close();
  });

  Future<ColonyProfile> profile() {
    return repos.profiles.create(
      colonyName: 'Test',
      displayName: 'Caio',
      timezone: 'UTC',
      locale: 'pt_BR',
      baseCurrency: 'BRL',
    );
  }

  test('getOrCreateForDate is idempotent for the same day', () async {
    final p = await profile();
    final a = await repos.dayPlan.getOrCreateForDate(p.id, '2026-08-24');
    final b = await repos.dayPlan.getOrCreateForDate(p.id, '2026-08-24');
    expect(a.plan.id, b.plan.id);
    expect(await repos.dayPlan.listPlans(p.id), hasLength(1));
  });

  test('addAdHoc then pullTask persist order and snapshot title', () async {
    final p = await profile();
    final plan = await repos.dayPlan.getOrCreateForDate(p.id, '2026-08-24');
    final adHoc = await repos.dayPlan.addAdHoc(
      dayPlanId: plan.plan.id,
      title: '  Comprar pão  ',
    );
    expect(adHoc.title, 'Comprar pão');
    expect(adHoc.orderIndex, 0);

    final task = await repos.tasks.capture(profileId: p.id, title: 'Revisar PR');
    final pulled = await repos.dayPlan.pullTask(
      dayPlanId: plan.plan.id,
      task: task,
    );
    expect(pulled.taskId, task.id);
    expect(pulled.title, 'Revisar PR');

    await repos.tasks.save(task.copyWith(title: 'Revisar PR v2'));
    final loaded = await repos.dayPlan.getForDate(p.id, '2026-08-24');
    expect(
      loaded!.items.firstWhere((e) => e.taskId == task.id).title,
      'Revisar PR',
    );

    expect(
      () => repos.dayPlan.pullTask(dayPlanId: plan.plan.id, task: task),
      throwsA(isA<DuplicateLinkedTaskException>()),
    );
  });

  test('toggleComplete cascades to linked next task and is reversible', () async {
    final p = await profile();
    final plan = await repos.dayPlan.getOrCreateForDate(p.id, '2026-08-24');
    var task = await repos.tasks.capture(profileId: p.id, title: 'PR');
    task = await repos.tasks.updateStatus(task, TaskStatus.next);
    final item = await repos.dayPlan.pullTask(
      dayPlanId: plan.plan.id,
      task: task,
    );

    final done = await repos.dayPlan.toggleComplete(item.id);
    expect(done.isRejected, isFalse);
    expect(done.item.isDone, isTrue);
    expect((await repos.tasks.getById(task.id))!.status, TaskStatus.done);

    final undone = await repos.dayPlan.toggleComplete(item.id);
    expect(undone.item.isDone, isFalse);
    expect((await repos.tasks.getById(task.id))!.status, TaskStatus.next);
  });

  test('toggleComplete rejects blocked linked tasks', () async {
    final p = await profile();
    final plan = await repos.dayPlan.getOrCreateForDate(p.id, '2026-08-24');
    var task = await repos.tasks.capture(profileId: p.id, title: 'Bloqueada');
    task = await repos.tasks.updateStatus(task, TaskStatus.next);
    task = await repos.tasks.updateStatus(
      task,
      TaskStatus.blocked,
      blockedReason: 'Esperando revisão',
    );
    final item = await repos.dayPlan.pullTask(
      dayPlanId: plan.plan.id,
      task: task,
    );
    final result = await repos.dayPlan.toggleComplete(item.id);
    expect(result.isRejected, isTrue);
    expect(result.item.isDone, isFalse);
    expect((await repos.tasks.getById(task.id))!.status, TaskStatus.blocked);
  });

  test('removeItem does not delete the global task', () async {
    final p = await profile();
    final plan = await repos.dayPlan.getOrCreateForDate(p.id, '2026-08-24');
    final task = await repos.tasks.capture(profileId: p.id, title: 'Keep');
    final item = await repos.dayPlan.pullTask(
      dayPlanId: plan.plan.id,
      task: task,
    );
    await repos.dayPlan.removeItem(item.id);
    expect(await repos.dayPlan.getItemById(item.id), isNull);
    expect(await repos.tasks.getById(task.id), isNotNull);
  });

  test('carryOverFrom copies unfinished items and is idempotent', () async {
    final p = await profile();
    final yesterday =
        await repos.dayPlan.getOrCreateForDate(p.id, '2026-08-23');
    await repos.dayPlan.addAdHoc(
      dayPlanId: yesterday.plan.id,
      title: 'Leite',
    );
    final done = await repos.dayPlan.addAdHoc(
      dayPlanId: yesterday.plan.id,
      title: 'Já feito',
    );
    await repos.dayPlan.toggleComplete(done.id);

    final today = await repos.dayPlan.getOrCreateForDate(p.id, '2026-08-24');
    final first = await repos.dayPlan.carryOverFrom(
      sourceDayPlanId: yesterday.plan.id,
      targetDayPlanId: today.plan.id,
    );
    expect(first, hasLength(1));
    expect(first.single.title, 'Leite');
    expect(first.single.sourceType, SourceType.derived);

    final second = await repos.dayPlan.carryOverFrom(
      sourceDayPlanId: yesterday.plan.id,
      targetDayPlanId: today.plan.id,
    );
    expect(second, isEmpty);
    final yesterdayAfter = await repos.dayPlan.getForDate(p.id, '2026-08-23');
    expect(yesterdayAfter!.items, hasLength(2));
  });

  test('export v37 round-trips day plans', () async {
    final p = await profile();
    final plan = await repos.dayPlan.getOrCreateForDate(p.id, '2026-08-24');
    await repos.dayPlan.addAdHoc(dayPlanId: plan.plan.id, title: 'Pão');
    final snapshot = await repos.export.buildSnapshot();
    expect(snapshot.version, 38);
    expect(snapshot.dayPlans, hasLength(1));
    expect(snapshot.dayPlanItems, hasLength(1));

    await repos.restore.restore(snapshot);
    final restored = await repos.dayPlan.getForDate(p.id, '2026-08-24');
    expect(restored!.items.single.title, 'Pão');
  });
}
