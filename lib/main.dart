import 'package:colony_database/colony_database.dart';
import 'package:colony_design_system/colony_design_system.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app/bootstrap/colony_app.dart';
import 'app/localization/app_locale.dart';
import 'app/localization/app_strings.dart';
import 'core/providers/app_providers.dart';
import 'features/integrations/application/calendar_ics_feed_store.dart';
import 'features/integrations/application/integrations_providers.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AppLocale.ensureInitialized();

  if (kIsWeb) {
    runApp(const _WebUnsupportedApp());
    return;
  }

  try {
    final database = await ColonyDatabase.open();
    runApp(
      ProviderScope(
        overrides: [
          databaseProvider.overrideWithValue(database),
          calendarIcsFeedStoreProvider.overrideWithValue(
            PrefsCalendarIcsFeedStore(),
          ),
        ],
        child: const ColonyApp(),
      ),
    );
  } catch (error) {
    runApp(_DatabaseOpenFailedApp(error: error));
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
