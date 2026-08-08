import 'package:colony_design_system/colony_design_system.dart';
import 'package:colony_domain/colony_domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/localization/app_strings.dart';
import '../../application/quest_controllers.dart';

class QuestLinkTaskSheet extends ConsumerStatefulWidget {
  const QuestLinkTaskSheet({
    super.key,
    required this.quest,
    required this.tasks,
  });

  final Quest quest;
  final List<ColonyTask> tasks;

  @override
  ConsumerState<QuestLinkTaskSheet> createState() => _QuestLinkTaskSheetState();
}

class _QuestLinkTaskSheetState extends ConsumerState<QuestLinkTaskSheet> {
  final _titleController = TextEditingController();
  var _creating = false;

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
            AppStrings.questLinkTask,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: ColonySpacing.md),
          if (widget.tasks.isNotEmpty) ...[
            Text(AppStrings.questPickExistingTask),
            const SizedBox(height: ColonySpacing.sm),
            ...widget.tasks.map(
              (task) => ListTile(
                title: Text(task.title),
                subtitle: Text(AppStrings.taskStatusLabel(task.status)),
                onTap: () async {
                  await ref
                      .read(questControllerProvider.notifier)
                      .linkTask(widget.quest, task);
                  if (context.mounted) Navigator.pop(context);
                },
              ),
            ),
            const Divider(),
          ],
          Text(AppStrings.questQuickCreateTask),
          const SizedBox(height: ColonySpacing.sm),
          TextField(
            controller: _titleController,
            decoration: const InputDecoration(
              hintText: AppStrings.captureHint,
            ),
          ),
          const SizedBox(height: ColonySpacing.md),
          FilledButton(
            onPressed: _creating
                ? null
                : () async {
                    final title = _titleController.text.trim();
                    if (title.isEmpty) return;
                    setState(() => _creating = true);
                    await ref
                        .read(questControllerProvider.notifier)
                        .quickCreateTask(widget.quest, title);
                    if (context.mounted) Navigator.pop(context);
                  },
            child: Text(_creating ? AppStrings.loading : AppStrings.save),
          ),
        ],
      ),
    );
  }
}
