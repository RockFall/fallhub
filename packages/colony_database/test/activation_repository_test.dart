import 'package:colony_database/colony_database.dart';
import 'package:colony_domain/colony_domain.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late ColonyDatabase db;
  late ColonyRepositories repos;
  var now = DateTime.utc(2026, 8, 23, 12);

  setUp(() {
    now = DateTime.utc(2026, 8, 23, 12);
    db = ColonyDatabase.inMemory();
    repos = ColonyRepositories.create(
      db,
      idGenerator: FixedIdGenerator([
        for (var i = 1; i <= 400; i++) 'id-$i',
      ]),
      clock: () => now,
    );
  });

  tearDown(() async {
    await db.close();
  });

  Future<ColonyProfile> profile() {
    return repos.profiles.create(
      colonyName: 'Colônia',
      displayName: 'Caio',
      timezone: 'UTC',
      locale: 'pt_BR',
      baseCurrency: 'BRL',
    );
  }

  test('seeds morning launch and runs one command at a time', () async {
    final created = await profile();
    final seeded = await repos.activation.seedDefaults(created.id);
    expect(seeded, greaterThan(0));

    final protocols = await repos.activation.listProtocols(created.id);
    final morning = protocols.firstWhere(
      (p) => p.seedKey == 'morning_launch_standard',
    );
    final bundle = (await repos.activation.getBundle(morning.id))!;
    expect(bundle.commands.first.instruction, 'Coloque os dois pés no chão.');

    final episode = await repos.activation.startEpisode(
      profileId: created.id,
      bundle: bundle,
      capacity: ActivationCapacityMode.standard,
      compiled: bundle.orderedCommands,
    );
    expect(episode.status, ActivationEpisodeStatus.mobilizing);
    final current = await repos.activation.getCurrentRun(episode.id);
    expect(current, isNotNull);
    expect(current!.instructionRendered, 'Coloque os dois pés no chão.');
    expect(current.status, ActivationCommandRunStatus.presented);
    final runs = await repos.activation.listRuns(episode.id);
    expect(runs.length, greaterThan(1));
    expect(runs.skip(1).every((r) => r.status == ActivationCommandRunStatus.pending), isTrue);
  });

  test('export redacts waypoint tokens and raw proof refs', () async {
    final created = await profile();
    await repos.activation.seedDefaults(created.id);
    await repos.activation.upsertWaypoint(
      ActivationWaypoint(
        id: const EntityId('wp-1'),
        profileId: created.id,
        name: 'Banheiro',
        waypointType: ActivationWaypointType.qr,
        token: 'secret-token',
        createdAt: now,
        updatedAt: now,
      ),
    );
    final exported = await repos.activation.exportBundle(created.id);
    expect(exported.waypoints, isNotEmpty);
    expect(exported.waypoints.every((w) => w.token == null), isTrue);
    expect(exported.proofs.every((p) => p.rawReference == null), isTrue);
  });

  test('expires raw inertia signals', () async {
    final created = await profile();
    await repos.activation.addSignal(
      InertiaSignal(
        id: const EntityId('sig-expire'),
        signalType: InertiaSignalType.stepDelta,
        observedAt: now.subtract(const Duration(hours: 2)),
        source: 'test',
        confidence: 0.4,
        expiresAt: now.subtract(const Duration(minutes: 1)),
        privacyClass: PrivacyClass.sensitive,
      ),
    );
    final expired = await repos.activation.expireSignals(now);
    expect(expired, 1);
    expect(created.id.value, isNotEmpty);
  });
}
