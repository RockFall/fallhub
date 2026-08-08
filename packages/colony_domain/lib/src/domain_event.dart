import 'dart:convert';

import 'package:equatable/equatable.dart';

import 'enums.dart';
import 'id_generator.dart';

class DomainEvent extends Equatable {
  const DomainEvent({
    required this.id,
    required this.aggregateType,
    required this.aggregateId,
    required this.eventType,
    required this.occurredAt,
    required this.recordedAt,
    required this.sourceType,
    required this.payloadVersion,
    required this.payload,
    required this.privacyClass,
    this.correlationId,
    this.causationId,
  });

  final EntityId id;
  final AggregateType aggregateType;
  final EntityId aggregateId;
  final EventType eventType;
  final DateTime occurredAt;
  final DateTime recordedAt;
  final SourceType sourceType;
  final int payloadVersion;
  final Map<String, Object?> payload;
  final PrivacyClass privacyClass;
  final String? correlationId;
  final String? causationId;

  String get payloadJson => jsonEncode(payload);

  factory DomainEvent.record({
    required EntityId id,
    required AggregateType aggregateType,
    required EntityId aggregateId,
    required EventType eventType,
    required DateTime occurredAt,
    required DateTime recordedAt,
    required SourceType sourceType,
    required Map<String, Object?> payload,
    PrivacyClass privacyClass = PrivacyClass.personal,
    String? correlationId,
    String? causationId,
    int payloadVersion = 1,
  }) {
    return DomainEvent(
      id: id,
      aggregateType: aggregateType,
      aggregateId: aggregateId,
      eventType: eventType,
      occurredAt: occurredAt,
      recordedAt: recordedAt,
      sourceType: sourceType,
      payloadVersion: payloadVersion,
      payload: payload,
      privacyClass: privacyClass,
      correlationId: correlationId,
      causationId: causationId,
    );
  }

  @override
  List<Object?> get props => [
        id,
        aggregateType,
        aggregateId,
        eventType,
        occurredAt,
        recordedAt,
        sourceType,
        payloadVersion,
        payload,
        privacyClass,
        correlationId,
        causationId,
      ];
}
