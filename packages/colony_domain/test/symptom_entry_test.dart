import 'package:colony_domain/colony_domain.dart';
import 'package:test/test.dart';

void main() {
  group('SymptomEntry', () {
    test('create trims note and validates intensity', () {
      final now = DateTime.utc(2026, 8, 7, 12);
      final entry = SymptomEntry.create(
        id: EntityId('sym-1'),
        profileId: EntityId('profile-1'),
        conditionId: EntityId('health-1'),
        occurredAt: now,
        intensity: 4,
        note: '  late afternoon  ',
        bodyRegion: ' cabeça ',
        createdAt: now,
      );

      expect(entry.note, 'late afternoon');
      expect(entry.bodyRegion, 'cabeça');
      expect(entry.intensity, 4);
    });

    test('create rejects invalid intensity', () {
      expect(
        () => SymptomEntry.create(
          id: EntityId('sym-1'),
          profileId: EntityId('profile-1'),
          occurredAt: DateTime.utc(2026, 8, 7),
          intensity: 0,
          createdAt: DateTime.utc(2026, 8, 7),
        ),
        throwsArgumentError,
      );
    });
  });
}
