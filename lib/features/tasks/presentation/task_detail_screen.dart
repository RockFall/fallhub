import 'package:colony_design_system/colony_design_system.dart';
import 'package:colony_domain/colony_domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/localization/app_strings.dart';
import '../../../core/providers/app_providers.dart';
import '../../../core/providers/feature_controllers.dart';
import '../../activation/application/activation_controllers.dart';
import '../../plan_day/application/plan_day_controller.dart';
import '../../plan_day/application/plan_day_providers.dart';
import '../../plan_day/presentation/widgets/plan_day_feedback.dart';
import '../../projects/application/project_providers.dart';
import '../application/task_controller.dart';
import '../application/task_providers.dart';
import 'widgets/task_composer.dart';

class TaskDetailScreen extends ConsumerWidget {
  const TaskDetailScreen({super.key, required this.taskId});

  final String taskId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final taskAsync = ref.watch(taskByIdProvider(taskId));
    return taskAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, __) => Center(child: Text(AppStrings.errorGeneric)),
      data: (task) {
        if (task == null) {
          return Center(child: Text(AppStrings.taskNotFound));
        }
        return _TaskDetailBody(task: task);
      },
    );
  }
}

class _TaskDetailBody extends ConsumerStatefulWidget {
  const _TaskDetailBody({required this.task});

  final ColonyTask task;

  @override
  ConsumerState<_TaskDetailBody> createState() => _TaskDetailBodyState();
}

class _TaskDetailBodyState extends ConsumerState<_TaskDetailBody> {
  late final TextEditingController _title;
  late final TextEditingController _notes;
  late final TextEditingController _estimate;

  @override
  void initState() {
    super.initState();
    _title = TextEditingController(text: widget.task.title);
    _notes = TextEditingController(text: widget.task.description ?? '');
    _estimate = TextEditingController(
      text: widget.task.estimatedMinutes?.toString() ?? '',
    );
  }

