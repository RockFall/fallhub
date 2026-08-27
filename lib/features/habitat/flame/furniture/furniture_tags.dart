/// Capability tags for furniture — drive jobs, light, joy, beauty without
/// hard-coding every kind in call sites.
enum FurnitureTag {
  /// Pawn can sit (chair, armchair, stool, couch).
  sit,

  /// Pawn can sleep (beds, bedrolls, sleep spots).
  sleep,

  /// Surface for gather / go-to-table.
  table,

  /// Emits light when active.
  light,

  /// Joy / recreate target (bookcase, tv, games…).
  joy,

  /// Passive / plant pot.
  plant,

  /// Pure beauty / sculpture.
  beauty,

  /// Storage (dresser, shelf) — future inventory hooks.
  storage,

  /// Wall-mounted (wall lamp) — placement rules later.
  wallMounted,

  /// Soft seating / social (couch, armchair).
  comfort,
}
