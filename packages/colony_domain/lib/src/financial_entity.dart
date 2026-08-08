import 'package:equatable/equatable.dart';

import 'id_generator.dart';

enum FinancialEntityKind {
  personal,
  business,
  project,
  trip,
  shared,
}

class FinancialEntity extends Equatable {
  const FinancialEntity({
    required this.id,
    required this.profileId,
    required this.name,
    required this.kind,
    required this.createdAt,
    required this.updatedAt,
  });

  final EntityId id;
  final EntityId profileId;
  final String name;
  final FinancialEntityKind kind;
  final DateTime createdAt;
  final DateTime updatedAt;

  factory FinancialEntity.create({
    required EntityId id,
    required EntityId profileId,
    required String name,
    required FinancialEntityKind kind,
    required DateTime createdAt,
  }) {
    return FinancialEntity(
      id: id,
      profileId: profileId,
      name: name.trim(),
      kind: kind,
      createdAt: createdAt,
      updatedAt: createdAt,
    );
  }

  FinancialEntity copyWith({
    String? name,
    FinancialEntityKind? kind,
    DateTime? updatedAt,
  }) {
    return FinancialEntity(
      id: id,
      profileId: profileId,
      name: name ?? this.name,
      kind: kind ?? this.kind,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [id, profileId, name, kind, createdAt, updatedAt];
}
