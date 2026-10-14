import 'package:colony_database/colony_database.dart';
import 'package:colony_domain/colony_domain.dart';
import 'package:flutter_test/flutter_test.dart';

import 'migration_fixtures.dart';

void main() {
  test('stores config and per-transaction overrides', () async {
    final db = ColonyDatabase.inMemory();
    addTearDown(db.close);
    final repos = ColonyRepositories.create(
      db,
      idGenerator: FixedIdGenerator(['profile-1']),
      clock: () => DateTime.utc(2026, 10, 14, 15),
    );
    final profile = await repos.profiles.create(
      colonyName: 'Test',
      displayName: 'Caio',
      timezone: 'America/Sao_Paulo',
      locale: 'pt_BR',
      baseCurrency: 'BRL',
    );
    final created = await repos.piggy.ensureConfig(
      profileId: profile.id,
      now: DateTime.utc(2026, 10, 14, 15),
    );
    expect(created.dailyAmountMinor, PiggyBankConfig.defaultDailyAmountMinor);
    expect(created.startDate, DateTime.utc(2026, 10, 14));

    await repos.piggy.saveConfig(
      created.copyWith(
        dailyAmountMinor: 12000,
        endDate: DateTime.utc(2026, 12, 7),
        excludedCategoryIds: const ['cat_housing'],
        updatedAt: DateTime.utc(2026, 10, 14, 16),
      ),
    );
    final again = await repos.piggy.ensureConfig(
      profileId: profile.id,
      now: DateTime.utc(2026, 11, 1),
    );
    expect(again.dailyAmountMinor, 12000);
    expect(again.endDate, DateTime.utc(2026, 12, 7));
    expect(again.excludedCategoryIds, ['cat_housing']);

    await repos.piggy.saveOverride(
      PiggyBankOverride(
        profileId: profile.id,
        transactionId: EntityId('tx-1'),
        excluded: true,
        amountOverrideMinor: 1500,
        updatedAt: DateTime.utc(2026, 10, 14, 16),
      ),
    );
    final overrides = await repos.piggy.listOverrides(profile.id);
    expect(overrides.single.excluded, isTrue);
    expect(overrides.single.amountOverrideMinor, 1500);
  });

  test('migration from v39 creates piggy tables', () async {
    final db = await openMigratedFrom(39, seed: seedProfile);
    addTearDown(db.close);
    final rows = await db.customSelect(
      "SELECT name FROM sqlite_master WHERE type = 'table' AND name LIKE 'piggy_bank_%'",
    ).get();
    expect(
      rows.map((row) => row.read<String>('name')).toSet(),
      {'piggy_bank_configs', 'piggy_bank_overrides'},
    );
  });
}
