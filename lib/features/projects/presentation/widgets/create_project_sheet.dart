import 'package:colony_design_system/colony_design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/localization/app_strings.dart';
import '../../application/project_controllers.dart';

class CreateProjectSheet extends ConsumerStatefulWidget {
  const CreateProjectSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (_) => const CreateProjectSheet(),
    );
  }

  @override
  ConsumerState<CreateProjectSheet> createState() => _CreateProjectSheetState();
}

class _CreateProjectSheetState extends ConsumerState<CreateProjectSheet> {
  final _titleController = TextEditingController();
  final _purposeController = TextEditingController();
  String? _titleError;

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
    final project = await ref.read(projectControllerProvider.notifier).create(
          title: _titleController.text.trim(),
          purpose: purpose.isEmpty ? null : purpose,
        );

    if (!mounted || project == null) return;
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
              AppStrings.newProject,
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
