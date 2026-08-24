import 'package:colony_domain/colony_domain.dart';
import 'package:test/test.dart';

void main() {
  final now = DateTime.utc(2026, 8, 24, 12);

  ColonyTask task({
    required String id,
    String title = 'Tarefa',
    TaskStatus status = TaskStatus.next,
    EntityId? parentTaskId,
    EntityId? projectId,
    TaskPriority priority = TaskPriority.none,
    DateTime? dueAt,
    DateTime? completedAt,
  }) {
    return ColonyTask(
      id: EntityId(id),
      profileId: EntityId('profile-1'),
      title: title,
      status: status,
      sourceType: SourceType.manual,
      createdAt: now,
      updatedAt: now,
      parentTaskId: parentTaskId,
      projectId: projectId,
      priority: priority,
      dueAt: dueAt,
      completedAt: completedAt,
    );
  }

  test('subtasks are one level only', () {
    final parent = task(id: 'p');
    final child = task(id: 'c', parentTaskId: parent.id);
    expect(TaskCapabilityPolicy.canHaveChildren(parent), isTrue);
    expect(TaskCapabilityPolicy.canHaveChildren(child), isFalse);
    expect(
      TaskCapabilityPolicy.canBeChildOf(child: child, parent: parent),
      isTrue,
    );
    expect(
      TaskCapabilityPolicy.canBeChildOf(child: parent, parent: child),
      isFalse,
    );
    expect(
      TaskCapabilityPolicy.canBeChildOf(child: parent, parent: parent),
      isFalse,
    );
  });

  test('top-level backlog hides children', () {
    final parent = task(id: 'p', title: 'Pai');
    final child = task(id: 'c', title: 'Filho', parentTaskId: parent.id);
    expect(TaskCapabilityPolicy.topLevelOpen([parent, child]), [parent]);
  });

  test('subtask progress ignores archived and does not auto-complete parent', () {
    final children = [
      task(id: 'a', status: TaskStatus.done),
      task(id: 'b', status: TaskStatus.next),
      task(id: 'c', status: TaskStatus.archived),
    ];
    expect(TaskCapabilityPolicy.subtaskProgress(children), (1, 2));
  });

  test('priority then deadline sorts the backlog', () {
    final later = task(id: '1', title: 'Depois', priority: TaskPriority.later);
    final nowP = task(id: '2', title: 'Agora', priority: TaskPriority.now);
    final dueSoon = task(
      id: '3',
      title: 'Prazo',
      dueAt: DateTime.utc(2026, 8, 25),
    );
    final dueLater = task(
      id: '4',
      title: 'Prazo tarde',
      dueAt: DateTime.utc(2026, 8, 30),
    );
    final list = [later, dueLater, dueSoon, nowP]
      ..sort(TaskCapabilityPolicy.compareBacklog);
    expect(list.map((t) => t.id.value).toList(), ['2', '3', '4', '1']);
  });

  test('overdue is calendar-local and ignores done tasks', () {
    final localToday = TaskCapabilityPolicy.localDateOnly(now);
    final overdue = task(
      id: '1',
      dueAt: localToday.subtract(const Duration(days: 2)),
    );
    final today = task(id: '2', dueAt: localToday);
    final done = task(
      id: '3',
      status: TaskStatus.done,
      dueAt: localToday.subtract(const Duration(days: 4)),
    );
    expect(TaskCapabilityPolicy.isOverdue(overdue, now), isTrue);
    expect(TaskCapabilityPolicy.isOverdue(today, now), isFalse);
    expect(TaskCapabilityPolicy.isOverdue(done, now), isFalse);
  });

  test('group by project puts ungrouped last', () {
    final trip = Project(
      id: EntityId('proj-1'),
      profileId: EntityId('profile-1'),
      title: 'Viagem',
      status: ProjectStatus.active,
      createdAt: now,
      updatedAt: now,
    );
    final grouped = TaskCapabilityPolicy.groupByProject(
      tasks: [
        task(id: 'a', title: 'Sem', priority: TaskPriority.now),
        task(id: 'b', title: 'Com', projectId: trip.id),
      ],
      projects: [trip],
      ungroupedTitle: 'Sem projeto',
    );
    expect(grouped, hasLength(2));
    expect(grouped.first.title, 'Viagem');
    expect(grouped.last.title, 'Sem projeto');
    expect(grouped.last.tasks.single.id.value, 'a');
  });
}
