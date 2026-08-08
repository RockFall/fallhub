import 'package:colony_domain/colony_domain.dart';
import 'package:test/test.dart';

void main() {
  group('HealthSafetyPolicy', () {
    test('rejects empty title and invalid severity', () {
      expect(
        () => HealthSafetyPolicy.validateTitle('  '),
        throwsArgumentError,
      );
      expect(
        () => HealthSafetyPolicy.validateSeverity(0),
        throwsArgumentError,
      );
      expect(
        () => HealthSafetyPolicy.validateSeverity(6),
        throwsArgumentError,
      );
      HealthSafetyPolicy.validateSeverity(3);
    });
  });

  group('HealthCondition', () {
    test('create trims title and notes', () {
      final condition = HealthCondition.create(
        id: EntityId('h-1'),
        profileId: EntityId('p-1'),
        title: '  Dor de cabeça  ',
        type: HealthConditionType.symptom,
        severityUserReported: 2,
        bodyRegions: [' cabeça ', ''],
        notes: '  leve  ',
        createdAt: DateTime.utc(2026, 8, 7),
      );

      expect(condition.title, 'Dor de cabeça');
      expect(condition.notes, 'leve');
      expect(condition.bodyRegions, ['cabeça']);
      expect(condition.status, HealthConditionStatus.active);
    });
  });
}
