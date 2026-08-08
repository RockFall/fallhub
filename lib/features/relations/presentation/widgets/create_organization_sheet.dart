import 'package:colony_design_system/colony_design_system.dart';
import 'package:colony_domain/colony_domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/localization/app_strings.dart';
import '../../application/relations_controllers.dart';

class CreateOrganizationSheet extends ConsumerStatefulWidget {
  const CreateOrganizationSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (_) => const CreateOrganizationSheet(),
    );
  }

  @override
  ConsumerState<CreateOrganizationSheet> createState() =>
      _CreateOrganizationSheetState();
}

class _CreateOrganizationSheetState
    extends ConsumerState<CreateOrganizationSheet> {
  final _nameController = TextEditingController();
  final _notesController = TextEditingController();
  OrganizationKind _kind = OrganizationKind.other;
  String? _nameError;

  @override
  void dispose() {
    _nameController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  bool _validate() {
    final name = _nameController.text.trim();
    setState(() {
      _nameError =
          name.isEmpty ? AppStrings.organizationNameRequired : null;
    });
    return _nameError == null;
  }

  Future<void> _save() async {
    if (!_validate()) return;
    final created = await ref
        .read(relationsControllerProvider.notifier)
        .createOrganization(
          name: _nameController.text.trim(),
          kind: _kind,
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
              AppStrings.organizationNew,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: ColonySpacing.lg),
            TextField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: AppStrings.organizationName,
                errorText: _nameError,
              ),
            ),
            const SizedBox(height: ColonySpacing.md),
            DropdownButtonFormField<OrganizationKind>(
              initialValue: _kind,
              decoration: const InputDecoration(
                labelText: AppStrings.organizationKind,
              ),
              items: OrganizationKind.values
                  .map(
                    (kind) => DropdownMenuItem(
                      value: kind,
                      child: Text(AppStrings.organizationKindLabel(kind)),
                    ),
                  )
                  .toList(),
              onChanged: (value) {
                if (value != null) setState(() => _kind = value);
              },
            ),
            const SizedBox(height: ColonySpacing.md),
            TextField(
              controller: _notesController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: AppStrings.organizationNotesOptional,
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
