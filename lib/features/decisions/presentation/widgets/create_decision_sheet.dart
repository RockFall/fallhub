import 'package:colony_design_system/colony_design_system.dart';
import 'package:colony_domain/colony_domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/localization/app_strings.dart';
import '../../application/decision_controllers.dart';
import '../../../quests/presentation/widgets/quest_string_list_field.dart';

class CreateDecisionSheet extends ConsumerStatefulWidget {
  const CreateDecisionSheet({super.key, this.questId});

  final String? questId;

  static Future<void> show(BuildContext context, {String? questId}) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (_) => CreateDecisionSheet(questId: questId),
    );
  }

  @override
  ConsumerState<CreateDecisionSheet> createState() => _CreateDecisionSheetState();
}

class _CreateDecisionSheetState extends ConsumerState<CreateDecisionSheet> {
  final _titleController = TextEditingController();
  final _contextController = TextEditingController();
  final _decisionController = TextEditingController();
  final _alternativesKey = GlobalKey<QuestStringListFieldState>();
  final _criteriaKey = GlobalKey<QuestStringListFieldState>();
  final _risksKey = GlobalKey<QuestStringListFieldState>();
  final _assumptionsKey = GlobalKey<QuestStringListFieldState>();
  final _expectedOutcomesKey = GlobalKey<QuestStringListFieldState>();
  DecisionReversibility _reversibility = DecisionReversibility.moderate;
  DateTime? _reviewAt;
  String? _titleError;
  String? _contextError;
  String? _decisionError;

  @override
  void dispose() {
    _titleController.dispose();
    _contextController.dispose();
    _decisionController.dispose();
    super.dispose();
  }

  bool _validate() {
    final title = _titleController.text.trim();
    final context = _contextController.text.trim();
    final decision = _decisionController.text.trim();
    setState(() {
      _titleError = title.isEmpty ? AppStrings.decisionTitleRequired : null;
      _contextError = context.isEmpty ? AppStrings.decisionContextRequired : null;
      _decisionError = decision.isEmpty ? AppStrings.decisionChoiceRequired : null;
    });
    return _titleError == null && _contextError == null && _decisionError == null;
  }

  Future<void> _save() async {
    if (!_validate()) return;

    final record = await ref.read(decisionControllerProvider.notifier).create(
          title: _titleController.text.trim(),
          context: _contextController.text.trim(),
          decision: _decisionController.text.trim(),
          alternatives: _alternativesKey.currentState?.collectValues() ?? const [],
          criteria: _criteriaKey.currentState?.collectValues() ?? const [],
          assumptions: _assumptionsKey.currentState?.collectValues() ?? const [],
          expectedOutcomes:
              _expectedOutcomesKey.currentState?.collectValues() ?? const [],
          risks: _risksKey.currentState?.collectValues() ?? const [],
          reversibility: _reversibility,
          reviewAt: _reviewAt,
          linkToQuestId:
              widget.questId == null ? null : EntityId(widget.questId!),
        );

    if (!mounted || record == null) return;
    Navigator.pop(context);
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
              AppStrings.newDecision,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: ColonySpacing.lg),
            TextField(
              controller: _titleController,
              decoration: InputDecoration(
                labelText: AppStrings.decisionTitle,
                errorText: _titleError,
              ),
              autofocus: true,
            ),
            const SizedBox(height: ColonySpacing.md),
            TextField(
              controller: _contextController,
              decoration: InputDecoration(
                labelText: AppStrings.decisionContext,
                errorText: _contextError,
              ),
              maxLines: 3,
            ),
            const SizedBox(height: ColonySpacing.md),
            TextField(
              controller: _decisionController,
              decoration: InputDecoration(
                labelText: AppStrings.decisionChoice,
                errorText: _decisionError,
              ),
              maxLines: 2,
            ),
            const SizedBox(height: ColonySpacing.md),
            QuestStringListField(
              key: _alternativesKey,
              label: AppStrings.decisionAlternatives,
              addLabel: AppStrings.decisionAddAlternative,
              hint: AppStrings.decisionAlternativeHint,
            ),
            const SizedBox(height: ColonySpacing.md),
            QuestStringListField(
              key: _criteriaKey,
              label: AppStrings.decisionCriteria,
              addLabel: AppStrings.decisionAddCriterion,
              hint: AppStrings.decisionCriterionHint,
            ),
            const SizedBox(height: ColonySpacing.md),
            QuestStringListField(
              key: _risksKey,
              label: AppStrings.decisionRisks,
              addLabel: AppStrings.decisionAddRisk,
              hint: AppStrings.decisionRiskHint,
            ),
            const SizedBox(height: ColonySpacing.md),
            QuestStringListField(
              key: _assumptionsKey,
              label: AppStrings.decisionAssumptions,
              addLabel: AppStrings.decisionAddAssumption,
              hint: AppStrings.decisionAssumptionHint,
            ),
            const SizedBox(height: ColonySpacing.md),
            QuestStringListField(
              key: _expectedOutcomesKey,
              label: AppStrings.decisionExpectedOutcomes,
              addLabel: AppStrings.decisionAddExpectedOutcome,
              hint: AppStrings.decisionExpectedOutcomeHint,
            ),
            const SizedBox(height: ColonySpacing.md),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(AppStrings.decisionReviewAt),
              subtitle: Text(
                _reviewAt == null
                    ? '—'
                    : MaterialLocalizations.of(context).formatMediumDate(
                        _reviewAt!.toLocal(),
                      ),
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (_reviewAt != null)
                    IconButton(
                      tooltip: AppStrings.decisionReviewAtClear,
                      icon: const Icon(Icons.clear),
                      onPressed: () => setState(() => _reviewAt = null),
                    ),
                  IconButton(
                    icon: const Icon(Icons.calendar_today_outlined),
                    onPressed: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: _reviewAt ?? DateTime.now(),
                        firstDate: DateTime(2020),
                        lastDate: DateTime(2100),
                      );
                      if (picked != null) {
                        setState(() => _reviewAt = picked);
                      }
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: ColonySpacing.md),
            DropdownButtonFormField<DecisionReversibility>(
              value: _reversibility,
              decoration: const InputDecoration(
                labelText: AppStrings.decisionReversibility,
              ),
              items: DecisionReversibility.values
                  .map(
                    (value) => DropdownMenuItem(
                      value: value,
                      child: Text(AppStrings.decisionReversibilityLabel(value)),
                    ),
                  )
                  .toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() => _reversibility = value);
                }
              },
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
