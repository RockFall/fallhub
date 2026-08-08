import 'package:colony_design_system/colony_design_system.dart';
import 'package:colony_domain/colony_domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/localization/app_strings.dart';
import '../../application/research_controllers.dart';

class CreateResearchNodeSheet extends ConsumerStatefulWidget {
  const CreateResearchNodeSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (_) => const CreateResearchNodeSheet(),
    );
  }

  @override
  ConsumerState<CreateResearchNodeSheet> createState() =>
      _CreateResearchNodeSheetState();
}

class _CreateResearchNodeSheetState extends ConsumerState<CreateResearchNodeSheet> {
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  ResearchNodeType _type = ResearchNodeType.knowledge;
  String? _titleError;

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  bool _validate() {
    final title = _titleController.text.trim();
    setState(() {
      _titleError = title.isEmpty ? AppStrings.researchTitleRequired : null;
    });
    return _titleError == null;
  }

  Future<void> _save() async {
    if (!_validate()) return;

    final description = _descriptionController.text.trim();
    final node = await ref.read(researchControllerProvider.notifier).create(
          title: _titleController.text.trim(),
          type: _type,
          description: description.isEmpty ? null : description,
        );

    if (!mounted || node == null) return;
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
              AppStrings.newResearchNode,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: ColonySpacing.lg),
            TextField(
              controller: _titleController,
              decoration: InputDecoration(
                labelText: AppStrings.researchTitle,
                errorText: _titleError,
              ),
            ),
            const SizedBox(height: ColonySpacing.md),
            DropdownButtonFormField<ResearchNodeType>(
              initialValue: _type,
              decoration: const InputDecoration(labelText: AppStrings.researchType),
              items: ResearchNodeType.values
                  .map(
                    (type) => DropdownMenuItem(
                      value: type,
                      child: Text(AppStrings.researchTypeLabel(type)),
                    ),
                  )
                  .toList(),
              onChanged: (value) {
                if (value != null) setState(() => _type = value);
              },
            ),
            const SizedBox(height: ColonySpacing.md),
            TextField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: AppStrings.researchDescriptionOptional,
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
