import 'package:colony_domain/colony_domain.dart';
import 'package:test/test.dart';

void main() {
  test('TripInventoryLink holds ids and linkedAt', () {
    final linkedAt = DateTime.utc(2026, 8, 7, 12);
    final link = TripInventoryLink(
      tripId: const EntityId('t-1'),
      inventoryItemId: const EntityId('i-1'),
      linkedAt: linkedAt,
    );
    expect(link.tripId.value, 't-1');
    expect(link.inventoryItemId.value, 'i-1');
    expect(link.linkedAt, linkedAt);
  });
}
