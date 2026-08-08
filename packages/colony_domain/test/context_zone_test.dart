import 'package:colony_domain/colony_domain.dart';
import 'package:test/test.dart';

void main() {
  final now = DateTime.utc(2026, 8, 7, 12);

  test('create trims and rejects empty name', () {
    final z = ContextZone.create(
      id: const EntityId('z-1'),
      profileId: const EntityId('p-1'),
      name: '  Avião  ',
      capabilities: const ['read', 'notes'],
      connectivity: ZoneConnectivity.offline,
      createdAt: now,
    );
    expect(z.name, 'Avião');
    expect(z.capabilities, ['read', 'notes']);
    expect(
      () => ContextZone.create(
        id: const EntityId('z-2'),
        profileId: const EntityId('p-1'),
        name: '  ',
        createdAt: now,
      ),
      throwsArgumentError,
    );
  });

  test('archive via copyWith', () {
    final z = ContextZone.create(
      id: const EntityId('z-1'),
      profileId: const EntityId('p-1'),
      name: 'Casa',
      createdAt: now,
    );
    final archived = z.copyWith(archivedAt: now, updatedAt: now);
    expect(archived.isArchived, isTrue);
  });
}
