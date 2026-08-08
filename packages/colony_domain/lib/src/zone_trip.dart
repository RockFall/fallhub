import 'package:equatable/equatable.dart';

import 'id_generator.dart';

/// N:N ContextZone↔Trip link (Phase 8 depth / §25–26).
class ZoneTripLink extends Equatable {
  const ZoneTripLink({
    required this.zoneId,
    required this.tripId,
    required this.linkedAt,
  });

  final EntityId zoneId;
  final EntityId tripId;
  final DateTime linkedAt;

  @override
  List<Object?> get props => [zoneId, tripId, linkedAt];
}
