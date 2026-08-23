import 'package:colony_design_system/colony_design_system.dart';
import 'package:colony_domain/colony_domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/localization/app_strings.dart';
import '../../application/relations_controllers.dart';
import '../../application/relations_providers.dart';
import 'edit_friendship_sheet.dart';
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
  DateTime? _birthday;
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
    _birthday = p.birthday;
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
    final preferred = _preferredController.text.trim();
    final notes = _notesController.text.trim();
    final updated = widget.person.copyWith(
      displayName: _nameController.text.trim(),
      preferredName: preferred,
      clearPreferredName: preferred.isEmpty,
      relationshipTypes: _parseTypes(),
      notes: notes,
      clearNotes: notes.isEmpty,
      birthday: _birthday,
      clearBirthday: _birthday == null,
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
    final interactionsAsync =
        ref.watch(personInteractionsProvider(widget.person.id));
    final friendship = ref.watch(friendshipForPersonProvider(widget.person.id));

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
            PersonMembershipsSection(person: widget.person),
            const SizedBox(height: ColonySpacing.md),
            OutlinedButton.icon(
              onPressed: () async {
                if (friendship == null) {
                  await ref
                      .read(relationsControllerProvider.notifier)
                      .ensureFriendship(person: widget.person);
                }
                if (!context.mounted) return;
                final current = ref.read(
                  friendshipForPersonProvider(widget.person.id),
                );
                if (current != null) {
                  await EditFriendshipSheet.show(context, current);
                }
              },
              icon: const Icon(Icons.favorite_outline),
              label: Text(
                friendship == null
                    ? AppStrings.personAddToFriendships
                    : AppStrings.personOpenFriendship,
              ),
            ),
            const SizedBox(height: ColonySpacing.lg),
            Text(
              AppStrings.personInteractionsTitle,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: ColonySpacing.sm),
            interactionsAsync.when(
              loading: () => const LinearProgressIndicator(),
              error: (_, __) => Text(AppStrings.errorGeneric),
              data: (items) {
                if (items.isEmpty) {
                  return Text(AppStrings.personInteractionsEmpty);
                }
                return Column(
                  children: [
                    for (final ix in items.take(8))
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        dense: true,
                        title: Text(AppStrings.interactionKindLabel(ix.kind)),
                        subtitle: Text(
                          [
                            ix.occurredAt.toIso8601String().split('T').first,
                            if (ix.note != null) ix.note!,
                          ].join(' · '),
                        ),
                      ),
                  ],
                );
              },
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
