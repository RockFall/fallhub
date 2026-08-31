import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

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
import 'widgets/sideload_build_panel.dart';
import 'widgets/sqlite_restore_preview_sheet.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  var _backupBusy = false;

  @override
  Widget build(BuildContext context) {
    final prefs = ref.watch(preferencesProvider);
    final profile = ref.watch(profileProvider);

    ref.listen(restoreControllerProvider, (previous, next) {
      if (next.hasError && !next.isLoading && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text(AppStrings.restoreInvalidFile)),
        );
      }
    });

    return Padding(
      padding: const EdgeInsets.all(ColonySpacing.lg),
      child: ListView(
        children: [
          Text(
            AppStrings.settings,
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: ColonySpacing.lg),
          profile.when(
            data: (p) => ColonyPanel(
              title: 'Perfil',
              child: p == null
                  ? const SizedBox.shrink()
                  : Text('${p.displayName} · ${p.colonyName}'),
            ),
            loading: () => const LinearProgressIndicator(),
            error: (_, __) => const Text(AppStrings.errorGeneric),
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
          const SizedBox(height: ColonySpacing.lg),
          ColonyPanel(
            title: AppStrings.sqliteBackupTitle,
            icon: Icons.save_alt_outlined,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  AppStrings.sqliteBackupHint,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: ColonyColors.textMuted,
                  ),
                ),
                const SizedBox(height: ColonySpacing.md),
                FilledButton.icon(
                  onPressed: _backupBusy ? null : () => _exportSqlite(context),
                  icon: const Icon(Icons.sd_storage_outlined),
                  label: const Text(AppStrings.sqliteBackupExport),
                ),
                const SizedBox(height: ColonySpacing.sm),
                OutlinedButton.icon(
                  onPressed: _backupBusy
                      ? null
                      : () => _pickAndRestore(context),
                  icon: const Icon(Icons.download),
                  label: const Text(AppStrings.restoreData),
                ),
                const SizedBox(height: ColonySpacing.md),
                Text(
                  AppStrings.sqliteBackupJsonHint,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: ColonyColors.textMuted,
                  ),
                ),
                const SizedBox(height: ColonySpacing.sm),
                OutlinedButton.icon(
                  onPressed: _backupBusy ? null : () => _exportJson(context),
                  icon: const Icon(Icons.upload_file),
                  label: const Text(AppStrings.exportData),
                ),
              ],
            ),
          ),
          const SizedBox(height: ColonySpacing.lg),
          const SideloadBuildPanel(),
        ],
      ),
    );
  }

  Future<void> _exportJson(BuildContext context) async {
    try {
      final json = await ref
          .read(exportControllerProvider.notifier)
          .exportJson();
      await SharePlus.instance.share(
        ShareParams(text: json, subject: 'colony-export.json'),
      );
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text(AppStrings.errorGeneric)));
      }
    }
  }

  Future<void> _exportSqlite(BuildContext context) async {
    setState(() => _backupBusy = true);
    File? tmp;
    try {
      final bytes = await ref.read(sqliteBackupPortProvider).exportBytes();
      final stamp = DateTime.now().toUtc().millisecondsSinceEpoch;
      tmp = File('${Directory.systemTemp.path}/fallhub-backup-$stamp.colonybk');
      await tmp.writeAsBytes(bytes, flush: true);
      await SharePlus.instance.share(
        ShareParams(
          files: [
            XFile(
              tmp.path,
              mimeType: 'application/octet-stream',
              name: 'fallhub-backup.colonybk',
            ),
          ],
          subject: AppStrings.sqliteBackupShareSubject,
        ),
      );
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text(AppStrings.errorGeneric)));
      }
    } finally {
      if (tmp != null) {
        try {
          await tmp.delete();
        } on FileSystemException {
          // Share may still be reading the temp file.
        }
      }
      if (mounted) setState(() => _backupBusy = false);
    }
  }

  Future<void> _pickAndRestore(BuildContext context) async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.any,
      withData: true,
    );
    if (result == null || result.files.isEmpty) return;

    final bytes = await _bytesFromPicker(result.files.single);
    if (bytes == null || bytes.isEmpty) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text(AppStrings.restoreInvalidFile)),
        );
      }
      return;
    }

    switch (ColonySqliteBackupCodec.sniff(bytes)) {
      case ColonyBackupKind.sqliteContainer || ColonyBackupKind.sqliteRaw:
        await _restoreSqlite(context, bytes);
      case ColonyBackupKind.json:
        await _restoreJson(context, bytes);
      case ColonyBackupKind.unknown:
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text(AppStrings.restoreInvalidFile)),
          );
        }
    }
  }

  Future<void> _restoreJson(BuildContext context, Uint8List bytes) async {
    final restoreController = ref.read(restoreControllerProvider.notifier);
    ExportSnapshot snapshot;
    try {
      snapshot = restoreController.parseExport(utf8.decode(bytes));
    } on ExportSnapshotException {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text(AppStrings.restoreInvalidFile)),
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
          const SnackBar(content: Text(AppStrings.restoreSuccess)),
        );
      }
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text(AppStrings.restoreInvalidFile)),
        );
      }
    }
  }

  Future<void> _restoreSqlite(BuildContext context, Uint8List bytes) async {
    ColonySqliteBackup backup;
    try {
      backup = ColonySqliteBackupCodec.decode(bytes);
      ColonySqliteBackupCodec.assertRestorable(
        backupSchemaVersion: backup.manifest.schemaVersion,
        appSchemaVersion: ref.read(databaseProvider).schemaVersion,
      );
    } on ColonySqliteBackupTooNewException {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text(AppStrings.sqliteBackupTooNew)),
        );
      }
      return;
    } on ColonySqliteBackupException {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text(AppStrings.restoreInvalidFile)),
        );
      }
      return;
    }

    if (!context.mounted) return;
    final previewConfirmed = await SqliteRestorePreviewSheet.show(
      context,
      backup: backup,
    );
    if (previewConfirmed != true || !context.mounted) return;

    final confirmed = await confirmRestoreReplace(context);
    if (!confirmed || !context.mounted) return;

    setState(() => _backupBusy = true);
    try {
      await ref.read(sqliteBackupPortProvider).restoreBytes(bytes);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text(AppStrings.restoreSuccess)),
        );
      }
    } on ColonySqliteBackupTooNewException {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text(AppStrings.sqliteBackupTooNew)),
        );
      }
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text(AppStrings.restoreInvalidFile)),
        );
      }
    } finally {
      if (mounted) setState(() => _backupBusy = false);
    }
  }

  Future<Uint8List?> _bytesFromPicker(PlatformFile file) async {
    if (file.bytes != null && file.bytes!.isNotEmpty) {
      return Uint8List.fromList(file.bytes!);
    }
    final path = file.path;
    if (path == null || path.isEmpty) return null;
    return Uint8List.fromList(await File(path).readAsBytes());
  }
}
