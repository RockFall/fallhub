/// Cardinal facing used by microbehavior resolvers (maps 1:1 to HabitatFacing).
enum MicroFacing { south, east, north, west }

/// Pure delta → facing (same rules as map `facingFromDelta`).
MicroFacing microFacingFromDelta(int dx, int dy) {
  if (dx.abs() >= dy.abs()) {
    if (dx > 0) return MicroFacing.east;
    if (dx < 0) return MicroFacing.west;
  }
  if (dy > 0) return MicroFacing.south;
  if (dy < 0) return MicroFacing.north;
  return MicroFacing.south;
}
