import 'dart:typed_data';

import 'package:colony_database/colony_database.dart';
import 'package:colony_design_system/colony_design_system.dart';
import 'package:colony_domain/colony_domain.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app/bootstrap/colony_app.dart';
import 'app/localization/app_locale.dart';
import 'app/localization/app_strings.dart';
import 'core/providers/app_providers.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AppLocale.ensureInitialized();

  if (kIsWeb) {
    runApp(const _WebUnsupportedApp());
    return;
  }

  try {
    final database = await ColonyDatabase.open();
    runApp(ColonyRoot(database: database));
  } catch (error) {
    runApp(_DatabaseOpenFailedApp(error: error));
  }
}

/// Owns the live [ColonyDatabase] so a SQLite restore can swap the file and
/// rebuild [ProviderScope] without killing the process (ADR-051).
class ColonyRoot extends StatefulWidget {
  const ColonyRoot({super.key, required this.database});

  final ColonyDatabase database;

  @override
  State<ColonyRoot> createState() => _ColonyRootState();
}

class _ColonyRootState extends State<ColonyRoot> {
  late ColonyDatabase _database;
  var _generation = 0;

  @override
  void initState() {
    super.initState();
    _database = widget.database;
  }

  Future<Uint8List> _export() => SqliteBackupStore.export(_database);

  Future<void> _restore(Uint8List bytes) async {
    try {
      final next = await SqliteBackupStore.restoreReplacing(
        current: _database,
        bytes: bytes,
        appSchemaVersion: ColonyDatabase.currentSchemaVersion,
      );
      _adopt(next);
    } on ColonySqliteBackupTooNewException {
      rethrow;
    } on ColonySqliteBackupException {
      rethrow;
    } on ColonySqliteRestoreFailedException catch (error) {
      _adopt(error.recovered);
      throw ColonySqliteBackupException(error.toString());
    }
  }

  void _adopt(ColonyDatabase next) {
    if (!mounted || identical(_database, next)) return;
    setState(() {
      _database = next;
      _generation++;
    });
  }

  @override
  Widget build(BuildContext context) {
    return ProviderScope(
      key: ValueKey(_generation),
      overrides: [
        databaseProvider.overrideWithValue(_database),
        sqliteBackupPortProvider.overrideWithValue(
          SqliteBackupPort(exportBytes: _export, restoreBytes: _restore),
        ),
      ],
      child: const ColonyApp(),
    );
  }
}

/// Falha ao abrir/migrar o SQLite antes do ProviderScope.
class _DatabaseOpenFailedApp extends StatelessWidget {
  const _DatabaseOpenFailedApp({required this.error});

  final Object error;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppStrings.appName,
      theme: ColonyTheme.dark(),
      home: Scaffold(
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(ColonySpacing.xl),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppStrings.bootErrorTitle,
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: ColonySpacing.lg),
                const Text(AppStrings.bootErrorBody),
                const SizedBox(height: ColonySpacing.md),
                SelectableText('$error'),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Web não suporta SQLite nativo (Drift + dart:ffi). Use Android ou emulador.
class _WebUnsupportedApp extends StatelessWidget {
  const _WebUnsupportedApp();

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppStrings.appName,
      theme: ColonyTheme.dark(),
      home: Scaffold(
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(ColonySpacing.xl),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppStrings.appName,
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: ColonySpacing.lg),
                const Text(
                  'Este app precisa de armazenamento local SQLite e não roda no navegador nesta versão.',
                ),
                const SizedBox(height: ColonySpacing.md),
                const Text('Use um dispositivo ou emulador Android:'),
                const SizedBox(height: ColonySpacing.sm),
                SelectableText(
                  'flutter run -d android',
                  style: Theme.of(
                    context,
                  ).textTheme.bodyLarge?.copyWith(fontFamily: 'monospace'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
