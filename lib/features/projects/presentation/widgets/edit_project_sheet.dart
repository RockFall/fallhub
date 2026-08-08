import 'package:colony_design_system/colony_design_system.dart';
import 'package:colony_domain/colony_domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/localization/app_strings.dart';
import '../../application/project_controllers.dart';

class EditProjectSheet extends ConsumerStatefulWidget {
  const EditProjectSheet({super.key, required this.project});

  final Project project;

  static Future<void> show(BuildContext context, Project project) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (_) => EditProjectSheet(project: project),
    );
  }

  @override
  ConsumerState<EditProjectSheet> createState() => _EditProjectSheetState();
}

class _EditProjectSheetState extends ConsumerState<EditProjectSheet> {
  late final TextEditingController _titleController;
  late final TextEditingController _purposeController;
  String? _titleError;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.project.title);
    _purposeController = TextEditingController(text: widget.project.purpose ?? '');
  }

  @override
  void dispose() {
    _titleController.dispose();
    _purposeController.dispose();
    super.dispose();
  }

  bool _validate() {
    final title = _titleController.text.trim();
    setState(() {
      _titleError = title.isEmpty ? AppStrings.projectTitleRequired : null;
    });
    return _titleError == null;
  }

  Future<void> _save() async {
    if (!_validate()) return;

    final purpose = _purposeController.text.trim();
    final updated = widget.project.copyWith(
      title: _titleController.text.trim(),
      purpose: purpose.isEmpty ? null : purpose,
      clearPurpose: purpose.isEmpty,
      updatedAt: DateTime.now().toUtc(),
    );

    await ref.read(projectControllerProvider.notifier).updateFields(updated);
    if (!mounted || ref.read(projectControllerProvider).hasError) return;
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
              AppStrings.projectEdit,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: ColonySpacing.lg),
            TextField(
              controller: _titleController,
              decoration: InputDecoration(
                labelText: AppStrings.projectTitle,
                errorText: _titleError,
              ),
              autofocus: true,
            ),
            const SizedBox(height: ColonySpacing.md),
            TextField(
              controller: _purposeController,
              decoration: const InputDecoration(
                labelText: AppStrings.projectPurposeOptional,
              ),
              maxLines: 3,
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
