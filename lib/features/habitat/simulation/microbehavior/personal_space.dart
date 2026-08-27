import '../identity/identity.dart';

/// Soft spatial cost near stationary pawns (MD 10 R12).
///
/// Does not block pathfinding — only biases slot / idle / wander choices.
abstract final class PersonalSpace {
  /// Base radius in cells (Manhattan) where cost applies.
  static const defaultRadius = 2;

  /// Cost at [cell] given other pawn positions.
  static double costAt({
    required (int, int) cell,
    required List<PersonalSpaceAgent> agents,
    required String selfId,
    SocialStyle socialStyle = SocialStyle.balanced,
    double relationshipComfort = 0.5,
    double crowdingTolerance = 0.5,
    bool groupActivity = false,
  }) {
    if (groupActivity) {
      // Groups may compact — only penalize exact overlaps strongly.
      var c = 0.0;
      for (final a in agents) {
        if (a.pawnId == selfId) continue;
        final d = (a.cell.$1 - cell.$1).abs() + (a.cell.$2 - cell.$2).abs();
        if (d == 0) c += 2.5;
        else if (d == 1 && !a.moving) c += 0.15;
      }
      return c;
    }

    var styleMul = switch (socialStyle) {
      SocialStyle.reserved => 1.35,
      SocialStyle.balanced => 1.0,
      SocialStyle.outgoing => 0.75,
    };
    // Low comfort with strangers → more space; high comfort → closer ok.
    styleMul *= (1.25 - relationshipComfort.clamp(0.0, 1.0) * 0.5);
    styleMul *= (1.3 - crowdingTolerance.clamp(0.0, 1.0) * 0.55);

    var cost = 0.0;
    for (final a in agents) {
      if (a.pawnId == selfId) continue;
      final d = (a.cell.$1 - cell.$1).abs() + (a.cell.$2 - cell.$2).abs();
      if (d > defaultRadius + (a.moving ? 0 : 0)) continue;
      if (d == 0) {
        cost += 3.0 * styleMul;
      } else if (d == 1) {
        cost += (a.moving ? 0.35 : 1.1) * styleMul;
      } else if (d == 2) {
        cost += (a.moving ? 0.1 : 0.4) * styleMul;
      }
    }
    return cost;
  }
}

class PersonalSpaceAgent {
  const PersonalSpaceAgent({
    required this.pawnId,
    required this.cell,
    this.moving = false,
  });

  final String pawnId;
  final (int, int) cell;
  final bool moving;
}
