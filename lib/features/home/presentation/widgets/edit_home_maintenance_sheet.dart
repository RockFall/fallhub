import 'package:colony_design_system/colony_design_system.dart';
import 'package:colony_domain/colony_domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/localization/app_strings.dart';
import '../../../inventory/application/inventory_providers.dart';
import '../../application/home_controllers.dart';

class EditHomeMaintenanceSheet extends ConsumerStatefulWidget {
  const EditHomeMaintenanceSheet({super.key, required this.task});

  final HomeMaintenanceTask task;

  static Future<void> show(BuildContext context, HomeMaintenanceTask task) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (_) => EditHomeMaintenanceSheet(task: task),
    );
  }

  @override
  ConsumerState<EditHomeMaintenanceSheet> createState() =>
      _EditHomeMaintenanceSheetState();
}

class _EditHomeMaintenanceSheetState
    extends ConsumerState<EditHomeMaintenanceSheet> {
  late final TextEditingController _titleController;
  late final TextEditingController _systemController;
  late final TextEditingController _cadenceController;
  late final TextEditingController _vendorController;
  late final TextEditingController _notesController;
  String? _titleError;
  String? _systemError;
  EntityId? _linkedInventoryItemId;

  @override
  void initState() {
    super.initState();
    final t = widget.task;
    _titleController = TextEditingController(text: t.title);
    _systemController = TextEditingController(text: t.systemOrItem);
    _cadenceController = TextEditingController(
      text: t.cadenceDays?.toString() ?? '',
    );
    _vendorController = TextEditingController(text: t.vendorLabel ?? '');
    _notesController = TextEditingController(text: t.notes ?? '');
    _linkedInventoryItemId = t.linkedInventoryItemId;
  }

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
    final cadence = cadenceRaw.isEmpty ? null : int.tryParse(cadenceRaw);
    if (cadenceRaw.isNotEmpty && (cadence == null || cadence <= 0)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text(AppStrings.homeMaintenanceCadenceInvalid)),
      );
      return;
    }
    final updated = widget.task.copyWith(
      title: _titleController.text.trim(),
      systemOrItem: _systemController.text.trim(),
      cadenceDays: cadence,
      clearCadenceDays: cadence == null,
      vendorLabel: _vendorController.text.trim(),
      clearVendorLabel: _vendorController.text.trim().isEmpty,
      notes: _notesController.text.trim(),
      clearNotes: _notesController.text.trim().isEmpty,
      linkedInventoryItemId: _linkedInventoryItemId,
      clearLinkedInventoryItemId: _linkedInventoryItemId == null,
    );
    final saved = await ref.read(homeControllerProvider.notifier).save(updated);
    if (!mounted || saved == null) return;
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final itemsAsync = ref.watch(inventoryItemsProvider);
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
              AppStrings.homeMaintenanceEdit,
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
            const SizedBox(height: ColonySpacing.md),
            itemsAsync.when(
              loading: () => const LinearProgressIndicator(),
              error: (_, __) => Text(AppStrings.errorGeneric),
              data: (items) {
                final active = items
                    .where((i) => !i.status.isHiddenFromActiveList)
                    .toList();
                return DropdownButtonFormField<String?>(
                  // ignore: deprecated_member_use
                  value: _linkedInventoryItemId?.value,
                  decoration: InputDecoration(
                    labelText: AppStrings.homeMaintenanceLinkedInventory,
                    helperText: active.isEmpty
                        ? AppStrings.homeMaintenanceLinkedInventoryEmpty
                        : AppStrings.homeMaintenanceLinkedInventoryHint,
                  ),
                  items: [
                    const DropdownMenuItem<String?>(
                      value: null,
                      child: Text(AppStrings.homeMaintenanceNoInventoryLink),
                    ),
                    ...active.map(
                      (item) => DropdownMenuItem<String?>(
                        value: item.id.value,
                        child: Text(item.name),
                      ),
                    ),
                  ],
                  onChanged: (v) => setState(() {
                    _linkedInventoryItemId =
                        v == null ? null : EntityId(v);
                  }),
                );
              },
            ),
            const SizedBox(height: ColonySpacing.lg),
            FilledButton(
              onPressed: _save,
              child: Text(AppStrings.save),
            ),
            TextButton(
              onPressed: () async {
                final archived = await ref
                    .read(homeControllerProvider.notifier)
                    .archive(widget.task);
                if (!mounted || archived == null) return;
                Navigator.pop(context);
              },
              child: Text(AppStrings.homeMaintenanceArchive),
            ),
          ],
        ),
      ),
    );
  }
}
