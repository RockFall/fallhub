import '../components/pawn_job_controller.dart';
import 'furniture_def.dart';
import 'furniture_registry.dart';
import 'furniture_tags.dart';

/// Maps furniture tags/use → jobs and runtime behaviours.
///
/// Keep call sites on this helper so new defs only need registry entries.
abstract final class FurnitureInteractions {
  static FurnitureDef? def(String kind) => FurnitureRegistry.tryGet(kind);

  static bool isLight(String kind) =>
      FurnitureRegistry.hasTag(kind, FurnitureTag.light);

  static bool isSit(String kind) =>
      FurnitureRegistry.hasTag(kind, FurnitureTag.sit);

  static bool isSleep(String kind) =>
      FurnitureRegistry.hasTag(kind, FurnitureTag.sleep);

  static bool isTable(String kind) =>
      FurnitureRegistry.hasTag(kind, FurnitureTag.table);

  static bool isJoy(String kind) =>
      FurnitureRegistry.hasTag(kind, FurnitureTag.joy);

  static bool isPlant(String kind) =>
      FurnitureRegistry.hasTag(kind, FurnitureTag.plant);

  static double lightRadius(String kind, {double qualityBonus = 0}) {
    final r = def(kind)?.lightRadius ?? 0;
    if (r <= 0) return 0;
    return r + qualityBonus;
  }

  static double beauty(String kind) => def(kind)?.beauty ?? 0;

  /// Job issued when the player / AI uses this prop.
  static HabitatJobKind? jobForUse(String kind) {
    final use = def(kind)?.use;
    return switch (use) {
      FurnitureUse.sit => HabitatJobKind.sit,
      FurnitureUse.sleep => HabitatJobKind.sleep,
      FurnitureUse.sitAtTable => HabitatJobKind.goToTable,
      FurnitureUse.recreate => HabitatJobKind.recreate,
      FurnitureUse.admire => HabitatJobKind.recreate,
      FurnitureUse.toggleLight || FurnitureUse.none || null => null,
    };
  }

  /// Kind string to look up for a job (first matching registry def).
  static String? kindForJob(HabitatJobKind job) {
    final tag = switch (job) {
      HabitatJobKind.sleep => FurnitureTag.sleep,
      HabitatJobKind.sit => FurnitureTag.sit,
      HabitatJobKind.goToTable => FurnitureTag.table,
      HabitatJobKind.recreate => FurnitureTag.joy,
      _ => null,
    };
    if (tag == null) return null;
    final match = FurnitureRegistry.withTag(tag);
    return match.isEmpty ? null : match.first.id;
  }

  /// Any prop kind that satisfies [job] (for map.propByKind / first-match).
  static bool kindMatchesJob(String kind, HabitatJobKind job) {
    return switch (job) {
      HabitatJobKind.sleep => isSleep(kind),
      HabitatJobKind.sit => isSit(kind),
      HabitatJobKind.goToTable => isTable(kind),
      HabitatJobKind.recreate => isJoy(kind),
      _ => false,
    };
  }
}
