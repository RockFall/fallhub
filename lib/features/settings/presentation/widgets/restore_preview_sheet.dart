import 'package:colony_design_system/colony_design_system.dart';
import 'package:colony_domain/colony_domain.dart';
import 'package:flutter/material.dart';

import '../../../../app/localization/app_strings.dart';

class RestorePreviewSheet extends StatelessWidget {
  const RestorePreviewSheet({
    super.key,
    required this.snapshot,
    required this.onConfirm,
  });

  final ExportSnapshot snapshot;
  final VoidCallback onConfirm;

  static Future<bool?> show(
    BuildContext context, {
    required ExportSnapshot snapshot,
  }) {
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (context) => RestorePreviewSheet(
        snapshot: snapshot,
        onConfirm: () => Navigator.pop(context, true),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final exportedLabel = snapshot.exportedAt.toLocal().toString().substring(0, 16);
    final counts = snapshot.entityCounts.entries
        .where((e) => e.value > 0)
        .toList()
      ..sort((a, b) => a.key.compareTo(b.key));

    return Padding(
      padding: const EdgeInsets.all(ColonySpacing.lg),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            AppStrings.restorePreviewTitle,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: ColonySpacing.md),
          Text('${AppStrings.restoreVersionLabel}: v${snapshot.version}'),
          Text(
            '${AppStrings.restoreExportedAt}: $exportedLabel',
          ),
          const SizedBox(height: ColonySpacing.md),
          Text(
            AppStrings.restoreEntityCounts,
            style: Theme.of(context).textTheme.titleSmall,
          ),
          const SizedBox(height: ColonySpacing.sm),
          if (counts.isEmpty)
            Text(
              AppStrings.emptyTimeline,
              style: Theme.of(context).textTheme.bodyMedium,
            )
          else
            ...counts.map(
              (entry) => Text(AppStrings.restoreCountLabel(entry.key, entry.value)),
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

Future<bool> confirmRestoreReplace(BuildContext context) async {
  final first = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text(AppStrings.restoreConfirmTitle),
      content: const Text(AppStrings.restoreConfirmBody),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text(AppStrings.restoreCancel),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, true),
          child: const Text(AppStrings.restoreConfirmAction),
        ),
      ],
    ),
  );
  if (first != true || !context.mounted) return false;

  final second = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text(AppStrings.restoreConfirmTitle),
      content: const Text(AppStrings.restoreConfirmBody),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text(AppStrings.restoreCancel),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, true),
          child: const Text(AppStrings.restoreConfirmAction),
        ),
      ],
    ),
  );
  return second == true;
}
