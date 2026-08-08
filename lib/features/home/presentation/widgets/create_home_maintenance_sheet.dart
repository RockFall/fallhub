import 'package:colony_design_system/colony_design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/localization/app_strings.dart';
import '../../application/home_controllers.dart';

class CreateHomeMaintenanceSheet extends ConsumerStatefulWidget {
  const CreateHomeMaintenanceSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (_) => const CreateHomeMaintenanceSheet(),
    );
  }

  @override
  ConsumerState<CreateHomeMaintenanceSheet> createState() =>
      _CreateHomeMaintenanceSheetState();
}

class _CreateHomeMaintenanceSheetState
    extends ConsumerState<CreateHomeMaintenanceSheet> {
  final _titleController = TextEditingController();
  final _systemController = TextEditingController();
  final _cadenceController = TextEditingController();
  final _vendorController = TextEditingController();
  final _notesController = TextEditingController();
  String? _titleError;
  String? _systemError;

  @override
  void dispose() {
    _titleController.dispose();
    _systemController.dispose();
    _cadenceController.dispose();
    _vendorController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  bool _validate() {
    final title = _titleController.text.trim();
    final system = _systemController.text.trim();
    setState(() {
      _titleError = title.isEmpty ? AppStrings.homeMaintenanceTitleRequired : null;
      _systemError =
          system.isEmpty ? AppStrings.homeMaintenanceSystemRequired : null;
    });
    return _titleError == null && _systemError == null;
  }

  Future<void> _save() async {
    if (!_validate()) return;
    final cadenceRaw = _cadenceController.text.trim();
    final cadence =
        cadenceRaw.isEmpty ? null : int.tryParse(cadenceRaw);
    if (cadenceRaw.isNotEmpty && (cadence == null || cadence <= 0)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text(AppStrings.homeMaintenanceCadenceInvalid)),
      );
      return;
    }
    final created = await ref.read(homeControllerProvider.notifier).create(
          title: _titleController.text.trim(),
          systemOrItem: _systemController.text.trim(),
          cadenceDays: cadence,
          vendorLabel: _vendorController.text.trim().isEmpty
              ? null
              : _vendorController.text.trim(),
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
              AppStrings.homeMaintenanceNew,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: ColonySpacing.lg),
            TextField(
              controller: _titleController,
              decoration: InputDecoration(
                labelText: AppStrings.homeMaintenanceTitleField,
                errorText: _titleError,
              ),
            ),
            const SizedBox(height: ColonySpacing.md),
            TextField(
              controller: _systemController,
              decoration: InputDecoration(
                labelText: AppStrings.homeMaintenanceSystem,
                errorText: _systemError,
              ),
            ),
            const SizedBox(height: ColonySpacing.md),
            TextField(
              controller: _cadenceController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: AppStrings.homeMaintenanceCadenceOptional,
              ),
            ),
            const SizedBox(height: ColonySpacing.md),
            TextField(
              controller: _vendorController,
              decoration: const InputDecoration(
                labelText: AppStrings.homeMaintenanceVendorOptional,
              ),
            ),
            const SizedBox(height: ColonySpacing.md),
            TextField(
              controller: _notesController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: AppStrings.homeMaintenanceNotesOptional,
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
