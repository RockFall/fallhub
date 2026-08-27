/// Asset path helpers for Living Habitat V0+.
abstract final class HabitatAssets {
  static const package = 'living_habitat_assets';

  static const bodyTypes = <String>[
    'male',
    'female',
    'thin',
    'fat',
    'hulk',
  ];

  static const hairStyles = <String>[
    'bob',
    'afro',
    'mohawk',
    'mop',
    'spikes',
    'wavy',
    'burgundy',
    'firestarter',
    'pigtails',
    'shaved',
  ];

  /// Beard styles (south/east sprites; north falls back to south).
  static const beardStyles = <String>['full', 'goatee', 'boxed'];

  /// Tintable torso pieces (per body type × dir).
  static const apparelTops = <String>[
    'shirt_basic',
    'shirt_button',
    'jacket',
  ];

  static const hats = <String>['tuque', 'cowboy'];

  /// Named visual loadouts (cosmetic only — no domain).
  static const loadoutIds = <String>['home', 'work', 'outdoors'];

  static const directions = <String>['south', 'east', 'north'];

  static String body(String dir, {String bodyType = 'male'}) =>
      'assets/v0/pawn/body/${bodyType}_$dir.png';

  static String head(String dir, {String bodyType = 'male'}) {
    final key = bodyType == 'female' ? 'female' : 'male';
    return 'assets/v0/pawn/head/${key}_$dir.png';
  }

  static String hair(String dir, {String style = 'bob'}) =>
      'assets/v0/pawn/hair/${style}_$dir.png';

  static String apparel(String piece, String bodyType, String dir) =>
      'assets/v0/pawn/apparel/${piece}_${bodyType}_$dir.png';

  static String hat(String style, String dir) =>
      'assets/v0/pawn/hat/${style}_$dir.png';

  /// Beards have no north sheet — callers should request south for north facing.
  static String beard(String style, String dir) {
    final d = dir == 'north' ? 'south' : dir;
    return 'assets/v0/pawn/beard/${style}_$d.png';
  }

  static const woodFloor = 'assets/v0/tiles/wood_floor.png';
  static const carpet = 'assets/v0/tiles/carpet.png';
  static const concrete = 'assets/v0/tiles/concrete.png';

  /// Legacy flat aliases (still loaded for older saves / tests).
  static const bedSouth = 'assets/v0/furniture/bed/south.png';
  static const chairSouth = 'assets/v0/furniture/dining_chair/south.png';
  static const tableSouth = 'assets/v0/furniture/table_2x2/south.png';
  static const lamp = 'assets/v0/furniture/lamp_standing/south.png';
  static const tvSouth = 'assets/v0/furniture/tv_south.png';

  /// Exported from RimWorld-style `DoorSimple_Mover.psd` (game_art_source).
  static const doorSimpleMover = 'assets/v0/furniture/door_simple_mover.png';

  static String furniture(String id, [String facing = 'south']) =>
      'assets/v0/furniture/$id/$facing.png';

  static String furnitureMask(String id, [String facing = 'south']) =>
      'assets/v0/furniture/$id/${facing}_mask.png';
}
