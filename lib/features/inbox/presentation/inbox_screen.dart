import 'package:colony_design_system/colony_design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/localization/app_strings.dart';
import '../../../core/providers/app_providers.dart';

class InboxScreen extends ConsumerWidget {
  const InboxScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final inbox = ref.watch(inboxTasksProvider);

    return Padding(
      padding: const EdgeInsets.all(ColonySpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(AppStrings.inbox, style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: ColonySpacing.lg),
          Expanded(
            child: inbox.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (_, __) => Center(child: Text(AppStrings.errorGeneric)),
              data: (tasks) {
                if (tasks.isEmpty) {
                  return Center(child: Text(AppStrings.emptyInbox));
                }
                return ListView.separated(
                  itemCount: tasks.length,
                  separatorBuilder: (_, __) =>
                      const Divider(color: ColonyColors.borderSubtle),
                  itemBuilder: (context, index) {
                    final task = tasks[index];
                    return ListTile(
                      title: Text(task.title),
                      subtitle: Text(task.createdAt.toLocal().toString()),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => context.go('/tasks/${task.id.value}'),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
