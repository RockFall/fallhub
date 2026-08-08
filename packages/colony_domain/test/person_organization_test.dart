import 'package:colony_domain/colony_domain.dart';
import 'package:test/test.dart';

void main() {
  test('PersonOrganizationLink holds membership fields', () {
    final linkedAt = DateTime.utc(2026, 8, 7, 12);
    final link = PersonOrganizationLink(
      personId: const EntityId('person-1'),
      organizationId: const EntityId('org-1'),
      linkedAt: linkedAt,
      role: 'membro',
    );

    expect(link.personId.value, 'person-1');
    expect(link.organizationId.value, 'org-1');
    expect(link.linkedAt, linkedAt);
    expect(link.role, 'membro');
  });

  test('PersonOrganizationLink equality ignores order of construction', () {
    final a = PersonOrganizationLink(
      personId: const EntityId('p'),
      organizationId: const EntityId('o'),
      linkedAt: DateTime.utc(2026, 1, 1),
    );
    final b = PersonOrganizationLink(
      personId: const EntityId('p'),
      organizationId: const EntityId('o'),
      linkedAt: DateTime.utc(2026, 1, 1),
    );
    expect(a, b);
  });
}
