import 'package:colony_design_system/colony_design_system.dart';
import 'package:colony_domain/colony_domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/localization/app_strings.dart';
import '../../application/health_controllers.dart';
import 'symptom_timeline_panel.dart';

class EditHealthConditionSheet extends ConsumerStatefulWidget {
  const EditHealthConditionSheet({super.key, required this.condition});

  final HealthCondition condition;

  static Future<void> show(BuildContext context, HealthCondition condition) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (_) => EditHealthConditionSheet(condition: condition),
    );
  }

  @override
  ConsumerState<EditHealthConditionSheet> createState() =>
      _EditHealthConditionSheetState();
}

class _EditHealthConditionSheetState
    extends ConsumerState<EditHealthConditionSheet> {
  late final TextEditingController _titleController;
  late final TextEditingController _notesController;
  late final TextEditingController _regionController;
  late HealthConditionType _type;
  late HealthConditionStatus _status;
  late int? _severity;
  String? _titleError;

  static const _editableStatuses = <HealthConditionStatus>[
    HealthConditionStatus.active,
    HealthConditionStatus.monitoring,
    HealthConditionStatus.resolved,
  ];

  @override
  void initState() {
    super.initState();
    final c = widget.condition;
    _titleController = TextEditingController(text: c.title);
    _notesController = TextEditingController(text: c.notes ?? '');
    _regionController = TextEditingController(
      text: c.bodyRegions.isEmpty ? '' : c.bodyRegions.first,
    );
    _type = c.type;
    _status = c.status == HealthConditionStatus.archived
        ? HealthConditionStatus.active
        : c.status;
    _severity = c.severityUserReported;
  }

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
    final now = DateTime.now().toUtc();
    final region = _regionController.text.trim();
    final notes = _notesController.text.trim();

    var updated = widget.condition.copyWith(
      title: _titleController.text.trim(),
      type: _type,
      status: _status,
      severityUserReported: _severity,
      clearSeverity: _severity == null,
      bodyRegions: region.isEmpty ? const [] : [region],
      notes: notes,
      clearNotes: notes.isEmpty,
      updatedAt: now,
    );

    if (_status == HealthConditionStatus.resolved) {
      updated = updated.copyWith(
        resolvedAt: widget.condition.resolvedAt ?? now,
      );
    } else if (widget.condition.resolvedAt != null) {
      updated = updated.copyWith(clearResolvedAt: true);
    }

    final saved =
        await ref.read(healthControllerProvider.notifier).saveCondition(updated);
    if (!mounted || saved == null) return;
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
              AppStrings.healthEditCondition,
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
            DropdownButtonFormField<HealthConditionStatus>(
              initialValue: _status,
              decoration: const InputDecoration(
                labelText: AppStrings.healthConditionStatus,
              ),
              items: _editableStatuses
                  .map(
                    (status) => DropdownMenuItem(
                      value: status,
                      child: Text(
                        AppStrings.healthConditionStatusLabel(status),
                      ),
                    ),
                  )
                  .toList(),
              onChanged: (value) {
                if (value != null) setState(() => _status = value);
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
            const SizedBox(height: ColonySpacing.lg),
            SymptomTimelinePanel(condition: widget.condition),
          ],
        ),
      ),
    );
  }
}
