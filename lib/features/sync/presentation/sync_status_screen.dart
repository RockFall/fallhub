import 'package:colony_design_system/colony_design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/localization/app_strings.dart';
import '../application/sync_controllers.dart';
import '../application/sync_providers.dart';

class SyncStatusScreen extends ConsumerWidget {
  const SyncStatusScreen({super.key});

  Future<void> _processLocal(BuildContext context, WidgetRef ref) async {
    final count =
        await ref.read(syncControllerProvider.notifier).processLocalNoop();
    if (!context.mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    final ctrl = ref.read(syncControllerProvider);
    if (ctrl.hasError) {
      messenger.showSnackBar(
        const SnackBar(content: Text(AppStrings.syncProcessLocalError)),
      );
      return;
    }
    messenger.showSnackBar(
      SnackBar(
        content: Text(
          count == 0
              ? AppStrings.syncProcessLocalEmpty
              : AppStrings.syncProcessLocalDone(count),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final deviceAsync = ref.watch(syncDeviceProvider);
    final pendingAsync = ref.watch(syncPendingProvider);
    final processing = ref.watch(syncControllerProvider).isLoading;

    return Semantics(
      container: true,
      identifier: 'sync.screen',
      label: AppStrings.syncTitle,
      child: Padding(
        padding: const EdgeInsets.all(ColonySpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              AppStrings.syncTitle,
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: ColonySpacing.sm),
            Semantics(
              label: AppStrings.syncDisclaimer,
              child: Text(
                AppStrings.syncDisclaimer,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
            const SizedBox(height: ColonySpacing.lg),
            deviceAsync.when(
              loading: () => const LinearProgressIndicator(),
              error: (_, __) => Text(AppStrings.errorGeneric),
              data: (device) => ColonyPanel(
                title: AppStrings.syncDevice,
                child: Text('${device.label} · ${device.id.value}'),
              ),
            ),
            const SizedBox(height: ColonySpacing.md),
            Expanded(
              child: pendingAsync.when(
                loading: () =>
                    const Center(child: CircularProgressIndicator()),
                error: (_, __) =>
                    Center(child: Text(AppStrings.errorGeneric)),
                data: (pending) {
                  if (pending.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(AppStrings.syncEmpty),
                          const SizedBox(height: ColonySpacing.sm),
                          Text(
                            AppStrings.syncEmptyHint,
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ],
                      ),
                    );
                  }
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Chip(
                          avatar: Icon(
                            Icons.cloud_upload_outlined,
                            size: 18,
                            color: Theme.of(context).colorScheme.onSecondaryContainer,
                          ),
                          label: Text(
                            AppStrings.syncPendingLabel(pending.length),
                          ),
                          visualDensity: VisualDensity.compact,
                        ),
                      ),
                      const SizedBox(height: ColonySpacing.sm),
                      Expanded(
                        child: ListView.builder(
                          itemCount: pending.length,
                          itemBuilder: (context, index) {
                            final op = pending[index];
                            return Card(
                              margin: const EdgeInsets.only(
                                bottom: ColonySpacing.sm,
                              ),
                              child: ListTile(
                                title: Text(
                                  AppStrings.syncEntityTypeLabel(
                                    op.entityType,
                                  ),
                                ),
                                subtitle: Text(
                                  '${op.operation.name} · ${op.status.name} · ${op.entityId.value}',
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
            const SizedBox(height: ColonySpacing.md),
            Semantics(
              button: true,
              identifier: 'sync.process_local',
              label: AppStrings.syncProcessLocal,
              child: FilledButton.icon(
                onPressed: processing
                    ? null
                    : () => _processLocal(context, ref),
                icon: processing
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.sync),
                label: Text(AppStrings.syncProcessLocal),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
