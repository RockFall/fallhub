import 'package:colony_design_system/colony_design_system.dart';
import 'package:colony_domain/colony_domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/localization/app_strings.dart';
import '../application/project_controllers.dart';
import '../application/project_providers.dart';
import 'widgets/edit_project_sheet.dart';

class ProjectDetailScreen extends ConsumerWidget {
  const ProjectDetailScreen({super.key, required this.projectId});

  final String projectId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.listen(projectControllerProvider, (previous, next) {
      if (next.hasError && !next.isLoading && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppStrings.errorGeneric)),
        );
      }
    });

    final projectAsync = ref.watch(projectProvider(projectId));
    final linkedQuests = ref.watch(projectLinkedQuestsProvider(projectId));

    return projectAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, __) => Center(child: Text(AppStrings.errorGeneric)),
      data: (project) {
        if (project == null) {
          return Center(child: Text(AppStrings.projectNotFound));
        }

        return ListView(
          padding: const EdgeInsets.all(ColonySpacing.lg),
          children: [
            Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: () => context.go('/projects'),
                ),
                Expanded(
                  child: Text(
                    project.title,
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                ),
                Chip(label: Text(AppStrings.projectStatusLabel(project.status))),
              ],
            ),
            if (project.status != ProjectStatus.archived) ...[
              const SizedBox(height: ColonySpacing.sm),
              Wrap(
                spacing: ColonySpacing.sm,
                runSpacing: ColonySpacing.sm,
                children: [
                  if (project.status == ProjectStatus.active) ...[
                    OutlinedButton.icon(
                      icon: const Icon(Icons.edit_outlined, size: 18),
                      label: const Text(AppStrings.projectEdit),
                      onPressed: () => EditProjectSheet.show(context, project),
                    ),
                    FilledButton.icon(
                      icon: const Icon(Icons.check, size: 18),
                      label: const Text(AppStrings.projectComplete),
                      onPressed: () => _complete(context, ref, project),
                    ),
                  ],
                  if (project.status == ProjectStatus.completed)
                    OutlinedButton.icon(
                      icon: const Icon(Icons.archive_outlined, size: 18),
                      label: const Text(AppStrings.projectArchive),
                      onPressed: () => _archive(context, ref, project),
                    ),
                ],
              ),
            ],
            const SizedBox(height: ColonySpacing.lg),
            if (project.purpose != null && project.purpose!.isNotEmpty)
              ColonyPanel(
                title: AppStrings.projectPurpose,
                icon: Icons.lightbulb_outline,
                child: Text(project.purpose!),
              ),
            const SizedBox(height: ColonySpacing.md),
            ColonyPanel(
              title: AppStrings.projectLinkedQuests,
              icon: Icons.flag_outlined,
              child: linkedQuests.when(
                loading: () => const LinearProgressIndicator(),
                error: (_, __) => Text(AppStrings.errorGeneric),
                data: (quests) {
                  if (quests.isEmpty) {
                    return Text(
                      AppStrings.projectNoLinkedQuests,
                      style: Theme.of(context).textTheme.bodyMedium,
                    );
                  }
                  return Column(
                    children: quests
                        .map(
                          (quest) => ListTile(
                            contentPadding: EdgeInsets.zero,
                            title: Text(quest.title),
                            subtitle: Text(AppStrings.questStatusLabel(quest.status)),
                            onTap: () => context.go('/quests/${quest.id.value}'),
                          ),
                        )
                        .toList(),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _complete(BuildContext context, WidgetRef ref, Project project) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(AppStrings.projectComplete),
        content: const Text(AppStrings.projectCompleteConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text(AppStrings.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(AppStrings.projectComplete),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    await ref.read(projectControllerProvider.notifier).complete(project);
  }

  Future<void> _archive(BuildContext context, WidgetRef ref, Project project) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(AppStrings.projectArchive),
        content: const Text(AppStrings.projectArchiveConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text(AppStrings.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(AppStrings.projectArchive),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    await ref.read(projectControllerProvider.notifier).archive(project);
  }
}
