import 'package:colony_domain/colony_domain.dart';
import 'package:test/test.dart';

void main() {
  test('PersonInteraction.create trims note and normalizes UTC', () {
    final at = DateTime(2026, 8, 7, 12);
    final ix = PersonInteraction.create(
      id: EntityId('ix-1'),
      profileId: EntityId('p1'),
      personId: EntityId('person-1'),
      kind: InteractionKind.call,
      occurredAt: at,
      note: '  hi  ',
      createdAt: DateTime.utc(2026, 8, 7, 13),
    );
    expect(ix.note, 'hi');
    expect(ix.occurredAt.isUtc, isTrue);
    expect(ix.kind, InteractionKind.call);
  });

  test('PersonInteraction.create nulls empty note', () {
    final ix = PersonInteraction.create(
      id: EntityId('ix-1'),
      profileId: EntityId('p1'),
      personId: EntityId('person-1'),
      kind: InteractionKind.message,
      occurredAt: DateTime.utc(2026, 8, 7),
      note: '   ',
      createdAt: DateTime.utc(2026, 8, 7),
    );
    expect(ix.note, isNull);
  });
}
