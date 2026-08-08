import 'package:colony_domain/colony_domain.dart';
import 'package:test/test.dart';

void main() {
  group('Trip', () {
    test('create trims title, destinations, purpose and notes', () {
      final trip = Trip.create(
        id: EntityId('trip-1'),
        profileId: EntityId('p-1'),
        title: '  Férias SP  ',
        destinations: ['  São Paulo ', '', 'Campinas'],
        purpose: '  descanso  ',
        notes: '  hotel centro  ',
        createdAt: DateTime.utc(2026, 8, 7),
      );

      expect(trip.title, 'Férias SP');
      expect(trip.destinations, ['São Paulo', 'Campinas']);
      expect(trip.purpose, 'descanso');
      expect(trip.notes, 'hotel centro');
      expect(trip.status, TripStatus.planned);
    });

    test('rejects empty title and end before start', () {
      expect(
        () => Trip.create(
          id: EntityId('trip-1'),
          profileId: EntityId('p-1'),
          title: '  ',
          createdAt: DateTime.utc(2026, 8, 7),
        ),
        throwsArgumentError,
      );
      expect(
        () => Trip.create(
          id: EntityId('trip-1'),
          profileId: EntityId('p-1'),
          title: 'Viagem',
          startAt: DateTime.utc(2026, 8, 10),
          endAt: DateTime.utc(2026, 8, 9),
          createdAt: DateTime.utc(2026, 8, 7),
        ),
        throwsArgumentError,
      );
    });

    test('cancelled is hidden from active list', () {
      expect(TripStatus.cancelled.isHiddenFromActiveList, isTrue);
      expect(TripStatus.planned.isHiddenFromActiveList, isFalse);
      expect(TripStatus.active.isHiddenFromActiveList, isFalse);
      expect(TripStatus.completed.isHiddenFromActiveList, isFalse);
    });
  });
}
