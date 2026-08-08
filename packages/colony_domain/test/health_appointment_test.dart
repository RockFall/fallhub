import 'package:colony_domain/colony_domain.dart';
import 'package:test/test.dart';

void main() {
  final now = DateTime.utc(2026, 8, 7, 12);

  test('create trims fields and rejects empty title', () {
    final a = HealthAppointment.create(
      id: const EntityId('a-1'),
      profileId: const EntityId('p-1'),
      title: '  Check-up  ',
      scheduledAt: DateTime.utc(2026, 9, 1, 10),
      locationLabel: '  Clínica  ',
      createdAt: now,
    );
    expect(a.title, 'Check-up');
    expect(a.locationLabel, 'Clínica');
    expect(a.status, HealthAppointmentStatus.scheduled);

    expect(
      () => HealthAppointment.create(
        id: const EntityId('a-2'),
        profileId: const EntityId('p-1'),
        title: '  ',
        scheduledAt: now,
        createdAt: now,
      ),
      throwsArgumentError,
    );
  });

  test('copyWith updates status', () {
    final a = HealthAppointment.create(
      id: const EntityId('a-1'),
      profileId: const EntityId('p-1'),
      title: 'Dentista',
      scheduledAt: DateTime.utc(2026, 9, 2),
      createdAt: now,
    );
    final done = a.copyWith(
      status: HealthAppointmentStatus.done,
      updatedAt: now.add(const Duration(hours: 1)),
    );
    expect(done.status, HealthAppointmentStatus.done);
    expect(done.status.isHiddenFromActiveList, isTrue);

    final cancelled = a.copyWith(
      status: HealthAppointmentStatus.cancelled,
      updatedAt: now.add(const Duration(hours: 2)),
    );
    expect(cancelled.status, HealthAppointmentStatus.cancelled);
    expect(cancelled.status.isHiddenFromActiveList, isTrue);
  });
}
