import 'package:colony_design_system/colony_design_system.dart';
import 'package:colony_domain/colony_domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/localization/app_strings.dart';
import '../../core/providers/app_providers.dart';
import '../../features/integrations/application/integrations_controllers.dart';
import '../routing/app_router.dart';

class ColonyApp extends ConsumerWidget {
  const ColonyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(notificationIngestRuntimeProvider);
    final router = ref.watch(routerProvider);
    final prefs = ref.watch(preferencesProvider);

    final themeMode = prefs.maybeWhen(
      data: (p) => switch (p.themeMode) {
        ThemeModePreference.dark => ThemeMode.dark,
        ThemeModePreference.light => ThemeMode.light,
        ThemeModePreference.system => ThemeMode.system,
      },
      orElse: () => ThemeMode.dark,
    );

    return MaterialApp.router(
      title: AppStrings.appName,
      theme: ColonyTheme.dark(),
      darkTheme: ColonyTheme.dark(),
      // RimWorld chrome is dark-only; light preference still uses dark tokens.
      themeMode: themeMode == ThemeMode.light ? ThemeMode.dark : themeMode,
      routerConfig: router,
    );
  }
}
