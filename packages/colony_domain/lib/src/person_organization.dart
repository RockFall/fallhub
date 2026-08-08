import 'package:equatable/equatable.dart';

import 'id_generator.dart';

/// N:N Person↔Organization membership (ADR-028 membership stub).
class PersonOrganizationLink extends Equatable {
  const PersonOrganizationLink({
    required this.personId,
    required this.organizationId,
    required this.linkedAt,
    this.role,
  });

  final EntityId personId;
  final EntityId organizationId;
  final DateTime linkedAt;
  final String? role;

  @override
  List<Object?> get props => [personId, organizationId, linkedAt, role];
}
