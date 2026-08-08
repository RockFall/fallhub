import 'package:equatable/equatable.dart';

import 'id_generator.dart';

enum SyncOpKind {
  upsert,
  delete,
}

enum SyncOpStatus {
  pending,
  processing,
  acked,
  failed,
  conflict;

  bool get isOpen => this == pending || this == processing || this == failed;
}

/// Local device registry entry (ADR-025). No remote auth.
class DeviceIdentity extends Equatable {
  const DeviceIdentity({
    required this.id,
    required this.label,
    required this.createdAt,
    this.lastSeenAt,
  });

  final EntityId id;
  final String label;
  final DateTime createdAt;
  final DateTime? lastSeenAt;

  factory DeviceIdentity.create({
    required EntityId id,
    required String label,
    required DateTime createdAt,
  }) {
    final trimmed = label.trim();
    if (trimmed.isEmpty) {
      throw ArgumentError('DeviceIdentity label cannot be empty');
    }
    return DeviceIdentity(
      id: id,
      label: trimmed,
      createdAt: createdAt,
      lastSeenAt: createdAt,
    );
  }

  DeviceIdentity touch(DateTime at) => DeviceIdentity(
        id: id,
        label: label,
        createdAt: createdAt,
        lastSeenAt: at,
      );

  @override
  List<Object?> get props => [id, label, createdAt, lastSeenAt];
}

/// Append-only sync outbox row (ADR-025 / §35.2). Local stub; no network.
class SyncOperation extends Equatable {
  const SyncOperation({
    required this.id,
    required this.entityType,
    required this.entityId,
    required this.operation,
    this.baseVersion,
    required this.payloadJson,
    required this.status,
    required this.attempts,
    this.nextAttemptAt,
    required this.createdAt,
    required this.updatedAt,
  });

  final EntityId id;
  final String entityType;
  final EntityId entityId;
  final SyncOpKind operation;
  final int? baseVersion;
  final String payloadJson;
  final SyncOpStatus status;
  final int attempts;
  final DateTime? nextAttemptAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  factory SyncOperation.enqueue({
    required EntityId id,
    required String entityType,
    required EntityId entityId,
    SyncOpKind operation = SyncOpKind.upsert,
    int? baseVersion,
    required String payloadJson,
    required DateTime createdAt,
  }) {
    final type = entityType.trim();
    if (type.isEmpty) {
      throw ArgumentError('SyncOperation entityType cannot be empty');
    }
    return SyncOperation(
      id: id,
      entityType: type,
      entityId: entityId,
      operation: operation,
      baseVersion: baseVersion,
      payloadJson: payloadJson,
      status: SyncOpStatus.pending,
      attempts: 0,
      createdAt: createdAt,
      updatedAt: createdAt,
    );
  }

  /// Local no-op worker: mark as acked without network.
  SyncOperation ackLocal(DateTime at) {
    return SyncOperation(
      id: id,
      entityType: entityType,
      entityId: entityId,
      operation: operation,
      baseVersion: baseVersion,
      payloadJson: payloadJson,
      status: SyncOpStatus.acked,
      attempts: attempts + 1,
      nextAttemptAt: null,
      createdAt: createdAt,
      updatedAt: at,
    );
  }

  @override
  List<Object?> get props => [
        id,
        entityType,
        entityId,
        operation,
        baseVersion,
        payloadJson,
        status,
        attempts,
        nextAttemptAt,
        createdAt,
        updatedAt,
      ];
}
