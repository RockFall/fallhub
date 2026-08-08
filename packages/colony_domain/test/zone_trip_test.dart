import 'package:colony_domain/colony_domain.dart';
import 'package:test/test.dart';

void main() {
  test('ZoneTripLink holds ids and linkedAt', () {
    final linkedAt = DateTime.utc(2026, 8, 7, 12);
    final link = ZoneTripLink(
      zoneId: const EntityId('z-1'),
      tripId: const EntityId('t-1'),
      linkedAt: linkedAt,
    );
    expect(link.zoneId.value, 'z-1');
    expect(link.tripId.value, 't-1');
    expect(link.linkedAt, linkedAt);
  });
}
