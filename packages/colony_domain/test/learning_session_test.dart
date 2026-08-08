import 'package:colony_domain/colony_domain.dart';
import 'package:test/test.dart';

void main() {
  group('LearningSession', () {
    test('create trims notes and drops empty', () {
      const profileId = EntityId('profile-1');
      const nodeId = EntityId('node-1');
      final startedAt = DateTime.utc(2026, 8, 6, 10);

      final withNotes = LearningSession.create(
        id: const EntityId('session-1'),
        profileId: profileId,
        nodeId: nodeId,
        startedAt: startedAt,
        durationMinutes: 45,
        mode: LearningSessionMode.read,
        notes: '  Anotações  ',
      );
      expect(withNotes.notes, 'Anotações');

      final withoutNotes = LearningSession.create(
        id: const EntityId('session-2'),
        profileId: profileId,
        nodeId: nodeId,
        startedAt: startedAt,
        durationMinutes: 30,
        mode: LearningSessionMode.practice,
        notes: '   ',
      );
      expect(withoutNotes.notes, isNull);
    });
  });
}
