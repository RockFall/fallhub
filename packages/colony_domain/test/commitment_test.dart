import 'package:colony_domain/colony_domain.dart';
import 'package:test/test.dart';

void main() {
  final now = DateTime.utc(2026, 8, 7, 12);

  test('create trims fields and accepts madeToLabel', () {
    final c = Commitment.create(
      id: const EntityId('c-1'),
      profileId: const EntityId('p-1'),
      description: '  Ligar amanhã  ',
      madeByLabel: '  eu  ',
      madeToLabel: '  Ana  ',
      createdAt: now,
    );
    expect(c.description, 'Ligar amanhã');
    expect(c.madeByLabel, 'eu');
    expect(c.madeToLabel, 'Ana');
    expect(c.status, CommitmentStatus.open);
  });

  test('create rejects empty description and missing counterpart', () {
    expect(
      () => Commitment.create(
        id: const EntityId('c-1'),
        profileId: const EntityId('p-1'),
        description: '  ',
        madeToLabel: 'x',
        createdAt: now,
      ),
      throwsArgumentError,
    );
    expect(
      () => Commitment.create(
        id: const EntityId('c-2'),
        profileId: const EntityId('p-1'),
        description: 'Promessa',
        createdAt: now,
      ),
      throwsArgumentError,
    );
  });

  test('withStatus updates status', () {
    final c = Commitment.create(
      id: const EntityId('c-1'),
      profileId: const EntityId('p-1'),
      description: 'Entregar livro',
      madeToPersonId: const EntityId('person-1'),
      createdAt: now,
    );
    final kept = c.withStatus(CommitmentStatus.kept, now.add(const Duration(hours: 1)));
    expect(kept.status, CommitmentStatus.kept);
    expect(kept.status.isHiddenFromActiveList, isTrue);
  });

  test('linkedQuestId round-trips via copyWith', () {
    final c = Commitment.create(
      id: const EntityId('c-1'),
      profileId: const EntityId('p-1'),
      description: 'Entregar relatório',
      madeToLabel: 'chefe',
      linkedQuestId: const EntityId('quest-1'),
      createdAt: now,
    );
    expect(c.linkedQuestId?.value, 'quest-1');
    final cleared = c.copyWith(clearLinkedQuestId: true);
    expect(cleared.linkedQuestId, isNull);
    final relinked = cleared.copyWith(linkedQuestId: const EntityId('quest-2'));
    expect(relinked.linkedQuestId?.value, 'quest-2');
  });
}
