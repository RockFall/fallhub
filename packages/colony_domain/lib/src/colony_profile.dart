import 'package:equatable/equatable.dart';

import 'id_generator.dart';

class ColonyProfile extends Equatable {
  const ColonyProfile({
    required this.id,
    required this.colonyName,
    required this.displayName,
    required this.timezone,
    required this.locale,
    required this.baseCurrency,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
    this.version = 1,
  });

  final EntityId id;
  final String colonyName;
  final String displayName;
  final String timezone;
  final String locale;
  final String baseCurrency;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? deletedAt;
  final int version;

  factory ColonyProfile.create({
    required EntityId id,
    required String colonyName,
    required String displayName,
    required String timezone,
    required String locale,
    required String baseCurrency,
    required DateTime createdAt,
  }) {
    return ColonyProfile(
      id: id,
      colonyName: colonyName,
      displayName: displayName,
      timezone: timezone,
      locale: locale,
      baseCurrency: baseCurrency,
      createdAt: createdAt,
      updatedAt: createdAt,
    );
  }

  ColonyProfile copyWith({
    String? colonyName,
    String? displayName,
    String? timezone,
    String? locale,
    String? baseCurrency,
    DateTime? updatedAt,
    DateTime? deletedAt,
    int? version,
  }) {
    return ColonyProfile(
      id: id,
      colonyName: colonyName ?? this.colonyName,
      displayName: displayName ?? this.displayName,
      timezone: timezone ?? this.timezone,
      locale: locale ?? this.locale,
      baseCurrency: baseCurrency ?? this.baseCurrency,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
      version: version ?? this.version,
    );
  }

  @override
  List<Object?> get props => [
        id,
        colonyName,
        displayName,
        timezone,
        locale,
        baseCurrency,
        createdAt,
        updatedAt,
        deletedAt,
        version,
      ];
}
