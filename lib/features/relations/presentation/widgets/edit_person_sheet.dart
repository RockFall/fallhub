import 'package:colony_design_system/colony_design_system.dart';
import 'package:colony_domain/colony_domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/localization/app_strings.dart';
import '../../application/relations_controllers.dart';
import 'membership_section.dart';

class EditPersonSheet extends ConsumerStatefulWidget {
  const EditPersonSheet({super.key, required this.person});

  final Person person;

  static Future<void> show(BuildContext context, Person person) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (_) => EditPersonSheet(person: person),
    );
  }

  @override
  ConsumerState<EditPersonSheet> createState() => _EditPersonSheetState();
}

class _EditPersonSheetState extends ConsumerState<EditPersonSheet> {
  late final TextEditingController _nameController;
  late final TextEditingController _preferredController;
  late final TextEditingController _typesController;
  late final TextEditingController _notesController;
  String? _nameError;

  @override
  void initState() {
    super.initState();
    final p = widget.person;
    _nameController = TextEditingController(text: p.displayName);
    _preferredController = TextEditingController(text: p.preferredName ?? '');
    _typesController =
        TextEditingController(text: p.relationshipTypes.join(', '));
    _notesController = TextEditingController(text: p.notes ?? '');
  }

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
    final preferred = _preferredController.text.trim();
    final notes = _notesController.text.trim();
    final updated = widget.person.copyWith(
      displayName: _nameController.text.trim(),
      preferredName: preferred,
      clearPreferredName: preferred.isEmpty,
      relationshipTypes: _parseTypes(),
      notes: notes,
      clearNotes: notes.isEmpty,
      updatedAt: DateTime.now().toUtc(),
    );
    final saved =
        await ref.read(relationsControllerProvider.notifier).savePerson(updated);
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
              AppStrings.personEdit,
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
            PersonMembershipsSection(person: widget.person),
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
