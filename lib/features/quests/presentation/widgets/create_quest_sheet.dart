import 'package:colony_design_system/colony_design_system.dart';
import 'package:colony_domain/colony_domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../app/localization/app_strings.dart';
import '../../application/quest_controllers.dart';
import '../../../projects/presentation/widgets/project_picker_sheet.dart';
import 'accept_quest_sheet.dart';
import 'quest_string_list_field.dart';

class CreateQuestSheet extends ConsumerStatefulWidget {
  const CreateQuestSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (_) => const CreateQuestSheet(),
    );
  }

  @override
  ConsumerState<CreateQuestSheet> createState() => _CreateQuestSheetState();
}

class _CreateQuestSheetState extends ConsumerState<CreateQuestSheet> {
  final _titleController = TextEditingController();
  final _purposeController = TextEditingController();
  final _criteriaKey = GlobalKey<QuestStringListFieldState>();
  final _risksKey = GlobalKey<QuestStringListFieldState>();
  DateTime? _deadline;
  List<EntityId> _selectedProjectIds = const [];
  String? _titleError;
  String? _purposeError;

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

  Future<void> _save({required bool activate}) async {
    if (!_validate()) return;

    final quest = await ref.read(questControllerProvider.notifier).create(
          title: _titleController.text.trim(),
          purpose: _purposeController.text.trim(),
          successCriteria: _criteriaKey.currentState?.collectValues() ?? const [],
          risks: _risksKey.currentState?.collectValues() ?? const [],
          deadline: _deadline,
        );

    if (!mounted || quest == null) return;

    if (activate) {
      final acceptance = await AcceptQuestSheet.show(
        context,
        initialPurpose: _purposeController.text.trim(),
      );
      if (!mounted) return;
      if (acceptance == null) {
        if (_selectedProjectIds.isNotEmpty) {
          await ref.read(questControllerProvider.notifier).setLinkedProjects(
                quest,
                _selectedProjectIds,
              );
        }
        Navigator.pop(context);
        return;
      }
      await ref.read(questControllerProvider.notifier).acceptAndActivate(
            quest,
            acceptanceAssumptions: acceptance.assumptions,
            acceptanceDeadline: acceptance.deadline,
          );
      if (!mounted) return;
    }

    if (_selectedProjectIds.isNotEmpty) {
      await ref.read(questControllerProvider.notifier).setLinkedProjects(
            quest,
            _selectedProjectIds,
          );
    }
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
              AppStrings.newQuest,
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
            ),
            const SizedBox(height: ColonySpacing.md),
            QuestStringListField(
              key: _risksKey,
              label: AppStrings.questRisks,
              addLabel: AppStrings.questAddRisk,
              hint: AppStrings.questRiskHint,
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
              trailing: IconButton(
                icon: const Icon(Icons.calendar_today_outlined),
                onPressed: _pickDeadline,
              ),
            ),
            const SizedBox(height: ColonySpacing.lg),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _save(activate: false),
                    child: const Text(AppStrings.questSaveDraft),
                  ),
                ),
                const SizedBox(width: ColonySpacing.md),
                Expanded(
                  child: FilledButton(
                    onPressed: () => _save(activate: true),
                    child: const Text(AppStrings.questCreateAndActivate),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
