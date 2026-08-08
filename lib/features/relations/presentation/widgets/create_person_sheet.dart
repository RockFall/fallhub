import 'package:colony_design_system/colony_design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/localization/app_strings.dart';
import '../../application/relations_controllers.dart';

class CreatePersonSheet extends ConsumerStatefulWidget {
  const CreatePersonSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (_) => const CreatePersonSheet(),
    );
  }

  @override
  ConsumerState<CreatePersonSheet> createState() => _CreatePersonSheetState();
}

class _CreatePersonSheetState extends ConsumerState<CreatePersonSheet> {
  final _nameController = TextEditingController();
  final _preferredController = TextEditingController();
  final _typesController = TextEditingController();
  final _notesController = TextEditingController();
  String? _nameError;

  @override
  void dispose() {
    _nameController.dispose();
    _preferredController.dispose();
    _typesController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  bool _validate() {
    final name = _nameController.text.trim();
    setState(() {
      _nameError = name.isEmpty ? AppStrings.personNameRequired : null;
    });
    return _nameError == null;
  }

  List<String> _parseTypes() {
    return _typesController.text
        .split(',')
        .map((t) => t.trim())
        .where((t) => t.isNotEmpty)
        .toList();
  }

  Future<void> _save() async {
    if (!_validate()) return;
    final created = await ref.read(relationsControllerProvider.notifier).create(
          displayName: _nameController.text.trim(),
          preferredName: _preferredController.text.trim().isEmpty
              ? null
              : _preferredController.text.trim(),
          relationshipTypes: _parseTypes(),
          notes: _notesController.text.trim().isEmpty
              ? null
              : _notesController.text.trim(),
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
              AppStrings.personNew,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: ColonySpacing.lg),
            TextField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: AppStrings.personDisplayName,
                errorText: _nameError,
              ),
            ),
            const SizedBox(height: ColonySpacing.md),
            TextField(
              controller: _preferredController,
              decoration: const InputDecoration(
                labelText: AppStrings.personPreferredNameOptional,
              ),
            ),
            const SizedBox(height: ColonySpacing.md),
            TextField(
              controller: _typesController,
              decoration: const InputDecoration(
                labelText: AppStrings.personRelationshipTypesOptional,
                hintText: AppStrings.personRelationshipTypesHint,
              ),
            ),
            const SizedBox(height: ColonySpacing.md),
            TextField(
              controller: _notesController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: AppStrings.personNotesOptional,
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
