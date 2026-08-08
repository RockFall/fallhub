import 'package:colony_domain/colony_domain.dart';
import 'package:test/test.dart';

void main() {
  final now = DateTime.utc(2026, 8, 7, 12);

  test('DeviceIdentity rejects empty label', () {
    expect(
      () => DeviceIdentity.create(
        id: const EntityId('d-1'),
        label: '  ',
        createdAt: now,
      ),
      throwsArgumentError,
    );
  });

  test('SyncOperation enqueue starts pending; ackLocal marks acked', () {
    final op = SyncOperation.enqueue(
      id: const EntityId('op-1'),
      entityType: 'commitment',
      entityId: const EntityId('c-1'),
      payloadJson: '{"id":"c-1"}',
      createdAt: now,
    );
    expect(op.status, SyncOpStatus.pending);
    expect(op.status.isOpen, isTrue);
    final acked = op.ackLocal(now.add(const Duration(seconds: 1)));
    expect(acked.status, SyncOpStatus.acked);
    expect(acked.attempts, 1);
    expect(acked.status.isOpen, isFalse);
  });
}
