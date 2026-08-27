import 'dart:math' as math;
import 'dart:ui';

import 'package:flame/components.dart';
import 'package:living_habitat_assets/living_habitat_assets.dart';

/// Grayscale sprites × color (RimWorld-style modulate tint).
Paint tintPaint(Color color) {
  return Paint()
    ..colorFilter = ColorFilter.mode(color, BlendMode.modulate)
    ..filterQuality = FilterQuality.none;
}

void renderTinted(
  Sprite sprite,
  Canvas canvas, {
  required Vector2 position,
  required Vector2 size,
  required Color tint,
}) {
  sprite.render(
    canvas,
    position: position,
    size: size,
    overridePaint: tintPaint(tint),
  );
}

/// Named cosmetic loadout presets (no domain linkage).
abstract final class VisualLoadouts {
  static const home = 'home';
  static const work = 'work';
  static const outdoors = 'outdoors';
  static const sleep = 'sleep';
  static const study = 'study';
  static const exercise = 'exercise';
  static const socialCasual = 'socialCasual';
  static const socialFormal = 'socialFormal';
  static const travel = 'travel';
  static const outsideCold = 'outsideCold';
  static const outsideHot = 'outsideHot';

  static String label(String id) => switch (id) {
        home => 'Casa',
        work => 'Trabalho',
        outdoors => 'Externo',
        sleep => 'Sono',
        study => 'Estudo',
        exercise => 'Exercício',
        socialCasual => 'Social',
        socialFormal => 'Formal',
        travel => 'Viagem',
        outsideCold => 'Frio',
        outsideHot => 'Calor',
        _ => id,
      };

  /// Returns (apparelTop?, hat?).
  static (String?, String?) kit(String id) => switch (id) {
        home => ('shirt_basic', null),
        work => ('shirt_button', 'tuque'),
        outdoors => ('jacket', 'cowboy'),
        sleep => ('shirt_basic', null),
        study => ('shirt_button', null),
        exercise => ('shirt_basic', null),
        socialCasual => ('shirt_button', null),
        socialFormal => ('shirt_button', 'cowboy'),
        travel => ('jacket', 'tuque'),
        outsideCold => ('jacket', 'tuque'),
        outsideHot => ('shirt_basic', null),
        _ => ('shirt_basic', null),
      };
}

/// Live appearance of the colonist (V6 cosmetics).
class PawnAppearance {
  PawnAppearance({
    this.name = 'Colonista',
    this.bodyType = 'male',
    this.hairStyle = 'bob',
    this.beardStyle,
    this.apparelTop = 'shirt_basic',
    this.hat,
    this.loadoutId = VisualLoadouts.home,
    this.skin = PawnPalettes.skinMedium,
    this.hair = PawnPalettes.hairBrown,
    this.apparelTint = StuffPalettes.clothBlue,
    this.bio = '',
  });

  String name;
  String bodyType;
  String hairStyle;

  /// Null = clean-shaven.
  String? beardStyle;

  /// Null = nude torso (body only).
  String? apparelTop;

  /// Null = no hat.
  String? hat;
  String loadoutId;
  Color skin;
  Color hair;
  Color apparelTint;

  /// Free-text local bio (inspect only — not domain data).
  String bio;

  void applyLoadout(String id) {
    loadoutId = id;
    final (top, h) = VisualLoadouts.kit(id);
    apparelTop = top;
    hat = h;
  }

  PawnAppearance copy() => PawnAppearance(
        name: name,
        bodyType: bodyType,
        hairStyle: hairStyle,
        beardStyle: beardStyle,
        apparelTop: apparelTop,
        hat: hat,
        loadoutId: loadoutId,
        skin: skin,
        hair: hair,
        apparelTint: apparelTint,
        bio: bio,
      );

  void copyFrom(PawnAppearance other) {
    name = other.name;
    bodyType = other.bodyType;
    hairStyle = other.hairStyle;
    beardStyle = other.beardStyle;
    apparelTop = other.apparelTop;
    hat = other.hat;
    loadoutId = other.loadoutId;
    skin = other.skin;
    hair = other.hair;
    apparelTint = other.apparelTint;
    bio = other.bio;
  }

  /// Randomize cosmetics. Skin only if [includeSkin].
  void randomize({bool includeSkin = false, math.Random? rng}) {
    final r = rng ?? math.Random();
    bodyType =
        HabitatAssets.bodyTypes[r.nextInt(HabitatAssets.bodyTypes.length)];
    hairStyle =
        HabitatAssets.hairStyles[r.nextInt(HabitatAssets.hairStyles.length)];
    hair = PawnPalettes.hairSwatches[r.nextInt(PawnPalettes.hairSwatches.length)];
    if (includeSkin) {
      skin = PawnPalettes.skinSwatches[r.nextInt(PawnPalettes.skinSwatches.length)];
    }
    // ~40% chance of beard (not on female silhouette).
    if (bodyType != 'female' && r.nextDouble() < 0.4) {
      beardStyle = HabitatAssets
          .beardStyles[r.nextInt(HabitatAssets.beardStyles.length)];
    } else {
      beardStyle = null;
    }
    applyLoadout(
      HabitatAssets.loadoutIds[r.nextInt(HabitatAssets.loadoutIds.length)],
    );
    apparelTint = StuffPalettes
        .furnitureSwatches[r.nextInt(StuffPalettes.furnitureSwatches.length)];
  }

