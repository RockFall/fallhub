import 'package:colony_design_system/colony_design_system.dart';
import 'package:colony_domain/colony_domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/localization/app_strings.dart';
import '../../../projects/application/project_providers.dart';
import '../../application/quest_controllers.dart';
import '../../../projects/presentation/widgets/project_picker_sheet.dart';

class QuestLinkedProjectsSection extends ConsumerWidget {
  const QuestLinkedProjectsSection({super.key, required this.quest});

  final Quest quest;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final linkedProjects = ref.watch(questLinkedProjectsProvider(quest.id.value));

    return Padding(
      padding: const EdgeInsets.only(top: ColonySpacing.md),
      child: ColonyPanel(
        title: AppStrings.questLinkedProjects,
        icon: Icons.folder_outlined,
        actions: [
          if (!quest.status.isTerminal)
            IconButton(
              tooltip: AppStrings.questLinkProject,
              icon: const Icon(Icons.link, size: 20),
              onPressed: () async {
                final current = linkedProjects.maybeWhen(
                  data: (projects) => projects,
                  orElse: () => const <Project>[],
                );
                final selected = await ProjectPickerSheet.show(
                  context,
                  selectedProjectIds: current.map((p) => p.id).toList(),
                );
                if (selected == null) return;
                await ref
                    .read(questControllerProvider.notifier)
                    .setLinkedProjects(quest, selected);
              },
            ),
        ],
        child: linkedProjects.when(
          loading: () => Text(AppStrings.loading),
          error: (_, __) => Text(AppStrings.errorGeneric),
          data: (projects) {
            if (projects.isEmpty) {
              return Text(
                AppStrings.questNoLinkedProjects,
                style: Theme.of(context).textTheme.bodyMedium,
              );
            }
            return Column(
              children: projects
                  .map(
                    (project) => ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(project.title),
                      subtitle: project.purpose == null
                          ? null
                          : Text(project.purpose!, maxLines: 2),
                      trailing: quest.status.isTerminal
                          ? null
                          : IconButton(
                              tooltip: AppStrings.questUnlinkProject,
                              icon: const Icon(Icons.link_off, size: 20),
                              onPressed: () => ref
                                  .read(questControllerProvider.notifier)
                                  .unlinkProject(quest, project.id),
                            ),
                      onTap: () => context.go('/projects/${project.id.value}'),
                    ),
                  )
                  .toList(),
            );
          },
        ),
      ),
    );
  }
}
