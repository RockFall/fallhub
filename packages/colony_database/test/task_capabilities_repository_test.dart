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
        for (var i = 0; i < 40; i++) 'tc-$i',
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

  test('createSimple keeps title-only and persists optional fields', () async {
    final p = await profile();
    final project = await repos.projects.create(
      profileId: p.id,
      title: 'Casa',
    );
    final task = await repos.tasks.createSimple(
      profileId: p.id,
      title: '  Pintar muro  ',
    );
    expect(task.title, 'Pintar muro');
    expect(task.status, TaskStatus.next);
    expect(task.priority, TaskPriority.none);
    expect(task.projectId, isNull);

    final updated = await repos.tasks.save(
      task.copyWith(
        projectId: project.id,
        priority: TaskPriority.now,
        dueAt: DateTime.utc(2026, 8, 30),
        scheduledStart: DateTime.utc(2026, 8, 25),
      ),
    );
    final loaded = await repos.tasks.getById(updated.id);
    expect(loaded!.projectId, project.id);
    expect(loaded.priority, TaskPriority.now);
    expect(loaded.dueAt, DateTime.utc(2026, 8, 30));
    expect(loaded.scheduledStart, DateTime.utc(2026, 8, 25));
  });

  test('subtasks stay under the parent and cannot nest', () async {
    final p = await profile();
    final parent = await repos.tasks.createSimple(
      profileId: p.id,
      title: 'Viajar',
    );
    final child = await repos.tasks.createSimple(
      profileId: p.id,
      title: 'Comprar passagem',
      parentTaskId: parent.id,
      projectId: parent.projectId,
    );
    expect(child.parentTaskId, parent.id);
    final children = await repos.tasks.watchChildren(parent.id).first;
    expect(children.map((t) => t.title), ['Comprar passagem']);

    expect(
      () => repos.tasks.createSimple(
        profileId: p.id,
        title: 'Neto',
        parentTaskId: child.id,
      ),
      throwsA(isA<ArgumentError>()),
    );

    final open = await repos.tasks.watchActive(p.id).first;
    expect(
      TaskCapabilityPolicy.topLevelOpen(open).map((t) => t.id),
      [parent.id],
    );
  });

  test('export v38 includes task capability keys', () async {
    final p = await profile();
    await repos.preferences.save(
      AppPreferences.defaults().copyWith(onboardingCompleted: true),
    );
    final project = await repos.projects.create(
      profileId: p.id,
      title: 'Casa',
    );
    final parent = await repos.tasks.createSimple(
      profileId: p.id,
      title: 'Reforma',
    );
    await repos.tasks.save(
      parent.copyWith(projectId: project.id, priority: TaskPriority.soon),
    );
    await repos.tasks.createSimple(
      profileId: p.id,
      title: 'Orçamento',
      parentTaskId: parent.id,
      projectId: project.id,
    );

    final snapshot = await repos.export.buildSnapshot();
    expect(snapshot.version, 38);
    final encoded = snapshot.toJson();
    final tasks = (encoded['tasks'] as List).cast<Map<String, dynamic>>();
    final reforma = tasks.firstWhere((row) => row['title'] == 'Reforma');
    expect(reforma['project_id'], project.id.value);
    expect(reforma['priority'], 'soon');
    final child = tasks.firstWhere((row) => row['title'] == 'Orçamento');
    expect(child['parent_task_id'], parent.id.value);
  });
}
