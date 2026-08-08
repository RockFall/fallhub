import 'package:colony_domain/colony_domain.dart';
import 'package:test/test.dart';

void main() {
  test('missingItemIds skips already linked and duplicates', () {
    final missing = TripPackingCopyPolicy.missingItemIds(
      sourceItemIds: const [
        EntityId('a'),
        EntityId('b'),
        EntityId('a'),
        EntityId('c'),
      ],
      targetItemIds: const [EntityId('b')],
    );
    expect(missing.map((e) => e.value), ['a', 'c']);
  });

  test('missingItemIds empty when source empty', () {
    expect(
      TripPackingCopyPolicy.missingItemIds(
        sourceItemIds: const [],
        targetItemIds: const [EntityId('x')],
      ),
      isEmpty,
    );
  });
}
