import 'package:colony_design_system/colony_design_system.dart';
import 'package:colony_domain/colony_domain.dart';
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
  DateTime? _birthday;
  bool _alsoFriendship = false;
  FriendshipKind _kind = FriendshipKind.unspecified;
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

  Future<void> _pickBirthday() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _birthday ?? DateTime(1990, 1, 1),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    if (picked == null) return;
    setState(() => _birthday = DateTime.utc(picked.year, picked.month, picked.day));
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
          birthday: _birthday,
          alsoFriendship: _alsoFriendship,
          friendshipKind: _kind,
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
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(
                _birthday == null
                    ? AppStrings.personBirthdayOptional
                    : '${AppStrings.personBirthdayOptional}: ${_birthday!.toIso8601String().split('T').first}',
              ),
              trailing: const Icon(Icons.cake_outlined),
              onTap: _pickBirthday,
            ),
            const SizedBox(height: ColonySpacing.md),
            TextField(
              controller: _notesController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: AppStrings.personNotesOptional,
              ),
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text(AppStrings.personAlsoFriendship),
              value: _alsoFriendship,
              onChanged: (value) => setState(() => _alsoFriendship = value),
            ),
            if (_alsoFriendship) ...[
              DropdownButtonFormField<FriendshipKind>(
                initialValue: _kind,
                decoration: const InputDecoration(
                  labelText: AppStrings.friendshipKind,
                ),
                items: FriendshipKind.values
                    .map(
                      (k) => DropdownMenuItem(
                        value: k,
                        child: Text(AppStrings.friendshipKindLabel(k)),
                      ),
                    )
                    .toList(),
                onChanged: (value) {
                  if (value != null) setState(() => _kind = value);
                },
              ),
            ],
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