  @override
  void didUpdateWidget(covariant _TaskDetailBody oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.task.title != widget.task.title &&
        _title.text != widget.task.title) {
      _title.text = widget.task.title;
    }
    if (oldWidget.task.description != widget.task.description &&
        _notes.text != (widget.task.description ?? '')) {
      _notes.text = widget.task.description ?? '';
    }
    if (oldWidget.task.estimatedMinutes != widget.task.estimatedMinutes) {
      _estimate.text = widget.task.estimatedMinutes?.toString() ?? '';
    }
  }

  @override
  void dispose() {
    _title.dispose();
    _notes.dispose();
    _estimate.dispose();
    super.dispose();
  }

  Future<void> _save(ColonyTask next) async {
    await ref.read(taskActionsControllerProvider.notifier).save(widget.task, next);
  }

  Future<void> _persistTitle() async {
    final trimmed = _title.text.trim();
    if (trimmed.isEmpty || trimmed == widget.task.title) return;
    await _save(
      widget.task.copyWith(
        title: trimmed,
        updatedAt: ref.read(clockProvider)(),
      ),
    );
  }

  Future<void> _persistNotes() async {
    final trimmed = _notes.text.trim();
    final current = widget.task.description ?? '';
    if (trimmed == current) return;
    await _save(
      widget.task.copyWith(
        description: trimmed.isEmpty ? null : trimmed,
        clearDescription: trimmed.isEmpty,
        updatedAt: ref.read(clockProvider)(),
      ),
    );
  }

  Future<void> _pickDate({required bool deadline}) async {
    final current = deadline ? widget.task.dueAt : widget.task.scheduledStart;
    final now = ref.read(clockProvider)().toLocal();
    final initial = current?.toLocal() ?? now;
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(now.year - 2),
      lastDate: DateTime(now.year + 8),
    );
    if (picked == null) return;
    final stored = DateTime(picked.year, picked.month, picked.day).toUtc();
    await _save(
      deadline
          ? widget.task.copyWith(
              dueAt: stored,
              updatedAt: ref.read(clockProvider)(),
            )
          : widget.task.copyWith(
              scheduledStart: stored,
              updatedAt: ref.read(clockProvider)(),
            ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final task = widget.task;
    final text = Theme.of(context).textTheme;
    final onPlan = ref.watch(todayPlanTaskIdsProvider).contains(task.id.value);
    final children =
        ref.watch(taskChildrenProvider(task.id.value)).asData?.value ?? const [];
    final progress = TaskCapabilityPolicy.subtaskProgress(children);
    final projects = ref.watch(projectsProvider).asData?.value ?? const [];
    final project = projects
        .where((item) => item.id == task.projectId)
        .firstOrNull;
    final now = ref.watch(clockProvider)();

    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(ColonySpacing.lg),
            children: [
              Row(
                children: [
                  Checkbox(
                    value: task.status == TaskStatus.done,
                    onChanged: (_) => ref
                        .read(taskBacklogControllerProvider.notifier)
                        .toggleDone(task),
                  ),
                  Expanded(
                    child: TextField(
                      controller: _title,
                      style: text.titleLarge,
                      decoration: const InputDecoration(
                        border: InputBorder.none,
                        isDense: true,
                      ),
                      onSubmitted: (_) => _persistTitle(),
                      onTapOutside: (_) => _persistTitle(),
                    ),
                  ),
                ],
              ),
              Text(
                '${AppStrings.status}: ${AppStrings.taskStatusLabel(task.status)}',
                style: text.bodySmall?.copyWith(color: ColonyColors.textMuted),
              ),
              if (TaskCapabilityPolicy.isOverdue(task, now))
                Padding(
                  padding: const EdgeInsets.only(top: ColonySpacing.sm),
                  child: Text(
                    AppStrings.taskOverdue,
                    style: text.labelLarge?.copyWith(
                      color: ColonyColors.statusRisk,
                    ),
                  ),
                ),
              const SizedBox(height: ColonySpacing.lg),
              TextField(
                controller: _notes,
                minLines: 2,
                maxLines: 5,
                decoration: const InputDecoration(
                  hintText: AppStrings.taskNotesHint,
                ),
                onSubmitted: (_) => _persistNotes(),
                onTapOutside: (_) => _persistNotes(),
              ),
              const SizedBox(height: ColonySpacing.lg),
              Text(AppStrings.taskPriority, style: text.labelLarge),
              const SizedBox(height: ColonySpacing.sm),
              Wrap(
                spacing: ColonySpacing.sm,
                children: [
                  for (final priority in TaskPriority.values)
                    ChoiceChip(
                      label: Text(AppStrings.taskPriorityLabel(priority)),
                      selected: task.priority == priority,
                      onSelected: (_) => _save(
                        task.copyWith(
                          priority: priority,
                          updatedAt: ref.read(clockProvider)(),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: ColonySpacing.lg),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text(AppStrings.taskProject),
                subtitle: Text(project?.title ?? AppStrings.tasksNoProject),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => _pickProject(projects),
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text(AppStrings.taskDeadline),
                subtitle: Text(
                  task.dueAt == null
                      ? AppStrings.taskPickDate
                      : AppStrings.taskDateLabel(task.dueAt!),
                ),
                trailing: task.dueAt == null
                    ? const Icon(Icons.event_outlined)
                    : IconButton(
                        tooltip: AppStrings.taskClearDeadline,
                        onPressed: () => _save(
                          task.copyWith(
                            clearDueAt: true,
                            updatedAt: ref.read(clockProvider)(),
                          ),
                        ),
                        icon: const Icon(Icons.close),
                      ),
                onTap: () => _pickDate(deadline: true),
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text(AppStrings.taskForDate),
                subtitle: Text(
                  task.scheduledStart == null
                      ? AppStrings.taskPickDate
                      : AppStrings.taskDateLabel(task.scheduledStart!),
                ),
                trailing: task.scheduledStart == null
                    ? const Icon(Icons.today_outlined)
                    : IconButton(
                        tooltip: AppStrings.taskClearForDate,
                        onPressed: () => _save(
                          task.copyWith(
                            clearScheduledStart: true,
                            updatedAt: ref.read(clockProvider)(),
                          ),
                        ),
                        icon: const Icon(Icons.close),
                      ),
                onTap: () => _pickDate(deadline: false),
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text(AppStrings.taskEstimate),
                subtitle: TextField(
                  controller: _estimate,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    isDense: true,
                    border: InputBorder.none,
                  ),
                  onSubmitted: (value) {
                    final parsed = int.tryParse(value.trim());
                    _save(
                      task.copyWith(
                        estimatedMinutes: parsed,
                        clearEstimatedMinutes: parsed == null,
                        updatedAt: ref.read(clockProvider)(),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: ColonySpacing.sm),
              Text(AppStrings.taskEnergy, style: text.labelLarge),
              Wrap(
                spacing: ColonySpacing.sm,
                children: [
                  for (final energy in EnergyRequirement.values)
                    ChoiceChip(
                      label: Text(AppStrings.taskEnergyLabel(energy)),
                      selected: task.energyRequirement == energy,
                      onSelected: (_) => _save(
                        task.copyWith(
                          energyRequirement: energy,
                          updatedAt: ref.read(clockProvider)(),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: ColonySpacing.xl),
              Row(
                children: [
                  Text(AppStrings.taskSubtasks, style: text.titleMedium),
                  if (progress.$2 > 0) ...[
                    const SizedBox(width: ColonySpacing.sm),
                    Text(
                      AppStrings.taskSubtaskProgress(progress.$1, progress.$2),
                      style: text.labelLarge?.copyWith(
                        color: ColonyColors.textMuted,
                      ),
                    ),
                  ],
                ],
              ),
              if (TaskCapabilityPolicy.canHaveChildren(task)) ...[
                for (final child in children)
                  CheckboxListTile(
                    contentPadding: EdgeInsets.zero,
                    value: child.status == TaskStatus.done,
                    onChanged: (_) => ref
                        .read(taskBacklogControllerProvider.notifier)
                        .toggleDone(child),
                    title: Text(
                      child.title,
                      style: text.bodyMedium?.copyWith(
                        decoration: child.status == TaskStatus.done
                            ? TextDecoration.lineThrough
                            : null,
                      ),
                    ),
                    secondary: IconButton(
                      tooltip: AppStrings.tasksOpenTask,
                      onPressed: () => context.go('/tasks/${child.id.value}'),
                      icon: const Icon(Icons.chevron_right),
                    ),
                  ),
                TaskComposer(
                  hint: AppStrings.taskSubtaskHint,
                  onSubmit: (title) async {
                    await ref
                        .read(taskBacklogControllerProvider.notifier)
                        .addSubtask(parent: task, title: title);
                  },
                ),
              ],
              const SizedBox(height: ColonySpacing.xl),
              Wrap(
                spacing: ColonySpacing.sm,
                runSpacing: ColonySpacing.sm,
                children: [
                  FilledButton.tonal(
                    onPressed: task.status.isTerminal && !onPlan
                        ? null
                        : () async {
                            await ref
                                .read(planDayControllerProvider.notifier)
                                .toggleTaskOnToday(task);
                            if (!context.mounted) return;
                            showPlanDayOpenSnack(
                              context,
                              onPlan
                                  ? AppStrings.planDayRemovedSnack
                                  : AppStrings.planDayAddedSnack,
                            );
                          },
                    child: Text(
                      onPlan
                          ? AppStrings.planDayOnPlanChip
                          : AppStrings.planDayAddToToday,
                    ),
                  ),
                  FilledButton.tonal(
                    onPressed: () async {
                      final episode = await ref
                          .read(activationControllerProvider.notifier)
                          .startForTask(taskId: task.id);
                      if (!context.mounted || episode == null) return;
                      context.go('/activation/episodes/${episode.id.value}');
                    },
                    child: const Text(AppStrings.activationMobilizeTask),
                  ),
                  FilledButton(
                    onPressed: () => ref
                        .read(taskActionsControllerProvider.notifier)
                        .updateStatus(task, TaskStatus.next),
                    child: const Text(AppStrings.markNext),
                  ),
                  OutlinedButton(
                    onPressed: () => ref
                        .read(taskActionsControllerProvider.notifier)
                        .archive(task),
                    child: const Text(AppStrings.archive),
                  ),
                  OutlinedButton(
                    onPressed: () => context.go('/tasks'),
                    child: const Text(AppStrings.taskBackToList),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _pickProject(List<Project> projects) async {
    final active = [
      for (final project in projects)
        if (project.status == ProjectStatus.active) project,
    ];
    final selected = await showModalBottomSheet<_ProjectPick>(
      context: context,
      builder: (context) {
        return SafeArea(
          child: ListView(
            shrinkWrap: true,
            children: [
              ListTile(
                title: const Text(AppStrings.taskClearProject),
                onTap: () => Navigator.pop(context, const _ProjectPick(null)),
              ),
              for (final project in active)
                ListTile(
                  title: Text(project.title),
                  selected: project.id == widget.task.projectId,
                  onTap: () =>
                      Navigator.pop(context, _ProjectPick(project.id)),
                ),
            ],
          ),
        );
      },
    );
    if (!mounted || selected == null) return;
    await _save(
      widget.task.copyWith(
        projectId: selected.id,
        clearProjectId: selected.id == null,
        updatedAt: ref.read(clockProvider)(),
      ),
    );
  }
}

class _ProjectPick {
  const _ProjectPick(this.id);
  final EntityId? id;
}
