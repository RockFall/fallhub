import 'package:colony_domain/colony_domain.dart';
import 'package:test/test.dart';

void main() {
  group('Organization', () {
    test('create trims name and notes', () {
      final org = Organization.create(
        id: EntityId('org-1'),
        profileId: EntityId('p-1'),
        name: '  Acme Ltd  ',
        kind: OrganizationKind.company,
        notes: '  cliente  ',
        createdAt: DateTime.utc(2026, 8, 7),
      );

      expect(org.name, 'Acme Ltd');
      expect(org.notes, 'cliente');
      expect(org.kind, OrganizationKind.company);
      expect(org.isArchived, isFalse);
    });

    test('rejects empty name', () {
      expect(
        () => Organization.create(
          id: EntityId('org-1'),
          profileId: EntityId('p-1'),
          name: '  ',
          kind: OrganizationKind.other,
          createdAt: DateTime.utc(2026, 8, 7),
        ),
        throwsArgumentError,
      );
    });

    test('archive via copyWith', () {
      final org = Organization.create(
        id: EntityId('org-1'),
        profileId: EntityId('p-1'),
        name: 'Clinica',
        kind: OrganizationKind.clinic,
        createdAt: DateTime.utc(2026, 8, 7),
      );
      final archived = org.copyWith(
        archivedAt: DateTime.utc(2026, 8, 8),
        updatedAt: DateTime.utc(2026, 8, 8),
      );
      expect(archived.isArchived, isTrue);
    });
  });
}
