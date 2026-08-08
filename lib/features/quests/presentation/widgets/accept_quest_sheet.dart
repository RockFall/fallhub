import 'package:colony_design_system/colony_design_system.dart';
import 'package:colony_domain/colony_domain.dart';
import 'package:flutter/material.dart';

import 'package:intl/intl.dart';



import '../../../../app/localization/app_strings.dart';

import 'quest_string_list_field.dart';



class QuestAcceptanceResult {

  const QuestAcceptanceResult({

    required this.assumptions,

    this.deadline,

  });



  final List<String> assumptions;

  final DateTime? deadline;

}



class AcceptQuestSheet extends StatefulWidget {

  const AcceptQuestSheet({

    super.key,

    required this.initialPurpose,

  });



  final String initialPurpose;



  static Future<QuestAcceptanceResult?> show(

    BuildContext context, {

    required String initialPurpose,

  }) {

    return showModalBottomSheet<QuestAcceptanceResult>(

      context: context,

      isScrollControlled: true,

      builder: (_) => AcceptQuestSheet(initialPurpose: initialPurpose),

    );

  }



  @override

  State<AcceptQuestSheet> createState() => _AcceptQuestSheetState();

}



class _AcceptQuestSheetState extends State<AcceptQuestSheet> {

  final _assumptionsKey = GlobalKey<QuestStringListFieldState>();

  DateTime? _acceptanceDeadline;

  String? _assumptionsError;



  Future<void> _pickDeadline() async {

    final now = DateTime.now();

    final picked = await showDatePicker(

      context: context,

      initialDate: _acceptanceDeadline ??

          scheduleCalendarDay(now.add(const Duration(days: 30))),

      firstDate: scheduleCalendarDay(now),

      lastDate: scheduleCalendarDay(now.add(const Duration(days: 365 * 3))),

    );

    if (picked != null) {

      setState(() => _acceptanceDeadline = scheduleCalendarDay(picked));

    }

  }



  void _confirm() {

    final assumptions = _assumptionsKey.currentState?.collectValues() ?? const [];

    if (assumptions.isEmpty) {

      setState(() => _assumptionsError = AppStrings.questAssumptionRequired);

      return;

    }

    Navigator.pop(

      context,

      QuestAcceptanceResult(

        assumptions: assumptions,

        deadline: _acceptanceDeadline,

      ),

    );

  }



  @override

  Widget build(BuildContext context) {

    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;

    final dateFormat = DateFormat('dd/MM/yyyy');



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

              AppStrings.questAcceptTitle,

              style: Theme.of(context).textTheme.titleLarge,

            ),

            const SizedBox(height: ColonySpacing.sm),

            Text(

              AppStrings.questAcceptSubtitle,

              style: Theme.of(context).textTheme.bodyMedium,

            ),

            const SizedBox(height: ColonySpacing.lg),

            QuestStringListField(

              key: _assumptionsKey,

              label: AppStrings.questAcceptanceAssumptions,

              addLabel: AppStrings.questAddAssumption,

              hint: AppStrings.questAssumptionHint,

              initialValues: widget.initialPurpose.trim().isEmpty

                  ? const []

                  : [widget.initialPurpose.trim()],

            ),

            if (_assumptionsError != null) ...[

              const SizedBox(height: ColonySpacing.xs),

              Text(

                _assumptionsError!,

                style: Theme.of(context).textTheme.bodySmall?.copyWith(

                      color: Theme.of(context).colorScheme.error,

                    ),

              ),

            ],

            const SizedBox(height: ColonySpacing.md),

            ListTile(

              contentPadding: EdgeInsets.zero,

              title: Text(AppStrings.questAcceptanceDeadline),

              subtitle: Text(

                _acceptanceDeadline == null

                    ? AppStrings.questNoDeadline

                    : dateFormat.format(_acceptanceDeadline!),

              ),

              trailing: Row(

                mainAxisSize: MainAxisSize.min,

                children: [

                  if (_acceptanceDeadline != null)

                    IconButton(

                      tooltip: AppStrings.questClearDeadline,

                      icon: const Icon(Icons.clear),

                      onPressed: () => setState(() => _acceptanceDeadline = null),

                    ),

                  IconButton(

                    icon: const Icon(Icons.calendar_today_outlined),

                    onPressed: _pickDeadline,

                  ),

                ],

              ),

            ),

            const SizedBox(height: ColonySpacing.lg),

            Row(

              children: [

                Expanded(

                  child: OutlinedButton(

                    onPressed: () => Navigator.pop(context),

                    child: const Text(AppStrings.questAcceptCancel),

                  ),

                ),

                const SizedBox(width: ColonySpacing.md),

                Expanded(

                  child: FilledButton(

                    onPressed: _confirm,

                    child: const Text(AppStrings.questAcceptConfirm),

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

