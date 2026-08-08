import 'package:colony_design_system/colony_design_system.dart';
import 'package:colony_domain/colony_domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../app/localization/app_strings.dart';
import '../../../../core/providers/app_providers.dart';
import '../../application/quest_controllers.dart';
import '../../../projects/presentation/widgets/project_picker_sheet.dart';
import 'quest_string_list_field.dart';

class EditQuestSheet extends ConsumerStatefulWidget {
  const EditQuestSheet({super.key, required this.quest});

  final Quest quest;

  static Future<void> show(BuildContext context, Quest quest) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (_) => EditQuestSheet(quest: quest),
    );
  }

  @override
  ConsumerState<EditQuestSheet> createState() => _EditQuestSheetState();
}

class _EditQuestSheetState extends ConsumerState<EditQuestSheet> {
  late final TextEditingController _titleController;
  late final TextEditingController _purposeController;
  final _criteriaKey = GlobalKey<QuestStringListFieldState>();
  final _risksKey = GlobalKey<QuestStringListFieldState>();
  DateTime? _deadline;
  List<EntityId> _selectedProjectIds = const [];
  String? _titleError;
  String? _purposeError;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.quest.title);
    _purposeController = TextEditingController(text: widget.quest.purpose);
    _deadline = widget.quest.deadline != null
        ? scheduleCalendarDay(widget.quest.deadline!)
        : null;
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadLinkedProjects());
  }

  Future<void> _loadLinkedProjects() async {
    final projects = await ref
        .read(repositoriesProvider)
        .projects
        .watchLinkedToQuest(widget.quest.id)
        .first;
    if (!mounted) return;
    setState(() => _selectedProjectIds = projects.map((p) => p.id).toList());
  }

  @override
  void dispose() {
    _titleController.dispose();
    _purposeController.dispose();
    super.dispose();
  }

  bool _validate() {
    final title = _titleController.text.trim();
    final purpose = _purposeController.text.trim();
    setState(() {
      _titleError = title.isEmpty ? AppStrings.questTitleRequired : null;
      _purposeError = purpose.isEmpty ? AppStrings.questPurposeRequired : null;
    });
    return _titleError == null && _purposeError == null;
  }

  Future<void> _save() async {
    if (!_validate()) return;

    final now = ref.read(clockProvider)();
    final updated = widget.quest.copyWith(
      title: _titleController.text.trim(),
      purpose: _purposeController.text.trim(),
      successCriteria: _criteriaKey.currentState?.collectValues() ?? const [],
      risks: _risksKey.currentState?.collectValues() ?? const [],
      deadline: _deadline,
      clearDeadline: _deadline == null,
      updatedAt: now,
      version: widget.quest.version + 1,
    );

    await ref.read(questControllerProvider.notifier).updateFields(updated);
    await ref.read(questControllerProvider.notifier).setLinkedProjects(
          updated,
          _selectedProjectIds,
        );
    if (!mounted) return;
    Navigator.pop(context);
  }

  Future<void> _pickProjects() async {
    final selected = await ProjectPickerSheet.show(
      context,
      selectedProjectIds: _selectedProjectIds,
    );
    if (selected != null) {
      setState(() => _selectedProjectIds = selected);
    }
  }

  Future<void> _pickDeadline() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _deadline ?? scheduleCalendarDay(now.add(const Duration(days: 7))),
      firstDate: scheduleCalendarDay(now),
      lastDate: scheduleCalendarDay(now.add(const Duration(days: 365 * 3))),
    );
    if (picked != null) {
      setState(() => _deadline = scheduleCalendarDay(picked));
    }
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
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              AppStrings.questEdit,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: ColonySpacing.lg),
            TextField(
              controller: _titleController,
              decoration: InputDecoration(
                labelText: AppStrings.questTitle,
                errorText: _titleError,
              ),
              autofocus: true,
            ),
            const SizedBox(height: ColonySpacing.md),
            TextField(
              controller: _purposeController,
              decoration: InputDecoration(
                labelText: AppStrings.questPurpose,
                errorText: _purposeError,
              ),
              maxLines: 3,
            ),
            const SizedBox(height: ColonySpacing.md),
            QuestStringListField(
              key: _criteriaKey,
              label: AppStrings.questSuccessCriteria,
              addLabel: AppStrings.questAddCriterion,
              hint: AppStrings.questCriterionHint,
              initialValues: widget.quest.successCriteria,
            ),
            const SizedBox(height: ColonySpacing.md),
            QuestStringListField(
              key: _risksKey,
              label: AppStrings.questRisks,
              addLabel: AppStrings.questAddRisk,
              hint: AppStrings.questRiskHint,
              initialValues: widget.quest.risks,
            ),
            const SizedBox(height: ColonySpacing.md),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(AppStrings.questLinkedProjects),
              subtitle: Text(
                _selectedProjectIds.isEmpty
                    ? AppStrings.questNoLinkedProjects
                    : AppStrings.questSelectedProjectsCount(_selectedProjectIds.length),
              ),
              trailing: IconButton(
                icon: const Icon(Icons.folder_outlined),
                onPressed: _pickProjects,
              ),
            ),
            const SizedBox(height: ColonySpacing.md),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(AppStrings.questDeadline),
              subtitle: Text(
                _deadline == null
                    ? AppStrings.questNoDeadline
                    : DateFormat('dd/MM/yyyy').format(_deadline!),
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (_deadline != null)
                    IconButton(
                      tooltip: AppStrings.questClearDeadline,
                      icon: const Icon(Icons.clear),
                      onPressed: () => setState(() => _deadline = null),
                    ),
                  IconButton(
                    icon: const Icon(Icons.calendar_today_outlined),
                    onPressed: _pickDeadline,
                  ),
                ],
              ),
            ),
            const SizedBox(height: ColonySpacing.lg),
            FilledButton(
              onPressed: _save,
              child: const Text(AppStrings.save),
            ),
          ],
        ),
      ),
    );
  }
}
