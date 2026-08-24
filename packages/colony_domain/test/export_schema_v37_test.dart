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

  test('export v37 parses day plans', () {
    final json = {
      ...base(version: 37),
      'day_plans': [
        {
          'id': 'plan-1',
          'local_date': '2026-08-24',
          'created_at': now.toIso8601String(),
          'updated_at': now.toIso8601String(),
        },
      ],
      'day_plan_items': [
        {
          'id': 'item-1',
          'day_plan_id': 'plan-1',
          'title': 'Comprar pão',
          'order_index': 0,
          'source_type': 'manual',
          'created_at': now.toIso8601String(),
          'updated_at': now.toIso8601String(),
        },
        {
          'id': 'item-2',
          'day_plan_id': 'plan-1',
          'task_id': 'task-1',
          'title': 'Revisar PR',
          'order_index': 1,
          'source_type': 'manual',
          'created_at': now.toIso8601String(),
          'updated_at': now.toIso8601String(),
          'completed_at': now.toIso8601String(),
        },
      ],
    };

    final snapshot = ExportSnapshot.fromJson(json);
    expect(snapshot.version, 37);
    expect(snapshot.dayPlans, hasLength(1));
    expect(snapshot.dayPlans.single.localDate, '2026-08-24');
    expect(snapshot.dayPlanItems, hasLength(2));
    expect(snapshot.dayPlanItems.first.taskId, isNull);
    expect(snapshot.dayPlanItems.last.taskId?.value, 'task-1');
    expect(snapshot.dayPlanItems.last.isDone, isTrue);
  });

  test('export v36 still parses without day plans', () {
    final snapshot = ExportSnapshot.fromJson(base(version: 36));
    expect(snapshot.version, 36);
    expect(snapshot.dayPlans, isEmpty);
    expect(snapshot.dayPlanItems, isEmpty);
  });

  test('toJson at v37 includes day plan keys', () {
    final snapshot = ExportSnapshot.fromJson({
      ...base(version: 37),
      'day_plans': [
        {
          'id': 'plan-1',
          'local_date': '2026-08-24',
          'created_at': now.toIso8601String(),
          'updated_at': now.toIso8601String(),
        },
      ],
      'day_plan_items': <Map<String, dynamic>>[],
    });
    final encoded = snapshot.toJson();
    expect(encoded['day_plans'], isA<List<dynamic>>());
    expect(encoded['day_plan_items'], isA<List<dynamic>>());
    expect(
      ExportSnapshot.fromJson(Map<String, dynamic>.from(encoded)),
      snapshot,
    );
  });

  test('export v38 is rejected', () {
    expect(
      () => ExportSnapshot.fromJson(base(version: 38)),
      throwsA(isA<ExportSnapshotException>()),
    );
  });
}
