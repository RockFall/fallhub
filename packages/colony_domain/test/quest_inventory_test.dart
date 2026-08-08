import 'package:colony_domain/colony_domain.dart';
import 'package:test/test.dart';

void main() {
  test('QuestInventoryLink holds ids and linkedAt', () {
    final linkedAt = DateTime.utc(2026, 8, 7, 12);
    final link = QuestInventoryLink(
      questId: const EntityId('q-1'),
      inventoryItemId: const EntityId('i-1'),
      linkedAt: linkedAt,
    );
    expect(link.questId.value, 'q-1');
    expect(link.inventoryItemId.value, 'i-1');
    expect(link.linkedAt, linkedAt);
  });
}