  void randomizeHair({math.Random? rng}) {
    final r = rng ?? math.Random();
    hairStyle =
        HabitatAssets.hairStyles[r.nextInt(HabitatAssets.hairStyles.length)];
    hair = PawnPalettes.hairSwatches[r.nextInt(PawnPalettes.hairSwatches.length)];
  }

  void randomizeClothes({math.Random? rng}) {
    final r = rng ?? math.Random();
    applyLoadout(
      HabitatAssets.loadoutIds[r.nextInt(HabitatAssets.loadoutIds.length)],
    );
    apparelTint = StuffPalettes
        .furnitureSwatches[r.nextInt(StuffPalettes.furnitureSwatches.length)];
  }

  static String hairStyleLabel(String style) => switch (style) {
        'bob' => 'Bob',
        'afro' => 'Afro',
        'mohawk' => 'Mohawk',
        'mop' => 'Mop',
        'spikes' => 'Spikes',
        'wavy' => 'Wavy',
        'burgundy' => 'Burgundy',
        'firestarter' => 'Firestarter',
        'pigtails' => 'Pigtails',
        'shaved' => 'Shaved',
        _ => style,
      };

  static String bodyTypeLabel(String type) => switch (type) {
        'male' => 'Masculino',
        'female' => 'Feminino',
        'thin' => 'Magro',
        'fat' => 'Cheio',
        'hulk' => 'Hulk',
        _ => type,
      };

  static String beardLabel(String? style) => switch (style) {
        null => 'Nenhuma',
        'full' => 'Cheia',
        'goatee' => 'Cavanhaque',
        'boxed' => 'Quadra',
        _ => style,
      };

  static String apparelLabel(String? piece) => switch (piece) {
        null => 'Nenhuma',
        'shirt_basic' => 'Camisa',
        'shirt_button' => 'Camisa social',
        'jacket' => 'Jaqueta',
        _ => piece,
      };

  static String hatLabel(String? style) => switch (style) {
        null => 'Nenhum',
        'tuque' => 'Gorro',
        'cowboy' => 'Chapéu',
        _ => style,
      };
}

/// Curated swatches — quick identity without a full color picker.
abstract final class PawnPalettes {
  static const skinPale = Color(0xFFFFE0BD);
  static const skinLight = Color(0xFFF1C27D);
  static const skinMedium = Color(0xFFE0AC69);
  static const skinTan = Color(0xFFC68642);
  static const skinDeep = Color(0xFF8D5524);
  static const skinDark = Color(0xFF5C3317);

  static const hairBlack = Color(0xFF1A1A1A);
  static const hairBrown = Color(0xFF5C3A21);
  static const hairAuburn = Color(0xFF8B3A2A);
  static const hairBlonde = Color(0xFFD4B06A);
  static const hairGray = Color(0xFF9A9A9A);
  static const hairWhite = Color(0xFFE8E8E8);
  static const hairBlue = Color(0xFF3D6FBF);
  static const hairPink = Color(0xFFD97CA8);
  static const hairGreen = Color(0xFF4A9B6D);

  static const List<Color> skinSwatches = [
    skinPale,
    skinLight,
    skinMedium,
    skinTan,
    skinDeep,
    skinDark,
  ];

  static const List<Color> hairSwatches = [
    hairBlack,
    hairBrown,
    hairAuburn,
    hairBlonde,
    hairGray,
    hairWhite,
    hairBlue,
    hairPink,
    hairGreen,
  ];
}

/// Stuff colors for furniture / apparel (cloth / wood / metal vibe).
abstract final class StuffPalettes {
  static const natural = Color(0xFFFFFFFF);
  static const wood = Color(0xFFC4A46A);
  static const woodDark = Color(0xFF8B6914);
  static const steel = Color(0xFFB0B6BE);
  static const clothBlue = Color(0xFF5B7C99);
  static const clothRed = Color(0xFFA85A5A);
  static const clothGreen = Color(0xFF6B8F71);
  static const clothPurple = Color(0xFF7A6B99);
  static const gold = Color(0xFFD4AF37);
  static const plastic = Color(0xFFE8E0D0);
  static const stone = Color(0xFF9A9A9A);

  static const List<Color> furnitureSwatches = [
    natural,
    wood,
    woodDark,
    steel,
    clothBlue,
    clothRed,
    clothGreen,
    clothPurple,
    gold,
    plastic,
    stone,
  ];
}
