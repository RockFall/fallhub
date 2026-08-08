import 'package:colony_design_system/colony_design_system.dart';
import 'package:colony_domain/colony_domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/localization/app_strings.dart';
import '../../application/health_controllers.dart';

class CreateHealthConditionSheet extends ConsumerStatefulWidget {
  const CreateHealthConditionSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (_) => const CreateHealthConditionSheet(),
    );
  }

  @override
  ConsumerState<CreateHealthConditionSheet> createState() =>
      _CreateHealthConditionSheetState();
}

class _CreateHealthConditionSheetState
    extends ConsumerState<CreateHealthConditionSheet> {
  final _titleController = TextEditingController();
  final _notesController = TextEditingController();
  final _regionController = TextEditingController();
  HealthConditionType _type = HealthConditionType.symptom;
  int? _severity;
  String? _titleError;

  @override
  void dispose() {
    _titleController.dispose();
    _notesController.dispose();
    _regionController.dispose();
    super.dispose();
  }

  bool _validate() {
    final title = _titleController.text.trim();
    setState(() {
      _titleError =
          title.isEmpty ? AppStrings.healthConditionTitleRequired : null;
    });
    return _titleError == null;
  }

  Future<void> _save() async {
    if (!_validate()) return;
    final created = await ref.read(healthControllerProvider.notifier).create(
          title: _titleController.text.trim(),
          type: _type,
          severityUserReported: _severity,
          notes: _notesController.text.trim().isEmpty
              ? null
              : _notesController.text.trim(),
          bodyRegion: _regionController.text.trim().isEmpty
              ? null
              : _regionController.text.trim(),
        );
    if (!mounted || created == null) return;
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
              AppStrings.healthNewCondition,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: ColonySpacing.lg),
            TextField(
              controller: _titleController,
              decoration: InputDecoration(
                labelText: AppStrings.healthConditionTitle,
                errorText: _titleError,
              ),
            ),
            const SizedBox(height: ColonySpacing.md),
            DropdownButtonFormField<HealthConditionType>(
              initialValue: _type,
              decoration: const InputDecoration(
                labelText: AppStrings.healthConditionType,
              ),
              items: HealthConditionType.values
                  .map(
                    (type) => DropdownMenuItem(
                      value: type,
                      child: Text(AppStrings.healthConditionTypeLabel(type)),
                    ),
                  )
                  .toList(),
              onChanged: (value) {
                if (value != null) setState(() => _type = value);
              },
            ),
            const SizedBox(height: ColonySpacing.md),
            DropdownButtonFormField<int?>(
              initialValue: _severity,
              decoration: const InputDecoration(
                labelText: AppStrings.healthSeverity,
              ),
              items: [
                const DropdownMenuItem<int?>(
                  value: null,
                  child: Text(AppStrings.healthSeverityNone),
                ),
                for (var i = 1; i <= 5; i++)
                  DropdownMenuItem<int?>(
                    value: i,
                    child: Text('$i'),
                  ),
              ],
              onChanged: (value) => setState(() => _severity = value),
            ),
            const SizedBox(height: ColonySpacing.md),
            TextField(
              controller: _regionController,
              decoration: const InputDecoration(
                labelText: AppStrings.healthBodyRegionOptional,
              ),
            ),
            const SizedBox(height: ColonySpacing.md),
            TextField(
              controller: _notesController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: AppStrings.healthNotesOptional,
              ),
            ),
            const SizedBox(height: ColonySpacing.lg),
            FilledButton(
              onPressed: _save,
              child: Text(AppStrings.save),
            ),
          ],
        ),
      ),
    );
  }
}
