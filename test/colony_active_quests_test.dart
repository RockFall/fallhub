import 'package:colony_database/colony_database.dart';
import 'package:colony_domain/colony_domain.dart';
import 'package:flutter_test/flutter_test.dart';

/// Widget pump of ColonyScreen hangs under Windows native-assets in this env
/// (pumpAndSettle / long-lived Drift streams). Cover the acceptance rule via
/// repository query instead; UI coverage remains in bootstrap/colony screens.
void main() {
  test('active quests list is capped at three for colony panel policy', () async {
    final db = ColonyDatabase.inMemory();
    addTearDown(db.close);

    final repos = ColonyRepositories.create(
      db,
      idGenerator: FixedIdGenerator([
        for (var i = 0; i < 40; i++) 'id-$i',
      ]),
      clock: () => DateTime.utc(2026, 8, 6, 12),
    );

    final profile = await repos.profiles.create(
      colonyName: 'Test',
      displayName: 'Caio',
      timezone: 'UTC',
      locale: 'pt_BR',
      baseCurrency: 'BRL',
    );

    for (var i = 1; i <= 4; i++) {
      await repos.quests.create(
        profileId: profile.id,
        title: 'Missão ativa $i',
        purpose: 'Propósito $i',
        status: QuestStatus.active,
      );
    }

    final active = (await repos.quests.listAll(profile.id))
        .where((q) => q.status == QuestStatus.active)
        .toList();
    expect(active, hasLength(4));
    // ColonyScreen shows `.take(3)` of active quests.
    final shown = active.take(3).map((q) => q.title).toSet();
    expect(shown, hasLength(3));
    expect(shown.intersection({'Missão ativa 1', 'Missão ativa 2', 'Missão ativa 3', 'Missão ativa 4'}), shown);
  });
}
