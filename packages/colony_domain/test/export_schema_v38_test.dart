import 'package:colony_domain/colony_domain.dart';
import 'package:test/test.dart';

void main() {
  final now = DateTime.utc(2026, 8, 24, 12);

  Map<String, Object?> base({required int version}) => {
        'exported_at': now.toIso8601String(),
        'version': version,
        'profile': {
          'id': 'profile-1',
          'colony_name': 'Schema',
          'display_name': 'Tester',
          'timezone': 'UTC',
          'locale': 'pt_BR',
          'base_currency': 'BRL',
          'created_at': now.toIso8601String(),
          'updated_at': now.toIso8601String(),
        },
        'preferences': {
          'density_mode': 'management',
          'theme_mode': 'dark',
          'week_starts_on_monday': true,
          'use_24_hour_format': true,
          'sectors_enabled': <String>[],
          'onboarding_completed': true,
        },
        'tasks': <Map<String, dynamic>>[],
        'events': <Map<String, dynamic>>[],
      };

  test('export v38 parses task capabilities', () {
    final json = {
      ...base(version: 38),
      'tasks': [
        {
          'id': 'task-1',
          'title': 'Comprar pão',
          'status': 'next',
          'source_type': 'manual',
          'created_at': now.toIso8601String(),
          'updated_at': now.toIso8601String(),
          'project_id': 'proj-1',
          'parent_task_id': 'task-0',
          'priority': 'soon',
          'due_at': now.toIso8601String(),
          'scheduled_start': now.toIso8601String(),
          'estimated_minutes': 25,
          'energy_requirement': 'low',
        },
      ],
    };

    final snapshot = ExportSnapshot.fromJson(json);
    expect(snapshot.version, 38);
    final task = snapshot.tasks.single;
    expect(task.projectId?.value, 'proj-1');
    expect(task.parentTaskId?.value, 'task-0');
    expect(task.priority, TaskPriority.soon);
    expect(task.dueAt, now);
    expect(task.scheduledStart, now);
    expect(task.estimatedMinutes, 25);
    expect(task.energyRequirement, EnergyRequirement.low);
  });

  test('export v37 still parses tasks without new keys', () {
    final snapshot = ExportSnapshot.fromJson({
      ...base(version: 37),
      'tasks': [
        {
          'id': 'task-1',
          'title': 'Só o nome',
          'status': 'inbox',
          'source_type': 'manual',
          'created_at': now.toIso8601String(),
          'updated_at': now.toIso8601String(),
        },
      ],
    });
    final task = snapshot.tasks.single;
    expect(task.priority, TaskPriority.none);
    expect(task.projectId, isNull);
    expect(task.parentTaskId, isNull);
    expect(task.dueAt, isNull);
  });

  test('toJson at v38 roundtrips capability keys', () {
    final snapshot = ExportSnapshot.fromJson({
      ...base(version: 38),
      'tasks': [
        {
          'id': 'task-1',
          'title': 'Revisar',
          'status': 'next',
          'source_type': 'manual',
          'created_at': now.toIso8601String(),
          'updated_at': now.toIso8601String(),
          'priority': 'now',
          'project_id': 'proj-1',
        },
      ],
    });
    final encoded = snapshot.toJson();
    final tasks = encoded['tasks'] as List<dynamic>;
    expect((tasks.first as Map)['priority'], 'now');
    expect((tasks.first as Map)['project_id'], 'proj-1');
    expect(
      ExportSnapshot.fromJson(Map<String, dynamic>.from(encoded)).tasks.single,
      snapshot.tasks.single,
    );
  });

  test('export v40 is rejected', () {
    expect(
      () => ExportSnapshot.fromJson(base(version: 40)),
      throwsA(isA<ExportSnapshotException>()),
    );
  });
}
