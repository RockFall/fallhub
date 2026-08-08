import 'package:colony_design_system/colony_design_system.dart';

import 'package:colony_domain/colony_domain.dart';

import 'package:file_picker/file_picker.dart';

import 'package:flutter/material.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';



import '../../../app/localization/app_strings.dart';

import '../../../core/providers/app_providers.dart';

import '../../../core/providers/feature_controllers.dart';

import 'widgets/restore_preview_sheet.dart';



class SettingsScreen extends ConsumerWidget {

  const SettingsScreen({super.key});



  @override

  Widget build(BuildContext context, WidgetRef ref) {

    final prefs = ref.watch(preferencesProvider);

    final profile = ref.watch(profileProvider);



    ref.listen(restoreControllerProvider, (previous, next) {

      if (next.hasError && !next.isLoading && context.mounted) {

        ScaffoldMessenger.of(context).showSnackBar(

          SnackBar(content: Text(AppStrings.restoreInvalidFile)),

        );

      }

    });



    return Padding(

      padding: const EdgeInsets.all(ColonySpacing.lg),

      child: ListView(

        children: [

          Text(AppStrings.settings,

              style: Theme.of(context).textTheme.headlineMedium),

          const SizedBox(height: ColonySpacing.lg),

          profile.when(

            data: (p) => ColonyPanel(

              title: 'Perfil',

              child: p == null

                  ? const SizedBox.shrink()

                  : Text('${p.displayName} · ${p.colonyName}'),

            ),

            loading: () => const LinearProgressIndicator(),

            error: (_, __) => Text(AppStrings.errorGeneric),

          ),

          const SizedBox(height: ColonySpacing.lg),

          prefs.when(

            data: (p) => ColonyPanel(

              title: 'Preferências',

              child: Text(

                'Densidade: ${p.densityMode.name} · Tema: ${p.themeMode.name}',

              ),

            ),

            loading: () => const SizedBox.shrink(),

            error: (_, __) => const SizedBox.shrink(),

          ),

          const SizedBox(height: ColonySpacing.lg),

          OutlinedButton.icon(
            onPressed: () => context.go('/settings/sync'),
            icon: const Icon(Icons.sync_outlined),
            label: const Text(AppStrings.syncTitle),
          ),

          const SizedBox(height: ColonySpacing.md),

          OutlinedButton.icon(
            onPressed: () => context.go('/settings/integrations'),
            icon: const Icon(Icons.extension_outlined),
            label: const Text(AppStrings.integrationsTitle),
          ),

          const SizedBox(height: ColonySpacing.md),

          FilledButton.icon(

            onPressed: () async {

              try {

                final json =

                    await ref.read(exportControllerProvider.notifier).exportJson();

                await SharePlus.instance.share(

                  ShareParams(text: json, subject: 'colony-export.json'),

                );

              } catch (_) {

                if (context.mounted) {

                  ScaffoldMessenger.of(context).showSnackBar(

                    SnackBar(content: Text(AppStrings.errorGeneric)),

                  );

                }

              }

            },

            icon: const Icon(Icons.upload_file),

            label: const Text(AppStrings.exportData),

          ),

          const SizedBox(height: ColonySpacing.md),

          OutlinedButton.icon(

            onPressed: () => _pickAndRestore(context, ref),

            icon: const Icon(Icons.download),

            label: const Text(AppStrings.restoreData),

          ),

        ],

      ),

    );

  }



  Future<void> _pickAndRestore(BuildContext context, WidgetRef ref) async {

    final result = await FilePicker.platform.pickFiles(

      type: FileType.custom,

      allowedExtensions: ['json'],

      withData: true,

    );

    if (result == null || result.files.isEmpty) return;



    final bytes = result.files.single.bytes;

    if (bytes == null) {

      if (context.mounted) {

        ScaffoldMessenger.of(context).showSnackBar(

          SnackBar(content: Text(AppStrings.restoreInvalidFile)),

        );

      }

      return;

    }



    final jsonString = String.fromCharCodes(bytes);

    final restoreController = ref.read(restoreControllerProvider.notifier);

    ExportSnapshot snapshot;

    try {

      snapshot = restoreController.parseExport(jsonString);

    } on ExportSnapshotException {

      if (context.mounted) {

        ScaffoldMessenger.of(context).showSnackBar(

          SnackBar(content: Text(AppStrings.restoreInvalidFile)),

        );

      }

      return;

    }



    if (!context.mounted) return;

    final previewConfirmed = await RestorePreviewSheet.show(

      context,

      snapshot: snapshot,

    );

    if (previewConfirmed != true || !context.mounted) return;



    final confirmed = await confirmRestoreReplace(context);

    if (!confirmed || !context.mounted) return;



    try {

      await restoreController.restore(snapshot);

      if (context.mounted) {

        ScaffoldMessenger.of(context).showSnackBar(

          SnackBar(content: Text(AppStrings.restoreSuccess)),

        );

      }

    } catch (_) {

      if (context.mounted) {

        ScaffoldMessenger.of(context).showSnackBar(

          SnackBar(content: Text(AppStrings.restoreInvalidFile)),

        );

      }

    }

  }

}


