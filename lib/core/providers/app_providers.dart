import 'dart:typed_data';

import 'package:colony_database/colony_database.dart';
import 'package:colony_domain/colony_domain.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';
import 'package:uuid/uuid.dart';

final loggerProvider = Provider<Logger>((ref) {
  final logger = Logger('ColonyApp');
  Logger.root.level = Level.INFO;
  Logger.root.onRecord.listen((record) {
    // Evita conteúdo sensível — apenas metadados.
    // ignore: avoid_print
    print('[${record.level.name}] ${record.loggerName}: ${record.message}');
  });
  return logger;
});

final idGeneratorProvider = Provider<IdGenerator>(
  (ref) => UuidIdGenerator.v7(() => const Uuid().v4()),
);

final clockProvider = Provider<DateTime Function()>(
  (ref) =>
      () => DateTime.now().toUtc(),
);

final databaseProvider = Provider<ColonyDatabase>((ref) {
  throw UnimplementedError('Database must be overridden in bootstrap');
});

/// Live SQLite snapshot export/restore (ADR-051). Overridden at app bootstrap.
class SqliteBackupPort {
  const SqliteBackupPort({
    required this.exportBytes,
    required this.restoreBytes,
  });

  final Future<Uint8List> Function() exportBytes;
  final Future<void> Function(Uint8List bytes) restoreBytes;
}

final sqliteBackupPortProvider = Provider<SqliteBackupPort>((ref) {
  throw UnimplementedError('SqliteBackupPort must be overridden in bootstrap');
});

final repositoriesProvider = Provider<ColonyRepositories>((ref) {
  final db = ref.watch(databaseProvider);
  return ColonyRepositories.create(
    db,
    idGenerator: ref.watch(idGeneratorProvider),
    clock: ref.watch(clockProvider),
  );
});

final profileProvider = FutureProvider<ColonyProfile?>((ref) {
  return ref.watch(repositoriesProvider).profiles.getActive();
});

final preferencesProvider = FutureProvider<AppPreferences>((ref) {
  return ref.watch(repositoriesProvider).preferences.get();
});

final inboxTasksProvider = StreamProvider<List<ColonyTask>>((ref) async* {
  final profile = await ref.watch(profileProvider.future);
  if (profile == null) {
    yield [];
    return;
  }
  yield* ref.watch(repositoriesProvider).tasks.watchInbox(profile.id);
});

final timelineProvider = StreamProvider<List<DomainEvent>>((ref) {
  return ref.watch(repositoriesProvider).events.watchTimeline();
});

final activeTasksProvider = StreamProvider<List<ColonyTask>>((ref) async* {
  final profile = await ref.watch(profileProvider.future);
  if (profile == null) {
    yield [];
    return;
  }
  yield* ref.watch(repositoriesProvider).tasks.watchActive(profile.id);
});
