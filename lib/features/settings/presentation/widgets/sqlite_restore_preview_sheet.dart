import 'package:colony_design_system/colony_design_system.dart';
import 'package:colony_domain/colony_domain.dart';
import 'package:flutter/material.dart';

import '../../../../app/localization/app_strings.dart';

class SqliteRestorePreviewSheet extends StatelessWidget {
  const SqliteRestorePreviewSheet({
    super.key,
    required this.backup,
    required this.onConfirm,
  });

  final ColonySqliteBackup backup;
  final VoidCallback onConfirm;

  static Future<bool?> show(
    BuildContext context, {
    required ColonySqliteBackup backup,
  }) {
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (context) => SqliteRestorePreviewSheet(
        backup: backup,
        onConfirm: () => Navigator.pop(context, true),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final exportedLabel = backup.manifest.exportedAt
        .toLocal()
        .toString()
        .substring(0, 16);
    return Padding(
      padding: const EdgeInsets.all(ColonySpacing.lg),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            AppStrings.sqliteBackupPreviewTitle,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: ColonySpacing.md),
          Text(
            '${AppStrings.sqliteBackupSchemaLabel}: '
            '${AppStrings.sqliteBackupSchemaValue(backup.manifest.schemaVersion)}',
          ),
          Text('${AppStrings.restoreExportedAt}: $exportedLabel'),
          Text(
            '${AppStrings.sqliteBackupSizeLabel}: '
            '${AppStrings.sqliteBackupSizeValue(backup.sqlite.length)}',
          ),
          Text(
            '${AppStrings.sqliteBackupSidecarsLabel}: '
            '${AppStrings.sqliteBackupSidecarsValue(backup.sidecars.length)}',
          ),
          const SizedBox(height: ColonySpacing.lg),
          FilledButton(
            onPressed: onConfirm,
            child: const Text(AppStrings.restoreConfirmAction),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text(AppStrings.restoreCancel),
          ),
        ],
      ),
    );
  }
}
