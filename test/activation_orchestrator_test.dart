import 'package:colony_database/colony_database.dart';
import 'package:colony_domain/colony_domain.dart';
import 'package:fallhub/features/activation/application/activation_orchestrator.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late ColonyDatabase db;
  late ColonyRepositories repos;
  late ActivationOrchestrator orchestrator;
  var now = DateTime.utc(2026, 8, 23, 7);

  setUp(() {
    now = DateTime.utc(2026, 8, 23, 7);
    db = ColonyDatabase.inMemory();
    final ids = FixedIdGenerator([
      for (var i = 1; i <= 500; i++) 'orch-$i',
    ]);
    repos = ColonyRepositories.create(
      db,
      idGenerator: ids,
      clock: () => now,
    );
    orchestrator = ActivationOrchestrator(
      repository: repos.activation,
      ids: ids,
      clock: () => now,
    );
  });

  tearDown(() async {
    await db.close();
  });

  test('morning launch confirms feet and releases on first meaningful action',
      () async {
    final profile = await repos.profiles.create(
      colonyName: 'Colônia',
      displayName: 'Caio',
      timezone: 'UTC',
      locale: 'pt_BR',
      baseCurrency: 'BRL',
    );
    await orchestrator.ensureSeeded(profile.id);
    final bundle = (await orchestrator.pickProtocol(
      profileId: profile.id,
      capacity: ActivationCapacityMode.standard,
      preferredType: ActivationProtocolType.wakeUp,
    ))!;
    expect(bundle.commands.first.instruction, 'Coloque os dois pés no chão.');

    final episode = await orchestrator.start(
      profileId: profile.id,
      bundle: bundle,
    );
    var snapshot = await orchestrator.loadSnapshot(episode.id);
    expect(
      snapshot.current!.instructionRendered,
      'Coloque os dois pés no chão.',
    );

    snapshot = await orchestrator.confirmCurrent(episodeId: episode.id);
    expect(snapshot.episode.status, ActivationEpisodeStatus.mobilizing);
    expect(snapshot.current, isNotNull);

    while (snapshot.current != null &&
        snapshot.episode.status.isOpen &&
        !snapshot.current!.isFirstMeaningfulAction) {
      snapshot = await orchestrator.confirmCurrent(episodeId: episode.id);
    }
    if (snapshot.current != null && snapshot.episode.status.isOpen) {
      snapshot = await orchestrator.confirmCurrent(episodeId: episode.id);
    }
    expect(snapshot.episode.status, ActivationEpisodeStatus.released);
    expect(snapshot.episode.releasedAt, isNotNull);

    final events = await repos.events.listTimeline(limit: 40);
    expect(
      events.any((e) => e.eventType == EventType.activationEpisodeStarted),
      isTrue,
    );
    expect(
      events.any((e) => e.eventType == EventType.activationEpisodeReleased),
      isTrue,
    );
  });
}
