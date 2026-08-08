import 'package:colony_domain/colony_domain.dart';
import 'package:test/test.dart';

void main() {
  group('Person', () {
    test('create trims names, notes and relationship types', () {
      final person = Person.create(
        id: EntityId('p-1'),
        profileId: EntityId('profile-1'),
        displayName: '  Ana Silva  ',
        preferredName: '  Aninha  ',
        relationshipTypes: [' amiga ', '', 'colegas'],
        notes: '  faculdade  ',
        createdAt: DateTime.utc(2026, 8, 7),
      );

      expect(person.displayName, 'Ana Silva');
      expect(person.preferredName, 'Aninha');
      expect(person.relationshipTypes, ['amiga', 'colegas']);
      expect(person.notes, 'faculdade');
      expect(person.isArchived, isFalse);
    });

    test('rejects empty display name', () {
      expect(
        () => Person.create(
          id: EntityId('p-1'),
          profileId: EntityId('profile-1'),
          displayName: '  ',
          createdAt: DateTime.utc(2026, 8, 7),
        ),
        throwsArgumentError,
      );
    });

    test('archive via archivedAt', () {
      final person = Person.create(
        id: EntityId('p-1'),
        profileId: EntityId('profile-1'),
        displayName: 'Ana',
        createdAt: DateTime.utc(2026, 8, 7),
      );
      final archived = person.copyWith(
        archivedAt: DateTime.utc(2026, 8, 8),
        updatedAt: DateTime.utc(2026, 8, 8),
      );
      expect(archived.isArchived, isTrue);
    });
  });
}
