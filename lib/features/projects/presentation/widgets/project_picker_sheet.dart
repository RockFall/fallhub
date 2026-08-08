import 'package:colony_design_system/colony_design_system.dart';
import 'package:colony_domain/colony_domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/localization/app_strings.dart';
import '../../application/project_providers.dart';

class ProjectPickerSheet extends ConsumerStatefulWidget {
  const ProjectPickerSheet({
    super.key,
    required this.selectedProjectIds,
  });

  final List<EntityId> selectedProjectIds;

  static Future<List<EntityId>?> show(
    BuildContext context, {
    required List<EntityId> selectedProjectIds,
  }) {
    return showModalBottomSheet<List<EntityId>>(
      context: context,
      isScrollControlled: true,
      builder: (_) => ProjectPickerSheet(selectedProjectIds: selectedProjectIds),
    );
  }

  @override
  ConsumerState<ProjectPickerSheet> createState() => _ProjectPickerSheetState();
}

class _ProjectPickerSheetState extends ConsumerState<ProjectPickerSheet> {
  late Set<EntityId> _selected;

  @override
  void initState() {
    super.initState();
    _selected = widget.selectedProjectIds.toSet();
  }

  @override
  Widget build(BuildContext context) {
    final projectsAsync = ref.watch(projectsProvider);
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;

    return Padding(
      padding: EdgeInsets.fromLTRB(
        ColonySpacing.lg,
        ColonySpacing.lg,
        ColonySpacing.lg,
        ColonySpacing.lg + bottomInset,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            AppStrings.questLinkProject,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: ColonySpacing.md),
          Flexible(
            child: projectsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (_, __) => Text(AppStrings.errorGeneric),
              data: (projects) {
                final active = projects
                    .where((p) => p.status == ProjectStatus.active)
                    .toList();
                if (active.isEmpty) {
                  return Text(
                    AppStrings.projectPickerEmpty,
                    style: Theme.of(context).textTheme.bodyMedium,
                  );
                }
                return ListView(
                  shrinkWrap: true,
                  children: active
                      .map(
                        (project) => CheckboxListTile(
                          value: _selected.contains(project.id),
                          onChanged: (checked) {
                            setState(() {
                              if (checked == true) {
                                _selected.add(project.id);
                              } else {
                                _selected.remove(project.id);
                              }
                            });
                          },
                          title: Text(project.title),
                          subtitle: project.purpose == null
                              ? null
                              : Text(project.purpose!, maxLines: 2),
                        ),
                      )
                      .toList(),
                );
              },
            ),
          ),
          const SizedBox(height: ColonySpacing.md),
          FilledButton(
            onPressed: () => Navigator.pop(context, _selected.toList()),
            child: const Text(AppStrings.save),
          ),
        ],
      ),
    );
  }
}
