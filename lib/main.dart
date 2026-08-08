import 'package:colony_database/colony_database.dart';
import 'package:colony_design_system/colony_design_system.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app/bootstrap/colony_app.dart';
import 'app/localization/app_strings.dart';
import 'core/providers/app_providers.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (kIsWeb) {
    runApp(const _WebUnsupportedApp());
    return;
  }

  final database = await ColonyDatabase.open();

  runApp(
    ProviderScope(
      overrides: [
        databaseProvider.overrideWithValue(database),
      ],
      child: const ColonyApp(),
    ),
  );
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
                const Text(
                  'Use um dispositivo ou emulador Android:',
                ),
                const SizedBox(height: ColonySpacing.sm),
                SelectableText(
                  'flutter run -d android',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        fontFamily: 'monospace',
                      ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
