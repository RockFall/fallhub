import 'package:colony_domain/colony_domain.dart';
import 'package:test/test.dart';

void main() {
  final now = DateTime.utc(2026, 8, 7, 12);

  test('create trims fields and rejects empty title', () {
    final task = HomeMaintenanceTask.create(
      id: const EntityId('hm-1'),
      profileId: const EntityId('p-1'),
      title: '  Filtro ar  ',
      systemOrItem: '  HVAC  ',
      cadenceDays: 90,
      createdAt: now,
    );
    expect(task.title, 'Filtro ar');
    expect(task.systemOrItem, 'HVAC');
    expect(
      () => HomeMaintenanceTask.create(
        id: const EntityId('hm-2'),
        profileId: const EntityId('p-1'),
        title: '  ',
        systemOrItem: 'x',
        createdAt: now,
      ),
      throwsArgumentError,
    );
  });

  test('markDone advances nextDueAt when cadence set', () {
    final task = HomeMaintenanceTask.create(
      id: const EntityId('hm-1'),
      profileId: const EntityId('p-1'),
      title: 'Filtro',
      systemOrItem: 'HVAC',
      cadenceDays: 30,
      nextDueAt: now,
      createdAt: now,
    );
    final done = task.markDone(now);
    expect(done.lastDoneAt, now);
    expect(done.nextDueAt, DateTime.utc(2026, 9, 6, 12));
  });

  test('markDone keeps nextDueAt when no cadence', () {
    final due = DateTime.utc(2026, 9, 1);
    final task = HomeMaintenanceTask.create(
      id: const EntityId('hm-1'),
      profileId: const EntityId('p-1'),
      title: 'Conserto',
      systemOrItem: 'Torneira',
      nextDueAt: due,
      createdAt: now,
    );
    final done = task.markDone(now);
    expect(done.lastDoneAt, now);
    expect(done.nextDueAt, due);
  });
}
