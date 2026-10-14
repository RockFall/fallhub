import 'package:colony_domain/colony_domain.dart';

import '../colony_database.dart';

class PiggyBankRepository {
  PiggyBankRepository(this._db, this._clock);

  final ColonyDatabase _db;
  final DateTime Function() _clock;

  Stream<PiggyBankConfig?> watchConfig(EntityId profileId) {
    return (_db.select(_db.piggyBankConfigs)
          ..where((row) => row.profileId.equals(profileId.value)))
        .watchSingleOrNull()
        .map(
          (row) => row == null ? null : ColonyMappers.toPiggyBankConfig(row),
        );
  }

  Future<PiggyBankConfig?> getConfig(EntityId profileId) async {
    final row = await (_db.select(_db.piggyBankConfigs)
          ..where((t) => t.profileId.equals(profileId.value)))
        .getSingleOrNull();
    return row == null ? null : ColonyMappers.toPiggyBankConfig(row);
  }

  Future<PiggyBankConfig> ensureConfig({
    required EntityId profileId,
    required DateTime now,
  }) async {
    final existing = await getConfig(profileId);
    if (existing != null) return existing;
    final created = PiggyBankConfig.initial(
      profileId: profileId,
      todayCivil: now,
      updatedAt: _clock(),
    );
    await saveConfig(created);
    return created;
  }

  Future<void> saveConfig(PiggyBankConfig config) async {
    config.validate();
    await _db.into(_db.piggyBankConfigs).insertOnConflictUpdate(
          ColonyMappers.fromPiggyBankConfig(config),
        );
  }

  Future<List<PiggyBankOverride>> listOverrides(EntityId profileId) async {
    final rows = await (_db.select(_db.piggyBankOverrides)
          ..where((row) => row.profileId.equals(profileId.value)))
        .get();
    return rows.map(ColonyMappers.toPiggyBankOverride).toList();
  }

  Future<void> saveOverride(PiggyBankOverride override) async {
    await _db.into(_db.piggyBankOverrides).insertOnConflictUpdate(
          ColonyMappers.fromPiggyBankOverride(override),
        );
  }
}
